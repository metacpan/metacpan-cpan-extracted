package DBIO::Oracle::Test::SequenceTest;
# ABSTRACT: Test result class for Oracle sequence tests

use strict;
use warnings;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('sequence_test');

__PACKAGE__->add_columns(
  pkid1 => {
    data_type => 'integer',
    sequence => 'pkid1_seq',
    is_auto_increment => 1,
    auto_nextval => 1,
  },
  pkid2 => {
    data_type => 'integer',
    sequence => 'pkid2_seq',
    is_auto_increment => 1,
    auto_nextval => 1,
  },
  nonpkid => {
    data_type => 'integer',
    sequence => 'nonpkid_seq',
    is_auto_increment => 1,
    auto_nextval => 1,
  },
  name => {
    data_type => 'varchar',
    size => 100,
    is_nullable => 1,
  },
);

__PACKAGE__->set_primary_key('pkid1', 'pkid2');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Test::SequenceTest - Test result class for Oracle sequence tests

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
