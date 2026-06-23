package DBIO::Test::Schema::TypedObject;
# ABSTRACT: Test result class for the typed_object table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('typed_object');
__PACKAGE__->add_columns(
  'objectid' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'type' => {
    data_type => 'varchar',
    size      => '100',
  },
  'value' => {
    data_type => 'varchar',
    size      => 100,
  },
);
__PACKAGE__->set_primary_key('objectid');

__PACKAGE__->has_many( collection_object => "DBIO::Test::Schema::CollectionObject",
                       { "foreign.object" => "self.objectid" }
                     );
__PACKAGE__->many_to_many( collections => collection_object => "collection" );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::TypedObject - Test result class for the typed_object table

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
