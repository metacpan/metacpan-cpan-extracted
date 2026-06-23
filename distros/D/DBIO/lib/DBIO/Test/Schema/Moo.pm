package DBIO::Test::Schema::Moo;
# ABSTRACT: Test schema with Moo-enabled result classes

use strict;
use warnings;

use Moo;
extends 'DBIO::Schema';

# Schema-level Moo attribute — demonstrates Moo on the schema class itself
has verbose => ( is => 'rw', lazy => 1, default => sub { 0 } );

__PACKAGE__->load_classes(
  { 'DBIO::Test::Schema::Moo' => [qw( Result::Artist Result::CD )] }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::Moo - Test schema with Moo-enabled result classes

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
