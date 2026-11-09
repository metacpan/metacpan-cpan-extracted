use strict;
use warnings;

use Test::More;

use DBI;
use DBIO::Schema;
use DBIO::Deploy::Base;
use DBIO::Oracle::Deploy;

# OFFLINE (karr k36). How DBIO::Oracle::Deploy builds the desired state of a
# diff: in a temporary Oracle user, not by a savepoint on the live connection.
#
# Oracle commits implicitly around every DDL statement, so a test deploy on
# the live connection cannot be rolled back (t/54-deploy-live.t measures it,
# ORA-01086). The class now does what core's TempDatabase does for databases,
# with a user as the throwaway: CREATE USER DBIO_TMP_<pid>_<n>, install DDL
# there, introspect there, DROP USER ... CASCADE -- on every path. What this
# file claims:
#
#   1. the order: privilege check, CREATE USER, grants, connect as the temp
#      user, install DDL, introspection on the temp handle, disconnect, DROP
#      USER;
#   2. the drop runs when the deploy dies, and the error is the deploy's; a
#      drop that fails is warned about with the user's name, the passwords
#      masked, and the model is still returned;
#   3. a connected user without CREATE USER or DROP USER gets a DBIO exception
#      naming it, before anything is created;
#   4. the name is DBIO_TMP_<pid>_<n> and n counts up;
#   5. the live handle of the schema gets no statement at all, and CREATE
#      USER / GRANT / DROP USER go over a connection of their own with
#      AutoCommit -- their implicit commits are not the caller's transaction;
#   6. a user half made (a grant fails) is dropped again;
#   7. diff and upgrade are core's own again: not refused.
#
# The handles are doubles, DBI->connect is replaced; nothing reaches a
# database. What Oracle does with it is t/54-deploy-live.t.

{
  package T::Temp::Author;
  use base 'DBIO::Core';
  __PACKAGE__->table('temp_author');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    name => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::Temp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Author => 'T::Temp::Author');
}

# Tables in other schemas (karr k58): OWNA.temp_item belongs to the bare
# temp_parent, OWNB.temp_x belongs to OWNA.temp_item.
{
  package T::Temp::Parent;
  use base 'DBIO::Core';
  __PACKAGE__->table('temp_parent');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
}
{
  package T::Temp::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('OWNA.temp_item');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'T::Temp::Parent', 'parent_id');
}
{
  package T::Temp::X;
  use base 'DBIO::Core';
  __PACKAGE__->table('OWNB.temp_x');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer' },
    item_id => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(item => 'T::Temp::Item', 'item_id');
}
{
  package T::Temp::XSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Parent => 'T::Temp::Parent');
  __PACKAGE__->register_class(Item   => 'T::Temp::Item');
  __PACKAGE__->register_class(X      => 'T::Temp::X');
}

# What a handle double has been asked, in order, across all of them.
my @LOG;
# What the double answers / dies on.
my (@PRIVS, $FAIL_ON, $FAIL_CONNECT, %INTRO_ARGS);

{
  package T::Temp::Dbh;
  sub new { my ($c, %a) = @_; bless {%a}, $c }
  sub _log { push @LOG, "$_[0]{role}: $_[1]" }
  sub do {
    my ($s, $sql) = @_;
    $s->_log($sql);
    die "ORA-00000: $s->{role} failed on [$sql]\n" if $FAIL_ON && $sql =~ $FAIL_ON;
    return '0E0';
  }
  sub selectcol_arrayref { my ($s, $sql) = @_; $s->_log($sql); [ @PRIVS ] }
  sub selectrow_array    { my ($s, $sql) = @_; $s->_log($sql); ('USERS') }
  sub disconnect         { $_[0]->_log('disconnect'); 1 }
}

