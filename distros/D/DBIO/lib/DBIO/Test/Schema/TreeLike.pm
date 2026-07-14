package DBIO::Test::Schema::TreeLike;
# ABSTRACT: Test result class for the treelike table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('treelike');
__PACKAGE__->add_columns(
  'id' => { data_type => 'integer', is_auto_increment => 1 },
  'parent' => { data_type => 'integer' , is_nullable=>1},
  'name' => { data_type => 'varchar',
    size      => 100,
 },
);
__PACKAGE__->set_primary_key(qw/id/);
__PACKAGE__->belongs_to('parent', 'TreeLike',
                          { 'foreign.id' => 'self.parent' });
__PACKAGE__->has_many('children', 'TreeLike', { 'foreign.parent' => 'self.id' });

## since this is a self referential table we need to do a post deploy hook and get
## some data in while constraints are off

 sub sqlt_deploy_hook {
   my ($self, $sqlt_table) = @_;

   ## We don't seem to need this anymore, but keeping it for the moment
   ## $sqlt_table->add_index(name => 'idx_name', fields => ['name']);
 }
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::TreeLike - Test result class for the treelike table

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
