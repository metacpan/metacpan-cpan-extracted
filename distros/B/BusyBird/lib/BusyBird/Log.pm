package BusyBird::Log;
use v5.8.0;
use strict;
use warnings;
use Exporter 5.57 qw(import);

our @EXPORT_OK = qw(bblog);
our $Logger = \&default_logger;

sub default_logger {
    my ($level, $msg) = @_;
    my ($caller_package) = caller(1);
    my $output = "$caller_package: $level: $msg";
    $output .= "\n" if $output !~ /[\n\r]$/;
    print STDERR $output;
}

sub bblog {
    my ($level, $msg) = @_;
    $Logger->($level, $msg) if defined $Logger;
}

1;

=pod

=head1 NAME

BusyBird::Log - simple logging infrastructure for BusyBird

=head1 SYNOPSIS


    use BusyBird::Log qw(bblog);
    
    bblog('error', 'Something bad happens');
    
    {
        my @logs = ();
        
        ## Temporarily change the Logger
        local $BusyBird::Log::Logger = sub {
            my ($level, $msg) = @_;
            push(@logs, [$level, $msg]);
        };

        bblog('info', 'This goes to @logs array.');
    }


=head1 DESCRIPTION

L<BusyBird::Log> manages the logger singleton used in L<BusyBird>.

This module is used by some of the L<BusyBird> component modules to log warning/error messages.


=head1 EXPORTABLE FUNCTIONS

The following functions are exported only by request.

=head2 bblog($level, $msg)

Logs the given message.

C<$level> is a string of log level such as 'info', 'warn', 'error', 'critical' etc.
C<$msg> is the log message body.

By default, it prints the log to STDERR.


=head1 PACKAGE VARIABLES

=head2 $BusyBird::Log::Logger = CODEREF($level, $msg)

A subroutine reference that is called when C<bblog()> is called.
The subroutine is supposed to do the logging.

Setting this to C<undef> disables logging at all.

=head1 AUTHOR

Toshio Ito C<< <toshioito [at] cpan.org> >>

=cut