{
  package T::Temp::Introspect;
  # The model of the temp user the handle is connected as. The main user holds
  # temp_parent; temp user _1 (OWNA) temp_item, whose foreign key points to the
  # main user's table; _2 (OWNB) temp_x, whose key points to temp user _1.
  sub model {
    my ($self) = @_;
    my ($main, $k) = ($self->{user} // '') =~ /\A(DBIO_TMP_\d+_\d+)(?:_(\d+))?\z/
      or return { tables => {}, columns => {}, marker => 'temp model' };
    my $u = $self->{user};
    my ($t, $fk_to) = !$k ? ('temp_parent', undef)
      : $k == 1 ? ('temp_item', "$main.temp_parent")
      :           ('temp_x',    "${main}_1.temp_item");
    return {
      marker             => 'temp model',
      tables             => { $t => { table_name => $t, schema => $u, kind => 'table' } },
      columns            => { $t => [ { column_name => 'id', ($k && $k == 1
        ? (is_auto_increment => 1, sequence => "$u.temp_item_id_seq") : ()) } ] },
      indexes            => { $t => {} },
      foreign_keys       => { $t => $fk_to ? [ {
        constraint_name => "fk_$t", from_table => $t, from_columns => ['x'],
        to_table => $fk_to, to_columns => ['id'] } ] : [] },
      primary_keys       => { $t => ['id'] },
      unique_constraints => { $t => [] },
    };
  }
}

my @CONNECT_INFO = ('dbi:Oracle:TEMPTEST', 'live_user', 'live_secret');

my @connects;
no warnings qw(redefine once);
local *DBI::connect = sub {
  my ($class, $dsn, $user, $pass, $attrs) = @_;
  push @connects, { dsn => $dsn, user => $user, pass => $pass, attrs => $attrs };
  die "ORA-12154: cannot connect to $dsn as $user/$pass\n" if $FAIL_CONNECT;
  return T::Temp::Dbh->new(user => $user, role =>
      $user =~ /\ADBIO_TMP_\d+_\d+_(\d+)\z/ ? "temp$1"
    : $user =~ /\ADBIO_TMP_/                  ? 'temp'
    :                                           'admin');
};

my $live = T::Temp::Dbh->new(role => 'live');
local *DBIO::Oracle::Deploy::_dbh = sub { $live };
local *DBIO::Oracle::Deploy::_new_introspect = sub {
  my ($self, $dbh, %args) = @_;
  push @LOG, "introspect on $dbh->{role}";
  $INTRO_ARGS{ $dbh->{role} } = \%args;
  return bless { user => $dbh->{user} }, 'T::Temp::Introspect';
};
use warnings;

my @warnings;
local $SIG{__WARN__} = sub {
  return if $_[0] =~ /\Anon-transactional DDL on DBIO::Oracle::Deploy\b/;
  push @warnings, $_[0];
};

sub fresh {
  my $class = shift // 'T::Temp::Schema';
  @LOG = @connects = @warnings = ();
  %INTRO_ARGS = ();
  @PRIVS = ('CREATE USER', 'DROP USER');
  ($FAIL_ON, $FAIL_CONNECT) = ();
  return DBIO::Oracle::Deploy->new(
    schema => $class->connect(@CONNECT_INFO),
  );
}

sub statements_of { my $role = shift; [ map { /\A\Q$role\E: (.*)\z/s ? $1 : () } @LOG ] }

# ----------------------------------------------- 1. the order, the happy path

{
  my $deploy = fresh();
  my $model  = $deploy->_build_target_model;

  is $model->{marker}, 'temp model', 'the model is the introspection of the temp user';

  my ($create) = grep { /\Aadmin: CREATE USER / } @LOG;
  my ($name)   = ($create // '') =~ /CREATE USER (\S+)/;
  like $name, qr/\ADBIO_TMP_\d+_\d+\z/, '4: the temp user is named DBIO_TMP_<pid>_<n>';
  like $name, qr/\ADBIO_TMP_\Q$$\E_/, '... with the pid of this process';

  my @shape = map {
    /\Aadmin: CREATE USER / ? 'create user'
      : /\Aadmin: GRANT (.+) TO \Q$name\E\z/ ? "grant $1"
      : /\Aadmin: DROP USER \Q$name\E CASCADE\z/ ? 'drop user'
      : /\Atemp: CREATE (\w+)/ ? "install $1"
      : /\Aintrospect on temp/ ? 'introspect'
      : /\Atemp: disconnect/ ? 'temp disconnect'
      : /\Aadmin: disconnect/ ? 'admin disconnect'
      : ()
  } @LOG;

  my @installed = grep { /\Ainstall / } @shape;
  ok scalar @installed, 'the install DDL ran on the temp handle';

  is_deeply [ grep { !/\Ainstall / } @shape ], [
    'create user',
    ( map { "grant $_" } 'CREATE SESSION', 'CREATE TABLE', 'CREATE SEQUENCE',
                         'CREATE TRIGGER', 'CREATE VIEW' ),
    'introspect', 'temp disconnect', 'drop user', 'admin disconnect',
  ], '1: privilege check, CREATE USER, the grants, install on the temp handle, '
   . 'introspection on it, its disconnect, then DROP USER, then the admin '
   . 'connection is closed';

  my ($first_install) = grep { $shape[$_] =~ /\Ainstall / } 0 .. $#shape;
  my ($introspect)    = grep { $shape[$_] eq 'introspect' } 0 .. $#shape;
  ok $first_install < $introspect, '... the install comes before the introspection';

  like $create, qr/\Aadmin: CREATE USER \S+ IDENTIFIED BY "[A-Za-z0-9]{20,}" DEFAULT TABLESPACE "USERS" QUOTA UNLIMITED ON "USERS"\z/,
    'the user gets a random password and an unlimited quota on the default '
  . 'tablespace of the connected user';

  my ($pass) = $create =~ /IDENTIFIED BY "([^"]+)"/;
  is_deeply [ map { @$_{qw(user pass)} } $connects[1] ], [ $name, $pass ],
    '... and the temp connection logs in with that user and password';
  is $connects[1]{dsn}, $CONNECT_INFO[0], '... on the DSN of the storage';

  is scalar(@connects), 2, 'two connections were opened: admin, temp';
  is $connects[0]{user}, 'live_user', 'the admin connection has the credentials of the storage';
  is $connects[0]{attrs}{AutoCommit}, 1, '5: ... and AutoCommit, so CREATE USER/GRANT/DROP USER '
    . 'commit nothing of the caller';
  is_deeply statements_of('live'), [],
    '5: the live handle of the schema was not touched by a single statement';

  # a second build: the counter has moved
  my ($n1) = $name =~ /_(\d+)\z/;
  @LOG = ();
  $deploy->_build_target_model;
  my ($name2) = (grep { /\Aadmin: CREATE USER / } @LOG)[0] =~ /CREATE USER (\S+)/;
  my ($n2) = $name2 =~ /_(\d+)\z/;
  is $n2, $n1 + 1, '4: the counter counts per process';
}

