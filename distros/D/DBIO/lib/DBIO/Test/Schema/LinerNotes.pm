package DBIO::Test::Schema::LinerNotes;
# ABSTRACT: Test result class for the liner_notes table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('liner_notes');
__PACKAGE__->add_columns(
  'liner_id' => {
    data_type => 'integer',
  },
  'notes' => {
    data_type => 'varchar',
    size      => 100,
  },
);
__PACKAGE__->set_primary_key('liner_id');
__PACKAGE__->belongs_to(
  'cd', 'DBIO::Test::Schema::CD', 'liner_id'
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::LinerNotes - Test result class for the liner_notes table

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
