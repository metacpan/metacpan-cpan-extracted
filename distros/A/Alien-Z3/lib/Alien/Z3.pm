package Alien::Z3;
use strict;
use warnings;

# ABSTRACT: Perl distribution for Z3 Solver
our $VERSION = '0.002';

use parent 'Alien::Base';

1;
__END__

=pod

=encoding utf8

=head1 NAME

Alien::Z3 - Perl distribution for Z3

=head1 VERSION

version 0.001

=head1 INSTALL

    cpanm Alien::Z3

=head1 DESCRIPTION

This Alien module wraps the Z3 C library. This release supports version 4.8.4 of the Z3 library

=head1 KNOWN ISSUES

The z3 binary is also built along with the library, this requires a significant amount of RAM to build.

=head1 AUTHOR

Ryan Voots

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 Ryan Voots

This library is free software; Distributed under the Artistic 2.0 License

The Z3 library is copyright Microsoft and distributed under the MIT license.

=cut

