package Chart::GGPlot::Position::Dodge;

# ABSTRACT: Position for 'dodge'

use Chart::GGPlot::Class;
use namespace::autoclean;

our $VERSION = '0.0009'; # VERSION

use List::AllUtils qw(count_by);
use Types::Standard qw(Enum);

use Chart::GGPlot::Position::Util qw(collide pos_dodge);


my $PreserveEnum = Enum [qw(total single)];

has width    => ( is => 'ro' );
has preserve => ( is => 'ro', isa => $PreserveEnum, default => 'total' );

with qw(Chart::GGPlot::Position);

method setup_data ($data, $params) {
    if ( not $data->exists('x')
        and List::AllUtils::all { $data->exists($_) } qw(xmin xmax) )
    {
        $data->set( 'x', ( $data->at('xmin') + $data->at('xmax') ) / 2 );
    }
    return $data;
}

method setup_params ($data) {
    my $splitted = $data->split( $data->at('PANEL') );
    my $n;
    if ( $self->preserve ne 'total' ) {
        $n = List::AllUtils::max(
            $splitted->values->map(
                sub {
                    my %count = count_by { $_ } $_->at('xmin')->flatten;
                    return List::AllUtils::max( values(%count), 1 );
                }
            )->flatten
        );
    }

    return { width => $self->width, n => $n };
}

method compute_panel ($data, $params, $scales) {
    return collide(
        $data, $params->{width}, 'position_dodge', \&pos_dodge,
        n           => $params->{n},
        check_width => false
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Position::Dodge - Position for 'dodge'

=head1 VERSION

version 0.0009

=head1 DESCRIPTION

Dodging preserves the vertical position of an geom while adjusting the
horizontal position.

=head1 ATTRIBUTES

=head2 width

Dodging width. Useful when you want to align narrow geoms with wider geoms.
See the examples.

=head2 preserve

Should dodging preserve the total width of all elements at a position, or
the width of a single element?
Possible values are C<"total"> and C<"single">. Default is C<"total">.

=head1 SEE ALSO

L<Chart::GGPlot::Position>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
