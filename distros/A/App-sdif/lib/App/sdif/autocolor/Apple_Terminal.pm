=head1 NAME

App::sdif::autocolor::Apple_Terminal

=head1 SYNOPSIS

sdif -Mautocolor::Apple_Terminal

=head1 DESCRIPTION

This is a module for L<sdif(1)> command to set default option
according to terminal background color taken by AppleScript.  Terminal
brightness is caliculated from terminal background RGB values by next
equation.

    Y = 0.30 * R + 0.59 * G + 0.11 * B

When the result is greater than 0.5, set B<--light> option, otherwise
B<--dark>.  You can override default setting in your F<~/.sdifrc>.

=head1 SEE ALSO

L<App::sdif::autocolor>, L<App::sdif::colors>

=cut

package App::sdif::autocolor::Apple_Terminal;

use strict;
use warnings;
use Data::Dumper;

use App::sdif::autocolor qw(rgb_to_brightness);

sub rgb {
    my $app = "Terminal";
    my $do = "background color of first window";
    my $bg = qx{osascript -e \'tell application \"$app\" to $do\'};
    $bg =~ /(\d+)/g;
}

sub brightness {
    my(@rgb) = rgb;
    @rgb == 3 or return undef;
    if (grep { not /^\d+$/ } @rgb) {
	undef;
    } else {
	rgb_to_brightness @rgb;
    }
}

sub initialize {
    my $rc = shift;
    if (defined (my $brightness = brightness)) {
	$rc->setopt(
	    default =>
	    $brightness > 50 ? '--light' : '--dark');
    }
}

1;

__DATA__
