package Chart::GGPlot::Scale::ContinuousDateTime;

# ABSTRACT: Continuous datetime scale

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.0001'; # VERSION

use Types::PDL qw(Piddle PiddleFromAny);
use Types::Standard qw(InstanceOf Maybe);

use Chart::GGPlot::Trans::Functions qw(time_trans);
use Chart::GGPlot::Util qw(:all);

extends qw(
  Chart::GGPlot::Scale::Continuous
);

has timezone => (is => 'rwp');

with qw(
  Chart::GGPlot::Scale::Positional
  Chart::GGPlot::Scale::SupportsSecondaryAxis
);

around transform($p) {
    my $tz = $p->$_can('timezone');
    if (not defined $self->timezone and defined $tz) {
        $self->_set_timezone($tz);
        $self->trans(time_trans($self->timezone));
    }
    return $self->$orig($p);
}

method map_to_limits ( $p, $limits = $self->get_limits ) {
    return $self->oob->( $p, $limits );
}

method break_info ($range = null()) {
    my $breaks = $self->SUPER::break_info($range);
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

Chart::GGPlot::Scale::ContinuousDateTime - Continuous datetime scale

=head1 VERSION

version 0.0001

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
