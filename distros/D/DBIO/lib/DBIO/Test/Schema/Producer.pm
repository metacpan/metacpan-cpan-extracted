package DBIO::Test::Schema::Producer;
# ABSTRACT: Test result class for the producer table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('producer');
__PACKAGE__->add_columns(
  'producerid' => {
    data_type => 'integer',
    is_auto_increment => 1
  },
  'name' => {
    data_type => 'varchar',
    size      => 100,
  },
);
__PACKAGE__->set_primary_key('producerid');
__PACKAGE__->add_unique_constraint(prod_name => [ qw/name/ ]);

__PACKAGE__->has_many(
    producer_to_cd => 'DBIO::Test::Schema::CD_to_Producer' => 'producer'
);
__PACKAGE__->many_to_many('cds', 'producer_to_cd', 'cd');
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::Producer - Test result class for the producer table

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
