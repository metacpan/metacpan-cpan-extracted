package Capture::SystemIO;

use 5.006000;
use strict;
use warnings;

use POSIX qw(SIGQUIT SIGINT);
#use IO::CaptureOutput qw(qxx);
use Capture::Tiny qw(capture tee);
use Exporter qw(import);

use Exception::Class (
    'Capture::SystemIO::Interrupt' => {
        fields => [qw(signal signal_no command stderr stdout)],
    },
    'Capture::SystemIO::Signal' => {
        fields => [qw(signal_no command stderr stdout)],
    },
    'Capture::SystemIO::Error' => {
        fields => [qw(stderr stdout return_code command)],
    },

);
our ($VERSION) = "0.01";
our @EXPORT_OK = qw(cs_system);




#
#  Swiped from IO::CaptureOutput for easy migration to Capture::Tiny
#  Please see IO::CaptureOutput for more information.
#  
sub capture_exec {
    my @args = @_;
    my ($output, $error) = capture sub { system _shell_quote(@args) };
    return wantarray ? ($output, $error) : $output;
}
#rl cut and pasted from above and swapped out capture for tee.
*qxxt = \&capture_exec_t;
sub capture_exec_t {
    my @args = @_;
    my ($output, $error) = tee sub { system _shell_quote(@args) };
    return wantarray ? ($output, $error) : $output;
}

*qxx = \&capture_exec;

