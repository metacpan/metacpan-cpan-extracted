package DBIO::Test::MooseSchema;
# ABSTRACT: Test schema with Moose-enabled result classes

use strict;
use warnings;

use Moose;
extends 'DBIO::Schema';

# Schema-level Moose attribute — demonstrates Moose on the schema class itself
has verbose => ( is => 'rw', isa => 'Bool', lazy => 1, default => 0 );

__PACKAGE__->load_classes(
  { 'DBIO::Test::MooseSchema' => [qw( Result::Artist Result::CD )] }
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::MooseSchema - Test schema with Moose-enabled result classes

=head1 VERSION

version 0.900002

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
