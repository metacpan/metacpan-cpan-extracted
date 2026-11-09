use strict;
use warnings;
use Test::More;

# Offline test for karr k145: VALIDATE CONSTRAINT of a foreign key added NOT
# VALID runs in a transaction of its own, after the COMMIT of the ADD
# CONSTRAINT, so the lock of the add is not held over the reading of the rows.
#
# Claim: DBIO::PostgreSQL::Storage reports the statement
# Diff::ForeignKey emits for action 'validate' as not transactional, and core's
# _execute_ddl then cuts the batch there. Asserted on the op's own SQL (the
# anchor cannot drift from the emitter), on narrowness (ADD CONSTRAINT, DROP
# CONSTRAINT and the words inside a literal stay in their bracket), and end to
# end through core's _execute_ddl.

use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::Diff::ForeignKey;
use DBIO::Deploy::Base ();

my $pg = DBIO::PostgreSQL::Storage->new;

my %info = (
  local_columns => ['parent_id'], remote_schema => 'public',
  remote_table => 'parent', remote_columns => ['id'],
);
my @ops = DBIO::PostgreSQL::Diff::ForeignKey->with_validation(
  DBIO::PostgreSQL::Diff::ForeignKey->new(
    action => 'create', table_key => 'public.child', schema_name => 'public',
    table_name => 'child', constraint_name => 'child_parent_id_fkey',
    fk_info => \%info, existing_table => 1));
is scalar(@ops), 2, 'with_validation: the create and its VALIDATE';

my ($add, $validate) = map { $_->as_sql } @ops;
like $add, qr/NOT VALID;$/, 'the first statement adds the key NOT VALID';
like $validate, qr/VALIDATE CONSTRAINT/, 'the second validates it';

ok $pg->_ddl_statement_is_transactional($add),
  'ADD CONSTRAINT ... NOT VALID keeps its transaction bracket';
ok !$pg->_ddl_statement_is_transactional($validate),
  'the op\'s own VALIDATE CONSTRAINT is reported as not transactional';
ok !$pg->_ddl_statement_is_transactional(
  q{ALTER TABLE "Odd Schema"."Child; x" VALIDATE CONSTRAINT "fk;1";}),
  '... also with quoted names';

for my $safe (
  q{ALTER TABLE public.child DROP CONSTRAINT child_parent_id_fkey;},
  q{ALTER TABLE public.child ADD COLUMN validate_constraint text;},
  q{INSERT INTO log (msg) VALUES ('ALTER TABLE t VALIDATE CONSTRAINT c')},
) {
  ok $pg->_ddl_statement_is_transactional($safe), "keeps its bracket: $safe";
}

# End to end through core's grouping.
{
  package T165::Storage;
  our @ISA = ('DBIO::PostgreSQL::Storage');
  our @LOG;
  sub txn_do { my ($s, $code) = @_; push @LOG, 'BEGIN'; my @r = $code->(); push @LOG, 'COMMIT'; @r }
  sub _dbh { $_[0]->{fake_dbh} }
  package T165::Dbh;
  sub new { bless {}, shift }
  sub do { push @T165::Storage::LOG, $_[1]; 1 }
  package T165::Schema;
  sub new { bless { storage => $_[1] }, $_[0] }
  sub storage { $_[0]{storage} }
}

my $storage = T165::Storage->new;
my $dbh = T165::Dbh->new;
$storage->{fake_dbh} = $dbh;
my $deploy = DBIO::Deploy::Base->new(schema => T165::Schema->new($storage));
{
  local $SIG{__WARN__} = sub {};
  $deploy->_execute_ddl($dbh, join "\n", $add, $validate);
}
my ($add_run, $validate_run) = map { s/;\z//r } $add, $validate;   # the splitter drops the semicolon
is_deeply \@T165::Storage::LOG, ['BEGIN', $add_run, 'COMMIT', $validate_run],
  'the ADD commits first; the VALIDATE runs after it, outside the bracket';

done_testing;
