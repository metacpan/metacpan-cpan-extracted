package Chart::GGPlot::Scale::ContinuousPosition;

# ABSTRACT: Continuous position scale

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.0009'; # VERSION

use Types::PDL qw(Piddle PiddleFromAny);
use Types::Standard qw(InstanceOf Maybe);

use Chart::GGPlot::Util qw(:all);

extends qw(
  Chart::GGPlot::Scale::Continuous
);

with qw(
    Chart::GGPlot::Scale::Positional
    Chart::GGPlot::Scale::SupportsSecondaryAxis
);

has '+limits' => (
    isa     => Piddle->plus_coercions(PiddleFromAny),
    coerce  => 1,
);

method map_to_limits ( $p, $limits = $self->get_limits ) {
    my $scaled = $self->oob->( $p, $limits );
    $scaled->setbadtoval($self->na_value);
    return $scaled;
}

around break_info ($range = null()) {
    my $breaks = $self->$orig($range);
    if ( defined $self->secondary_axis
        and not $self->secondary_axis->empty() )
    {
        $self->secondary_axis->init($self);
        $breaks = [
            $breaks->flatten,
            $self->secondary_axis->break_info( $breaks->range, $self )->flatten
        ];
    }
    return $breaks;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Scale::ContinuousPosition - Continuous position scale

=head1 VERSION

version 0.0009

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
