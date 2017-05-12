#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use GD;
use AI::Termites;

use Getopt::Long;

my $world = 1;
my $specie = 'NemusNidor';
my $termites = 20;
my $wood = 200;
my $near;
my $one_of = 5;
my $width = 1024;
my $dim = 2;
my $taken = 0;
my $output = "output";
my $truecolor = 0;
my $top = 0;

my $result = GetOptions( "world-size=s" => \$world,
                         "specie=s"     => \$specie,
                         "termites=i"   => \$termites,
                         "wood=i"       => \$wood,
                         "near=s"       => \$near,
                         "one-of=i"     => \$one_of,
                         "width=i"      => \$width,
                         "dim=i"        => \$dim,
                         "taken"        => \$taken,
                         "output=s"     => \$output,
                         "truecolor"    => \$truecolor,
                         "top=i"          => \$top,
                       );

sub scl {
    my $p = shift;
    @{$width * $p}[0, 1];
}

sub sscl {
    my $s = shift;
    $width * $s;
}

$| = 1;

my $class = "AI::Termites::$specie";
eval "require $class; 1" or die "unable to load $class: $@";

my $ters = $class->new(dim => $dim, world_size => $world,
                       n_wood => $wood, n_termites => $termites,
                       near => $near);

my $n = 0;
my $fn = 0;

while (1) {

    my $im = GD::Image->new($width, $width, $truecolor);

    my $white = $im->colorAllocate(255,255,255);
    $im->filledRectangle(0, 0, $width, $width, $white);

    my $black = $im->colorAllocate(0, 0, 0);
    # $im->interlaced('true');

    my $red = $im->colorAllocate(255, 0, 0);
    my $blue = $im->colorAllocate(0, 0, 255);
    my $orange = $im->colorAllocate(255, 128, 0);
    my $green = $im->colorAllocate(0, 255, 0);

    my $txt = sprintf ("dim: %d, near: %.2f%%, termites: %d, wood: %d, wood taken: %d, iteration %d",
                       $dim,
                       100 * $ters->{near} / $world,
                       $termites, $wood, $ters->{taken},
                       $n );

    $im->string(gdSmallFont, 4, 4, $txt, $black);
    
    for my $wood (@{$ters->{wood}}) {
        if ($wood->{taken}) {
            $taken and $im->filledEllipse(scl($wood->{pos}), 8, 8, $orange);
        }
        else {
            $im->filledEllipse(scl($wood->{pos}), 5, 5, $blue);
        }
    }

    for my $ter (@{$ters->{termites}}) {
        my $color = (defined($ter->{wood_ix}) ? $red : $green);
        $im->filledEllipse(scl($ter->{pos}), 3, 3, $color);
    }

    my $name = sprintf "%s-%05d.png", $output, $fn;
    open my $fh, ">", $name;
    print $fh $im->png;
    close $fh;

    print "$n ($fn)\r";
    for (1..$one_of) {
        $n++;
        $ters->iterate;
    }
    $fn++;
    last if ($top and $n > $top);
}

__END__

=head1 NAME

termites.pl - Artificial Termites

=head1 SYNOPSIS

  termites.pl [OPTIONS]

=head1 DESCRIPTION

This script runs the Artificial Termites simulation provided by the
Perl module L<AI::Termites>.

The accepted options are as follows:

=over

=item --dim N

Number of dimensions of the world. Defaults to 2.

=item --world-size SIZE

The size of the world box, Defaults to 1.

=item --specie NAME

The name of the artificial termite subspecie to simulate.

The currently accepted ones are C<LoginquitasPostulo>, C<NemusNidor>,
C<VicinusOcurro> and C<PeractioBaro>.

=item --wood N

Piezes of wood in the simulated world.

=item --termites N

Number of termites in the simulated world.

=item --near SIZE

The size of the boll that a termite will consider as its
neighborhood. Defaults to 1/50 of the world size.

Every specie uses this parameter in a different way.

=item --taken

Represent on the drawings the pieces of wood that are actually being
moved by some termite.

=item --output FILENAME

Prefix used for the file names of the generated PNGs. Defaults to
C<output>.

=item --one-of N

Save to file one of every N frames. Defaults to 5.

=item --top N

Exit the application when the number of iterations reachs the given
number.

=item --width W

Number of pixels of the generated images. Defaults to 1024.

=item --truecolor

Generate TrueColor PNGs.

The default PNG format uses a 8bit indexed palette that is not
correctly handled by some programs as ffmpeg or mencoder.

=back

=head1 EXAMPLES

  termites.pl --specie=VicinusOccurro --truecolor --output vo --one-of 1 --top 10000

  termites.pl --specie=PeractioBaro --one-of 10 --near 0.02 --taken --dim 2 \
              --truecolor --output pb --top 40000



=head1 MAKING MOVIES

In order to convert a set of PNGs into an animation, ffmpeg can be
used as follows:

  ffmpeg -i output-%05d.png video.mpg

=head1 SEE ALSO

The idea about artificial termites comes from the book "Adventures in
Modeling" by Vanessa Stevens Colella, Eric Klopfer and Mitchel Resnick
(L<http://education.mit.edu/starlogo/adventures/>).

An online Artificial Termites simulation can be found here:
L<http://www.permutationcity.co.uk/alife/termites.html>.

The origin of this module lies on the following PerlMonks post:
L<http://perlmonks.org/?node_id=908684>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Salvador FandiE<ntilde>o,
E<lt>sfandino@yahoo.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