# --------------------------------------------- 2. the drop on every path

{
  my $deploy = fresh();
  $FAIL_ON = qr/\ACREATE TABLE/;

  my $ok = eval { $deploy->_build_target_model; 1 };
  my $err = $@;

  ok !$ok, '2: a deploy that dies, dies';
  like "$err", qr/ORA-00000: temp failed on \[CREATE TABLE/,
    '... with its own error';
  is scalar(grep { /\Aadmin: DROP USER DBIO_TMP_\d+_\d+ CASCADE\z/ } @LOG), 1,
    '... and the temp user is dropped all the same';
  is scalar(grep { $_ eq 'temp: disconnect' } @LOG), 1,
    '... after the temp connection is closed';
  is scalar(grep { $_ eq 'admin: disconnect' } @LOG), 1, '... and the admin connection is closed too';
  is_deeply \@warnings, [], '... and nothing is warned about';
}

{
  my $deploy = fresh();
  $FAIL_ON = qr/\ADROP USER/;

  my $model = eval { $deploy->_build_target_model };
  my $err   = $@;

  is $err, '', '2: a drop that fails does not change the outcome ...';
  is $model->{marker}, 'temp model', '... the model is returned';

  is scalar(@warnings), 1, '... but it is warned about, once';
  like $warnings[0], qr/\ADBIO::Oracle::Deploy: temporary database 'DBIO_TMP_\d+_\d+' could not be dropped/,
    '... naming the user that is still on the server';
  unlike $warnings[0], qr/live_secret/, '... without the password of the connected user';
  my ($create) = grep { /\Aadmin: CREATE USER / } @LOG;
  my ($pass)   = $create =~ /IDENTIFIED BY "([^"]+)"/;
  unlike $warnings[0], qr/\Q$pass\E/, '... or the password of the temp user';
  is scalar(grep { $_ eq 'admin: disconnect' } @LOG), 1, '... the admin connection is closed anyway';
}

# --------------------------------------- 3. the privilege, before anything

