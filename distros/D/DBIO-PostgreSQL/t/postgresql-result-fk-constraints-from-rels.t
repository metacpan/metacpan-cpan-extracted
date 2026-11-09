#!perl
use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::DDL;

{
    package DBIO::Test::FKRels::Schema;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('PostgreSQL');
}

{
    package DBIO::Test::FKRels::Result::Customer;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('customer');
    __PACKAGE__->add_columns(
        id => { data_type => 'integer', is_auto_increment => 1 },
    );
    __PACKAGE__->set_primary_key('id');
}

# No option set, plain column-equality belongs_to: the default is on, so it
# must emit a FOREIGN KEY.
{
    package DBIO::Test::FKRels::Result::CustomerOrder;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('customer_order');
    __PACKAGE__->add_columns(
        id          => { data_type => 'integer', is_auto_increment => 1 },
        customer_id => { data_type => 'integer' },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to(customer => 'DBIO::Test::FKRels::Result::Customer', 'customer_id');
}

# Default on, but the belongs_to condition is not plain column equality:
# must be skipped with a comment, not silently dropped.
{
    package DBIO::Test::FKRels::Result::Weird;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('weird');
    __PACKAGE__->add_columns(
        id          => { data_type => 'integer', is_auto_increment => 1 },
        customer_id => { data_type => 'integer' },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to(customer => 'DBIO::Test::FKRels::Result::Customer', sub { {} });
}

# Plain column-equality belongs_to, switched off for the class with 0:
# no FK is auto-generated.
{
    package DBIO::Test::FKRels::Result::OptOut;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('opt_out');
    __PACKAGE__->add_columns(
        id          => { data_type => 'integer', is_auto_increment => 1 },
        customer_id => { data_type => 'integer' },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to(customer => 'DBIO::Test::FKRels::Result::Customer', 'customer_id');
    __PACKAGE__->pg_fk_constraints_from_rels(0);
}

# Default on, plain column equality, but the foreign class is not part of
# this schema deploy (never registered): refused, rather than emitting a FK
# that references a table that will not exist or leaving a note (karr k120).
{
    package DBIO::Test::FKRels::Result::Unregistered;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('unregistered_target');
    __PACKAGE__->add_columns(
        id => { data_type => 'integer', is_auto_increment => 1 },
    );
    __PACKAGE__->set_primary_key('id');
}

{
    package DBIO::Test::FKRels::Result::Orphan;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('orphan');
    __PACKAGE__->add_columns(
        id        => { data_type => 'integer', is_auto_increment => 1 },
        target_id => { data_type => 'integer' },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to(target => 'DBIO::Test::FKRels::Result::Unregistered', 'target_id');
}

{
    package DBIO::Test::FKRels::Result::Ghostly;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('ghostly');
    __PACKAGE__->add_columns(
        id       => { data_type => 'integer', is_auto_increment => 1 },
        ghost_id => { data_type => 'integer' },
    );
    __PACKAGE__->set_primary_key('id');
    # hashref condition skips ensure_class_loaded, so the foreign class below
    # is never loaded at all -- the FK phase must refuse it by name, not die on
    # ->table
    __PACKAGE__->belongs_to(ghost => 'DBIO::Test::FKRels::Result::NeverLoaded',
        { 'foreign.id' => 'self.ghost_id' });
}

DBIO::Test::FKRels::Schema->register_class(Customer      => 'DBIO::Test::FKRels::Result::Customer');
DBIO::Test::FKRels::Schema->register_class(CustomerOrder => 'DBIO::Test::FKRels::Result::CustomerOrder');
DBIO::Test::FKRels::Schema->register_class(Weird         => 'DBIO::Test::FKRels::Result::Weird');
DBIO::Test::FKRels::Schema->register_class(OptOut        => 'DBIO::Test::FKRels::Result::OptOut');

# The two declarations that cannot become a foreign key are each a schema of
# their own: the script is refused, so they cannot share one with the rest.
for my $case (
  [ Orphan  => 'DBIO::Test::FKRels::Result::Orphan'  ],
  [ Ghostly => 'DBIO::Test::FKRels::Result::Ghostly' ],
) {
  my $schema = "DBIO::Test::FKRels::Schema::$case->[0]";
  eval "package $schema; use base 'DBIO::Schema'; __PACKAGE__->load_components('PostgreSQL'); 1"
    or die $@;
  $schema->register_class(Customer => 'DBIO::Test::FKRels::Result::Customer');
  $schema->register_class($case->[0] => $case->[1]);
}

my $sql = DBIO::PostgreSQL::DDL->install_ddl('DBIO::Test::FKRels::Schema');

like($sql,
  qr/ALTER TABLE customer_order ADD CONSTRAINT customer_order_customer_id_fkey FOREIGN KEY \(customer_id\) REFERENCES customer \(id\);/,
  'opted-in belongs_to with plain column equality emits a FOREIGN KEY constraint');

like($sql, qr/-- skipped FK for rel customer: non-column condition/,
  'non-column-equality belongs_to condition is skipped with a comment');
unlike($sql, qr/skipped FK for rel (?:target|ghost)/,
  'no other reason is a note: those are refused');

is(DBIO::Test::FKRels::Result::CustomerOrder->pg_fk_constraints_from_rels, 1,
  'default is on: a class that sets nothing writes its foreign keys');
is(DBIO::Test::FKRels::Result::OptOut->pg_fk_constraints_from_rels, 0,
  'a class can switch it off with 0');
unlike($sql, qr/ADD CONSTRAINT opt_out_customer_id_fkey/,
  'switched off with 0: a belongs_to of that class gets no auto-generated FK');

{
  my $err = do { local $@; eval { DBIO::PostgreSQL::DDL->install_ddl('DBIO::Test::FKRels::Schema::Orphan'); 1 } ? '' : "$@" };
  like($err, qr/refusing to write the install DDL: relationship 'target' of orphan .*unregistered_target.*not part of this schema deploy/,
    'a belongs_to to a class outside this schema deploy refuses the script, naming relationship, table and target');
}
{
  my $err = do { local $@; eval { DBIO::PostgreSQL::DDL->install_ddl('DBIO::Test::FKRels::Schema::Ghostly'); 1 } ? '' : "$@" };
  like($err, qr/refusing to write the install DDL: relationship 'ghost' of ghostly .*\S+NeverLoaded, which is not loaded/,
    'an unloaded foreign class (hashref-cond belongs_to) refuses the script by name instead of dying on ->table');
}

# Ordering: every CREATE TABLE must appear before every FK ALTER (cross-table
# refs -- the FK phase runs only after every table in the batch exists).
my $last_create_table_pos = 0;
while ($sql =~ /CREATE TABLE/g) {
  $last_create_table_pos = pos($sql);
}
ok($sql =~ /ADD CONSTRAINT customer_order_customer_id_fkey/,
  'sanity: the FK statement is present') or BAIL_OUT('FK statement missing, cannot check ordering');
my $fk_alter_pos = $-[0];
ok($fk_alter_pos > $last_create_table_pos,
  'FK ALTER statements are emitted after every CREATE TABLE in the batch');

done_testing;