# extra quoting required on Win32 systems
*_shell_quote = ($^O =~ /MSWin32/) ? \&_shell_quote_win32 : sub {@_};
sub _shell_quote_win32 {
    my @args;
    for (@_) {
        if (/[ \"]/) { # TODO: check if ^ requires escaping
            (my $escaped = $_) =~ s/([\"])/\\$1/g;
            push @args, '"' . $escaped . '"';
            next;
        }
        push @args, $_
    }
    return @args;
}

#
# End of Swiped Code.
#






=head1 NAME

Capture::SystemIO - system() capture stderr, stdout, and signals.


=head1 SYNOPSIS

 use strict;
 use warnings;
 use Capture::SystemIO qw(cs_system);

 # Run a command; chuck the output.
 cs_system("dd if=/dev/zero of=/dev/sda");


 # Run a command and capture STDIN and STDOUT; do something with it.
 my ($stdin, $stdout) = cs_system("ls -l /bin");

 print "ls said: $$stdout \n\n ls also mentioned: $$stderr";


 # Run a command and check for errors.
 eval {
     cs_system("sudo rm -rf /");
 };
 if (my $e = Exception::Class->Caught("Capture::SystemIO::Interrupt")) {
     print "Keyboard interrupt. Signal: " $e->signal();
     exit();
 } elsif (my $e = Exception::Class->Caught("Capture::SystemIO::Error")) {
     print "Stderr: ". $e->stderr()
	."Stdout: ". $e->stdout()
	."Return code: ". $return_code
	."Command: ". $command
 } elsif (my $e = Exception::Class->Caught())  {
     print "Some other error". $e->stderr();
     $e->rethrow();
 }




=head1 DESCRIPTION


Runs a system command from within Perl and captures both STDOUT
and STDERR;
  
provides exception based interface to SIGINT and SIGQUIT;

provides exceptions for non-zero return values.

=cut




=head1 EXPORTS

=head2 Default

none

=head2 Optional

cs_system

=cut




=head1 CLASS METHODS



=head2 Capture::SystemIO::cs_system()

This is a wrapper for L<system()|perlfunc/"system"> that uses 
L<Capture::Tiny::Capture()> along with  bits and pieces of L<IO::CaptureOutput>,
to capture both STDOUT and STDERR. It also checks the return value of system()
and throws an exception if the command terminated unexpectedly because of a 
signal or the command exited with a non-zero result to indicate failure. In 
which case, the captured STDOUT and STDERR are contained within the exception
object.

When used in list context, references to the captured STDOUT and STDERR are 
returned. In scalar context, however, only numeric exit code for the command is
 returned.

=head3 Example

 my ($$stdout,$stderr) = cs_system("true");
 my ($return) = cs_system("true");

=head3 Arguments

See perfunc system for details

=head3 Return

The return value depends on the context in which cs_system was called

=over

=item Scalar

The return code from the call to system

=item List

References to the captured stderr and stdout

=back


=head3 Exceptions

=over

=item Capture::SystemIO::Interrupt

Thrown if the subprocess terminated as a result of either SIGINT or SIGQUIT

=item Capture::SystemIO::Signal

Thrown if the subprocess terminated as a result of another signal

=item Capture::SystemIO::Error

Thrown if the return value of the subprocess is non-zero

=back

=cut

sub cs_system {
    my @command = @_;
    my $command_str = join " ", @command;
    my ($stdout, $stderr, $success, $exit_code);

    if ($Capture::SystemIO::T || $ENV{CAPTURE_SYSTEM_T}) {
       ($stdout, $stderr, $success, $exit_code) = qxxt(@command);
    } else {
       ($stdout, $stderr, $success, $exit_code) = qxx(@command);
    }
    if (my $code = $?) {
        my $sig_desc;
	if (my $signal = ($code & 127)) {
	    $sig_desc = {
                SIGINT() => "Interrupt",
	        SIGQUIT() => "Quit",
            }->{$signal};
            if ($sig_desc) {
                Capture::SystemIO::Interrupt->throw(
                    command => $command_str,
		    stdout => $stdout,
		    stderr => $stderr,
		    signal => $sig_desc
		);
            } else {
                Capture::SystemIO::Signal->throw(
                    command => $command_str,
		    stdout => $stdout,
		    stderr => $stderr,
		    signal_no => $signal,
		);
                warn "HERE";
            }
        }
        'Capture::SystemIO::Error'->throw(
	    error => "Command: '$command_str'\n Stderr:\n $stderr",
            stdout=>$stdout, stderr=>$stderr, return_code => $code,
            command => $command_str
        );
    }
    wantarray ? \($stdout, $stderr) : $exit_code;
}




=head1 EXCEPTIONS


=head2 Capture::SystemIO::Error

=over

=item $e->stderr()

 my $stderr = $e->stderr();

=item $e->stdout()

 my $stdout = $e->stdout();

=item $e->return_code()

 my $return_code = $e->return_code();

=item $e->command()

 my $command = $e->command();

=back

=head2 Capture::SystemIO::Interrupt

=over

=item $e->signal()

 my $signal = $e->signal();

The name signal that caused the subprocess to terminate

=item $e->signal_no()

 my $signal_number = $e->signal_no();

The numerical signal that caused the subprocess to terminate

=item $e->stdout() 

Standard output captured before termination

=item $e->stdoerr() 

Returns the Standard error output captured before termination of the subprocess


=back

=head2 Capture::SystemIO::Signal

=over

=item $e->signal()

The name of the  signal that caused the subprocess to terminate, if known.

=item $e->signal_no() 

 my $signal_number = $e->signal_no();

The numerical signal that caused the subprocess to terminate


=item $e->stdout() 

Standard output captured before termination

=item $e->stdoerr() 

Returns the Standard error output captured before termination of the subprocess


=back






=head1 TODO

=head2 planned

=over

=item * move pre-condition checks from test suite to Makefile.PL

=item * write more tests

=item * test on more systems/platforms

=back

=head2 possible 

=over

=item Add OO interface for returned output and setting options.

=back




=head1 SEE ALSO

L<Capture::Tiny>,
L<Exception::Class>,
L<IO::CaptureOutput>,
L<perlfunc/"system">,
L<signal(7)>,
L<Posix/SIGNAL>



=head1 AUTHOR

Rudolf Lippan <rlippan@kolkhoz.org>




=head1 LICENSE

You may distribute under the terms of either the GNU General Public License or the Artistic License, as specified in the Perl README file.



=head1 COPYRIGHT

Copyright (c) 2008 - 2010, Remote Linux, Inc.  All rights reserved.

Portions Copyright (c) 2009-2010, Public Karma, Inc.

Portions lifted from IO::CaptureOutput; copyright belongs to the respective authors.

=cut




return q{
    Minnie and Winnie
    Slept in a shell.
    Sleep, little ladies!
    And they slept well.

    Pink was the shell within,
    Silver without;
    Sounds of the great sea
    Wander'd about.

    Sleep, little ladies!
    Wake not soon!
    Echo on echo
    Dies to the moon.

    Two bright stars
    Peep'd into the shell.
    "What are you dreaming of?
    Who can tell?"

    Started a green linnet
    Out of the croft;
    Wake, little ladies,
    The sun is aloft!
};


