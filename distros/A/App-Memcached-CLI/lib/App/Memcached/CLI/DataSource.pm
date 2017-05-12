package App::Memcached::CLI::DataSource;

use strict;
use warnings;
use 5.008_001;

use Carp;
use IO::Socket;
use Time::HiRes;

use App::Memcached::CLI::Util qw(is_unixsocket debug);

sub new {
    my $class = shift;
    my %args  = @_;
    bless \%args, $class;
}

sub connect {
    my $class = shift;
    my $addr  = shift;
    my %opts  = @_;

    my $socket = sub {
        return IO::Socket::UNIX->new(Peer => $addr) if is_unixsocket($addr);
        return IO::Socket::INET->new(
            PeerAddr => $addr,
            Proto    => 'tcp',
            Timeout  => $opts{timeout} || 1,
        );
    }->();
    confess "Can't connect to $addr" unless $socket;

    return $class->new(socket => $socket);
}

sub ping {
    my $self = shift;
    my $version = eval {
        return $self->query_one('version');
    };
    if (!$version or $@) {
        debug "Ping failed.";
        debug "ERROR: " . $@ if $@;
        return;
    }
    return 1;
}

sub get {
    my $self = shift;
    return $self->_retrieve('get', shift);
}

sub gets {
    my $self = shift;
    return $self->_retrieve('gets', shift);
}

sub _retrieve {
    my $self = shift;
    my ($cmd, $keys) = @_;

    my $key_str = join(q{ }, @$keys);
    $self->{socket}->write("$cmd $key_str\r\n");

    my @results;

    while (1) {
        my $response = $self->_readline;
        next if ($response =~ m/^[\r\n]+$/);
        if ($response =~ m/^VALUE (\S+) (\d+) (\d+)(?: (\d+))?/) {
            my %data = (
                key    => $1,
                flags  => $2,
                length => $3,
                cas    => $4,
            );
            local $SIG{ALRM} = sub { die 'Timed out to Read Socket.' };
            alarm 3;
            $self->{socket}->read($response, $data{length});
            alarm 0;
            $data{value} = $response;
            push @results, \%data;
        } elsif ($response =~ m/^END/) {
            last;
        } else {
            warn "Unknown response '$response'";
        }
    }

    return \@results;
}

sub set     { return &_store(shift, 'set', @_); }
sub add     { return &_store(shift, 'add', @_); }
sub replace { return &_store(shift, 'replace', @_); }
sub append  { return &_modify(shift, 'append',  @_); }
sub prepend { return &_modify(shift, 'prepend', @_); }

sub _modify {
    my $self  = shift;
    my ($cmd, $key, $value) = @_;
    return $self->_store($cmd, $key, $value);
}

sub _store {
    my $self   = shift;
    my $cmd    = shift;
    my $key    = shift;
    my $value  = shift;
    my %option = @_;

    my $flags  = $option{flags}  || 0;
    my $expire = $option{expire} || 0;
    my $bytes  = sub {
        use bytes;
        return length $value;
    }->();

    $self->{socket}->write("$cmd $key $flags $expire $bytes\r\n");
    $self->{socket}->write("$value\r\n");
    my $response = eval {
        return $self->_readline;
    };
    if ($@) {
        confess qq{Failed to store data by "$cmd"! ($key, $value) ERROR: } . $@;
    }
    if ($response !~ m/^STORED/) {
        debug qq{Failed to $cmd data as ($key, $value)};
        return;
    }
    return 1;
}

sub cas {
    my $self   = shift;
    my $key    = shift;
    my $value  = shift;
    my $cas    = shift;
    my %option = @_;

    my $flags  = $option{flags}  || 0;
    my $expire = $option{expire} || 0;
    my $bytes  = sub {
        use bytes;
        return length $value;
    }->();

    $self->{socket}->write("cas $key $flags $expire $bytes $cas\r\n");
    $self->{socket}->write("$value\r\n");
    my $response = eval {
        return $self->_readline;
    };
    if ($@) {
        confess qq{Failed to store data by "cas"! ($key, $value) ERROR: } . $@;
    }
    if ($response !~ m/^STORED/) {
        debug qq{Failed to set data as ($key, $value) with cas $cas};
        return;
    }
    return 1;
}

