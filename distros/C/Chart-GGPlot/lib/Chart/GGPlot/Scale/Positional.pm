package Chart::GGPlot::Scale::Positional;

# ABSTRACT: Role for positional scale

use Chart::GGPlot::Role qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use Chart::GGPlot::Types qw(:all);
use Types::Standard qw(ArrayRef CodeRef Str);


has position => ( is => 'rw', isa => PositionEnum, default => "left" );


method break_positions ($range=$self->get_limits()) {
    return $self->map_to_limits( $self->get_breaks($range) );
}

method axis_order () {
    my @ord = qw(primary secondary);
    if ( $self->position eq 'right' or $self->position eq 'bottom' ) {
        @ord = reverse @ord;
    }
    return \@ord;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Scale::Positional - Role for positional scale

=head1 VERSION

version 0.002000

=head1 ATTRIBUTES

=head2 position

=head1 METHODS

=head2 break_positions

    break_positons($range=$self->get_limits)

The numeric position of scale breaks, used by coord/guide.

=head2 axis_order

    axis_order()

Only relevant for positional scales.

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
