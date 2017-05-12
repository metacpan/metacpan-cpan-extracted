package Acme::SaBalTongMun;
our $VERSION = '1.100830';
use Moose;
# ENCODING: utf-8
# ABSTRACT: make a round robin (사발통문, 沙鉢通文)

use namespace::autoclean;


use common::sense;
use GD;
use List::Util qw( max );


has 'radius' => ( isa => 'Int', is => 'rw', required => 1 );


has 'font' => ( isa => 'Str', is => 'rw', required => 1 );


has 'font_size' => ( isa => 'Int', is => 'rw', required => 1 );


has 'font_charset' => ( isa => 'Str', is => 'rw', default => 'Unicode' );


has 'color' => ( isa => 'Str', is => 'rw', required => 1 );


has 'people' => ( isa => 'ArrayRef[Str]', is => 'rw', required => 1 );


sub generate {
    my $self = shift;

    my $max_string_width
        = max( map length, @{$self->people} ) * $self->font_size;

    my $cx = $self->radius + $max_string_width;
    my $cy = $self->radius + $max_string_width;
    my $width  = ( $self->radius + $max_string_width ) * 2;
    my $height = ( $self->radius + $max_string_width ) * 2;

    my $angle = ( 2 * 3.14 ) / @{$self->people};

    #
    # Make GD::Image
    #
    my $image = GD::Image->new($width, $height);

    my $white = $image->colorAllocate( _get_rgb("#FFFFFF") );
    my $black = $image->colorAllocate( _get_rgb("#000000") );

    # make the background transparent and interlaced
    $image->transparent( _get_rgb("#FFFFFF") );
    $image->interlaced('true');

    my $dest_angle = 0;
    for my $string ( @{$self->people} ) {
        my $dest_x = $cx + ( $self->radius * cos $dest_angle );
        my $dest_y = $cy + ( $self->radius * sin $dest_angle );

        my $string_angle = (2 * 3.14) - $dest_angle;

        $image->stringFT(
            $image->colorAllocate( _get_rgb( $self->color ) ),  # fgcolor
            $self->font,                                        # .ttf path
            $self->font_size,                                   # point size
            $string_angle,                                      # rotation angle
            $dest_x,                                            # X coordinates
            $dest_y,                                            # Y coordinates
            $string,
            {
                charmap     => $self->font_charset,
            },
        );

        $dest_angle += $angle;
    }

    return $image;
}

sub _get_rgb { map hex, $_[0] =~ m/^#(..)(..)(..)$/ }

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__
=pod

=encoding utf-8

=head1 NAME

Acme::SaBalTongMun - make a round robin (사발통문, 沙鉢通文)

=head1 VERSION

version 1.100830

=head1 SYNOPSIS

    use Acme::SaBalTongMun;
    
    my $sabal = Acme::SabalTongMun->new(
        radius    => 30,
        font      => '/home/keedi/.fonts/NanumGothic.ttf',
        font_size => 20;
        color     => '#0000FF',
        people    => [
            'a3r0',
            'jeen',
            'keedi',
            'saillinux',
        ],
    );
    
    my $image->generate;
    
    binmode STDOUT;
    print $image->png;

=head1 DESCRIPTION

This module generates a round robin.
The round robin is known as "사발통문(沙鉢通文)" in Korea.
Since all members of the group doesn't have a order,
it has been used to hide the leader of the group.
The origin of the round robin in Korea is 
Donghak Peasants Revolution(동학농민혁명, 東學農民運動).

=head1 ATTRIBUTES

=head2 radius

This attribute stores the radius
which is the center circle of the round robin.

=head2 font

This attribute stores the TrueType(*.ttf) font path.
Only the font which has unicode charmap is allowed.

=head2 font_size

This attribute stores the size of the font.

=head2 font_charset

This attribute stores the charset of the font.
This is optional and the default value is "Unicode".

=head2 color

This attribute stores the color of the font.

=head2 people

This attribte is an arrayref of strings
that are the members of the round robin.

=head1 METHODS

=head2 new

    my $sabal = Acme::SabalTongMun->new(
        radius    => 30,
        font      => '/home/keedi/.fonts/NanumGothic.ttf',
        font_size => 20;
        color     => '#0000FF',
        people    => [
            'a3r0',
            'jeen',
            'keedi',
            'saillinux',
        ],
    );

This method will create and return Acme::SabalTongMun object.

=head2 generate

    my $image = $sabal->generate;

This method will return GD::Image object.

=head1 AUTHOR

  Keedi Kim - 김도형 <keedi at cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

