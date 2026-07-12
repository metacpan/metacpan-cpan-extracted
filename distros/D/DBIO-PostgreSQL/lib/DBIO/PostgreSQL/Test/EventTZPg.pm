package DBIO::PostgreSQL::Test::EventTZPg;
# ABSTRACT: Test result class for PostgreSQL timezone-aware datetime inflation

use strict;
use warnings;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);

__PACKAGE__->table('event');

__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_auto_increment => 1 },

  starts_at => { data_type => 'date', datetime_undef_if_invalid => 1 },

  created_on => {
    data_type => 'timestamp with time zone',
    timezone  => 'America/Chicago',
  },
  varchar_date => { data_type => 'varchar', size => 20, is_nullable => 1 },
  varchar_datetime => { data_type => 'varchar', size => 20, is_nullable => 1 },
  skip_inflation => { data_type => 'datetime', inflate_datetime => 0, is_nullable => 1 },
  ts_without_tz => { data_type => 'timestamp without time zone', is_nullable => 1 },
);

__PACKAGE__->set_primary_key('id');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Test::EventTZPg - Test result class for PostgreSQL timezone-aware datetime inflation

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
