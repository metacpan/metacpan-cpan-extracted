package Daemon::Daemonize;
BEGIN {
  $Daemon::Daemonize::VERSION = '0.0052';
}
# ABSTRACT: An easy-to-use daemon(izing) toolkit

use warnings;
use strict;


use Sub::Exporter::Util qw/ curry_method /;
use Sub::Exporter -setup => { exports => [ map { $_ => curry_method } qw/
    daemonize
    superclose 
    write_pidfile read_pidfile check_pidfile delete_pidfile
    does_process_exist can_signal_process check_port
/ ] };
use POSIX;
use Carp;
use Path::Class;

sub _fork_or_die {
    my $self = shift;

    my $pid = fork;
    confess "Unable to fork" unless defined $pid;
    return $pid;
}

sub superclose {
    my $self = shift;
    my $from = shift || 0;

    my $openmax = POSIX::sysconf( &POSIX::_SC_OPEN_MAX );
    $openmax = 64 if ! defined( $openmax ) || $openmax < 0;

    return unless $from < $openmax;

    POSIX::close( $_ ) foreach ($from .. $openmax - 1);
}


sub daemonize {
    my $self = shift;
    my %options = @_;

    {
        if ( my $run = delete $options{run} ) {

            if ( -1 == $self->daemonize( %options, continue => 1 ) ) {
                # We're the parent, continue on...
            }
            else {
                # We've daemonized... launch into the code we've been given...
                $run->();
                exit 0;
            }

            return; # Daemonization actually handled in call above... Abort, abort, pull-up!
        }
    }

    my $chdir = exists $options{chdir} ? $options{chdir} : '/';
    my $close = defined $options{close} ? $options{close} : 1;

    # Fork once to go into the background
    {
        if ( my $pid = $self->_fork_or_die ) {
            return -1 if $options{continue};
            exit 0;
        }
    }

    # Create new session
    (POSIX::setsid)
        || confess "Cannot detach from controlling process";

    # Fork again to ensure that daemon never reacquires a control terminal
    $self->_fork_or_die && exit 0;

    # Clear the file creation mask
    umask 0;

    if ( defined $chdir ) {
        chdir $chdir or confess "Unable to chdir to \"$chdir\": $!";
    }

    if ( $close eq 1 || $close eq '!std' ) {
        # Close any open file descriptors
        $self->superclose( $close eq '!std' ? 3 : 0 );
    }

    my $stdout_file = $ENV{DAEMON_DAEMONIZE_STDOUT} || $options{stdout};
    my $stderr_file = $ENV{DAEMON_DAEMONIZE_STDERR} || $options{stderr};

    if ( $close eq 1 || $close eq 'std' ) {
        # Re-open  STDIN, STDOUT, STDERR to /dev/null
        open( STDIN,  "+>/dev/null" ) or confess "Could not redirect STDIN to /dev/null";

        unless ( $stdout_file ) {
            open( STDOUT, "+>&STDIN" ) or confess "Could not redirect STDOUT to /dev/null";
        }

        unless ( $stderr_file ) {
            open( STDERR, "+>&STDIN" ) or confess "Could not redirect STDERR to /dev/null";
        }

        # Avoid 'stdin reopened for output' warning (taken from MooseX::Daemonize)
        local *_NIL;
        open( _NIL, '/dev/null' );
        <_NIL> if 0;
    }

    if ( $stdout_file ) {
        open STDOUT, ">>", $stdout_file or confess "Could not redirect STDOUT to $stdout_file : $!";
    }

    if ( $stderr_file ) {
        open STDERR, ">>", $stderr_file or confess "Could not redirect STDERR to $stderr_file : $!";
    }

    return 1;
}

sub _pidfile($) {
    my $pidfile = shift;
    confess "No pidfile given" unless defined $pidfile;
    return Path::Class::File->new( ref $pidfile eq 'ARRAY' ? @$pidfile : "$pidfile" );
}


sub read_pidfile {
    my $self = shift;
    my $pidfile = _pidfile shift;

    return unless -s $pidfile;
    return unless -f $pidfile && -r $pidfile;
    return scalar $pidfile->slurp( chomp => 1 );
}


sub check_pidfile {
    my $self = shift;
    my $pidfile = _pidfile shift;

    my $pid = $self->read_pidfile( $pidfile );
    return 0 unless $pid;
    return 0 unless $self->does_process_exist( $pid );
    return $pid;
}


sub write_pidfile {
    my $self = shift;
    my $pidfile = _pidfile shift;
    my $pid = shift || $$;

    my $fh = $pidfile->openw;
    $fh->print( $pid . "\n" );
    $fh->close;
}


sub delete_pidfile {
    my $self = shift;
    my $pidfile = _pidfile shift;

    $pidfile->remove;
}


