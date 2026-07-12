package DBIO::Test::Schema::Image;
# ABSTRACT: Test result class for the images table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('images');
__PACKAGE__->add_columns(
  'id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'artwork_id' => {
    data_type => 'integer',
    is_foreign_key => 1,
  },
  'name' => {
    data_type => 'varchar',
    size => 100,
  },
  'data' => {
    data_type => 'blob',
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('artwork', 'DBIO::Test::Schema::Artwork', 'artwork_id');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::Image - Test result class for the images table

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
