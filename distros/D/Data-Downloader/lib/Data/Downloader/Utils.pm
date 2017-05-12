=head1 NAME

Data::Downloader::Utils;

=head1 DESCRIPTION

Miscellaneous exportable functions.

=head1 FUNCTIONS

=over

=cut

package Data::Downloader::Utils;

use Sub::Exporter -setup => {
             exports => [ qw/human_size do_system_call ERRORDIE WARNDIE/ ] };
use Log::Log4perl qw/:easy/;

use strict;

=item human_size

Given a number of bytes, return a human-readable
string (like du(1))

=cut

sub human_size {
    my $val   = shift;
    my @units = qw/B K M G T P/;
    my $unit = shift @units;
    do {
        $unit = shift @units;
        $val /= 1000;
    } until $val < 1000 || !@units;
    return sprintf( "%.1f%s", $val, $unit );
}

=item do_system_call

Test commands without invoking system calls.
Returns 1 on success, dies on failure.

=cut

sub do_system_call {
    # Hook for test scripts. 
    if ($ENV{TEST_SYSTEM_STUB} && $ENV{HARNESS_ACTIVE}) { 
        my $cmd = \& { $ENV{TEST_SYSTEM_STUB} };
        return &$cmd(@_);
    } else {
        system(@_) == 0 or do {
            ERROR "command: @_ failed : $? ".(${^CHILD_ERROR_NATIVE} || '');
	    return;
        };
    }
    return 1;
}

=item WARNDIE

Logs an WARN message and then dies.

=cut

sub WARNDIE {
    WARN @_;
    die;
}

=item ERRORDIE

Logs an ERROR and then dies.

=cut

sub ERRORDIE {
    ERROR @_;
    die;
}

=back

=head1 SEE ALSO

Sub::Exporter 

=cut

1;

