package Chart::GGPlot::Geom::Bar;

# ABSTRACT: Class for bar geom

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;
use MooseX::Singleton;

extends qw(Chart::GGPlot::Geom::Rect);

our $VERSION = '0.0001'; # VERSION

use Chart::GGPlot::Aes;
use Chart::GGPlot::Util qw(:all);

has '+non_missing_aes' => ( default => sub { [qw(xmin xmax ymin ymax)] } );

classmethod required_aes() { [qw(x y)] }
classmethod extra_params() { [qw(na_rm width)] }

method setup_data ($data, $params) {
    unless ( $data->exists('width') ) {
        $data->set( 'width',
            $params->at('width')
              // pdl( resolution( $data->at('x'), false ) * 0.9 ) );
    }
    return $data->transform( {
            ymin => fun($col, $df) { pmin($df->at('y'), 0) }, 
            ymax => fun($col, $df) { pmax($df->at('y'), 0) },
            xmin => fun($col, $df) { $df->at('x') - $df->at('width') / 2 },
            xmax => fun($col, $df) { $df->at('x') + $df->at('width') / 2 },
            width => undef,
        } );
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Geom::Bar - Class for bar geom

=head1 VERSION

version 0.0001

=head1 SEE ALSO

L<Chart::GGPlot::Geom>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
