package Chart::GGPlot::Facet::Null;

# ABSTRACT: A single panel for faceting

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use Data::Frame;
use PDL::Primitive qw(which);
use Type::Params;
use Types::Standard qw(ArrayRef Bool CodeRef Enum Maybe Str);

use Chart::GGPlot::Types qw(:all);


with qw(Chart::GGPlot::Facet);

has '+shrink' => ( default => 1 );
has '+params' => (init_arg => undef);

method compute_layout ($data, $params) {
    return $self->layout_null();
}

method map_data ($data, $layout, $params) {
    if ( not defined $data ) {
        return Data::Frame->new( columns => [ PANEL => null ] );
    }
    if ( $data->isempty ) {
        return $data->merge( PANEL => null );
    }

    $data->set('PANEL', pdl([0])->repeat( $data->nrow ));
    return $data;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Facet::Null - A single panel for faceting

=head1 VERSION

version 0.002000

=head1 DESCRIPTION

This class represents a single panel for faceting.
This is the default facet specification.

=head1 ATTRIBUTES

=head2 shrink

If true, will shrink scales to fit output of statistics, not
raw data. If fause will be range of raw data before statistical
summary.

The default is true.

=head1 SEE ALSO

L<Chart::GGPlot::Facet> 

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
