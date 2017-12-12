=head1 NAME

App::sdif::osx_autocolor

=head1 SYNOPSIS

sdif -Mosx_autocolor

=head1 DESCRIPTION

This is a module for L<sdif(1)> command to set default option
according to terminal background color taken by AppleScript.  Terminal
brightness is caliculated from terminal background RGB values by next
equation.

    Y = 0.30 * R + 0.59 * G + 0.11 * B

When the result is greater than 0.5, set B<--LIGHT_SCREEN> option,
otherwise set B<--DARK_SCREEN> option.

Because these options are not defined in this module, user have to
define them somewhere.

If the environment variable C<BRIGHTNESS> is defined, its value is
used as a brightness rather than caliculated from terminal color.  The
value of C<BRIGHTNESS> is in a range of 0 to 100.

=head1 SEE ALSO

L<App::sdif::colors>

=cut

package App::sdif::osx_autocolor;

use strict;
use warnings;

sub brightness {
    defined $ENV{BRIGHTNESS} and return $ENV{BRIGHTNESS};
    my $app = "Terminal";
    my $do = "background color of first window";
    my $bg = qx{osascript -e \'tell application \"$app\" to $do\'};
    my($r, $g, $b) = $bg =~ /(\d+)/g;
    int(($r * 30 + $g * 59 + $b * 11) / 65535); # 0 .. 100
}

sub initialize {
    my $rc = shift;
    $rc->setopt(
	default =>
	brightness > 50 ? '--LIGHT_SCREEN' : '--DARK_SCREEN');
}

1;

__DATA__
