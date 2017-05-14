package Chart::Plotly::Trace::Mesh3d;
use Moose;

use Chart::Plotly::Trace::Attribute::Colorbar;
use Chart::Plotly::Trace::Attribute::Contour;
use Chart::Plotly::Trace::Attribute::Lighting;
use Chart::Plotly::Trace::Attribute::Lightposition;

our $VERSION = '0.012';    # VERSION

sub TO_JSON {
    my $self = shift;
    my %hash = %$self;
    if ( $self->can('type') && ( !defined $hash{'type'} ) ) {
        $hash{type} = $self->type();
    }
    return \%hash;
}

has alphahull => (
    is  => 'rw',
    isa => "Num",
    documentation =>
      "Determines how the mesh surface triangles are derived from the set of vertices (points) represented by the `x`, `y` and `z` arrays, if the `i`, `j`, `k` arrays are not supplied. For general use of `mesh3d` it is preferred that `i`, `j`, `k` are supplied. If *-1*, Delaunay triangulation is used, which is mainly suitable if the mesh is a single, more or less layer surface that is perpendicular to `delaunayaxis`. In case the `delaunayaxis` intersects the mesh surface at more than one point it will result triangles that are very long in the dimension of `delaunayaxis`. If *>0*, the alpha-shape algorithm is used. In this case, the positive `alphahull` value signals the use of the alpha-shape algorithm, _and_ its value acts as the parameter for the mesh fitting. If *0*,  the convex-hull algorithm is used. It is suitable for convex bodies or if the intention is to enclose the `x`, `y` and `z` point set into a convex hull.",
);

has color => ( is            => 'rw',
               documentation => "Sets the color of the whole mesh", );

