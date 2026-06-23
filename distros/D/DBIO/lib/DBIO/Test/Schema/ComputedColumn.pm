package DBIO::Test::Schema::ComputedColumn;
# ABSTRACT: Test result class for the computed_column_test table

use strict;
use warnings;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('computed_column_test');

__PACKAGE__->add_columns(
  id => {
    data_type         => 'integer',
    is_auto_increment => 1,
  },
  a_computed_column => {
    data_type     => undef,
    is_nullable   => 0,
    default_value => \'getdate()',
  },
  a_timestamp => {
    data_type   => 'timestamp',
    is_nullable => 0,
  },
  charfield => {
    data_type     => 'varchar',
    size          => 20,
    default_value => 'foo',
    is_nullable   => 0,
  },
);

__PACKAGE__->set_primary_key('id');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::ComputedColumn - Test result class for the computed_column_test table

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
