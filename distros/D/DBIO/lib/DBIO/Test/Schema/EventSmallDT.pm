package DBIO::Test::Schema::EventSmallDT;
# ABSTRACT: Test result class for the event_small_dt table with smalldatetime inflation

use strict;
use warnings;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);

__PACKAGE__->table('event_small_dt');

__PACKAGE__->add_columns(
  id       => { data_type => 'integer', is_auto_increment => 1 },
  small_dt => { data_type => 'smalldatetime', datetime_undef_if_invalid => 1 },
);

__PACKAGE__->set_primary_key('id');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::EventSmallDT - Test result class for the event_small_dt table with smalldatetime inflation

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
