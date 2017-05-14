# Copyright (c) 2015  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package Attach::Stuff;

# ABSTRACT: Attach stuff to other stuff
use v5.14;
use warnings;
use Moose;
use namespace::autoclean;
use SVG;

# According to SVG spec, there are 3.543307 pixels per mm.  See:
# http://www.w3.org/TR/SVG/coords.html#Units
use constant MM_IN_PX  => 3.543307;

has 'width' => (
    is       => 'rw',
    isa      => 'Num',
    required => 1,
);
has 'height' => (
    is       => 'rw',
    isa      => 'Num',
    required => 1,
);
has 'screw_default_radius' => (
    is       => 'rw',
    isa      => 'Num',
    required => 1,
);
has 'screw_holes' => (
    is       => 'rw',
    isa      => 'ArrayRef[ArrayRef[Num]]',
    required => 1,
);
has 'stroke_width' => (
    is       => 'rw',
    isa      => 'Num',
    required => 1,
    default  => sub { 0.3 },
);


sub draw
{
    my ($self) = @_;
    my $width                = $self->width;
    my $height               = $self->height;
    my $screw_default_radius = $self->screw_default_radius;
    my $stroke_width         = $self->stroke_width;
    my @screw_holes          = @{ $self->screw_holes };

    my $svg = SVG->new(
        width  => $self->mm_to_px( $width ),
        height => $self->mm_to_px( $height ),
    );

    my $draw = $svg->group(
        id    => 'draw',
        style => {
            stroke         => 'black',
            'stroke-width' => $stroke_width,
            fill           => 'none',
        },
    );

    # Draw outline
    $draw->rectangle(
        x      => 0,
        y      => 0,
        width  => $self->mm_to_px( $width ),
        height => $self->mm_to_px( $height ),
    );

    # Draw screw holes
    $draw->circle(
        cx => $self->mm_to_px( $_->[0] ),
        cy => $self->mm_to_px( $_->[1] ),
        r  => $self->mm_to_px( $screw_default_radius ),
    ) for @screw_holes;

    return $svg;
}


sub mm_to_px
{
    my ($self, $mm) = @_;
    return $mm * MM_IN_PX;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

  Attach::Stuff - Attach stuff to other stuff

=head1 SYNOPSIS

    use Attach::Stuff;

    # You've got a board that's 26x34 mm, with two screw holes with a 
    # 2 mm diameter, spaced 3mm from the edge
    my $attach = Attach::Stuff->new({
        width                => 26,
        height               => 34,
        stroke_width         => 0.3,
        screw_default_radius => 1.25, # 2mm diameter, plus some wiggle room
        screw_holes          => [
            [ 3,       3 ],
            [ 26 - 3,  3 ],
        ],
    });
    my $svg = $attach->draw;
    print $svg->xmlify;

=head1 DESCRIPTION

You've got stuff, like a PCB board, that needs to be attached to other stuff, 
like a lasercut enclosure. How do you attach the stuff to the other stuff?  
This is a question we ask a lot when doing homebuilt Internet of Things 
projects.  Perl has the "Internet" half down pat. This module is an attempt to 
improve the "Things" part.

Lasercutters and other CNC machines often work with SVGs. Or more likely SVGs 
can be converted into something that are converted into G-code by whatever turd 
of a software package came with your CNC machine.  Whatever the case, you can 
probably start with an SVG and work your way from there.

Before you can get there, you need measurements of the board and the location 
of the screw holes.  If you're lucky, you can find full schematics for your 
board that will tell you the sizes exactly.  If not, you'll need to get out 
some callipers and possibly do some guesswork.

Protip: if you had to guess on some of the locations, etch a prototype into 
cardboard. Then you can lay the board over the cardboard and see if it matches 
up right.

=head1 METHODS

=head2 new

Constructor.  Has the attributes below.  Note that all lengths are measured 
in millimeters.

=over 4

=item * width

=item * height

=item * stroke_width - The width of the lines.  Defaults to 0.3.

=item * screw_default_radius - All screws will be this radius.  Currently, there is no way to specify a screw with any other radius.  It's recommended to add a little extra to the radius to fit the screws through.

=item * screw_holes - Arrayref of arrayrefs of the x/y coords of screw holes

=back

=head2 draw

Draw based on the parameters given in the constructor. Returns an L<SVG> 
object.

=head2 mm_to_px

Takes a measurement in millimeters and returns the length in pixels according 
to the SVG standard. Useful if you need to draw more complex shapes for your 
board after Attach::Stuff did the basics.  See the C<examples/rpi_camera.pl> 
file in this distribution for an example of this.


=head1 SEE ALSO

L<SVG>

=head1 LICENSE


Copyright (c) 2015,  Timm Murray
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are 
permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of 
      conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of 
      conditions and the following disclaimer in the documentation and/or other materials 
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS 
OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
