package Color::Spectrum::Multi;

use warnings;
use strict;
use base qw(Color::Spectrum);


=head1 NAME

Color::Spectrum::Multi - simple L<Color::Spectrum> wrapper to handle fading
between multiple colours.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

A simple wrapper around L<Color::Spectrum>, to allow generating a range of colours
fading between multiple colours (e.g. a red -> yellow -> green fade) easy.

Usage is much the same as L<Color::Spectrum>, except you can supply as many
colours as you wish.

  # Procedural interface:
  use Color::Spectrum::Multi qw(generate);
  my @color = generate(10,'#FF0000','#00FF00', '#0000FF');

  # OO interface:
  use Color::Spectrum::Multi;
  my $spectrum = Color::Spectrum::Multi->new();
  my @color = $spectrum->generate(10,'#FF0000','#00FF00', '#0000FF');

=head1 DESCRIPTION

L<Color::Spectrum> provides an easy way to fade between two colours in a given
number of steps.  This module is a simple wrapper around Color::Spectrum, making
it easy to fade between an arbitrary number of colours.

=head1 METHODS

=over

=item generate

Given the desired number of steps and two or more colours, returns a series of
colours.

=cut

sub generate {
    my $self = shift if ref($_[0]) eq __PACKAGE__;
    
    # If we have two or less colours, just allow Color::Spectrum to do its
    # thing:
    if (@_ <= 2) {
       return Color::Spectrum::generate(@_);
   }

    my ($steps, @points) = @_;
    my @colours;
    my $steps_used = 0;
    # take the first colour waypoint off:
    my $startpoint = shift @points;
    
    # How many steps do we get between each waypoint?
    my $substeps = int($steps / scalar @points);
    while(my $endpoint = shift @points) {
        if (@points == 0) {
            # there's no more points left... make sure we don't fall short
            # on the number of steps:
            if (($steps_used + $substeps) != $steps) {
                $substeps = $steps - $steps_used;
            }
        }
       
        # Since we start from the last colour of the previous fade, if this
        # isn't the first fade, we want to generate one extra colour, and drop
        # the first (otherwise, we'd duplicate colours)
        my @colour_set = 
            Color::Spectrum::generate(
                $steps_used ? $substeps+1 : $substeps, $startpoint,$endpoint
            );
        push @colours, $steps_used ? @colour_set[1..$substeps] : @colour_set;

        # next fade will start from last colour of this fade:
        $startpoint = $endpoint; 
                                
        $steps_used += $substeps;
    }
    return @colours;
}

=back

=head1 AUTHOR

David Precious, C<< <davidp at preshweb.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-color-spectrum-multi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Color-Spectrum-Multi>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Color::Spectrum::Multi


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Color-Spectrum-Multi>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Color-Spectrum-Multi>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Color-Spectrum-Multi>

=item * Search CPAN

L<http://search.cpan.org/dist/Color-Spectrum-Multi/>

=back



=head1 COPYRIGHT & LICENSE

Copyright 2009 David Precious, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Color::Spectrum::Multi
