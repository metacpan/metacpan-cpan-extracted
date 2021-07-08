package Chart::GGPlot::Scale::Discrete;

# ABSTRACT: Discrete scale

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.0016'; # VERSION

use PDL::Primitive qw(which);
use Types::Standard qw(Any ArrayRef Bool CodeRef ConsumerOf InstanceOf);
use Types::PDL -types;

use Chart::GGPlot::Range::Discrete;
use Chart::GGPlot::Range::Functions qw(discrete_range);
use Chart::GGPlot::Util qw(:all);

has drop            => ( is => 'ro', default => sub { true } );
has na_translate    => ( is => 'ro' );
has _n_breaks_cache => ( is => 'rw' );

has _palette_cache => (
    is      => 'rw',
    isa     => ConsumerOf ['PDL::SV'],
    default => sub { PDL::SV->new( [] ); },
);

has range => (
    is      => 'ro',
    isa     => ConsumerOf ["Chart::GGPlot::Range::Discrete"],
    default => sub { discrete_range() }
);
has range_c => (
    is  => 'rw',
    isa => ConsumerOf ['Chart::GGPlot::Range::Continuous'],
);

with qw(
  Chart::GGPlot::Scale
  MooseX::Clone
);

method train ($p) {
    return if ( $p->isempty );
    $self->range->train( $p, $self->drop, !$self->na_translate );
}

method transform ($p) { $p; }

method map_to_limits ( $p, $limits = $self->get_limits ) {
    my $n = $limits->ngood;

    my $pal;
    if ( defined $self->_n_breaks_cache and $self->_n_breaks_cache == $n ) {
        $pal = $self->_palette_cache;
    }
    else {
        if ( defined $self->_n_breaks_cache ) {
            warn "Cached palette does not match requested";
        }
        $pal = $self->palette->($n);
        $self->_palette_cache($pal);
        $self->_n_breaks_cache($n);
    }

    my $pal_match =
      $pal->slice( match( $p, ( $pal->$_call_if_can('names') // $limits ) ) );

    return (
        $self->na_translate
        ? ifelse(
            ( $p->isbad | $pal_match->isbad ),
            PDL::SV->new( [ $self->na_value ] ),
            $pal_match
          )
        : $pal_match
    );
}

method dimension ( $expand = pdl([0, 0, 0, 0]) ) {
    return expand_range4( [ 0, scalar( @{ $self->get_limits } ) ], $expand );
}

method get_breaks ( $limits = $self->get_limits() ) {
    if ( $limits->isempty ) {
        $limits = $self->get_limits();
    }

    return pdl( [] ) if $self->isempty;
    return null if ( $self->breaks->$_call_if_object('isempty') );

    my $breaks;
    if ( not defined $self->breaks ) {
        $breaks = $limits;
    }
    else {
        $breaks = call_if_coderef( $self->breaks, $limits );
    }

    # Breaks can only occur only on values in domain

    # TODO: See if it's better to change the behavior of PDL::Factor or
    #  make some level of abstraction there.
    state $unpdl = sub {
        my ($x) = @_;
        if ($x->$_DOES('PDL::Factor')) {
            my $levels = $x->levels;
            return $x->unpdl->map(sub { $levels->[$_] });
        } else {
            return $x->unpdl;
        }
    };
    my $in_domain = $unpdl->($breaks)->intersect( $unpdl->($limits) );
    return PDL::SV->new($in_domain);
}

sub get_breaks_minor { return []; }

method get_labels ( $breaks = $self->get_breaks ) {
    return pdl( [] ) if $self->isempty;

    return null if $breaks->$_call_if_object('isempty');
    return null if $self->labels->$_call_if_object('isempty');

    if ( not defined $self->labels ) {
        return $self->get_breaks();
    }
    elsif ( Ref::Util::is_coderef( $self->labels ) ) {
        return $self->labels->($breaks);
    }
    else {
        if ( not $self->labels->names->isempty ) {

            # If labels have names, use them to match with breaks
            my $labels   = $breaks;
            my $match_id = which( match( $self->labels->names, $labels ) > 0 );
            $labels->slice($match_id) .= $self->labels->slice($match_id);
            return $labels;
        }
        else {
            my $labels = $self->labels;

      # TODO
      # Need to ensure that if breaks were dropped, corresponding labels are too
      # pos <- attr(breaks, "pos")
      # if (!is.null(pos)) {
      #    <- labels[pos]
      # }
            return $labels;
        }
    }
}

method break_info ( $range = undef ) {

    # for discrete, limits != range
    my $limits = $self->get_limits;

    my $major = $self->get_breaks($limits);
    my $major_n;
    my $labels;
    if ( defined $major ) {
        $labels = $self->get_labels($major);
        $major  = $self->map_to_limits($major);

        $major_n = rescale( $major, [ 0, 1 ], $range );
    }

    # Discreate scale has no minor breaks
    return {
        range        => $range,
        labels       => $labels,
        major        => $major_n,
        major_source => $major,
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Scale::Discrete - Discrete scale

=head1 VERSION

version 0.0016

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
