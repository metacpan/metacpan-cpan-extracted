# $Id: Clamd.pm,v 1.12 2002/11/21 14:51:45 matt Exp $

package Clamd;
use strict;
use vars qw($VERSION);
use File::Find qw(find);
use IO::Socket;

$VERSION = '1.04';

=head1 NAME

Clamd - Connect to a local clamd service and send commands

=head1 SYNOPSIS

  my $clamd = Clamd->new();
  if ($clamd->ping) {
    my %found = $clamd->scan('/tmp');
    foreach my $file (keys %found) {
      print "Found virus: $found{$file} in $file\n";
    }
  }

=head1 DESCRIPTION

This module provides a simplified perl interface onto a local
clamd scanner, allowing you to do fast virus scans on files
on your local hard drive. It also simplifies and unifies the
clamd interface.

=head1 API

=head2 new()

Create a new Clamd object. By default tries to connect to a
local unix domain socket at F</tmp/clamd>. Options are passed
in as key/value pairs.

B<Available Options:>

=over 4

=item * port

A port or socket to connect to if you do not wish to use the
unix domain socket at F</tmp/clamd>. If the socket has been
setup as a TCP/IP socket (see the C<TCPSocket> option in the
F<clamav.conf> file), then specifying in a number will cause Clamd
to use a TCP socket.

Examples:

  my $clamd = Clamd->new(); # Default - uses /tmp/clamd socket
  
  # Use the unix domain socket at /var/sock/clam
  my $clamd = Clamd->new(port => '/var/sock/clam');
  
  # Use tcp/ip at port 3310
  my $clamd = Clamd->new(port => 3310);

Note: there is no way to connect to a clamd on another machine.
The reason for this is that clamd can only scan local files,
so there would not be much point in doing this (unless you
had NFS shares). Plus if you are using TCP/IP clamd appears
to bind to all adaptors, so it is probably insecure.

=item * find_all

By default clamd will stop at the first virus it detects. This
is useful for performance, but sometimes you want to find all
possible viruses in all of the files. To do that, specify a
true value for find_all.

Examples:

  # Stop at first virus
  my $clamd = Clamd->new();
  my ($file, $virus) = $clamd->scan('/home/bob');
  
  # Return all viruses
  my $clamd = Clamd->new(find_all => 1);
  my %caught = $clamd->scan('/home/bob');

=cut

sub new {
    my $class = shift;
    my (%options) = @_;
    $options{port} ||= '/tmp/clamd';
    $options{find_all} ||= 0;
    return bless \%options, $class;
}

=head2 ping()

Pings the clamd to check it is alive. Returns true if it is
alive, false if it is dead. Note that it is still possible for
a race condition to occur between your test for ping() and
any call to scan(). See below for more details.

=cut

sub ping {
    my $self = shift;
    my $response;
    eval {
        my $conn = $self->_get_connection();
        print $conn "PING\n";
        $response = $conn->getline;
        1 while (<$conn>);
        $conn->close;
    };
    $response = '' unless defined $response;
    chomp($response);
    return $response eq 'PONG';
}

=head2 scan($dir_or_file)

Scan a directory or a file. Note that the resource must be
readable by the user clamd is running as.

Returns a hash of C<< filename => virusname >> mappings.

If we cannot connect to the clamd backend for any reason, an
exception will be thrown.

If clamd encounters an error (for example it cannot read a
file) then it will throw an exception. If you wish to
continue in the presence of errors, you will need to pass
an option to scan() as follows:

  $clamd->scan($dir, { RaiseError => 0 });

=cut

sub scan {
    my $self = shift;
    if ($self->{find_all}) {
        return $self->_scan('SCAN', @_);
    }
    return $self->_scan_shallow('SCAN', @_);
}

=head2 rawscan($dir_or_file)

Same as scan(), but does not scan inside of archives.

=cut

sub rawscan {
    my $self = shift;
    if ($self->{find_all}) {
        return $self->_scan('RAWSCAN', @_);
    }
    return $self->_scan_shallow('RAWSCAN', @_);
}

