use strict;
use warnings;
use Test::More;

use DBIO::Deploy::Base;
use DBIO::Diff::Base;
use DBIO::Deploy::Base::TempDatabase;
use DBIO::Storage::DBI;
use DBIO::AccessBroker;

# --- Fakes: no real database -------------------------------------------------
{
  package Fake::DBH;
  sub new { my ($c, $tag) = @_; bless { tag => $tag, stmts => [], AutoCommit => 1 }, $c }
  sub do { my ($s, $sql) = @_; push @{ $s->{stmts} }, $sql; 1 }
  sub disconnect { $_[0]->{disconnected} = 1 }

  package Fake::Storage;
  sub new { my ($c, $dbh, $ci) = @_; bless { dbh => $dbh, connect_info => $ci }, $c }
  sub dbh { $_[0]->{dbh} }
  sub connect_info { $_[0]->{connect_info} }
  sub access_broker { undef }
  # the storage's normalised form: [ $dsn, $user, $pass, \%attrs ]
  sub _dbi_connect_info {
    my @i = @{ $_[0]->{connect_info} || [] };
    return [ @i ] unless ref $i[0] eq 'HASH';
    my $h = $i[0];
    return [ $h->{dsn}, $h->{user}, $h->{password} // $h->{pass}, {} ];
  }

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
  our @ISA = ('DBIO::Diff::Base');   # apply classifies the diff
  sub operations { [] }
  sub new { my ($c, %a) = @_; bless { %a }, $c }
  sub source { $_[0]->{source} }
  sub target { $_[0]->{target} }
  sub has_changes { $_[0]->{source}{tag} ne $_[0]->{target}{tag} }
  sub as_sql { "ALTER TABLE a ADD c int;\n-- skip me;\nALTER TABLE b ADD d int;" }
}

sub mk_schema {
  my ($tag, $ci) = @_;
  $ci = [ 'dbi:Pg:dbname=live', 'live_user', 'live-pw-k353' ] if @_ < 2;   # an explicit undef stays undef
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

# A comment is not the statement behind it (karr k326). A generator that
# writes "-- users" above a CREATE TABLE has written a statement with a
# comment in front, and the table has to exist afterwards: dropping every
# piece that begins with "--" dropped the table with it, and said nothing.
{
  my $dbh = Fake::DBH->new('x');
  InMemory::Deploy->new(schema => mk_schema('source'))->_execute_ddl($dbh,
    "-- users\nCREATE TABLE t (id int);\n/* audit */\nCREATE TABLE u (id int);\n-- done\n");
  is_deeply $dbh->{stmts},
    ['CREATE TABLE t (id int)', 'CREATE TABLE u (id int)'],
    '_execute_ddl runs a statement that has a comment in front of it, and no '
  . 'comment reaches the handle as a statement';
}

# What reaches the handle is a statement, whole: a semicolon inside a literal
# or a trigger body ends nothing.
{
  my $dbh = Fake::DBH->new('x');
  my @ddl = (
    "CREATE TABLE s (id int, s text DEFAULT 'a;b')",
    'CREATE TRIGGER tr AFTER INSERT ON s BEGIN UPDATE s SET id = 1; DELETE FROM u; END',
  );
  InMemory::Deploy->new(schema => mk_schema('source'))
    ->_execute_ddl($dbh, join '', map { "$_;\n" } @ddl);
  is_deeply $dbh->{stmts}, \@ddl,
    '_execute_ddl hands a literal and a trigger body with semicolons over whole';
}

# --- the storage names the SQL dialect the splitter reads --------------------
#
# A literal that ends on a backslash is complete on PostgreSQL and SQLite and
# unfinished on MySQL. The text cannot say which; the engine can, and the
# storage already carries the engine's facts. _execute_ddl must ask it, or a
# driver has no way to stop the splitter taking both readings.
{
  package Dialect::Storage;
  our @ISA = ('Fake::Storage');
  sub _ddl_sql_dialect { $_[0]->{dialect} }

  package main;

  my $ddl = q{SELECT 'C:\';} . "\n" . q{SELECT 'a;b';};
  my @standard = (q{SELECT 'C:\'}, q{SELECT 'a;b'});

  my $run = sub {
    my ($storage) = @_;
    my $dbh = $storage->dbh;
    InMemory::Deploy->new(schema => Fake::Schema->new($storage))
      ->_execute_ddl($dbh, $ddl);
    return $dbh->{stmts};
  };

  my $pg = Dialect::Storage->new(Fake::DBH->new('pg'));
  $pg->{dialect} = 'postgresql';
  is_deeply $run->($pg), \@standard,
    '_execute_ddl reads the backslash as a character where the storage says postgresql';

  my $undeclared = Dialect::Storage->new(Fake::DBH->new('none'));
  isnt join("\0", @{ $run->($undeclared) }), join("\0", @standard),
    '... and takes both readings where the storage declares nothing (as before)';

  is_deeply $run->(Fake::Storage->new(Fake::DBH->new('plain'))),
    $run->(Dialect::Storage->new(Fake::DBH->new('none2'))),
    '... a storage with no such method at all behaves as one that declares nothing';

  require DBIO::Test::Storage;
  is(DBIO::Test::Storage->_ddl_sql_dialect, undef,
    'the default dialect is undef: not declared');
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

# === a temp database that could not be dropped is said, not swallowed ========
#
# The drop is cleanup, and cleanup that fails leaves a database on the server:
# one more with every diff, and nobody the wiser (karr k316). It is said with a
# warning and not with an exception -- a diff that has its model still returns
# it, and a deploy that failed still dies of what it failed of. The warning
# names the database, because the name is what an operator drops it by.
{
  package Temp::DropFails;
  use base 'Temp::Deploy';
  sub _create_temp_db { 'tmpdb_' . ++$_[0]->{serial} }
  sub _drop_temp_db   { die $_[0]->{drop_error} // "drop boom\n" }

  # the connect info is another one by the time of the drop
  package Temp::DropFails::Changes;
  use base 'Temp::DropFails';
  sub _create_temp_db {
    my $self = shift;
    my $name = $self->SUPER::_create_temp_db(@_);
    $self->schema->storage->{connect_info} = $self->{changed_to};
    return $name;
  }

  package Temp::BothFail;
  use base 'Temp::DropFails';
  sub _deploy_and_introspect_temp { die "deploy boom\n" }

  # an exception that is false: only the eval can say the drop failed
  package Temp::FalseError;
  use overload 'bool' => sub { 0 }, '""' => sub { 'a false drop error' }, fallback => 1;
}

# ($model, $error, @warnings) of one _build_target_model; $error is undef when
# it returned
sub build_target_model {
  my ($deploy) = @_;
  my ($model, $error, @warnings);
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    eval { $model = $deploy->_build_target_model; 1 } or $error = $@;
  }
  return ($model, $error, @warnings);
}

# --- the deploy went through, the drop did not --------------------------------
{
  my $deploy = Temp::DropFails->new(schema => mk_schema('source'));
  my ($model, $error, @warnings) = build_target_model($deploy);

  is scalar(@warnings), 1, 'a drop that fails is warned about, once';
  like $warnings[0], qr/temporary database 'tmpdb_1'/,
    '... naming the database, so that it can be dropped by hand';
  like $warnings[0], qr/still on the server/, '... saying that it was left there';
  like $warnings[0], qr/drop boom/, '... and why the drop failed';
  like $warnings[0], qr/^Temp::DropFails: /, '... in the name of the deploy class';
  like $warnings[0], qr/drop boom\n\z/, '... as one line, ended';

  is $error, undef, 'the failed drop does not fail the build: the model is there';
  is_deeply $model, { tag => 'target' }, '... and is returned';

  # No one-time brake, unlike the notices of _execute_ddl: every database left
  # behind is another database.
  (undef, undef, @warnings) = build_target_model($deploy);
  is scalar(@warnings), 1, 'the next database that stays is warned about again';
  like $warnings[0], qr/temporary database 'tmpdb_2'/, '... by its own name';
}

# --- the deploy failed and the drop failed ------------------------------------
{
  my $deploy = Temp::BothFail->new(schema => mk_schema('source'));
  my ($model, $error, @warnings) = build_target_model($deploy);

  is $error, "deploy boom\n",
    'deploy and drop both fail: the build dies of the deploy, its error untouched';
  is scalar(@warnings), 1, '... and the database that stayed is warned about';
  like $warnings[0], qr/temporary database 'tmpdb_1'.*still on the server.*drop boom/,
    '... by name, with the error of the drop';
  unlike $warnings[0], qr/deploy boom/, '... which is not the error of the deploy';
}

# --- a drop that fails with an exception that is false ------------------------
{
  my $deploy = Temp::DropFails->new(
    schema     => mk_schema('source'),
    drop_error => bless({}, 'Temp::FalseError'),
  );
  my ($model, $error, @warnings) = build_target_model($deploy);

  is scalar(@warnings), 1, 'a drop that dies of a false exception is warned about all the same';
  like $warnings[0], qr/temporary database 'tmpdb_1'.*: a false drop error\n\z/,
    '... with what the exception says';
  is_deeply $model, { tag => 'target' }, '... and the model is returned';
}

# --- the warning never quotes the password (karr k297) ------------------------
#
# A DBD may repeat any of the connect info in its error. Firebird's drop has to
# connect to the temp database first, and DBI quotes the data source it was
# refused -- which is why the text is masked with the connect info of the temp
# database: the password is masked wherever the error repeats it, and one
# inside the data source to the end of its value, which only the data source
# says where it is.
for my $form (
  [ 'the DBI form' => [ 'dbi:K316:dbname=live;password=in dsn;host=h', 'u', 's3cret-k316' ] ],
  [ 'a hash'       => [ { dsn => 'dbi:K316:dbname=live;password=in dsn;host=h',
                          user => 'u', password => 's3cret-k316' } ] ],
) {
  my ($name, $info) = @$form;
  my $deploy = Temp::DropFails->new(
    schema     => mk_schema('source', $info),
    drop_error => "DBI connect('dbname=tmpdb_1;password=in dsn;host=h','u',...) failed: "
                . "no login for u with s3cret-k316 at Fake.pm line 1.\n",
  );
  my ($model, $error, @warnings) = build_target_model($deploy);

  is scalar(@warnings), 1, "password, $name: the failed drop is warned about";
  like $warnings[0],
    qr/DBI connect\('dbname=tmpdb_1;password=\*\*\*;host=h','u',\.\.\.\) failed: no login for u with \*\*\* at/,
    "password, $name: ... with the error of the drop, the passwords masked";
  unlike $warnings[0], qr/s3cret-k316|in dsn|dsn;/,
    "password, $name: ... and none of either password left";
}

# --- no connect info to mask with is no reason to say nothing ------------------
#
# The connect info is probed before the temp database is created, so what
# _temp_connect_info cannot read at the drop is a change after the probe. The
# warning is not to fail of what it is masked with: the database stays on the
# server either way.
for my $form (
  [ 'a coderef'       => [ sub { }, 'u', 'p' ] ],
  [ 'no connect info' => undef ],
) {
  my ($name, $info) = @$form;
  my $deploy = Temp::DropFails::Changes->new(
    schema     => mk_schema('source'),
    changed_to => $info,
    drop_error => "refused: password=s3cret-k316 host=h\n",
  );
  my ($model, $error, @warnings) = build_target_model($deploy);

  is $error, undef, "$name: the build does not die of masking the warning";
  is_deeply $model, { tag => 'target' }, "$name: ... the model is returned";
  is scalar(@warnings), 1, "$name: ... and the failed drop is warned about";
  like $warnings[0], qr/temporary database 'tmpdb_1'.*refused: password=\*\*\* host=h/,
    "$name: ... a password under its key still masked";
}

# --- a drop that works says nothing --------------------------------------------
for my $class (qw( Temp::Deploy Temp::Failing )) {
  my $deploy = $class->new(schema => mk_schema('source'));
  my (undef, undef, @warnings) = build_target_model($deploy);
  is_deeply $deploy->{dropped}, ['tmpdb'], "$class: the temp db is dropped";
  is_deeply \@warnings, [], "$class: ... and nothing is warned about";
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

# --- _temp_connect_info: a storage with a broker (karr k348) ------------------
# connect_info of such a storage is [ $broker ]; the connection details are the
# broker's current answer, which the storage reads as _dbi_connect_info.
{
  package T::AnswerBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($c, $f) = @_; bless { f => $f, calls => 0 }, $c }
  sub connect_info_for { my $s = shift; $s->{f}->(++$s->{calls}) }

  package main;

  my $d = sub {
    my $broker  = shift;
    my $storage = DBIO::Storage::DBI->new(undef);
    $storage->connect_info([ $broker ]);
    Temp::Deploy->new(schema => Fake::Schema->new($storage));
  };

  # the answer of the moment: whichever call of the broker the read made last
  my $b = T::AnswerBroker->new(sub {
    [ "dbi:Pg:dbname=app$_[0];host=h", "bu$_[0]", "bp$_[0]", {} ];
  });
  my $dep = $d->($b);
  my @r = $dep->_temp_connect_info('tmpdb');
  my $n = $b->{calls};
  is_deeply \@r, [ 'dbi:Pg:dbname=tmpdb;host=h', "bu$n", "bp$n" ],
    'broker array answer: dsn rewritten, user and pass passed through';
  @r = $dep->_temp_connect_info('tmpdb');
  isnt $b->{calls}, $n, '... the broker is asked again on every call';
  $n = $b->{calls};
  is_deeply \@r, [ 'dbi:Pg:dbname=tmpdb;host=h', "bu$n", "bp$n" ],
    '... and the current answer is used';

  $b = T::AnswerBroker->new(sub {
    { dsn => 'dbi:Pg:dbname=app;host=h', user => "hu$_[0]", password => "hp$_[0]" };
  });
  @r = $d->($b)->_temp_connect_info('tmpdb');
  $n = $b->{calls};
  is_deeply \@r, [ 'dbi:Pg:dbname=tmpdb;host=h', "hu$n", "hp$n" ],
    'broker hash answer: dsn, user and password';

  $b = T::AnswerBroker->new(sub { { dbh_maker => sub { } } });
  eval { $d->($b)->_temp_connect_info('tmpdb') };
  like $@, qr/coderef DSN/, 'broker answer with dbh_maker dies';
  unlike $@, qr/dbh_maker|secret/, '... without a value of the answer';
}

# --- _temp_connect_info: connection parameters without a dsn (karr k353) ------
# A storage of a driver that builds its DSN from connection parameters holds
# them as given; _dbi_connect_info is the normalised form with the DSN built.
{
  package T::ParamStorage;
  use base 'DBIO::Storage::DBI';
  __PACKAGE__->register_driver('K353' => __PACKAGE__);

  package main;

  my $storage = T::ParamStorage->new(undef);
  $storage->connect_info([{
    dbname => 'app', host => 'h', user => 'pu', password => 'pp',
  }]);
  my $dep = Temp::Deploy->new(schema => Fake::Schema->new($storage));

  my @warnings;
  my @r;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    @r = $dep->_temp_connect_info('tmpdb');
  }
  is_deeply \@r, [ 'dbi:K353:dbname=tmpdb;host=h', 'pu', 'pp' ],
    'connection parameters without a dsn: the temp DSN is built on the driver\'s own DSN';
  is_deeply \@warnings, [], '... without a warning';
}

# --- the connect info is probed before the temp database exists (karr k353) ---
for my $form (
  [ 'a coderef DSN'      => [ sub { }, 'u', 'p' ],              qr/coderef DSN/ ],
  [ 'no connect info'    => undef,                               qr/DSN/ ],
  [ 'an empty DSN'       => [ '', 'u', 'p' ],                    qr/DSN/ ],
  [ 'a hash without dsn' => [ { user => 'u' } ],                 qr/DSN/ ],
  [ 'a non-scalar DSN'   => [ [ 'dbi:Pg:dbname=x' ], 'u', 'p' ], qr/DSN/ ],
) {
  my ($name, $info, $re) = @$form;
  my $deploy = Temp::Deploy->new(schema => mk_schema('source', $info));
  my ($model, $error, @warnings) = build_target_model($deploy);

  like $error, $re, "$name: the build is refused, saying so";
  is $deploy->{created}, undef, "$name: ... before a temp database is created";
  is $deploy->{dropped}, undef, "$name: ... so nothing is dropped";
  is_deeply \@warnings, [], "$name: ... and nothing is warned about";

  eval { $deploy->_temp_connect_info('tmpdb') };
  like $@, $re, "$name: _temp_connect_info refuses the same";
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

# === the txn_do bracket only goes round the storage's OWN handle =============
#
# _execute_ddl takes $dbh as an argument but can only bracket through
# $storage->txn_do, and the two are not always the same connection: the
# TempDatabase path deploys into a handle it opened itself. Bracketing there
# would open a transaction on the LIVE connection around DDL running on another
# one -- no atomicity gained, and a failure would roll back whatever the caller
# had open live.
{
  package Txn::Storage;
  sub new {
    my ($c, $dbh, $ci) = @_;
    bless { dbh => $dbh, connect_info => $ci, txn_do => 0 }, $c;
  }
  sub dbh          { $_[0]->{dbh} }
  sub access_broker { undef }
  sub _dbh         { $_[0]->{dbh} }
  sub connect_info { $_[0]->{connect_info} }
  sub _dbi_connect_info { [ @{ $_[0]->{connect_info} || [] } ] }
  sub _use_transactional_ddl { 1 }
  sub txn_do { my ($s, $code) = @_; $s->{txn_do}++; return $code->() }
}

sub mk_txn_schema {
  my ($tag, $ci) = @_;
  return Fake::Schema->new(Txn::Storage->new(Fake::DBH->new($tag), $ci));
}

# --- the storage's own handle: bracketed -------------------------------------
{
  my $schema  = mk_txn_schema('source');
  my $storage = $schema->storage;
  my $deploy  = InMemory::Deploy->new(schema => $schema);

  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $deploy->_execute_ddl($storage->dbh, "ONE;\nTWO;");
  }

  is $storage->{txn_do}, 1,
    'a transactional storage brackets DDL on its own handle';
  is_deeply $storage->{dbh}{stmts}, ['ONE', 'TWO'], '... running every statement';
  is scalar(grep { /non-transactional DDL/ } @warnings), 0,
    '... with no non-transactional notice';
}

# --- a foreign handle: NOT bracketed, and not warned about either ------------
{
  my $schema  = mk_txn_schema('source');
  my $storage = $schema->storage;
  my $deploy  = InMemory::Deploy->new(schema => $schema);
  my $foreign = Fake::DBH->new('temp');

  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $deploy->_execute_ddl($foreign, "ONE;\nTWO;");
  }

  is $storage->{txn_do}, 0,
    'a handle the storage does not own is never bracketed';
  is_deeply $foreign->{stmts}, ['ONE', 'TWO'],
    '... the statements still all run, on the handle they were given';
  is_deeply $storage->{dbh}{stmts}, [],
    '... and nothing was sent to the live handle';

  # The F02 notice is about a LIVE schema left half migrated. Here it would be
  # noise -- and its text, pointing at the version-row gate, would be wrong.
  is scalar(grep { /non-transactional DDL/ } @warnings), 0,
    '... and no notice is emitted: this is not the case F02 warns about';
}

# --- the regression, through the real TempDatabase path ----------------------
#
# Only DBI->connect is faked; _deploy_and_introspect_temp itself is the shipped
# one, so this fails if the ownership check is dropped again.
{
  package Temp::RealDeploy;
  use base 'DBIO::Deploy::Base::TempDatabase';
  sub _ddl_class        { 'Fake::DDL' }
  sub _introspect_class { 'Fake::Introspect' }
  sub _diff_class       { 'Fake::Diff' }
  sub _create_temp_db { 'tmpdb' }
  sub _drop_temp_db   { 1 }
}

{
  require DBI;
  my $temp_dbh = Fake::DBH->new('temp');
  my $schema   = mk_txn_schema('source', [ 'dbi:Pg:dbname=live', 'u', 'p' ]);
  my $storage  = $schema->storage;

  my $model;
  {
    no warnings 'redefine';
    local *DBI::connect = sub { $temp_dbh };
    $model = Temp::RealDeploy->new(schema => $schema)->_build_target_model;
  }

  is_deeply $model, { tag => 'temp' }, 'temp build introspects the temp handle';
  is_deeply $temp_dbh->{stmts},
    ['CREATE TABLE a (id int)', 'CREATE TABLE b (id int)'],
    '... having deployed the install DDL into the temp database';
  is $storage->{txn_do}, 0,
    'the temp deploy opens NO transaction on the live connection';
  is_deeply $storage->{dbh}{stmts}, [],
    '... and touches the live handle not at all';
}

# --- a disconnect that fails does not replace the error of the deploy ----------
#
# The temp handle is closed after the deploy whatever became of it, and it
# raises errors. One that cannot be closed any more -- the server went away
# under the deploy -- is the likeliest to have failed the deploy as well, and
# then the caller has to hear what the deploy died of (karr k316).
{
  package Fake::DBH::NoDisconnect;
  use base 'Fake::DBH';
  sub do { die "DDL boom\n" if $_[0]->{tag} eq 'ddl dies'; $_[0]->SUPER::do($_[1]) }
  sub disconnect { die "disconnect boom\n" }

  package Fake::Introspect::Dies;
  sub new   { bless {}, $_[0] }
  sub model { die "introspect boom\n" }

  package Temp::RealDeploy::IntrospectDies;
  use base 'Temp::RealDeploy';
  sub _introspect_class { 'Fake::Introspect::Dies' }
}

for my $case (
  [ 'the DDL'           => 'Temp::RealDeploy',                 'ddl dies', "DDL boom\n" ],
  [ 'the introspection' => 'Temp::RealDeploy::IntrospectDies', 'temp',     "introspect boom\n" ],
  # Nothing else failed: the error of the disconnect is the only one there is,
  # and it is raised, as it always was.
  [ 'nothing else'      => 'Temp::RealDeploy',                 'temp',     "disconnect boom\n" ],
) {
  my ($what, $class, $tag, $expected) = @$case;
  my $temp_dbh = Fake::DBH::NoDisconnect->new($tag);
  my $deploy   = $class->new(schema => mk_txn_schema('source', [ 'dbi:Pg:dbname=live', 'u', 'p' ]));

  my $error;
  {
    no warnings 'redefine';
    local *DBI::connect = sub { $temp_dbh };
    eval { $deploy->_deploy_and_introspect_temp('tmpdb'); 1 } or $error = $@;
  }

  is $error, $expected,
    "$what fails and the disconnect fails: the temp deploy dies of " . $expected =~ s/\n//r;
}

# === per-statement exceptions: the batch splits round DDL that cannot be in
# === a transaction
#
# The capability is one boolean for the connection, but PostgreSQL's
# ALTER TYPE ... ADD VALUE cannot be inside a transaction at all. Consecutive
# statements are grouped by the storage's _ddl_statement_is_transactional hook,
# in the original order.
{
  package Txn::PickyStorage;
  our @ISA = ('Txn::Storage');
  # Stands in for the PostgreSQL case without depending on that driver.
  sub _ddl_statement_is_transactional { $_[1] !~ /ADD VALUE/ ? 1 : 0 }
}

sub mk_picky {
  my $schema = Fake::Schema->new(Txn::PickyStorage->new(Fake::DBH->new('live')));
  return ($schema, $schema->storage, InMemory::Deploy->new(schema => $schema));
}

# --- a hook that never says no changes nothing -------------------------------
#
# The single most important property: a driver that does not define the hook,
# or defines one that always says yes, must get exactly the old behaviour --
# one txn_do around everything, no notice.
{
  my $schema  = mk_txn_schema('source');
  my $storage = $schema->storage;
  my $deploy  = InMemory::Deploy->new(schema => $schema);

  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $deploy->_execute_ddl($storage->dbh, "ONE;\nTWO;\nTHREE;");
  }

  is $storage->{txn_do}, 1, 'no hook at all: still exactly one txn_do';
  is_deeply $storage->{dbh}{stmts}, ['ONE', 'TWO', 'THREE'],
    '... every statement inside it';
  is scalar(grep { /split DDL batch/ } @warnings), 0,
    '... and nothing is announced, because nothing was split';
}

# --- the exception runs alone, the rest keeps its transaction ----------------
{
  my ($schema, $storage, $deploy) = mk_picky();

  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $deploy->_execute_ddl($storage->dbh,
      "CREATE TABLE a (id int);\n"
    . "ALTER TYPE mood ADD VALUE 'ok';\n"
    . "ALTER TABLE a ADD c mood;");
  }

  is $storage->{txn_do}, 2,
    'the batch splits into two bracketed runs round the statement that cannot be in one';
  is_deeply $storage->{dbh}{stmts},
    [ 'CREATE TABLE a (id int)',
      "ALTER TYPE mood ADD VALUE 'ok'",
      'ALTER TABLE a ADD c mood' ],
    '... with every statement run, in the order it was written';

  is scalar(grep { /split DDL batch/ } @warnings), 1,
    'the split is announced once -- the upgrade is no longer atomic as a whole';
  like $warnings[0], qr/1 statement\(s\) cannot run inside a transaction/,
    '... saying how many statements forced it';
  like $warnings[0], qr/InMemory::Deploy/,
    '... and naming the deploy class, as the non-transactional notice does';
}

# --- consecutive exceptions collapse into one bare run -----------------------
{
  my ($schema, $storage, $deploy) = mk_picky();
  $deploy->_execute_ddl($storage->dbh,
    "ALTER TYPE mood ADD VALUE 'a';\nALTER TYPE mood ADD VALUE 'b';");

  is $storage->{txn_do}, 0,
    'a batch of nothing but exceptions opens no transaction at all';
  is scalar @{ $storage->{dbh}{stmts} }, 2, '... and still runs both statements';
}

# --- the announcement is one-shot per deploy class ---------------------------
{
  my ($schema, $storage, $deploy) = mk_picky();
  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $deploy->_execute_ddl($storage->dbh, "CREATE TABLE a (id int);\nALTER TYPE m ADD VALUE 'x';");
    $deploy->_execute_ddl($storage->dbh, "CREATE TABLE b (id int);\nALTER TYPE m ADD VALUE 'y';");
  }
  is scalar(grep { /split DDL batch/ } @warnings), 0,
    'the notice does not repeat -- it was already emitted for this class above';
}

# --- the hook is not consulted where nothing is bracketed anyway --------------
#
# A non-transactional storage runs statement-at-a-time regardless, so asking
# would be pointless; more to the point, a driver must not be able to turn the
# grouping on by defining the hook alone.
{
  package Txn::PickyButNotTransactional;
  our @ISA = ('Txn::PickyStorage');
  sub _use_transactional_ddl { 0 }
}

{
  my $schema = Fake::Schema->new(
    Txn::PickyButNotTransactional->new(Fake::DBH->new('live')));
  my $storage = $schema->storage;
  my $deploy  = InMemory::Deploy->new(schema => $schema);

  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $deploy->_execute_ddl($storage->dbh, "CREATE TABLE a (id int);\nALTER TYPE m ADD VALUE 'x';");
  }

  is $storage->{txn_do}, 0, 'a non-transactional storage brackets nothing';
  is scalar @{ $storage->{dbh}{stmts} }, 2, '... and runs both statements';
  is scalar(grep { /split DDL batch/ } @warnings), 0,
    '... without announcing a split that never happened';
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
