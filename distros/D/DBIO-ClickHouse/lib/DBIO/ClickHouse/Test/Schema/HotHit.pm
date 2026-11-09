package DBIO::ClickHouse::Test::Schema::HotHit;
# ABSTRACT: Test result class -- a non-virtual view over the hit table

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Core';


__PACKAGE__->table_class('DBIO::ResultSource::View');
__PACKAGE__->table('dbio_test_hot_hit');

__PACKAGE__->add_columns(
  id   => { data_type => 'uuid',    is_nullable => 0 },
  url  => { data_type => 'varchar', size => 2048, is_nullable => 0 },
  hits => { data_type => 'integer', extra => { unsigned => 1 }, is_nullable => 0 }
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->result_source_instance->view_definition(
  'SELECT `id`, `url`, `hits` FROM `dbio_test_hit` WHERE `hits` >= 100'
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Test::Schema::HotHit - Test result class -- a non-virtual view over the hit table

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The one view in L<DBIO::ClickHouse::Test::Schema>. It is not virtual, so
L<DBIO::ClickHouse::DDL/install_ddl> emits a real C<CREATE VIEW> for it -- the
only route by which L<DBIO::ClickHouse::DDL::Emit/create_view> is ever executed
against a server.

Views are outside the upgrade path (L<DBIO::ClickHouse::Diff/Views are not
diffed>), so having one here also pins that: the deploy round trip in
C<t/30-deploy.t> must stay clean B<despite> a view being present on both sides,
whose C<create_table_query> the server rewrites into a database-qualified form
that would never compare equal.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