has colorbar => ( is  => 'rw',
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Colorbar" );

has colorscale => (
    is => 'rw',
    documentation =>
      "Sets the colorscale. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in z space, use zmin and zmax",
);

has contour => ( is  => 'rw',
                 isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Contour" );

has delaunayaxis => (
    is => 'rw',
    documentation =>
      "Sets the Delaunay axis, which is the axis that is perpendicular to the surface of the Delaunay triangulation. It has an effect if `i`, `j`, `k` are not provided and `alphahull` is set to indicate Delaunay triangulation.",
);

has facecolor => ( is            => 'rw',
                   documentation => "Sets the color of each face Overrides *color* and *vertexcolor*.", );

has flatshading => (
    is  => 'rw',
    isa => "Bool",
    documentation =>
      "Determines whether or not normal smoothing is applied to the meshes, creating meshes with an angular, low-poly look via flat reflections.",
);

has i => (
    is => 'rw',
    documentation =>
      "A vector of vertex indices, i.e. integer values between 0 and the length of the vertex vectors, representing the *first* vertex of a triangle. For example, `{i[m], j[m], k[m]}` together represent face m (triangle m) in the mesh, where `i[m] = n` points to the triplet `{x[n], y[n], z[n]}` in the vertex arrays. Therefore, each element in `i` represents a point in space, which is the first vertex of a triangle.",
);

has intensity => ( is            => 'rw',
                   documentation => "Sets the vertex intensity values, used for plotting fields on meshes", );

has j => (
    is => 'rw',
    documentation =>
      "A vector of vertex indices, i.e. integer values between 0 and the length of the vertex vectors, representing the *second* vertex of a triangle. For example, `{i[m], j[m], k[m]}`  together represent face m (triangle m) in the mesh, where `j[m] = n` points to the triplet `{x[n], y[n], z[n]}` in the vertex arrays. Therefore, each element in `j` represents a point in space, which is the second vertex of a triangle.",
);

has k => (
    is => 'rw',
    documentation =>
      "A vector of vertex indices, i.e. integer values between 0 and the length of the vertex vectors, representing the *third* vertex of a triangle. For example, `{i[m], j[m], k[m]}` together represent face m (triangle m) in the mesh, where `k[m] = n` points to the triplet  `{x[n], y[n], z[n]}` in the vertex arrays. Therefore, each element in `k` represents a point in space, which is the third vertex of a triangle.",
);

has lighting => ( is  => 'rw',
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Lighting" );

has lightposition => ( is  => 'rw',
                       isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Lightposition" );

has opacity => ( is            => 'rw',
                 isa           => "Num",
                 documentation => "Sets the opacity of the surface.",
);

has reversescale => ( is            => 'rw',
                      isa           => "Bool",
                      documentation => "Reverses the colorscale.",
);

has showscale => ( is            => 'rw',
                   isa           => "Bool",
                   documentation => "Determines whether or not a colorbar is displayed for this trace.",
);

has vertexcolor => ( is            => 'rw',
                     documentation => "Sets the color of each vertex Overrides *color*.", );

has x => (
    is => 'rw',
    documentation =>
      "Sets the X coordinates of the vertices. The nth element of vectors `x`, `y` and `z` jointly represent the X, Y and Z coordinates of the nth vertex.",
);

has y => (
    is => 'rw',
    documentation =>
      "Sets the Y coordinates of the vertices. The nth element of vectors `x`, `y` and `z` jointly represent the X, Y and Z coordinates of the nth vertex.",
);

has z => (
    is => 'rw',
    documentation =>
      "Sets the Z coordinates of the vertices. The nth element of vectors `x`, `y` and `z` jointly represent the X, Y and Z coordinates of the nth vertex.",
);

has name => ( is            => 'rw',
              isa           => "Str",
              documentation => "Sets the trace name",
);

sub type {
    my @components = split( /::/, __PACKAGE__ );
    return lc( $components[-1] );
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Mesh3d

=head1 VERSION

version 0.012

=head1 SYNOPSIS

 use Chart::Plotly qw(show_plot);
 use Chart::Plotly::Trace::Mesh3d;
 use List::Flatten;
 use List::MoreUtils qw/pairwise/;
 use English qw(-no_match_vars);
 
 my @x = flat map { [ 0 .. 10 ] } ( 0 .. 10 );
 my @y = flat map {
     my $y = $ARG;
     map { $y } ( 0 .. 10 )
 } ( 0 .. 10 );
 my @z = pairwise { $a * $a + $b * $b } @x, @y;
 my $mesh3d = Chart::Plotly::Trace::Mesh3d->new( x => \@x, y => \@y, z => \@z );
 
 show_plot( [$mesh3d] );

=head1 DESCRIPTION

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#mesh3d>

=head1 NAME 

Chart::Plotly::Trace::Mesh3d

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head1 ATTRIBUTES

=over

=item * alphahull

Determines how the mesh surface triangles are derived from the set of vertices (points) represented by the `x`, `y` and `z` arrays, if the `i`, `j`, `k` arrays are not supplied. For general use of `mesh3d` it is preferred that `i`, `j`, `k` are supplied. If *-1*, Delaunay triangulation is used, which is mainly suitable if the mesh is a single, more or less layer surface that is perpendicular to `delaunayaxis`. In case the `delaunayaxis` intersects the mesh surface at more than one point it will result triangles that are very long in the dimension of `delaunayaxis`. If *>0*, the alpha-shape algorithm is used. In this case, the positive `alphahull` value signals the use of the alpha-shape algorithm, _and_ its value acts as the parameter for the mesh fitting. If *0*,  the convex-hull algorithm is used. It is suitable for convex bodies or if the intention is to enclose the `x`, `y` and `z` point set into a convex hull.

=item * color

Sets the color of the whole mesh

=item * colorbar

=item * colorscale

Sets the colorscale. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in z space, use zmin and zmax

=item * contour

=item * delaunayaxis

Sets the Delaunay axis, which is the axis that is perpendicular to the surface of the Delaunay triangulation. It has an effect if `i`, `j`, `k` are not provided and `alphahull` is set to indicate Delaunay triangulation.

=item * facecolor

Sets the color of each face Overrides *color* and *vertexcolor*.

=item * flatshading

Determines whether or not normal smoothing is applied to the meshes, creating meshes with an angular, low-poly look via flat reflections.

=item * i

A vector of vertex indices, i.e. integer values between 0 and the length of the vertex vectors, representing the *first* vertex of a triangle. For example, `{i[m], j[m], k[m]}` together represent face m (triangle m) in the mesh, where `i[m] = n` points to the triplet `{x[n], y[n], z[n]}` in the vertex arrays. Therefore, each element in `i` represents a point in space, which is the first vertex of a triangle.

=item * intensity

Sets the vertex intensity values, used for plotting fields on meshes

=item * j

A vector of vertex indices, i.e. integer values between 0 and the length of the vertex vectors, representing the *second* vertex of a triangle. For example, `{i[m], j[m], k[m]}`  together represent face m (triangle m) in the mesh, where `j[m] = n` points to the triplet `{x[n], y[n], z[n]}` in the vertex arrays. Therefore, each element in `j` represents a point in space, which is the second vertex of a triangle.

=item * k

A vector of vertex indices, i.e. integer values between 0 and the length of the vertex vectors, representing the *third* vertex of a triangle. For example, `{i[m], j[m], k[m]}` together represent face m (triangle m) in the mesh, where `k[m] = n` points to the triplet  `{x[n], y[n], z[n]}` in the vertex arrays. Therefore, each element in `k` represents a point in space, which is the third vertex of a triangle.

=item * lighting

=item * lightposition

=item * opacity

Sets the opacity of the surface.

=item * reversescale

Reverses the colorscale.

=item * showscale

Determines whether or not a colorbar is displayed for this trace.

=item * vertexcolor

Sets the color of each vertex Overrides *color*.

=item * x

Sets the X coordinates of the vertices. The nth element of vectors `x`, `y` and `z` jointly represent the X, Y and Z coordinates of the nth vertex.

=item * y

Sets the Y coordinates of the vertices. The nth element of vectors `x`, `y` and `z` jointly represent the X, Y and Z coordinates of the nth vertex.

=item * z

Sets the Z coordinates of the vertices. The nth element of vectors `x`, `y` and `z` jointly represent the X, Y and Z coordinates of the nth vertex.

=item * name

Sets the trace name

=back

=head2 type

Trace type.

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
