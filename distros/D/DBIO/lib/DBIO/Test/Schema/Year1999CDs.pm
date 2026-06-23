package DBIO::Test::Schema::Year1999CDs;
# ABSTRACT: Test virtual view result class for 1999 CDs
## Used in 104view.t

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table_class('DBIO::ResultSource::View');

__PACKAGE__->table('year1999cds');
__PACKAGE__->result_source_instance->is_virtual(1);
__PACKAGE__->result_source_instance->view_definition(
  "SELECT cdid, artist, title, single_track FROM cd WHERE year ='1999'"
);
__PACKAGE__->add_columns(
  'cdid' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'artist' => {
    data_type => 'integer',
  },
  'title' => {
    data_type => 'varchar',
    size      => 100,
  },
  'single_track' => {
    data_type => 'integer',
    is_nullable => 1,
    is_foreign_key => 1,
  },
);
__PACKAGE__->set_primary_key('cdid');
__PACKAGE__->add_unique_constraint([ qw/artist title/ ]);

__PACKAGE__->belongs_to( artist => 'DBIO::Test::Schema::Artist' );
__PACKAGE__->has_many( tracks => 'DBIO::Test::Schema::Track', 'cd' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::Year1999CDs - Test virtual view result class for 1999 CDs

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