for my $lacking (['CREATE USER'], ['DROP USER'], ['CREATE USER', 'DROP USER']) {
  my $deploy = fresh();
  @PRIVS = grep { my $p = $_; !grep { $_ eq $p } @$lacking } 'CREATE USER', 'DROP USER';

  my $ok = eval { $deploy->_build_target_model; 1 };
  my $err = $@;

  ok !$ok, "3: without " . join(' and ', @$lacking) . " the build is refused";
  isa_ok $err, 'DBIO::Exception', '... what is thrown';
  like "$err", qr/\Q$_\E/, "... it names the missing privilege $_" for @$lacking;

  is scalar(grep { /\Aadmin: (?:CREATE USER|GRANT|DROP USER) / } @LOG), 0,
    '... and nothing was created, granted or dropped';
  is scalar(@connects), 1, '... the only connection was the admin one (no temp login)';
  is scalar(grep { $_ eq 'admin: disconnect' } @LOG), 1, '... and it is closed again';
}

# ------------------------------------------- 6. a user half made is dropped

{
  my $deploy = fresh();
  $FAIL_ON = qr/\AGRANT CREATE TRIGGER/;

  my $ok = eval { $deploy->_build_target_model; 1 };

  ok !$ok, '6: a grant that fails stops the build ...';
  like "$@", qr/ORA-00000: admin failed on \[GRANT CREATE TRIGGER/, '... with its error';
  is scalar(grep { /\Aadmin: DROP USER DBIO_TMP_\d+_\d+ CASCADE\z/ } @LOG), 1,
    '... and the user made before it is dropped again';
  is scalar(@connects), 1, '... no temp login was attempted';
}

# ----------------------------------------------- the passwords stay masked

{
  my $deploy = fresh();
  $FAIL_CONNECT = 1;

  my $ok = eval { $deploy->_build_target_model; 1 };

  ok !$ok, 'a connection that cannot be opened stops the build';
  unlike "$@", qr/live_secret/, '... without the password of the connected user in the message';
  is scalar(grep { /CREATE USER/ } @LOG), 0, '... and no user was made';
}

# ------------------- 8. tables in other schemas: a temp user for each (k58)
#
# A source 'OWNA.item' is a table in the schema (user) OWNA. The desired state
# of a diff cannot make that user, so each such schema gets a temp user of its
# own, DBIO_TMP_<pid>_<n>_<k>; the install DDL is written with the temp users
# as qualifiers, every statement runs as the user whose schema it writes to,
# and the model is read back with the real schema names.

sub dropped_and_created {
  return ([ map { /\Aadmin: CREATE USER (\S+)/ ? $1 : () } @LOG ],
          [ map { /\Aadmin: DROP USER (\S+) CASCADE\z/ ? $1 : () } @LOG ]);
}

{
  my $deploy = fresh('T::Temp::XSchema');
  my $model  = $deploy->_build_target_model;

  my ($created, $dropped) = dropped_and_created();
  is scalar(@$created), 3, '8: a temp user for the main schema and one for each other schema (OWNA, OWNB)';
  my $main = $created->[0];
  like $main, qr/\ADBIO_TMP_\d+_\d+\z/, '... the first is the main DBIO_TMP_<pid>_<n>';
  is_deeply [ @$created[1, 2] ], [ "${main}_1", "${main}_2" ],
    '... the others DBIO_TMP_<pid>_<n>_<k>, k counting the foreign schemas in name order';
  is scalar(grep { /\Aadmin: GRANT CREATE SESSION TO / } @LOG), 3, '... each gets the grants';

  is scalar(grep { /\Atemp\d?: .*(?:OWNA|OWNB)/s } @LOG), 0,
    '... no statement sent to a temp user names a real foreign schema: the qualifiers are the temp users\'';
  ok scalar(grep { /\Atemp: CREATE TABLE "temp_parent"/ } @LOG),
    '... the bare table is made on the main temp user';
  ok scalar(grep { /\Atemp1: CREATE TABLE "\Q${main}_1\E"\."temp_item"/ } @LOG),
    '... OWNA.temp_item is made as that temp user, on its own connection';
  ok scalar(grep { /\Atemp1: CREATE SEQUENCE "\Q${main}_1\E"\."temp_item_id_seq"/ } @LOG)
    && scalar(grep { /\Atemp1: CREATE OR REPLACE TRIGGER "\Q${main}_1\E"\."temp_item_id_trg"/ } @LOG),
    '... with its sequence and trigger';
  ok scalar(grep { /\Atemp2: CREATE TABLE "\Q${main}_2\E"\."temp_x"/ } @LOG),
    '... OWNB.temp_x on the connection of the second';

  # a foreign key across temp users: the owner of the parent grants REFERENCES
  # to the child's user (the sandbox only; the install DDL writes no GRANT)
  my ($g1) = grep { $LOG[$_] eq qq{temp: GRANT REFERENCES ON "temp_parent" TO ${main}_1} } 0 .. $#LOG;
  my ($f1) = grep { $LOG[$_] =~ /\Atemp1: ALTER TABLE "\Q${main}_1\E"\."temp_item" ADD CONSTRAINT .* REFERENCES "temp_parent"/s } 0 .. $#LOG;
  ok defined $g1 && defined $f1 && $g1 < $f1,
    '... the owner of the parent grants REFERENCES on it to the child\'s temp user, before the foreign key';
  my ($g2) = grep { $LOG[$_] eq qq{temp1: GRANT REFERENCES ON "${main}_1"."temp_item" TO ${main}_2} } 0 .. $#LOG;
  my ($f2) = grep { $LOG[$_] =~ /\Atemp2: ALTER TABLE "\Q${main}_2\E"\."temp_x" ADD CONSTRAINT .* REFERENCES "\Q${main}_1\E"\."temp_item"/s } 0 .. $#LOG;
  ok defined $g2 && defined $f2 && $g2 < $f2, '... also between two foreign temp users';
  is scalar(grep { /GRANT (?!CREATE|REFERENCES)/ } @LOG), 0, '... and nothing else is granted';

  is_deeply [ map { /\Aintrospect on (temp\d?)\z/ ? $1 : () } @LOG ], [qw(temp temp1 temp2)],
    '... every temp user is introspected on its own connection (it sees no table of the others)';

  is_deeply [ sort keys %{ $model->{tables} } ], [ 'OWNA.temp_item', 'OWNB.temp_x', 'temp_parent' ],
    '... the model names the tables schema.table again, as the live introspection does';
  is $model->{tables}{'OWNA.temp_item'}{schema}, 'OWNA', '... with the real schema';
  is $model->{columns}{'OWNA.temp_item'}[0]{sequence}, 'OWNA.temp_item_id_seq',
    '... and the real schema in the sequence';
  is $model->{foreign_keys}{'OWNA.temp_item'}[0]{from_table}, 'OWNA.temp_item',
    '... the key of a foreign table knows its key';
  is $model->{foreign_keys}{'OWNA.temp_item'}[0]{to_table}, 'temp_parent',
    '... a key to the main schema names the bare table';
  is $model->{foreign_keys}{'OWNB.temp_x'}[0]{to_table}, 'OWNA.temp_item',
    '... a key to another foreign schema names schema.table';
  for my $sec (qw(tables columns foreign_keys primary_keys)) {
    unlike join(' ', keys %{ $model->{$sec} }), qr/DBIO_TMP/, "... no temp user in the $sec keys";
  }

  is_deeply [ sort @$dropped ], [ sort @$created ], '... and every temp user is dropped';
  my ($last_disc) = grep { $LOG[$_] =~ /\Atemp\d?: disconnect/ } reverse 0 .. $#LOG;
  my ($first_drop) = grep { $LOG[$_] =~ /\Aadmin: DROP USER/ } 0 .. $#LOG;
  ok $last_disc < $first_drop, '... after the temp connections are closed';
  is_deeply statements_of('live'), [], '... the live handle untouched';
  is_deeply \@warnings, [], '... nothing warned';
}

{
  my $deploy = fresh('T::Temp::XSchema');
  $FAIL_ON = qr/\ACREATE TABLE "[^"]+"\."temp_x"/;
  my $ok = eval { $deploy->_build_target_model; 1 };
  ok !$ok, '8: a deploy that dies in a foreign schema dies ...';
  like "$@", qr/ORA-00000: temp2 failed/, '... with its own error';
  my ($created, $dropped) = dropped_and_created();
  is_deeply [ sort @$dropped ], [ sort @$created ], '... and all three temp users are dropped all the same';
  is scalar(grep { /\Atemp\d?: disconnect\z/ } @LOG), 3, '... all temp connections closed';
}

