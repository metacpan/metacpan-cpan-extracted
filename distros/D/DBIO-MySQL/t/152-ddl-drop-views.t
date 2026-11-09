use strict;
use warnings;
use Test::More;

# OFFLINE half of karr k114: add_drop_table drops the declared views before the
# tables, on the sync way (DBIO::MySQL::Deploy) and on the async way (the
# pre-pass of deploy_async), each in backticks.
#
# WHY IT MATTERS. The install DDL says CREATE VIEW, never CREATE OR REPLACE, so
# a second deploy over a database that already holds the views dies on the first
# of them -- and a table drop in front of it leaves the views behind, reading a
# table that is not there. The idempotent re-deploy add_drop_table promises has
# to take the views away first, a reader before the view it reads, and name them
# as the install DDL names them.

use DBIO::MySQL::DDL;
use DBIO::MySQL::Deploy;

{
  package DropViews::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package DropViews::Schema::Result::Order;
  use DBIO;
  __PACKAGE__->table('order');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
}
{
  package DropViews::Schema::Result::Line;
  use DBIO;
  __PACKAGE__->table('line');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
}
# a_top reads z_base, which reads `order`: name order is not read order
{
  package DropViews::Schema::Result::ATop;
  use base 'DBIO::Core';
  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('a_top');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->result_source_instance->view_definition('SELECT id FROM z_base');
  # the async pre-pass orders the views by what they declare, not by reading the SQL
  __PACKAGE__->result_source_instance->deploy_depends_on({ 'DropViews::Schema::Result::ZBase' => 1 });
}
{
  package DropViews::Schema::Result::ZBase;
  use base 'DBIO::Core';
  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('z_base');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->result_source_instance->view_definition('SELECT id FROM `order`');
}
{
  package DropViews::Schema::Result::Virt;
  use base 'DBIO::Core';
  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('virt_view');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->result_source_instance->view_definition('SELECT 1 AS id');
  __PACKAGE__->result_source_instance->is_virtual(1);
}
DropViews::Schema->register_class($_ => "DropViews::Schema::Result::$_")
  for qw(Order Line ATop ZBase Virt);

my @views  = ('DROP VIEW IF EXISTS `a_top`;', 'DROP VIEW IF EXISTS `z_base`;');
my @tables = ('DROP TABLE IF EXISTS `line`;', 'DROP TABLE IF EXISTS `order`;');
my @atables = map { s{;$}{ CASCADE;}r } @tables;

# --- the shared statement list -------------------------------------------------
{
  my @got = split /\n\n/, DBIO::MySQL::DDL->drop_ddl('DropViews::Schema');
  is_deeply [ @got[0, 1] ], \@views,
    'drop_ddl: the views first, a reader before the view it reads';
  is_deeply [ sort @got[2 .. $#got] ], \@tables, 'then the tables, backticked';
  is scalar(@got), 4, 'nothing else: the virtual view is no object of the database';
  unlike join("\n", @got), qr/virt_view/, 'no DROP for the virtual view';
}

# --- the sync way: DBIO::MySQL::Deploy -----------------------------------------
{
  package DropViews::Probe;
  our @ISA = ('DBIO::MySQL::Deploy');
  sub _dbh { $_[0]{dbh} }
  sub _execute_ddl { my ($self, $dbh, $sql) = @_; push @{ $self->{ran} }, $sql; 1 }
  package DropViews::Dbh;
  sub new { bless { did => [] }, shift }
  sub do  { push @{ $_[0]{did} }, $_[1]; 1 }
}

{
  my $dbh = DropViews::Dbh->new;
  my $d = DropViews::Probe->new(schema => 'DropViews::Schema', dbh => $dbh, add_drop_table => 1);
  $d->install;
  my ($drop_batch, $install_batch) = @{ $d->{ran} };
  like $install_batch // '', qr/\ACREATE TABLE/, 'the install DDL runs after the drops, as it did';
  my @drops = split /\n\n/, $drop_batch // '';
  is_deeply [ @drops[0, 1] ], \@views, 'Deploy install: the views dropped first, in read order';
  is_deeply [ sort @drops[2 .. $#drops] ], \@tables, 'Deploy install: then the tables';
  is_deeply $dbh->{did},
    [ 'SET FOREIGN_KEY_CHECKS = 0', 'SET FOREIGN_KEY_CHECKS = 1' ],
    'the foreign key checks are off for the drops only and on again after';

  my $plain = DropViews::Probe->new(schema => 'DropViews::Schema', dbh => DropViews::Dbh->new);
  $plain->install;
  is scalar(@{ $plain->{ran} }), 1, 'install without add_drop_table runs the install DDL alone';
  unlike $plain->{ran}[0], qr/DROP/, 'and drops nothing';
}

# --- the async way: the pre-pass of deploy_async --------------------------------
SKIP: {
  eval { require DBIO::MySQL::Storage::Async; 1 }
    or skip 'DBIO::Async not installed (recommends only)', 4;
  for my $class (qw(DBIO::MySQL::Storage::Async DBIO::MySQL::Storage::MariaDB::Async)) {
    eval "require $class; 1" or die $@;
    my @got = split /\n\n/, $class->new(undef)->_drop_statements_for('DropViews::Schema');
    is_deeply [ @got[0, 1] ], \@views, "$class: the views first, backticked, a reader before its view";
    is_deeply [ sort @got[2 .. $#got] ], \@atables, "$class: then the tables";
  }
}

done_testing;
