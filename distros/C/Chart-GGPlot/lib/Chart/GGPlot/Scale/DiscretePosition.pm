package Chart::GGPlot::Scale::DiscretePosition;

# ABSTRACT: Discrete position scale

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.0007'; # VERSION

use Types::PDL qw(Piddle PiddleFromAny);
use Types::Standard qw(Any InstanceOf);

use Chart::GGPlot::Util qw(:all);

extends qw(
  Chart::GGPlot::Scale::Discrete
);

with qw(
  Chart::GGPlot::Scale::Positional
);

has '+limits' => (
    isa => ( InstanceOf ["PDL::SV"] )
      ->plus_coercions( Any, sub { PDL::SV->new($_) } ),
    coerce => 1,
);

method train ($p) {
    if ( is_discrete($p) ) {
        return $self->range->train( $p, $self->drop, !$self->na_translate );
    }
    else {
        return $self->range_c->train($p);
    }
}

method get_limits () {
    return pdl( [ 0, 1 ] ) if ( $self->isempty );
    return ( $self->limits->isempty ? $self->range->range : $self->limits );
}

method isempty () {
    return List::AllUtils::all { $_->isempty }
    ( $self->range->range, $self->limits, $self->range_c->range );
}

method reset () {

    # Can't reset discrete scale because no way to recover values
    $self->range_c->reset();
}

method map_to_limits ( $p, $limits = $self->get_limits ) {
    return (
          is_discrete($p)
        ? pdl( [ 0 .. $limits->length - 1 ] )
          ->slice( match( $p, $limits ) )
        : $p
    );
}

method dimension ( $expand = pdl([0, 0, 0, 0]) ) {
    my $c_range = $self->range_c->range;
    my $d_range = $self->get_limits();

    if ( $self->isempty ) {
        return pdl([ 0, 1 ]);
    }
    elsif ( $self->range->range->isempty ) {    # only continuous
        return expand_range4( $c_range, $expand );
    }
    elsif ( $c_range->isempty ) {               # only discrete
        return expand_range4( [ 0, $d_range->length - 1 ], $expand );
    }
    else {                                      # both
        return range_(
            $c_range->glue(
                0, expand_range4( [ 0, $d_range->length - 1 ], $expand )
            )
        );
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Scale::DiscretePosition - Discrete position scale

=head1 VERSION

version 0.0007

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
