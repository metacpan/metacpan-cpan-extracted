package DBIO::Test::Schema::BooksInLibrary;
# ABSTRACT: Test result class for the books table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('books');
__PACKAGE__->add_columns(
  'id' => {
    # part of a test (auto-retrieval of PK regardless of autoinc status)
    # DO NOT define
    #is_auto_increment => 1,

    data_type => 'integer',
  },
  'source' => {
    data_type => 'varchar',
    size      => '100',
  },
  'owner' => {
    data_type => 'integer',
  },
  'title' => {
    data_type => 'varchar',
    size      => '100',
  },
  'price' => {
    data_type => 'integer',
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint (['title']);

__PACKAGE__->resultset_attributes({where => { source => "Library" } });

__PACKAGE__->belongs_to ( owner => 'DBIO::Test::Schema::Owners', 'owner' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::BooksInLibrary - Test result class for the books table

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
