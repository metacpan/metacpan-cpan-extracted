# NAME

CAD::Mesh3D - Create and Manipulate 3D Vertexes and Meshes and output for 3D printing

# SYNOPSIS

    use CAD::Mesh3D qw(+STL :create :formats);
    my $vect = createVertex();
    my $tri  = createFacet($v1, $v2, $v3);
    my $mesh = createMesh();
    $mesh->addToMesh($tri);
    ...
    $mesh->output(STL => $filehandle_or_filename, $ascii_or_binary);

# DESCRIPTION

A framework to create and manipulate 3D vertexes and meshes, suitable for generating STL files
(or other similar formats) for 3D printing.

A **Mesh** is the container for the surface of the shape or object being generated.  The surface is broken down
into locally-flat pieces known as **Facets**.  Each **Facet** is a triangle made from three points, called
**Vertexes** (also spelled as vertices).  Each **Vertex** is made up of three x, y, and z **coordinates**, which
are just floating-point values to represent the position in 3D space.

# TODO

- Add more math for **Vertexes** and **Facets**, as new functions are identified
as being useful.

# AUTHOR

Peter C. Jones `<petercj AT cpan DOT org>`

<div>
    <a href="https://github.com/pryrt/CAD-Mesh3D/issues"><img src="https://img.shields.io/github/issues/pryrt/CAD-Mesh3D.svg" alt="issues" title="issues"></a>
    <a href="https://ci.appveyor.com/project/pryrt/CAD-Mesh3D"><img src="https://ci.appveyor.com/api/projects/status/bc5jt6b2bjmpig5x?svg=true" alt="appveyor build status" title="appveyor build status"></a>
    <a href="https://travis-ci.org/pryrt/CAD-Mesh3D"><img src="https://travis-ci.org/pryrt/CAD-Mesh3D.svg?branch=master" alt="travis build status" title="travis build status"></a>
    <a href='https://coveralls.io/github/pryrt/CAD-Mesh3D?branch=master'><img src='https://coveralls.io/repos/github/pryrt/CAD-Mesh3D/badge.svg?branch=master' alt='Coverage Status' title='Coverage Status' /></a>
</div>

# COPYRIGHT

Copyright (C) 2017,2018,2019,2020,2021 Peter C. Jones

# LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
