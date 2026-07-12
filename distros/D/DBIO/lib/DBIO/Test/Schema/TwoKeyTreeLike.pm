package DBIO::Test::Schema::TwoKeyTreeLike;
# ABSTRACT: Test result class for the twokeytreelike table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('twokeytreelike');
__PACKAGE__->add_columns(
  'id1' => { data_type => 'integer' },
  'id2' => { data_type => 'integer' },
  'parent1' => { data_type => 'integer' },
  'parent2' => { data_type => 'integer' },
  'name' => { data_type => 'varchar',
    size      => 100,
 },
);
__PACKAGE__->set_primary_key(qw/id1 id2/);
__PACKAGE__->add_unique_constraint('tktlnameunique' => ['name']);
__PACKAGE__->belongs_to('parent', 'DBIO::Test::Schema::TwoKeyTreeLike',
                          { 'foreign.id1' => 'self.parent1', 'foreign.id2' => 'self.parent2'});

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::TwoKeyTreeLike - Test result class for the twokeytreelike table

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