{
  my $deploy = fresh('T::Temp::XSchema');
  $FAIL_ON = qr/\ADROP USER DBIO_TMP_\d+_\d+_1 CASCADE/;
  my $model = eval { $deploy->_build_target_model };
  is "$@", '', '8: a drop that fails does not change the outcome ...';
  ok $model && $model->{tables}{'OWNA.temp_item'}, '... the model is returned';
  is scalar(@warnings), 1, '... one warning';
  like $warnings[0], qr/temporary database 'DBIO_TMP_\d+_\d+_1' could not be dropped/, '... naming that user';
  is scalar(grep { /\Aadmin: DROP USER / } @LOG), 3, '... the others are dropped';
}

{
  my $deploy = fresh('T::Temp::XSchema');
  $FAIL_ON = qr/\AGRANT CREATE SESSION TO DBIO_TMP_\d+_\d+_2\z/;
  my $ok = eval { $deploy->_build_target_model; 1 };
  ok !$ok, '8: a temp user that cannot be made stops the build ...';
  my ($created, $dropped) = dropped_and_created();
  is_deeply [ sort @$dropped ], [ sort @$created ], '... the ones made before it, and it, are dropped again';
  is scalar(grep { /\Atemp\d?: / } @LOG), 0, '... and nothing was installed';
}

