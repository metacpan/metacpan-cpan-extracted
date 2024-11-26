package Alien::DuckDB;

use strict;
use warnings;
use parent qw( Alien::Base );
use 5.008004;

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Alien::DuckDB - Find or build DuckDB

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

 use Alien::DuckDB;
 use FFI::Platypus;
 
 my $ffi = FFI::Platypus->new;
 $ffi->lib(Alien::DuckDB->dynamic_libs);

=head1 DESCRIPTION

This distribution provides DuckDB so that it can be used by other Perl distributions
that require it. DuckDB is an in-process SQL OLAP database management system that 
provides fast analytics on large datasets.

This Alien distribution will download and install the appropriate pre-built DuckDB
binaries for your platform. It supports Linux (x86_64, aarch64), macOS (Universal),
and Windows (x86_64, arm64).

=head1 METHODS

=head2 dynamic_libs

 my @libs = Alien::DuckDB->dynamic_libs;

Returns a list of dynamic libraries (usually a single dynamic library) that make up 
DuckDB. This is the recommended way to use DuckDB via FFI.

=head1 SEE ALSO

=over 4

=item L<Alien>

Documentation on the Alien concept itself.

=item L<Alien::Base>

The base class for this Alien.

=item L<FFI::Platypus>

The recommended FFI interface for using C libraries like DuckDB from Perl.

=item L<https://duckdb.org/>

The DuckDB homepage with comprehensive documentation.

=item L<https://github.com/duckdb/duckdb>

The DuckDB GitHub repository.

=back

=head1 AUTHOR

Chris Prather E<lt>chris@prather.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Chris Prather

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
