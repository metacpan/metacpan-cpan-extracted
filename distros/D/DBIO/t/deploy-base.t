use strict;
use warnings;
use Test::More;

use DBIO::Deploy::Base;
use DBIO::Deploy::Base::TempDatabase;

# --- Fakes: no real database -------------------------------------------------
{
  package Fake::DBH;
  sub new { my ($c, $tag) = @_; bless { tag => $tag, stmts => [] }, $c }
  sub do { my ($s, $sql) = @_; push @{ $s->{stmts} }, $sql; 1 }
  sub disconnect { $_[0]->{disconnected} = 1 }

  package Fake::Storage;
  sub new { my ($c, $dbh, $ci) = @_; bless { dbh => $dbh, connect_info => $ci }, $c }
  sub dbh { $_[0]->{dbh} }
  sub connect_info { $_[0]->{connect_info} }

  package Fake::Schema;
  sub new { my ($c, $storage) = @_; bless { storage => $storage }, $c }
  sub storage { $_[0]->{storage} }

  package Fake::DDL;
  sub install_ddl {
    return "CREATE TABLE a (id int);\nCREATE TABLE b (id int);\n-- a trailing comment;";
  }

  package Fake::Introspect;
  sub new { my ($c, %a) = @_; bless { dbh => $a{dbh} }, $c }
  sub model { return { tag => $_[0]->{dbh}{tag} } }

  package Fake::Diff;
  sub new { my ($c, %a) = @_; bless { %a }, $c }
  sub source { $_[0]->{source} }
  sub target { $_[0]->{target} }
  sub has_changes { $_[0]->{source}{tag} ne $_[0]->{target}{tag} }
  sub as_sql { "ALTER TABLE a ADD c int;\n-- skip me;\nALTER TABLE b ADD d int;" }
}

sub mk_schema {
  my ($tag, $ci) = @_;
  return Fake::Schema->new(Fake::Storage->new(Fake::DBH->new($tag), $ci));
}

# In-memory style driver: overrides _build_target_model, no temp database.
{
  package InMemory::Deploy;
  use base 'DBIO::Deploy::Base';
  sub _ddl_class        { 'Fake::DDL' }
  sub _introspect_class { 'Fake::Introspect' }
  sub _diff_class       { 'Fake::Diff' }
  sub _build_target_model { { tag => 'target' } }   # differs from source

  package InMemory::NoChange;
  use base 'InMemory::Deploy';
  sub _build_target_model { { tag => 'source' } }   # equals source -> no changes
}

# --- install: runs install DDL on the live dbh, skipping comment statements --
{
  my $schema = mk_schema('source');
  InMemory::Deploy->new(schema => $schema)->install;
  my @stmts = @{ $schema->storage->dbh->{stmts} };
  is scalar(@stmts), 2, 'install ran 2 statements (comment skipped)';
  like $stmts[0], qr/CREATE TABLE a/, 'first create';
  like $stmts[1], qr/CREATE TABLE b/, 'second create';
  ok !(grep { /^\s*--/ } @stmts), 'no comment-only statement executed';
}

# --- diff: source from live introspect, target from _build_target_model ------
{
  my $deploy = InMemory::Deploy->new(schema => mk_schema('source'));
  my $diff = $deploy->diff;
  isa_ok $diff, 'Fake::Diff', 'diff returns the driver diff class';
  is $diff->source->{tag}, 'source', 'source model from live introspect';
  is $diff->target->{tag}, 'target', 'target model from _build_target_model';
  ok $diff->has_changes, 'diff reports changes (source != target)';
}

# --- apply: runs as_sql, skips comments; no-op when no changes ---------------
{
  my $schema = mk_schema('source');
  my $deploy = InMemory::Deploy->new(schema => $schema);
  my $applied = $deploy->apply($deploy->diff);
  ok $applied, 'apply returns true when there are changes';
  my @stmts = @{ $schema->storage->dbh->{stmts} };
  is scalar(@stmts), 2, 'apply ran 2 statements (comment skipped)';
  like $stmts[0], qr/ALTER TABLE a/, 'apply first stmt';

  my $no = Fake::Diff->new(source => { tag => 'x' }, target => { tag => 'x' });
  my $sch2 = mk_schema('source');
  my $rv = InMemory::Deploy->new(schema => $sch2)->apply($no);
  ok !$rv, 'apply is a no-op (falsey) when diff has no changes';
  is scalar(@{ $sch2->storage->dbh->{stmts} }), 0, 'no statements run on no-op apply';
}

