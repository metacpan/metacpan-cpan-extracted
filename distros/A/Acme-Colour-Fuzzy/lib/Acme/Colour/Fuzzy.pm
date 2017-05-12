package Acme::Colour::Fuzzy;

=head1 NAME

Acme::Colour::Fuzzy - give names to arbitrary RGB triplets

=head1 SYNOPSIS

  # specify colour set, default is VACCC
  my $fuzzy = Acme::Colour::Fuzzy->new( 'VACCC' );

  # list of similar colours, sorted by similarity
  my @approximations = $fuzzy->colour_approximations( $r, $g, $b, $count );

  # made-up name for the colour
  my $name = $fuzzy->colour_name( $r, $g, $b );

=head1 DESCRIPTION

This module uses sophisticated colour-distance metrics and some
made-up computations to give a likely name to an arbitrary RGB
triplet.

=cut

use strict;
use base qw(Class::Accessor::Fast);

our $VERSION = '0.02';

use Graphics::ColorNames qw(hex2tuple);
use Color::Similarity;
use List::Util qw(max);

__PACKAGE__->mk_ro_accessors( qw(scheme colours) );

=head1 METHODS

=head2 new

  my $fuzzy = Acme::Colour::Fuzzy->new( $colour_set );

Creates a new C<Acme::Colour::Fuzzy> object using the specified colour
set.  The coolour set can be any backend for C<Graphic::ColorNames>
with 'VACCC' as default.

=cut

sub new {
    my( $class, $scheme, $distance ) = @_;
    $scheme ||= 'VACCC';
    $distance ||= 'Color::Similarity::HCL';

    my $similarity = Color::Similarity->new( $distance );

    # remove duplicates, favour longer names
    tie my %name2rgb, 'Graphics::ColorNames', $scheme;
    my %rgb2name;
    while( my( $nname, $rgb ) = each %name2rgb ) {
        my $cname = $rgb2name{$rgb} || '';
        my( $lnname, $lcname ) = ( length( $nname ), length( $cname ) );
        if( $lnname > $lcname ) {
            $rgb2name{$rgb} = $nname;
        }
    }
    my %unique = reverse %rgb2name;

    my $self = $class->SUPER::new( { scheme   => $scheme,
                                     colours  => \%unique,
                                     distance => $similarity,
                                     } );

    return $self;
}

=head2 colour_approximations

  my @approximations = $fuzzy->colour_approximations( $r, $g, $b, $count );

Returns a list of at most C<$count> colours similar to the given
one. Each element of the list is an hash with the following structure:

  { name     => 'Red', # name taken from Graphics::ColourNames
    distance => 7.1234567,
    rgb      => [ 255, 0, 0 ],
    }

=cut

sub colour_approximations {
    my( $self, $ir, $ig, $ib, $count ) = @_;
    my $cdist = $self->{distance};
    my $ic = $cdist->convert_rgb( $ir, $ig, $ib );

    my @res;
    while( my( $name, $rgb ) = each %{$self->colours} ) {
        my( $nr, $ng, $nb ) = hex2tuple( $rgb );
        my $nc = $cdist->convert_rgb( $nr, $ng, $nb );

        my $dist = $cdist->distance( $ic, $nc );
        push @res, { distance => $dist,
                     name     => $name,
                     rgb      => [ $nr, $ng, $nb ],
                     };
    }
    @res = sort { $a->{distance} <=> $b->{distance} } @res;

    return @res[ 0 .. ( $count || 20 ) - 1 ];
}

=head2 colour_name

  my $name = $fuzzy->colour_name( $r, $g, $b );

Makes up a colour name using the data computed by C<colour_approximations>.

=cut

sub colour_name {
    my( $self, $ir, $ig, $ib ) = @_;
    my @similar = $self->colour_approximations( $ir, $ig, $ib );
    my %words;

    # FIXME use some real metric, not made-up computations
    my $max_distance = $similar[-1]{distance};
    my $pivot = max( ( $max_distance * 9 / 13 ), 1 );
    foreach my $similar ( @similar ) {
        my @words = map { /^(dark)(\w+)/ ? ( $1, $2 ) : ( $_ ) }
                    map { s/\d+//; $_ } # remove numbers
                        split /[ \-]+/, $similar->{name};
        my $weight = ( $pivot - $similar->{distance} ) / $pivot;
        foreach( @words ) {
            $words{$_} += $weight;
        }
    }
    my @weights = sort { $b->[1] <=> $a->[1] }
                  map  [ $_ => $words{$_} ],
                       keys %words;

    my @names;
    my $first_weight = $weights[0][1];
    foreach my $weight ( @weights ) {
        last if $weight->[1] < $first_weight / 3;
        push @names, $weight->[0];
    }

    return join ' ', reverse @names;
}

=head1 SEE ALSO

L<Color::Distance::HCL>

=head1 AUTHOR

Mattia Barbon, C<< <mbarbon@cpan.org> >>

=head1 COPYRIGHT

Copyright (C) 2007, Mattia Barbon

This program is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;
