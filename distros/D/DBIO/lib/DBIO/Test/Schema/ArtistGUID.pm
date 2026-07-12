package DBIO::Test::Schema::ArtistGUID;
# ABSTRACT: Test result class for the artist_guid table (UNIQUEIDENTIFIER PK)
use strict;
use warnings;
use base 'DBIO::Test::BaseResult';

__PACKAGE__->table('artist_guid');
__PACKAGE__->add_columns(
  artistid => {
    data_type => 'uniqueidentifier',
    is_auto_increment => 1,
  },
  name => {
    data_type => 'varchar',
    size      => 100,
    is_nullable => 1,
  },
  rank => {
    data_type => 'integer',
    default_value => 13,
  },
  charfield => {
    data_type => 'char',
    size => 10,
    is_nullable => 1,
  },
  a_guid => {
    data_type => 'uniqueidentifier',
    is_nullable => 1,
    auto_nextval => 1, # not a PK -- only auto_nextval triggers GUID prefetch
  },
);
__PACKAGE__->set_primary_key('artistid');
__PACKAGE__->resultset_class('DBIO::Test::BaseResultSet');
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::ArtistGUID - Test result class for the artist_guid table (UNIQUEIDENTIFIER PK)

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
