use strict;
use warnings;
use Test::More;

# OFFLINE half of karr k88: the DROP pre-pass of deploy_async(add_drop_table => 1)
# on the future_io transport quotes the tables with backticks.
#
# WHY IT MATTERS. Core's seam quotes ANSI -- a plain name bare, any other in
# double quotes. On MySQL and MariaDB `DROP TABLE IF EXISTS order` is a syntax
# error (1064) and "my-tab" is a string literal, so an idempotent re-deploy of
# any schema with a reserved-word table name died before it began. The install
# DDL quotes with DBIO::MySQL::Identifier (k77); the pre-pass has to name the
# tables the same way, or it drops other tables than the DDL creates.
# Which objects are dropped (the declared views first -- karr k114 -- then the
# regular tables, computed names skipped) is core's and is pinned here as well,
# so an override that quotes right but drops the wrong set fails.

BEGIN {
  eval { require DBIO::MySQL::Storage::Async; 1 }
    or plan skip_all => 'DBIO::Async not installed (recommends only)';
}

{
  package DropQuote::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package DropQuote::Schema::Result::Order;
  use DBIO;
  __PACKAGE__->table('order');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
}
{
  package DropQuote::Schema::Result::Hyphen;
  use DBIO;
  __PACKAGE__->table('my-tab');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
}
{
  package DropQuote::Schema::Result::Tick;
  use DBIO;
  __PACKAGE__->table('we`ird');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
}
{
  package DropQuote::Schema::Result::Plain;
  use DBIO;
  __PACKAGE__->table('plain');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
}
{
  package DropQuote::Schema::Result::OrderView;
  use base 'DBIO::Core';
  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('order_view');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->result_source_instance->view_definition('SELECT id FROM `order`');
}
DropQuote::Schema->register_class($_ => "DropQuote::Schema::Result::$_")
  for qw(Order Hyphen Tick Plain OrderView);

for my $class (qw(DBIO::MySQL::Storage::Async DBIO::MySQL::Storage::MariaDB::Async)) {
  eval "require $class; 1" or die $@;
  my $storage = $class->new(undef);
  my @stmts = split /\n\n/, $storage->_drop_statements_for('DropQuote::Schema');
  my %got = map { $_ => 1 } @stmts;

  for my $t ('`order`', '`my-tab`', '`we``ird`', '`plain`') {
    ok $got{"DROP TABLE IF EXISTS $t CASCADE;"}, "$class: $t dropped, backticked";
  }
  is scalar(@stmts), 5, "$class: five statements -- the four tables and the view";
  is $stmts[0], 'DROP VIEW IF EXISTS `order_view`;', "$class: the view goes first, backticked";
  ok !(grep { /order_view/ } @stmts[1 .. $#stmts]), "$class: no DROP for the view among the tables";
  is $storage->_drop_statements_for('DropQuote::Schema'),
     join("\n\n", @stmts), "$class: one string, statements joined by a blank line";
}

done_testing;
