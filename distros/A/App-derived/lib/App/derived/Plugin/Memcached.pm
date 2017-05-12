package App::derived::Plugin::Memcached;

use strict;
use warnings;
use parent qw/App::derived::Plugin/;
use Class::Accessor::Lite (
    ro => [qw/host port timeout/],
);
use IO::Socket::INET;
use POSIX qw(EINTR EAGAIN EWOULDBLOCK :sys_wait_h);
use Socket qw(IPPROTO_TCP TCP_NODELAY);
use Log::Minimal;

our $MAX_REQUEST_SIZE = 131072;
our $CRLF      = "\x0d\x0a";
our $DELIMITER = "\x20";

sub init {
    my $self = shift;

    $self->{host} = '0' unless $self->{host};
    $self->{port} = 12306 unless $self->{port};
    $self->{timeout} = 10 unless $self->{timeout};
    
    my $localaddr = $self->{host} .':'. $self->{port};
    my $sock = IO::Socket::INET->new(
        Listen    => SOMAXCONN,
        LocalAddr => $localaddr,
        Proto     => 'tcp',
        (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
    ) or die "failed to listen to port $localaddr: $!";
    infof('Memcached server starts listen on %s',$localaddr);
    $self->add_worker(
        'memcached_server_'.$localaddr,
        sub {
            $0 = "$0 memcached_server";
            $self->server($sock);            
        }
    );
}

sub server {
    my $self = shift;
    my $sock = shift;

    local $SIG{CHLD} = sub {
        1 until (-1 == waitpid(-1, WNOHANG));
    };

    while(1) {
        local $SIG{PIPE} = 'IGNORE';
        if ( my $conn = $sock->accept ) {
            debugf("[server] new connection from %s:%s", $conn->peerhost, $conn->peerport);
            $conn->blocking(0)
                or die "failed to set socket to nonblocking mode:$!";
            $conn->setsockopt(IPPROTO_TCP, TCP_NODELAY, 1)
                or die "setsockopt(TCP_NODELAY) failed:$!";
            my $pid = fork();
            die "cannot fork: $!" unless defined $pid;
            if ( $pid == 0 ) {
                $self->handle_connection($conn);
                debugf("[server] close connection: %s:%s", $conn->peerhost, $conn->peerport);
                $conn->close;
                exit;
            }
            $conn->close;
        }
    }

}

sub handle_connection {
    my ($self, $conn) = @_;
    
    my $buf = '';
    my $req = +{};

    while (1) {
        my $rlen = read_timeout(
            $conn, \$buf, $MAX_REQUEST_SIZE - length($buf), length($buf), $self->{timeout},
        ) or last;
        if ( parse_read_buffer($buf, $req ) ) {
            $buf = '';
            if ( $req->{cmd} eq 'get' ) {
                my @keys = split /\x20+/, $req->{keys};
                my $result;
                debugf("[server] request get => %s from %s:%s", $req->{keys}, $conn->peerhost, $conn->peerport);
                for my $key ( @keys ) {
                    my $mode = '';
                    if ( $key =~ m!:full$! ) {
                        $mode = 'full';
                        $key =~ s!:full$!!;
                    }
                    elsif ( $key =~ m!:latest$! ) {
                        $mode = 'latest';
                        $key =~ s!:latest$!!;                        
                    }
                    if ( $self->exists_service($key) ) {
                        my $ref = $self->service_stats($key);
                        if ( $mode eq 'full' ) {
                            my $val = $self->json->encode($ref);
                            $result .= join $DELIMITER, "VALUE", $key, 0, length($val);
                            $result .= $CRLF . $val . $CRLF;
                        }
                        elsif ( $mode eq 'latest' ) {
                            if ( defined $ref->{latest} ) {
                                my $val = $ref->{latest};
                                $result .= join $DELIMITER, "VALUE", $key, 0, length($val);
                                $result .= $CRLF . $val . $CRLF;
                            }
                        }
                        else {
                            if ( defined $ref->{persec} ) {
                                my $val = $ref->{persec};
                                $result .= join $DELIMITER, "VALUE", $key, 0, length($val);
                                $result .= $CRLF . $val . $CRLF;
                            }
                        }
                    }
                }
                $result .= "END" . $CRLF;
                write_all( $conn, $result, $self->{timeout} );
            }
            elsif ( $req->{cmd} eq 'version' ) {
                write_all( $conn, "VERSION $App::derived::VERSION$CRLF", $self->{timeout} );
            }
            elsif ( $req->{cmd} eq 'quit' ) {
                #do nothing
                last;
            }
            else {
                write_all( $conn, "ERROR".$CRLF, $self->{timeout} );
            }
        }
    }
    return;
}

sub parse_read_buffer {
    my ($buf, $ret) = @_;
    if ( $buf =~ /$CRLF$/o ) {
        my ($req_line) = split /$CRLF/, $buf;
        ($ret->{cmd}, $ret->{keys}) = split /$DELIMITER/o, $req_line, 2;
        $ret->{keys} ||= '';
        return 1;
    }
    return;
}

# returns (positive) number of bytes read, or undef if the socket is to be closed
sub read_timeout {
    my ($sock, $buf, $len, $off, $timeout) = @_;
    do_io(undef, $sock, $buf, $len, $off, $timeout);
}

# returns (positive) number of bytes written, or undef if the socket is to be closed
sub write_timeout {
    my ($sock, $buf, $len, $off, $timeout) = @_;
    do_io(1, $sock, $buf, $len, $off, $timeout);
}

# writes all data in buf and returns number of bytes written or undef if failed
sub write_all {
    my ($sock, $buf, $timeout) = @_;
    my $off = 0;
    while (my $len = length($buf) - $off) {
        my $ret = write_timeout($sock, $buf, $len, $off, $timeout)
            or return;
        $off += $ret;
    }
    return length $buf;
}

# returns value returned by $cb, or undef on timeout or network error
sub do_io {
    my ($is_write, $sock, $buf, $len, $off, $timeout) = @_;
    my $ret;
 DO_READWRITE:
    # try to do the IO
    if ($is_write) {
        $ret = syswrite $sock, $buf, $len, $off
            and return $ret;
    } else {
        $ret = sysread $sock, $$buf, $len, $off
            and return $ret;
    }
    unless ((! defined($ret)
                 && ($! == EINTR || $! == EAGAIN || $! == EWOULDBLOCK))) {
        return;
    }
    # wait for data
 DO_SELECT:
    while (1) {
        my ($rfd, $wfd);
        my $efd = '';
        vec($efd, fileno($sock), 1) = 1;
        if ($is_write) {
            ($rfd, $wfd) = ('', $efd);
        } else {
            ($rfd, $wfd) = ($efd, '');
        }
        my $start_at = time;
        my $nfound = select($rfd, $wfd, $efd, $timeout);
        $timeout -= (time - $start_at);
        last if $nfound;
        return if $timeout <= 0;
    }
    goto DO_READWRITE;
}

1;


__END__

=encoding utf8

=head1 NAME

App::derived::Plugin::Memcached - memcached-protocol server for derived

=head1 SYNOPSIS

  $ derived -MMemcahced,port=12306 CmdsFile

=head1 DESCRIPTION

This plugin has a memcached-protocol server. You can get some status from 
any memcached client.

=head1 ARGUMENTS

=over 4

=item port:Int

Port number to bind

=item host:String

Host name or Address to bind

=item timeout:Int

Timeout seconds to read request. default 10.

=back

=head1 CLIENT SAMPLE

You can access to data by any memcached client.

  use Cache::Memcached::Fast;

  my $memcached = Cache::Memcached::Fast->new({
    servers => [qw/localhost:12306/],
  });

  say $memcached->get('slowqueris'); # only per seconds value.
  say $memcached->get('slowqueris:latest'); # only latest value.
  say $memcached->get('slowqueris:full'); #JSON formated data include raw values
  
=head1 SEE ALSO

<drived>, <App::derived::Plugin> for writing plugins

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=head1 LICENSE

Copyright (C) Masahiro Nagano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

