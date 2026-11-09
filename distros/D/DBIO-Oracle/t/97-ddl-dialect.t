use strict;
use warnings;
use Test::More;

use DBIO::Schema;
use DBIO::Oracle::Storage;
use DBIO::Oracle::Deploy;

# OFFLINE (karr k66). The storage declares the SQL dialect of its DDL,
# _ddl_sql_dialect 'oracle', and core's splitter (DBIO::Deploy::Base,
# _execute_ddl) cuts the install DDL under it: a CREATE TRIGGER is one
# statement and keeps the semicolon after its END, without the do callback
# this class once put on the handle (karr k42). A trigger sent without the
# semicolon is created invalid (ORA-24344, ORA-04098 on the first insert).
# The handle is a double that records what reaches do(); nothing touches a
# database.

{
  package T::Dialect::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('dialect_item');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 50 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::Dialect::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Item => 'T::Dialect::Item');
}

{
  package T::Dialect::Dbh;
  sub new { bless { do => [] }, shift }
  sub do { push @{ $_[0]{do} }, $_[1]; '0E0' }
}

my $schema  = T::Dialect::Schema->connect('dbi:Oracle:never', 'u', 'p');
my $storage = $schema->storage;

is $storage->_ddl_sql_dialect, 'oracle', 'the storage declares the dialect oracle';

my $deploy = DBIO::Oracle::Deploy->new(schema => $schema);
is(
  $deploy->_driver_storage->_ddl_sql_dialect, 'oracle',
  'the dialect arrives where Deploy reads it, on the storage of the schema',
);

ok(
  !DBIO::Oracle::Deploy->can('_execute_ddl')
    || DBIO::Oracle::Deploy->can('_execute_ddl') == DBIO::Deploy::Base->can('_execute_ddl'),
  'Deploy has no _execute_ddl of its own: core\'s runs the DDL',
);

my $dbh = T::Dialect::Dbh->new;
{
  local $SIG{__WARN__} = sub {};   # core's one-time non-transactional DDL notice
  $deploy->_execute_ddl($dbh, $deploy->_install_ddl);
}

my @stmts = @{ $dbh->{do} };
my ($trigger) = grep { /\ACREATE\s+(?:OR\s+REPLACE\s+)?TRIGGER\b/i } @stmts;

ok defined $trigger, 'the install DDL has a trigger statement';
like $trigger, qr/\bEND;\z/, 'the trigger reaches do() with the semicolon after END';
is(
  scalar(grep { /\bTRIGGER\b/i } @stmts), 1,
  '... and the PL/SQL block is one statement, not cut at its inner semicolons',
);
unlike(
  join('', grep { $_ ne $trigger } @stmts), qr/\bEND;/,
  '... while the other statements stay without a closing semicolon',
);

done_testing;
