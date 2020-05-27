package Alien::sqlite;

use strict;
use warnings;
use parent qw( Alien::Base );

our $VERSION = '1.06';


1;

__END__

=head1 NAME

Alien::sqlite - Compile the Sqlite library

=head1 BUILD STATUS
 
=begin HTML
 
<p>
    <img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
    <a href="https://travis-ci.org/shawnlaffan/perl-alien-sqlite"><img src="https://travis-ci.org/shawnlaffan/perl-alien-sqlite.svg?branch=master" /></a>
    <a href="https://ci.appveyor.com/project/shawnlaffan/perl-alien-sqlite"><img src="https://ci.appveyor.com/api/projects/status/weou0nr12huxqa72?svg=true" /></a>
</p>

=end HTML

=head1 SYNOPSIS

    use Alien::sqlite;

    
=head1 DESCRIPTION


This Alien package is probably most useful for compilation of other modules, e.g. L<Geo::GDAL::FFI>.

The Sqlite library can already be accessed from Perl code via the L<DBD::SQLite> package.  

=head1 REPORTING BUGS

Please send any bugs, suggestions, or feature requests to 
L<https://github.com/shawnlaffan/perl-alien-sqlite/issues>.

=head1 SEE ALSO

L<Geo::GDAL::FFI>

L<Alien::gdal>

L<Alien::geos::af>

L<Alien::proj>

L<Alien::spatialite>


=head1 AUTHORS

Shawn Laffan, E<lt>shawnlaffan@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE


Copyright 2018- by Shawn Laffan


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
