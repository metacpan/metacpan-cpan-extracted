package DBIO::Test::Schema::Owners;
# ABSTRACT: Test result class for the owners table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('owners');
__PACKAGE__->add_columns(
  'id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'name' => {
    data_type => 'varchar',
    size      => '100',
  },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint(['name']);

__PACKAGE__->has_many(books => "DBIO::Test::Schema::BooksInLibrary", "owner");

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::Owners - Test result class for the owners table

=head1 VERSION

version 0.900001

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