{
  my $deploy = fresh('T::Temp::XSchema');
  @PRIVS = ('CREATE USER');
  my $ok = eval { $deploy->_build_target_model; 1 };
  ok !$ok && "$@" =~ /DROP USER/, '8: the privilege check stands for a schema with foreign tables';
  is scalar(grep { /\Aadmin: CREATE USER/ } @LOG), 0, '... nothing created';
}

{
  package T::Temp::Me;
  use base 'DBIO::Core';
  __PACKAGE__->table('USERS.temp_me');    # 'USERS' is the connected user of the doubles
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
}
{
  package T::Temp::MeSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Me => 'T::Temp::Me');
}
{
  my $deploy = fresh('T::Temp::MeSchema');
  $deploy->_build_target_model;
  my ($created, $dropped) = dropped_and_created();
  is scalar(@$created), 1, '8: a table qualified with the connected user\'s own name needs no user of its own';
  ok scalar(grep { /\Atemp: CREATE TABLE "\Q$created->[0]\E"\."temp_me"/ } @LOG),
    '... it is made in the main temp user';
  is_deeply [ sort @$dropped ], [ sort @$created ], '... which is dropped';
}

{
  # the live schema is read with the foreign schemas of the declaration
  my $deploy = fresh('T::Temp::XSchema');
  $deploy->_introspect_current;
  is_deeply $INTRO_ARGS{live}{schemas}, [qw(OWNA OWNB)],
    '8: the live schema is introspected with schemas => the foreign schemas of the declaration';
}

# ------------------------------------ 7. diff and upgrade are core's again

is( DBIO::Oracle::Deploy->can($_), DBIO::Deploy::Base->can($_),
  "7: $_ is DBIO::Deploy::Base's own: it is not refused" )
  for qw(diff apply upgrade install);

# the look at the rows of the live tables (t/86 pins what it refuses) is the
# base's seam since core k399: it runs once the diff is released, before the
# first statement
{
  my @called;
  no warnings qw(redefine once);
  local *DBIO::Deploy::Base::_check_before_apply = sub { push @called, 'base'; 1 };
  local *DBIO::Oracle::Deploy::_dbh = sub { 'the live handle' };
  local *DBIO::Oracle::Deploy::_refuse_unfillable = sub { push @called, [ @_[1, 2] ]; return };
  my $diff = bless {}, 'FakeDiff';

  my $deploy = bless {}, 'DBIO::Oracle::Deploy';
  $deploy->_check_before_apply($diff);
  is_deeply( \@called, [ [ $diff, 'the live handle' ], 'base' ],
    '7: _check_before_apply looks at the rows of the live tables, then goes on as the base does' );
}

ok( DBIO::Oracle::Deploy->isa('DBIO::Deploy::Base::TempDatabase'),
  'the class is a TempDatabase deploy' );

{
  my $deploy = fresh();
  local *DBIO::Oracle::Deploy::_introspect_current = sub { { tables => {}, columns => {} } };

  my $diff = eval { $deploy->diff };
  is "$@", '', '7: diff on the schema runs through the temp user ...';
  isa_ok $diff, 'DBIO::Oracle::Diff', '... and returns the diff class';
  is scalar(grep { /\Aadmin: DROP USER / } @LOG), 1, '... with the user dropped';
  is_deeply statements_of('live'), [], '... and the live handle untouched';
}

is_deeply \@warnings, [], 'no warning on the way, beside core\'s notice that this DDL is not atomic';

done_testing;
