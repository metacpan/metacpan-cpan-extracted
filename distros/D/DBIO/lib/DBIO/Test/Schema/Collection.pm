package DBIO::Test::Schema::Collection;
# ABSTRACT: Test result class for the collection table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('collection');
__PACKAGE__->add_columns(
  'collectionid' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'name' => {
    data_type => 'varchar',
    size      => 100,
  },
);
__PACKAGE__->set_primary_key('collectionid');

__PACKAGE__->has_many( collection_object => "DBIO::Test::Schema::CollectionObject",
                       { "foreign.collection" => "self.collectionid" }
                     );
__PACKAGE__->many_to_many( objects => collection_object => "object" );
__PACKAGE__->many_to_many( pointy_objects => collection_object => "object",
                           { where => { "object.type" => "pointy" } }
                         );
__PACKAGE__->many_to_many( round_objects => collection_object => "object",
                           { where => { "object.type" => "round" } }
                         );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::Collection - Test result class for the collection table

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
