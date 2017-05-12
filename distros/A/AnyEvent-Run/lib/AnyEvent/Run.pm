package AnyEvent::Run;

use strict;
use base 'AnyEvent::Handle';

use AnyEvent ();
use AnyEvent::Util ();
use Carp;
use POSIX ();

our $VERSION = 0.01;

our $FD_MAX = eval { POSIX::sysconf(&POSIX::_SC_OPEN_MAX) - 1 } || 1023;

BEGIN {
    if ( AnyEvent::WIN32 ) {
        eval { require Win32 };
        die "Win32 failed to load:\n$@" if $@;
        
        eval { require Win32::Console };
        die "Win32::Console failed to load:\n$@" if $@;
        Win32::Console->import();
        
        eval { require Win32API::File };
        die "Win32API::File failed to load:\n$@" if $@;
        Win32API::File->import('FdGetOsFHandle');
        
        eval { require Win32::Job };
        die "Win32::Job failed to load:\n$@" if $@;
    }
};

sub new {
    my ( $class, %args ) = @_;
    
    my $cls = $args{class};
    my $cmd = $args{cmd};
    
    unless ( $cls || $cmd ) {
        croak "mandatory argument cmd or class is missing";
    }
    
    if ( $cls ) {
        my $method = $args{method} || 'main';
        # double quotes around -e needed on Windows for some reason
        $cmd = "$^X -M$cls -I" . join( ' -I', @INC ) . " -e \"${cls}::${method}()\"";
    }
    
    $args{args} ||= [];
    
    my ($parent, $child) = AnyEvent::Util::portable_socketpair
        or croak "unable to create AnyEvent::Run socketpair: $!";
        
    $args{fh} = $child;
    
    my $self = $class->SUPER::new(%args);

    my $pid = fork;
    
    if ( $pid == 0 ) {
        # child
        
        close $child;
                
        # Stdio should not be tied.
        if (tied *STDOUT) {
            carp "Cannot redirect into tied STDOUT.  Untying it";
            untie *STDOUT;
        }
        if (tied *STDERR) {
            carp "Cannot redirect into tied STDERR.  Untying it";
            untie *STDERR;
        }
        
        # Set priority if requested
        if ( $args{priority} && $args{priority} =~ /^-?\d+$/ ) {
            $self->_set_priority();
        }
        
        # Redirect STDIN from the read end of the stdin pipe.
        close STDIN if AnyEvent::WIN32;
        open STDIN, "<&" . fileno($parent)
            or croak "can't redirect STDIN in child pid $$: $!";

        # Redirect STDOUT
        close STDOUT if AnyEvent::WIN32;
        open STDOUT, ">&" . fileno($parent)
            or croak "can't redirect stdout in child pid $$: $!";

        # Redirect STDERR
        close STDERR if AnyEvent::WIN32;
        open STDERR, ">&" . fileno($parent) 
            or die "can't redirect stderr in child: $!";
        
        # Make STDOUT and STDERR auto-flush.
        select STDERR; $| = 1;
        select STDOUT; $| = 1;
        
        if ( AnyEvent::WIN32 )  {
            # The Win32 pseudo fork sets up the std handles in the child
            # based on the true win32 handles For the exec these get
            # remembered, so manipulation of STDIN/OUT/ERR is not enough.
            # Only necessary for the exec, as Perl CODE subroutine goes
            # through 0/1/2 which are correct.  But of course that coderef
            # might invoke exec, so better do it regardless.
            # HACK: Using Win32::Console as nothing else exposes SetStdHandle
            Win32::Console::_SetStdHandle(
                STD_INPUT_HANDLE(),
                FdGetOsFHandle(fileno($parent))
            );
            Win32::Console::_SetStdHandle(
                STD_OUTPUT_HANDLE(),
                FdGetOsFHandle(fileno($parent))
            );
            Win32::Console::_SetStdHandle(
                STD_ERROR_HANDLE(),
                FdGetOsFHandle(fileno($parent))
            );
        }
        
        if ( ref $cmd eq 'CODE' ) {
            unless ( AnyEvent::WIN32 ) {
                my @fd_keep = (
                    fileno(STDIN),
                    fileno(STDOUT),
                    fileno(STDERR),
                    fileno($parent),
                );
                
                for my $fd ( 0..$FD_MAX ) {
                    next if grep { $_ == $fd } @fd_keep;
                    POSIX::close($fd);
                }
            }
              
            $cmd->( @{$args{args}} );
            
            close $parent;
            
            if ( AnyEvent::WIN32 ) {
                sleep 10; # give parent a chance to kill us
                exit 1;
            }
            else {
                POSIX::_exit(0);
            }
        }
        
        if ( AnyEvent::WIN32 ) {
            my $exitcode = 0;
            
            # XXX: should close open fd's, but it doesn't seem to work right on win32

            my ($appname, $cmdline);

            if ( ref $cmd eq 'ARRAY' ) {
                $appname = $cmd->[0];
                $cmdline = join(' ', map { /\s/ && ! /"/ ? qq{"$_"} : $_ } (@{$cmd}, @{$args{args}}) );
            }
            else {
                $appname = undef;
                $cmdline = join(' ', $cmd, map { /\s/ && ! /"/ ? qq{"$_"} : $_ } @{$args{args}} );
            }

            my $w32job;

            unless ( $w32job = Win32::Job->new() ) {
                die Win32::FormatMessage( Win32::GetLastError() );
            }

            my $w32pid;

            unless ( $w32pid = $w32job->spawn( $appname, $cmdline ) ) {
                die Win32::FormatMessage( Win32::GetLastError() );
            }
            else {
                my $ok = $w32job->watch( sub { 0 }, 60 );
                my $hashref = $w32job->status();
                $exitcode = $hashref->{$w32pid}->{exitcode};
            }

            close $parent;
            
            sleep 10; # give parent a chance to kill us
            exit($exitcode);
        }
        
        if ( ref $cmd eq 'ARRAY' ) {
            exec( @{$cmd}, @{$args{args}} )
                or die "can't exec (" . @{$cmd} . ") in child pid $$: $!";
        }
        else {
            exec( join(" ", $cmd, @{$args{args}} ) )
                or die "can't exec ($cmd) in child pid $$: $!";
        }
        
        # end of child
    }
    
    # parent
    close $parent;
    
    $self->{child_pid} = $pid;
    
    return $self;
}

sub _set_priority {
    my $self = shift;
    
    my $pri = $self->{priority};
    
    if ( AnyEvent::WIN32 ) {
        eval { require Win32::API };
        die "Win32::API failed to load:\n$@" if $@;
        
        eval { require Win32::Process };
        die "Win32::Process failed to load:\n$@" if $@;
        
        # ABOVE_NORMAL_PRIORITY_CLASS and BELOW_NORMAL_PRIORITY_CLASS aren't
        # provided by Win32::Process so their values have been hardcoded.
        $pri = $pri <= -16 ? Win32::Process::HIGH_PRIORITY_CLASS()
             : $pri <= -6  ? 0x00008000 # ABOVE_NORMAL
             : $pri <= 4   ? Win32::Process::NORMAL_PRIORITY_CLASS()
             : $pri <= 14  ? 0x00004000 # BELOW_NORMAL
             :               Win32::Process::IDLE_PRIORITY_CLASS();
        
        my $getCurrentProcess = Win32::API->new('kernel32', 'GetCurrentProcess', ['V'], 'N');
        my $setPriorityClass  = Win32::API->new('kernel32', 'SetPriorityClass',  ['N', 'N'], 'N');
        
        my $processHandle = eval { $getCurrentProcess->Call(0) };
        
        if ( !$processHandle || $@ ) {
            carp "Can't get process handle ($^E) [$@]";
            return;
        }
        
        eval { $setPriorityClass->Call($processHandle, $pri) };
        
        if ( $@ ) {
            carp "Couldn't set priority to $pri ($^E) [$@]";
        }
    }
    else {
        eval {
            unless ( setpriority( 0, $$, $pri ) ) {
                die "unable to set child priority to $pri\n";
            }
        };
        carp $@ if $@;
    }
}

sub DESTROY {
    my $self = shift;
    
    # XXX: doesn't play nice with linger option, so clear wbuf
    $self->{wbuf} = '';
    
    $self->SUPER::DESTROY(@_);
    
    if ( $self->{child_pid} ) {
        kill 9 => $self->{child_pid};
        waitpid $self->{child_pid}, 0;
    }
}

1;
__END__

=head1 NAME

AnyEvent::Run - Run a process or coderef asynchronously

=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::Run;
    
    my $cv = AnyEvent->condvar;

    my $handle = AnyEvent::Run->new(
        cmd      => [ 'ls', '-l' ],
        priority => 19,              # optional nice value 
        on_read  => sub {
            my $handle = shift;
            ...
            $cv->send;
        },
        on_error  => sub {
            my ($handle, $fatal, $msg) = @_;
            ...
            $cv->send;
        },
    );
    
    # Send data to the process's STDIN
    $handle->push_write($data);

    $cv->recv;

=head1 DESCRIPTION

AnyEvent::Run is a subclass of L<AnyEvent::Handle>, so reading it's
documentation first is recommended.

This module is designed to run a child process, using an explicit
command line, a class name, or a coderef.  It should work on any
Unix system as well as Windows 2000 and higher.

For an alternate way of running a coderef in a forked process using
AnyEvent, see L<AnyEvent::Util>'s fork_call function.

=head1 METHODS

=head2 $handle = new( %args )

Creates and returns a new AnyEvent::Run object.  The process forks and either
execs (Unix) or launches a new process (Windows).  If using a coderef, the
coderef is run in the forked process.

The process's STDIN, STDOUT, and STDERR and connected to $handle->{fh}.

The child process is automatically killed if the AnyEvent::Run object goes out
of scope.

See L<AnyEvent::Handle> for additional parameters for new().

=over 4

=item cmd

Required. Takes a string, an arrayref, or a code reference.

    cmd => 'ps ax'
    cmd => [ 'ps, 'ax' ]
    cmd => sub { print "Hi, I'm $$\n" }

When launching an external command, using an arrayref is recommended so
that your command is properly escaped.

Take care when using coderefs on Windows, as your code will run in
a thread.  Avoid using modules that are not thread-safe.

=item args

Optional. Arrayref of arguments to be passed to cmd.

=item class

Optional. Class name to be loaded in the child process. Using this
method is a more efficient way to execute Perl code than by using a
coderef. This will exec a new Perl interpreter, loading only this class,
and will call that class's main() method.

    my $handle = AnyEvent::Run->new(
        class => 'My::SubProcess',
        ...
    );
    
    package My::SubProcess;
    
    sub main {
        print "Hi, I'm $$\n";
    }
    
    1;

=item method

Optional. When using class, instead of calling main(), the given method will
be called.

=item priority

Optional. A numeric value between -19 and 19. On Unix, you must be root
to change the priority to a value less than 0.  On Windows, these
values are mapped to the following priority levels:

    -19 to -16  High
    -15 to  -6  Above Normal
    -5  to   4  Normal
     5  to  14  Below Normal
    15  to  19  Idle

=back

=head1 BUGS

L<AnyEvent::Handle>'s linger option is not supported.

Open file descriptors are not closed under Windows after forking.

=head1 THANKS

This module was based in part on L<POE::Wheel::Run> and L<POE::Wheel::Run::Win32>.

=head1 SEE ALSO

L<AnyEvent>
L<AnyEvent::Handle>
L<AnyEvent::Util>

=head1 AUTHOR

Andy Grundman, E<lt>andy@hybridized.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This program is free software, you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
