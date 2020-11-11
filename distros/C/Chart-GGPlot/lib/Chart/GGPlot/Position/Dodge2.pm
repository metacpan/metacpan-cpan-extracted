package Chart::GGPlot::Position::Dodge2;

# ABSTRACT: Position for 'dodge2'

use Chart::GGPlot::Class;
use namespace::autoclean;

our $VERSION = '0.0011'; # VERSION

extends 'Chart::GGPlot::Position::Dodge';

use List::AllUtils qw(count_by);
use Types::Standard qw(Num);

use Chart::GGPlot::Position::Util qw(collide2 pos_dodge2);


has padding => ( is => 'ro', isa => Num, default => 0.1 );
has reverse => ( is => 'ro', default => sub { false } );

with qw(Chart::GGPlot::Position);

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

    return {
        width   => $self->width,
        n       => $n,
        padding => $self->padding,
        reverse => $self->reverse
    };
}

method compute_panel ($data, $params, $scales) {
    return collide2(
        $data, $params->{width}, 'position_dodge2', \&pos_dodge2,
        n           => $params->{n},
        padding     => $params->{padding},
        check_width => false,
        reverse     => $params->{reverse},
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Position::Dodge2 - Position for 'dodge2'

=head1 VERSION

version 0.0011

=head1 DESCRIPTION

This is a special case of "dodge" for arranging box plots, bars and
rectangles. It allows padding between elements at the same position.

=head1 ATTRIBUTES

=head2 padding

Padding between elements at the same position.
Elements are shrunk by this proportion to allow space between them.
Defaults to 0.1.

=head2 reverse

If true, will reverse the default stacking order.
This is useful if you're rotating both the plot and legend. 

=head1 SEE ALSO

L<Chart::GGPlot::Position>,
L<Chart::GGPlot::Position::Dodge>,

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2020 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