# --- upgrade: diff + apply; returns diff on change, undef when up to date -----
{
  my $schema = mk_schema('source');
  my $deploy = InMemory::Deploy->new(schema => $schema);
  my $diff = $deploy->upgrade;
  isa_ok $diff, 'Fake::Diff', 'upgrade returns the diff when changes applied';
  ok scalar(@{ $schema->storage->dbh->{stmts} }) > 0, 'upgrade applied statements';

  my $up = InMemory::NoChange->new(schema => mk_schema('source'))->upgrade;
  is $up, undef, 'upgrade returns undef when already up to date';
}

# --- _execute_ddl directly ---------------------------------------------------
{
  my $dbh = Fake::DBH->new('x');
  InMemory::Deploy->new(schema => mk_schema('source'))
    ->_execute_ddl($dbh, "ONE;\n-- comment;\nTWO;");
  is_deeply $dbh->{stmts}, ['ONE', 'TWO'],
    '_execute_ddl splits statements and skips comments';
}

# === TempDatabase base =======================================================

# Temp driver: stubs the engine seam + bypasses real DBI in the temp deploy.
{
  package Temp::Deploy;
  use base 'DBIO::Deploy::Base::TempDatabase';
  sub _ddl_class        { 'Fake::DDL' }
  sub _introspect_class { 'Fake::Introspect' }
  sub _diff_class       { 'Fake::Diff' }
  sub _create_temp_db { push @{ $_[0]->{created} }, 'tmpdb'; 'tmpdb' }
  sub _drop_temp_db   { push @{ $_[0]->{dropped} }, $_[2] }
  sub _deploy_and_introspect_temp {
    my ($self, $name) = @_;
    $self->{deployed} = $name;
    return { tag => 'target' };
  }

  package Temp::Failing;
  use base 'Temp::Deploy';
  sub _deploy_and_introspect_temp { die "deploy boom\n" }
}

# --- _build_target_model: create -> deploy -> drop ---------------------------
{
  my $deploy = Temp::Deploy->new(schema => mk_schema('source'));
  my $model = $deploy->_build_target_model;
  is_deeply $model, { tag => 'target' }, 'temp build returns introspected target';
  is_deeply $deploy->{created}, ['tmpdb'], 'temp db created';
  is_deeply $deploy->{dropped}, ['tmpdb'], 'temp db dropped';
  is $deploy->{deployed}, 'tmpdb', 'deployed into the temp db';
}

# --- drop happens even when deploy/introspect dies; error re-raised ----------
{
  my $deploy = Temp::Failing->new(schema => mk_schema('source'));
  eval { $deploy->_build_target_model };
  like $@, qr/deploy boom/, 'error from temp deploy is re-raised';
  is_deeply $deploy->{dropped}, ['tmpdb'], 'temp db still dropped on failure (no leak)';
}

# --- full diff() through the temp-db path ------------------------------------
{
  my $diff = Temp::Deploy->new(schema => mk_schema('source'))->diff;
  isa_ok $diff, 'Fake::Diff', 'temp-db diff returns the driver diff class';
  is $diff->source->{tag}, 'source', 'temp-db diff source from live';
  is $diff->target->{tag}, 'target', 'temp-db diff target from temp build';
}

# --- _temp_connect_info: DSN rewriting ---------------------------------------
{
  my $d = sub {
    my $ci = shift;
    Temp::Deploy->new(schema => mk_schema('source', $ci));
  };

  my @r = $d->(['dbi:Pg:dbname=app;host=h', 'u', 'p'])->_temp_connect_info('tmpdb');
  is $r[0], 'dbi:Pg:dbname=tmpdb;host=h', 'rewrites dbname= in array DSN';
  is $r[1], 'u', 'user passed through';
  is $r[2], 'p', 'pass passed through';

  @r = $d->(['dbi:mysql:database=app;host=h', 'u', 'p'])->_temp_connect_info('tmpdb');
  is $r[0], 'dbi:mysql:database=tmpdb;host=h', 'rewrites database= in array DSN';

  @r = $d->(['dbi:Pg:host=h', 'u', 'p'])->_temp_connect_info('tmpdb');
  is $r[0], 'dbi:Pg:host=h;dbname=tmpdb', 'appends dbname= when absent';

  @r = $d->([{ dsn => 'dbi:Pg:dbname=app', user => 'hu', password => 'hp' }])
        ->_temp_connect_info('tmpdb');
  is $r[0], 'dbi:Pg:dbname=tmpdb', 'rewrites dbname= in hashref connect-info';
  is $r[1], 'hu', 'user from hashref';
  is $r[2], 'hp', 'password from hashref';

  eval { $d->([ sub { }, 'u', 'p' ])->_temp_connect_info('tmpdb') };
  like $@, qr/coderef DSN/, 'coderef DSN dies';
}

