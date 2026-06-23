package DBIO::Test::Schema::Genre;
# ABSTRACT: Test result class for the genre table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('genre');
__PACKAGE__->add_columns(
    genreid => {
      data_type => 'integer',
      is_auto_increment => 1,
    },
    name => {
      data_type => 'varchar',
      size => 100,
    },
);
__PACKAGE__->set_primary_key('genreid');
__PACKAGE__->add_unique_constraint ( genre_name => [qw/name/] );

__PACKAGE__->has_many (cds => 'DBIO::Test::Schema::CD', 'genreid');

__PACKAGE__->has_one (model_cd => 'DBIO::Test::Schema::CD', 'genreid');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::Genre - Test result class for the genre table

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
