package Chart::GGPlot::Scale::Continuous;

# ABSTRACT: Continuous scale

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use PDL::Primitive qw(which);
use Types::PDL qw(Piddle PiddleFromAny);
use Types::Standard qw(Bool CodeRef ConsumerOf Maybe InstanceOf);

use Chart::GGPlot::Range::Continuous;
use Chart::GGPlot::Types qw(:all);
use Chart::GGPlot::Util qw(:all);


has rescaler => ( is => 'ro', isa => CodeRef, default => sub { \&rescale } );


has oob => ( is => 'ro', isa => CodeRef, default => sub { \&censor } );


has minor_breaks => ( is => 'ro', isa => Maybe [ ( Piddle | CodeRef ) ] );
has range => (
    is      => 'ro',
    isa     => ConsumerOf ["Chart::GGPlot::Range::Continuous"],
    default => sub { Chart::GGPlot::Range::Continuous->new },
);

with qw(
  Chart::GGPlot::Scale
  MooseX::Clone
);

# merge $p into range of the scale object
method train ($p) {
    return if ( $p->isempty );
    $self->range->train($p);
}

method transform ($p) {
    my $new_p = $self->trans->transform->($p);
    if ( ( $p->isfinite != $new_p->isfinite )->any ) {
        my $type =
          $self->scale_name eq "position_c" ? "continuous" : "discrete";
        my $axis = $self->aesthetics->exists('x') ? "x" : "y";
        warn("Transformation introduced infinite values in $type ${axis}-axis");
    }
    return $new_p;
}

method map_to_limits ( $p, $limits = $self->get_limits() ) {

    # rescale from $limits to [0,1]
    my $new_p =
      $self->rescaler->( $self->oob->( $p, $limits ), pdl( [ 0, 1 ] ),
        $limits );

    my $uniq   = $new_p->uniqvec;                         # $uniq is sorted pdl
    my $pal    = $self->palette->($uniq);
    my $scaled = $pal->slice( match( $new_p, $uniq ) );

    return $scaled->setbadtoval( $self->na_value );
}

method dimension ( $expand = pdl([0, 0, 0, 0]) ) {
    return expand_range4( $self->get_limits(), $expand );
}

# return arrayref of breaks
method get_breaks ( $limits=$self->get_limits ) {
    if ( $limits->isempty ) {
        $limits = $self->get_limits();
    }

    return pdl( [] ) if $self->isempty;
    return null if ( $self->breaks->$_call_if_object('isempty') );

    # Limits in transformed space need to be converted back to data space
    $limits = $self->trans->inverse->($limits);

    my $breaks;
    if ( zero_range($limits) ) {
        $breaks = pdl( [ $limits->at(0) ] );
    }
    elsif ( not defined $self->breaks ) {
        $breaks = $self->trans->breaks->($limits);
    }
    else {
        $breaks = call_if_coderef( $self->breaks, $limits );
    }

    # Breaks in data space need to be converted back to transformed space
    # And any breaks outside the dimensions need to be flagged as missing

    $breaks = censor( $self->trans->transform->($breaks),
        $self->trans->transform->($limits), 0 );
    return $breaks;
}

method get_breaks_minor (
    $n      = 2,
    $b      = $self->break_positions,
    $limits = $self->get_limits()
  ) {
    if ( $limits->isempty ) {
        $limits = $self->get_limits();
    }

    return pdl( [] ) if ( zero_range($limits) );
    return null if ( $self->minor_breaks->$_call_if_object('isempty') );

    my $breaks;
    if ( not defined $self->minor_breaks ) {
        $breaks =
          $b->isempty
          ? null
          : $self->trans->minor_breaks->( $b, $limits, $n );
    }
    elsif ( Ref::Util::is_coderef( $self->minor_breaks ) ) {

        # Find breaks in data space, and convert to numeric
        $breaks = $self->minor_breaks->( $self->trans->inverse->($limits) );
        $breaks = $self->trans->transform->($breaks);
    }
    else {
        $breaks = $self->trans->transform->( $self->minor_breaks );
    }

    # Any minor breaks outside the dimensions need to be thrown away
    return discard( $breaks, $limits );
}

method get_labels ( $breaks = $self->get_breaks ) {
    return null if ( $breaks->isempty );

    $breaks = $self->trans->inverse->($breaks);

    my $labels;
    if ( not defined $self->labels ) {
        $labels = $self->trans->format->($breaks);
    }
    elsif ( $self->labels->$_call_if_object('isempty') ) {
        return PDL::SV->new( [] );
    }
    else {
        $labels = call_if_coderef( $self->labels, $breaks );
    }
    if ( $labels->length != $breaks->length ) {
        die("Breaks and labels are different lengths");
    }
    return $labels;
}

method break_info ($range=$self->dimension) {
    if ( $range->$_DOES('Chart::GGPlot::Range') ) {
        $range = $range->range;
    }
    if ( $range->isempty ) {
        $range = $self->dimension;
    }

    # major breaks and labels
    my $major  = $self->get_breaks($range);
    my $labels = $self->get_labels($major);

    # drop oob breaks/labels by testing major == NA
    if ( not $labels->isempty and $major->badflag ) {
        $labels = $labels->where( $major->isgood );
    }
    if ( not $major->isempty and $major->badflag ) {
        $major = $major->where( $major->isgood );
    }

    my $minor = $self->get_breaks_minor( 2, $major, $range );
    unless ( $minor->isempty and $minor->badflag ) {
        $minor = $minor->where( $minor->isgood );
    }

    # rescale to [0, 1]
    my $major_n = rescale( $major, pdl( [ 0, 1 ] ), $range );
    my $minor_n = rescale( $minor, pdl( [ 0, 1 ] ), $range );

    return {
        range        => $range,
        labels       => $labels,
        major        => $major_n,
        minor        => $minor_n,
        major_source => $major,
        minor_source => $minor,
    };
}

method string () {
    my $show_range = sub {
        my $p = shift;
        return $p . '';
    };

    return join( "\n",
        "<" . ref($self) . ">",
        " Range:  " . &$show_range( $self->range->range ),
        " Limits: " . &$show_range( $self->dimension() ),
    ) . "\n";
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Scale::Continuous - Continuous scale

=head1 VERSION

version 0.002000

=head1 ATTRIBUTES

=head2 rescaler

A function used by diverging and n color gradients, to scale the
input values to the range of C<[0, 1]>.

=head2 oob

A function that handles limits outside of the scale limits (out of bounds).
The default replaces out of bounds values with NA.

=head2 minor_breaks

One of 

=over 4

=item *

C<null> or C<[]> for no minor breaks.

=item *

C<undef> for default breaks (one minor break between each major break).

=item *

a numeric vector of positions.

=item *

a function that given the limits returns a vector of minor breaks.

=back

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
