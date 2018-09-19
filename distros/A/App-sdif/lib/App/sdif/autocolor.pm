=head1 NAME

App::sdif::autocolor

=head1 SYNOPSIS

sdif -Mautocolor

=head1 DESCRIPTION

This is a module for L<sdif(1)> command to set operating system
dependent autocolor option.

Each module is expected to set B<--light> or B<--dark> option
according to the brightness of a terminal program.

If the environment variable C<BRIGHTNESS> is defined, its value is
used as a brightness without calling submodules.  The value of
C<BRIGHTNESS> is expected in range of 0 to 100.

=head1 SEE ALSO

L<App::sdif::autocolor::Apple_Terminal>

=cut

package App::sdif::autocolor;

use strict;
use warnings;
use v5.14;
use Data::Dumper;

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw(rgb_to_brightness);

sub rgb_to_brightness {
    my($r, $g, $b) = @_;
    int(($r * 30 + $g * 59 + $b * 11) / 65535); # 0 .. 100
}

my %TERM_PROGRAM = qw(
    Apple_Terminal	Apple_Terminal
    );

sub initialize {
    my $mod = shift;

    if ((my $brightness = $ENV{BRIGHTNESS} // '') =~ /^\d+$/) {
	$mod->setopt(default =>
		     $brightness > 50 ? '--light' : '--dark');
    }
    elsif (my $term_program = $ENV{TERM_PROGRAM}) {

	if (defined (my $module = $TERM_PROGRAM{$term_program})) {
	    $mod->setopt(default => "-Mautocolor::${module}");
	}

    }
}

1;

__DATA__
