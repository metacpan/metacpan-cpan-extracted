package DBIO::Test::Schema::CD_to_Producer;
# ABSTRACT: Test result class for the cd_to_producer table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('cd_to_producer');
__PACKAGE__->add_columns(
  cd => { data_type => 'integer' },
  producer => { data_type => 'integer' },
  attribute => { data_type => 'integer', is_nullable => 1 },
);
__PACKAGE__->set_primary_key(qw/cd producer/);

# the undef condition in this rel is *deliberate*
# tests oddball legacy syntax
__PACKAGE__->belongs_to(
  'cd', 'DBIO::Test::Schema::CD'
);

__PACKAGE__->belongs_to(
  'producer', 'DBIO::Test::Schema::Producer',
  { 'foreign.producerid' => 'self.producer' },
  { on_delete => undef, on_update => undef },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::CD_to_Producer - Test result class for the cd_to_producer table

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
