package DBIO::Version;
# ABSTRACT: Schema class for versioning support
use base 'DBIO::Schema';
use strict;
use warnings;

use DBIO::Version::Table;

__PACKAGE__->register_class('Table', 'DBIO::Version::Table');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Version - Schema class for versioning support

=head1 VERSION

version 0.900000

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