sub delete {
    my $self = shift;
    my $key  = shift;

    my $response = $self->query_one("delete $key");
    if ($response !~ m/^DELETED/) {
        warn "Failed to delete '$key'";
        return;
    }
    return 1;
}

sub touch {
    my $self   = shift;
    my $key    = shift;
    my $expire = shift;

    my $response = $self->query_one("touch $key $expire");
    if ($response =~ m/^NOT_FOUND/) {
        debug "No such data KEY '$key'";
        return;
    } elsif ($response !~ m/^TOUCHED/) {
        warn "Failed to touch '$key' with EXPIRE '$expire'. RES: $response";
        return;
    }
    return 1;
}

sub incr { return &_incr_decr(shift, 'incr', @_); }
sub decr { return &_incr_decr(shift, 'decr', @_); }

sub _incr_decr {
    my $self   = shift;
    my $cmd    = shift;
    my $key    = shift;
    my $number = shift;

    my $response = $self->query_one("$cmd $key $number");
    if ($response =~ m/^NOT_FOUND/) {
        warn "No such data KEY '$key'";
        return;
    } elsif ($response !~ m/^(\d+)/) {
        warn "Failed to $cmd '$key' by number '$number'. RES: $response";
        return;
    }
    my $new_value = $1;
    return $new_value;
}

sub query_one {
    my $self  = shift;
    my $query = shift;

    $self->{socket}->write("$query\r\n");
    my $response = eval {
        return $self->_readline;
    };
    if ($@) {
        confess "Failed to query! query: $query ERROR: " . $@;
    }
    chomp $response if $response;
    return $response;
}

sub query_any {
    my $self  = shift;
    my $query = shift;

    $self->{socket}->write("$query\r\n");

    # Save blocking mode
    my $blocking_mode = $self->{socket}->blocking;

    my $response = eval {
        local $SIG{ALRM} = sub { die 'Timed out to Read Socket.' };
        alarm 5;
        my $resp = q{};
        $self->{socket}->blocking(0);
        my $getline_from_sock = sub {
            for my $i (1..3) {
                my $line = $self->{socket}->getline;
                return $line if defined $line;
                #debug "failed to getline - $i. query: $query";
                Time::HiRes::sleep(0.01);
            }
            return;
        };
        while (my $line = $getline_from_sock->()) {
            $resp .= $line;
        }
        alarm 0;
        return $resp;
    };
    my $err = $@;

    # Restore blocking mode
    $self->{socket}->blocking($blocking_mode);

    if ($err) {
        confess "Failed to query! query: $query ERROR: " . $err;
    }

    return $response;
}

sub query {
    my $self  = shift;
    my $query = shift;
    my $response = eval {
        return $self->_query($query);
    };
    if ($@) {
        confess "Failed to query! query: $query ERROR: " . $@;
    }
    return $response;
}

sub _query {
    my $self  = shift;
    my $query = shift;

    $self->{socket}->write("$query\r\n");

    my @response;
    while (1) {
        my $line = $self->_readline;
        $line =~ s/[\r\n]+$//;
        last if ($line =~ m/^(OK|END)/);
        die $line if ($line =~ m/^(CLIENT|SERVER_)?ERROR/);
        push @response, $line;
    }

    return \@response;
}

sub _readline {
    my $self = shift;
    local $SIG{ALRM} = sub { die 'Timed out to Read Socket.' };
    alarm 3;
    my $line = $self->{socket}->getline;
    alarm 0;
    return $line;
}

sub DESTROY {
    my $self = shift;
    if ($self->{socket}) { $self->{socket}->close; }
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Memcached::CLI::DataSource - Data Access Interface of Memcached server

=head1 SYNOPSIS

    use App::Memcached::CLI::DataSource;
    my $ds = App::Memcached::CLI::DataSource->connect(
            $params{addr}, timeout => $params{timeout}
        );
    my $stats = $ds->query('stats');

=head1 DESCRIPTION

This provides data access interface for Memcached server.

=head1 LICENSE

Copyright (C) YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=cut

