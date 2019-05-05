package Chart::GGPlot::Coord::Flip;

# ABSTRACT: Cartesian coordinates with x and y flipped

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.0003'; # VERSION

extends qw(Chart::GGPlot::Coord::Cartesian); 

my $coord_flip_pod = <<'=cut';

    coord_flip(:$xlim=undef, :$ylim=undef, :$expand=true)

Flip cartesian coordinates so that horizontal becomes vertical, and
vertical becoms horizontal.

=cut

my $coord_flip_code = sub {
    return __PACKAGE__->new(@_);
};

classmethod ggplot_functions() {
    return [
        {
            name => 'coord_flip',
            code => $coord_flip_code,
            pod  => $coord_flip_pod,
        }
    ];  
}

use Chart::GGPlot::Scale::Functions qw(scale_flip_position);

# The R ggplot2 code has some logic for flipping things inside its
#  CoordFlip class. For Chart::Plot we don't do similar things here.
#  Instead we implement that in the graphics backend. 

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Coord::Flip - Cartesian coordinates with x and y flipped

=head1 VERSION

version 0.0003

=head1 DESCRIPTION

This class inherits L<Chart::GGPlot::Coord::Cartesian>.

=head1 SEE ALSO

L<Chart::GGPlot::Coord>,
L<Chart::GGPlot::Coord::Cartesian>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