sub _scan {
    my $self = shift;
    my $cmd = shift;
    my $options = {};
    if (ref($_[-1]) eq 'HASH') {
        # Last param is options
        $options = pop(@_);
    }
    
    # Ugh - a bug in clamd makes us do every file
    # on a separate connection! So we will do a File::Find
    # ourselves to get all the files, then do each on
    # a separate connection to the daemon. Hopefully
    # this bug will be fixed and I can remove this horrible
    # hack.
    
    # Files
    my @files = grep { -f $_ } @_;
    
    # Directories
    foreach my $dir (@_) {
        next unless -d $dir;
        find( 
            sub {
                if (-f $File::Find::name) {
                    push @files, $File::Find::name;
                }
            }, $dir);
    }

    if (!@files) {
        die "You must specify a directory or file to scan";
    }
    
    my @results;
    foreach my $file (@files) {
        push @results, $self->_scan_shallow($cmd, $file, $options);
    }
    return @results;
}

sub _scan_shallow {
    # same as _scan, but stops at first virus
    my $self = shift;
    my $cmd = shift;
    my $options = {};
    if (ref($_[-1]) eq 'HASH') {
        # Last param is options
        $options = pop(@_);
    }
    $options->{RaiseError} = 1 unless exists($options->{RaiseError});
    $options->{ShowWarnings} = 1 unless exists($options->{ShowWarnings});
    my @dirs = @_;

    my @results;
    
    foreach my $file (@dirs) {
        my $conn = $self->_get_connection();
        print $conn "$cmd $file\n";
        
        while (my $result = $conn->getline) {
            chomp($result);
            if ($result !~ /^(.*): (.*)(ERROR|FOUND|OK)$/ and $options->{ShowWarnings}) {
                warn("Unrecognised line from clamd: $result\n");
            }
            my ($filename, $desc, $type) = ($1, $2, $3);
            if ($type eq 'ERROR' and $options->{RaiseError}) {
                die("Error processing $filename: $desc");
            }
            elsif ($type eq 'FOUND') {
                push @results, $filename, $desc;
            }
        }
    }
    return @results;
}

=head2 quit()

Sends the QUIT message to clamd, causing it to cleanly exit.

This may or may not work, I think due to bugs in clamd's C code
(it does not waitpid after a child exit, so you get zombies). However
it seems to be fine on BSD derived operating systems (i.e. it's just
broken under Linux).

The test file t/03quit.t will currently wait 5 seconds before trying
a kill -9 to get rid of the process. You may have to do something
similar on Linux, or just don't use this method to kill Clamd - use
C<kill `cat /path/to/clamd.pid`> instead which seems to work fine.

=cut

sub quit {
    my $self = shift;
    my $conn = $self->_get_connection();
    print $conn "QUIT\r\n";
    1 while (<$conn>);
    $conn->close;
    return 1;
}

=head2 reload()

Cause clamd to reload its virus database.

=cut

sub reload {
    my $self = shift;
    my $conn = $self->_get_connection();
    print $conn "RELOAD\n";
    my $response = $conn->getline;
    1 while (<$conn>);
    $conn->close;
    return 1;
}

sub _get_connection {
    my $self = shift;
    # Check if port containst any non-digits
    if ($self->{port} =~ /\D/) {
        return $self->_get_unix_connection();
    }
    else {
        return $self->_get_tcp_connection();
    }
}

sub _get_tcp_connection {
    my $self = shift;
    return IO::Socket::INET->new(
        PeerAddr => 'localhost',
        PeerPort => $self->{port},
        Proto => 'tcp',
        Type => SOCK_STREAM,
        Timeout => 10,
        ) || die "Cannot connect to 'localhost:$self->{port}': $!";
}

sub _get_unix_connection {
    my $self = shift;
    return IO::Socket::UNIX->new(
        Type => SOCK_STREAM,
        Peer => $self->{port},
        ) || die "Cannot connect to unix socket '$self->{port}': $!";
}

1;
__END__

=head1 AUTHOR

Matt Sergeant, All Rights Reserved.

=head1 LICENSE

This is free software. You may use and distribute it under the same
terms as perl itself.

=cut