# --- _temp_dsn hook: default form is bit-identical to the inline rewrite ------
{
  my $deploy = Temp::Deploy->new(schema => mk_schema('source'));
  is $deploy->_temp_dsn('dbi:Pg:dbname=app;host=h', 'tmpdb'),
    'dbi:Pg:dbname=tmpdb;host=h', 'default _temp_dsn rewrites dbname=';
  is $deploy->_temp_dsn('dbi:mysql:database=app;host=h', 'tmpdb'),
    'dbi:mysql:database=tmpdb;host=h', 'default _temp_dsn rewrites database=';
  is $deploy->_temp_dsn('dbi:Pg:host=h', 'tmpdb'),
    'dbi:Pg:host=h;dbname=tmpdb', 'default _temp_dsn appends dbname= when absent';
}

# --- a driver overriding ONLY _temp_dsn gets its DSN form, inherits the rest --
# Simulates dbio-firebird's localhost:$db form without re-implementing the
# connect-info shape handling or user/password extraction.
{
  package Temp::FirebirdShape;
  use base 'Temp::Deploy';
  sub _temp_dsn {
    my ($self, $dsn, $temp_db) = @_;
    return "dbi:Firebird:localhost:$temp_db";
  }
}

{
  my $deploy = Temp::FirebirdShape->new(
    schema => mk_schema('source', [{
      dsn      => 'dbi:Firebird:localhost:live.fdb',
      user     => 'sysdba',
      password => 'masterkey',
    }]),
  );
  my @r = $deploy->_temp_connect_info('tmpdb');
  is $r[0], 'dbi:Firebird:localhost:tmpdb',
    'overridden _temp_dsn supplies the Firebird DSN form';
  is $r[1], 'sysdba',
    'user still extracted by inherited _temp_connect_info (hashref shape)';
  is $r[2], 'masterkey',
    'password still extracted by inherited _temp_connect_info (hashref shape)';

  # INTENT: the override must actually drive the final DSN. If _temp_connect_info
  # stopped routing through _temp_dsn, it would fall back to the generic
  # dbname= rewrite and this would read 'dbi:Firebird:localhost:live.fdb'
  # (no dbname= key, so ';dbname=tmpdb' appended) -- never the override's form.
  unlike $r[0], qr/live\.fdb/,
    'temp DSN does not retain the live database (hook took effect)';

  # The inherited coderef guard still applies even with the override in place.
  my $cd = Temp::FirebirdShape->new(schema => mk_schema('source', [ sub { }, 'u', 'p' ]));
  eval { $cd->_temp_connect_info('tmpdb') };
  like $@, qr/coderef DSN/, 'inherited coderef DSN guard still fires under override';
}

# --- abstract hooks die ------------------------------------------------------
{
  my $bare = DBIO::Deploy::Base->new(schema => 'x');
  eval { $bare->_ddl_class };          like $@, qr/_ddl_class not implemented/, 'bare _ddl_class dies';
  eval { $bare->_introspect_class };   like $@, qr/_introspect_class not implemented/, 'bare _introspect_class dies';
  eval { $bare->_diff_class };         like $@, qr/_diff_class not implemented/, 'bare _diff_class dies';
  eval { $bare->_build_target_model }; like $@, qr/_build_target_model not implemented/, 'bare _build_target_model dies';

  my $bare_temp = DBIO::Deploy::Base::TempDatabase->new(schema => 'x');
  eval { $bare_temp->_create_temp_db('dbh') }; like $@, qr/_create_temp_db not implemented/, 'bare _create_temp_db dies';
  eval { $bare_temp->_drop_temp_db('dbh', 'n') }; like $@, qr/_drop_temp_db not implemented/, 'bare _drop_temp_db dies';
}

done_testing;
