package DBIO::Test::Schema::BindType;
# ABSTRACT: Test result class for the bindtype_test table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('bindtype_test');

__PACKAGE__->add_columns(
  'id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'bytea' => {
    data_type => 'bytea',
    is_nullable => 1,
  },
  'blob' => {
    data_type => 'blob',
    is_nullable => 1,
  },
  'clob' => {
    data_type => 'clob',
    is_nullable => 1,
  },
  'a_memo' => {
    data_type => 'mediumtext',
    is_nullable => 1,
  },
);

__PACKAGE__->set_primary_key('id');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::BindType - Test result class for the bindtype_test table

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