sub does_process_exist {
    my $self = shift;
    my $pid = shift;

    croak "No pid given to check" unless $pid; 

    return 1 if kill 0, $pid;
    my $errno = $!;

    if ( eval { require Errno } ) {
        return 1 if exists &Errno::EPERM && $errno == &Errno::EPERM;
    }

    # So $errno == ESRCH, or we don't have Errno.pm, ... just going to assume non-existent
    return 0;
}


sub can_signal_process {
    my $self = shift;
    my $pid = shift;

    croak "No pid given to check" unless $pid; 

    return kill 0, $pid ? 1 : 0;
    # So $! is ESRCH or EPERM or something else, so we can't signal/control it
}


sub check_port {
    require IO::Socket::INET;
    my $self = shift;
    my $port = shift;

    croak "No port given to check" unless $port; 

    my $socket = IO::Socket::INET->new( PeerAddr => 'localhost', PeerPort => $port, Proto => 'tcp' );
    if ( $socket ) {
        $socket->close;
        return 1;
    }
    return 0;
}


1;

__END__
=pod

=head1 NAME

Daemon::Daemonize - An easy-to-use daemon(izing) toolkit

=head1 VERSION

version 0.0052

=head1 SYNOPSIS

    use Daemon::Daemonize qw/ :all /

    daemonize( %options, run => sub {

        # Daemon code in here...

    } )

    # Do some non-daemon stuff here...

You can also use it in the traditional way, daemonizing the current process:

    daemonize( %options )

    # Daemon code in here...

and use it to check up on your daemon:

    # In your daemon

    use Daemon::Daemonize qw/ :all /

    write_pidfile( $pidfile )
    $SIG{INT} = sub { delete_pidfile( $pidfile ) }

    ... Elsewhere ...

    use Daemon::Daemonize qw/ :all /

    # Return the pid from $pidfile if it contains a pid AND
    # the process is running (even if you don't own it), 0 otherwise
    my $pid = check_pidfile( $pidfile )

    # Return the pid from $pidfile, or undef if the
    # file doesn't exist, is unreadable, etc.
    # This will return the pid regardless of if the process is running
    my $pid = read_pidfile( $pidfile )

=head1 DESCRIPTION

Daemon::Daemonize is a toolkit for daemonizing processes and checking up on them. It takes inspiration from L<http://www.clapper.org/software/daemonize/>, L<MooseX::Daemon>, L<Net::Server::Daemon>

=head2 A note about the C<close> option

If you're having trouble with IPC in a daemon, try closing only STD* instead of everything:

    daemonize( ..., close => std, ... )

This is a workaround for a problem with using C<Net::Server> and C<IPC::Open3> in a daemonized process

=head1 USAGE

You can use the following functions in two ways, by either importing them:

    use Daemon::Daemonize qw/ daemonize /

    daemonize( ... )

or calling them as a class method:

    use Daemon::Daemonize

    Daemon::Daemonize->daemonize

=head2 daemonize( %options )

Daemonize the current process, according to C<%options>:

    chdir <dir>         Change to <dir> when daemonizing. Pass undef for *no* chdir.
                        Default is '/' (to prevent a umount conflict)

    close <option>      Automatically close opened files when daemonizing:

                            1     Close STDIN, STDOUT, STDERR (usually redirected
                                  from/to /dev/null). In addition, close any other
                                  opened files (up to POSIX::_SC_OPEN_MAX)

                            0     Don't close anything

                            std   Only close STD{IN,OUT,ERR} (as in 1)

                        Default is 1 (close everything)

    stdout <file>       Open up STDOUT of the process to <file>. This will override any
                        closing of STDOUT

    stderr <file>       Open up STDERR of the process to <file>. This will override any
                        closing of STDERR

    run <code>          After daemonizing, run the given code and then exit

=head2 read_pidfile( $pidfile )

Return the pid from $pidfile. Return undef if the file doesn't exist, is unreadable, etc.
This will return the pid regardless of if the process is running

For an alternative, see C<check_pidfile>

=head2 check_pidfile( $pidfile )

Return the pid from $pidfile if it contains a pid AND the process is running (even if you don't own it), and 0 otherwise

This method will always return a number

=head2 write_pidfile( $pidfile, [ $pid ] )

Write the given pid to $pidfile, creating/overwriting any existing file. The second
argument is optional, and will default to $$ (the current process number)

=head2 delete_pidfile( $pidfile )

Unconditionally delete (unlink) $pidfile

=head2 does_process_exist( $pid )

Using C<kill>, attempts to determine if $pid exists (is running).

If you don't own $pid, this method will still return true (by examining C<errno> for EPERM).

For an alternative, see C<can_signal_process>

=head2 can_signal_process( $pid )

Using C<kill>, attempts to determine if $pid exists (is running) and is owned (signable) by the user.

=head2 check_port( $port )

Returns true if $port on the localhost is accepting connections. 

=head1 SEE ALSO

L<MooseX::Daemonize>

L<Proc::Daemon>

L<Net::Server::Daemonize>

=head1 AUTHOR

  Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

