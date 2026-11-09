use strict;
use warnings;
use Test::More;

# karr k46 -- the database context around the temp database of Deploy::diff.
#
# Live on ASE 16.0 SP02, CREATE DATABASE on a connection whose current database
# is the target (testdb) is refused:
#   Msg 1809 "CREATE DATABASE must be preceded by a 'USE master' command."
# so every diff()/upgrade() died before comparing anything. The fix switches
# the handle to master for CREATE/DROP DATABASE and switches it BACK afterwards
# -- also when the statement fails -- because the handle is the live storage's:
# _build_target_model introspects and apply()s the target through it, and a
# handle left in master would read and alter master instead.
#
# Fully offline. The fake handle keeps a current database and refuses
# CREATE/DROP DATABASE anywhere but master, which is the server behaviour the
# live run met, so the assertions sample the context and not merely a string.

use Time::HiRes ();
use DBIO::Sybase::Deploy;

{
  package K46::Dbh;
  sub new {
    bless {
      AutoCommit => 1, db => $_[1], log => [], fail => {},
      there => {}, option => {}, printed => [],   # karr k69, below
    }, $_[0];
  }
  sub selectrow_array {
    my ($self, $sql) = @_;
    # karr k69: is 'abort tran on log full' set on the database?
    # karr k69 part B: the size of model, asked once per temp database
    return (16384, 1536, 850) if $sql =~ /^SELECT \@\@maxpagesize/;
    my ($asked_of) = $sql =~ /^SELECT status2 & 1 FROM master\.\.sysdatabases WHERE name = '(\w+)'$/;
    die "unexpected query: $sql"
      unless defined $asked_of or $sql =~ /^\s*SELECT\s+db_name\(\)\s*$/i;
    push @{ $self->{log} }, $sql;
    return defined $asked_of ? ( $self->{option}{$asked_of} ? 1 : 0 ) : $self->{db};
  }
  sub do {
    my ($self, $sql) = @_;
    push @{ $self->{log} }, $sql;
    $self->{err} = undef;   # as with DBI: every call starts without an error
    if ($sql =~ /^USE\s+(\S+)$/i) { $self->{db} = $1; return 1 }
    if ($sql =~ /^(CREATE|DROP)\s+DATABASE\s+(\S+)/i) {
      my ($op, $name) = ($1, $2);
      die "Msg 1809: $op DATABASE must be preceded by a 'USE master' command.\n"
        unless $self->{db} eq 'master';
      die "Msg 1810: simulated failure\n" if $self->{fail}{lc $op};
      # karr k74: something is in the database for the next {in_use} DROPs
      if (uc $op eq 'DROP' and $self->{in_use} and $self->{in_use}--) {
        $self->{err} = 3702;
        die "DBD::Sybase::db do failed: Server message number=3702 severity=16 "
          . "state=4 line=1 server=MYSYBASE text=Cannot drop or replace the "
          . "database '_dbio_tmp_1_2' because it is currently in use.\n";
      }
      # karr k69: which databases there are
      if (uc $op eq 'CREATE') { $self->{there}{$name} = 1 } else { delete $self->{there}{$name} }
    }
    # karr k69: sp_dboption as the server answered it live. It is refused
    # outside master and inside a transaction, and reports what it did in two
    # messages of severity 10 -- which DBD::Sybase hands to the handle's
    # syb_err_handler and prints as warnings unless that returns false.
    if ($sql =~ /^EXEC sp_dboption '(\w+)', 'abort tran on log full', true$/) {
      my $name = $1;
      my $message = sub {
        my ($number, $severity, $text) = @_;
        my $handler = $self->{syb_err_handler};
        return $handler ? $handler->($number, $severity, 1, 1, 'MYSYBASE', 'sp_dboption', $text) : 1;
      };
      die "Msg 17428: You must be in the 'master' database in order to change database options.\n"
        unless $self->{db} eq 'master';
      die "Msg 17260: Can't run sp_dboption from within a transaction.\n"
        unless $self->{AutoCommit};
      if ($self->{fail}{option}) {
        $message->(17424, 16, 'simulated failure');
        die "Msg 17424: simulated failure\n";
      }
      return 1 if $self->{deaf};   # takes the statement and sets nothing
      $self->{option}{$name} = 1;
      for my $text (
        "Database option 'abort tran on log full' turned ON for database '$name'.",
        "Running CHECKPOINT on database '$name' for option 'abort tran on log full' to take effect.",
      ) {
        push @{ $self->{printed} }, $text if $message->(0, 10, $text);
      }
    }
    return 1;
  }
  sub err { $_[0]{err} }
}
{
  package K46::Schema;
  sub new     { bless { storage => $_[1] }, $_[0] }
  sub sources { () }   # nothing to deploy: the temp database is as large as model
  sub storage { $_[0]{storage} }
}
{
  package K46::Storage;
  sub new          { bless { dbh => $_[1], connect_info => $_[2] }, $_[0] }
  sub dbh          { $_[0]{dbh} }
  sub connect_info { $_[0]{connect_info} }
  # the core reads the connect info the storage connects with (dbio k353)
  sub _dbi_connect_info { $_[0]{connect_info} }
}

sub deploy_for {
  my ($dbh, $info) = @_;
  DBIO::Sybase::Deploy->new(schema => K46::Schema->new(
    K46::Storage->new($dbh, $info // ['dbi:Sybase:host=h;port=5000;database=testdb', 'sa', 'pw'])));
}

sub stmts { [ grep { !/db_name/i } @{ $_[0]{log} } ] }

# karr k69: what _create_temp_db sends after CREATE DATABASE.
sub option_sql { "EXEC sp_dboption '$_[0]', 'abort tran on log full', true" }
sub is_set_sql { "SELECT status2 & 1 FROM master..sysdatabases WHERE name = '$_[0]'" }

# --- create: USE master, CREATE, back to the original database --------------
# RESPELLED (karr k69): the sequence was USE master, CREATE DATABASE, USE
# <original>. The database option and the look at it now stand between CREATE
# and the way back; the claim of k46 -- master around it, the original
# database afterwards -- is what it was. What the two new statements are for
# is the k69 section below.
{
  my $dbh    = K46::Dbh->new('testdb');
  my $deploy = deploy_for($dbh);
  my $name   = $deploy->_create_temp_db($dbh);

  is_deeply(stmts($dbh),
    [ 'USE master', "CREATE DATABASE $name ON default = '24M'", option_sql($name), is_set_sql($name), 'USE testdb' ],
    'create: USE master, CREATE DATABASE, its option, USE <original>');
  is($dbh->{db}, 'testdb', 'create: the handle is back in the target database');
}

# --- drop: same bracket ------------------------------------------------------
{
  my $dbh    = K46::Dbh->new('testdb');
  my $deploy = deploy_for($dbh);
  $deploy->_drop_temp_db($dbh, '_dbio_tmp_1_2');

  is_deeply(stmts($dbh), [ 'USE master', 'DROP DATABASE _dbio_tmp_1_2', 'USE testdb' ],
    'drop: USE master, DROP DATABASE, USE <original>');
  is($dbh->{db}, 'testdb', 'drop: the handle is back in the target database');
}

# --- failure: the context is restored and the error still propagates ---------
for my $op (qw(create drop)) {
  my $dbh    = K46::Dbh->new('testdb');
  $dbh->{fail}{$op} = 1;
  my $deploy = deploy_for($dbh);

  my $ok = eval {
    $op eq 'create' ? $deploy->_create_temp_db($dbh)
                    : $deploy->_drop_temp_db($dbh, '_dbio_tmp_1_2');
    1;
  };
  my $err = $@;
  ok(!$ok, "$op failure: the error propagates");
  like($err, qr/Msg 1810/, "$op failure: ... it is the statement's own error");
  is($dbh->{log}[-1], 'USE testdb', "$op failure: USE <original> still ran last");
  is($dbh->{db}, 'testdb', "$op failure: the handle is back in the target database");
}

# --- the whole _build_target_model cycle leaves the handle where it was ------
# create -> deploy+introspect over the temp database's own connection (stubbed
# here: its DBI->connect is not what k46 is about) -> drop on the live handle.
# After it, the live handle must still point at the target database, since
# the caller goes on to introspect the live side and apply through it.
{
  my $dbh    = K46::Dbh->new('testdb');
  my $deploy = deploy_for($dbh);
  my $seen_db;
  no warnings 'redefine', 'once';
  local *DBIO::Sybase::Deploy::_deploy_and_introspect_temp = sub {
    $seen_db = $dbh->{db};
    return { tables => {} };
  };

  my $model = $deploy->_build_target_model;
  is_deeply($model, { tables => {} }, 'cycle: the temp model is returned');
  is($seen_db, 'testdb', 'cycle: the live handle is in the target during the temp deploy');
  is($dbh->{db}, 'testdb', 'cycle: ... and after the temp database is dropped');
}

# --- karr k74: a temp database that is in use is waited for, within a bound --
# ASE refuses DROP DATABASE with Msg 3702 while anything is in the database,
# and core drops the temp database the moment it has closed the session into
# it; the server's own checkpoint process was seen live in a database no
# client was connected to. Core's _build_target_model catches whatever the
# drop dies of, so one refusal left _dbio_tmp_<pid>_<time> on the server
# without a word (live: t/66-drop-database-in-use-live.t). The drop is
# repeated on that message, and on it alone, a fixed number of times; the
# handle stays in master for all of them and goes back afterwards.
{
  my @slept;
  no warnings 'redefine';
  local *Time::HiRes::sleep = sub (;@) { push @slept, $_[0] };

  {
    my $dbh    = K46::Dbh->new('testdb');
    $dbh->{in_use} = 2;
    my $deploy = deploy_for($dbh);

    ok(eval { $deploy->_drop_temp_db($dbh, '_dbio_tmp_1_2') },
      'in use: a database in use at the first two tries is dropped at the third')
      or diag $@;
    is_deeply(stmts($dbh),
      [ 'USE master', ('DROP DATABASE _dbio_tmp_1_2') x 3, 'USE testdb' ],
      'in use: USE master, DROP DATABASE until it is taken, USE <original>');
    is_deeply(\@slept, [ 0.25, 0.25 ], 'in use: ... a quarter of a second apart');
    is($dbh->{db}, 'testdb', 'in use: the handle is back in the target database');
  }

  {
    @slept = ();
    my $dbh    = K46::Dbh->new('testdb');
    $dbh->{in_use} = 1000;
    my $deploy = deploy_for($dbh);

    my $ok  = eval { $deploy->_drop_temp_db($dbh, '_dbio_tmp_1_2'); 1 };
    my $err = $@;
    ok(!$ok, 'in use for good: the drop gives up');
    like($err, qr/number=3702\b.*currently in use/,
      'in use for good: ... with the server\'s own error');
    is(scalar(grep { /^DROP DATABASE/ } @{ stmts($dbh) }), 40,
      'in use for good: ... after 40 tries, a fixed number');
    is(scalar(@slept), 39, 'in use for good: ... a wait between two tries, none after the last');
    is($dbh->{log}[-1], 'USE testdb', 'in use for good: USE <original> still ran last');
  }

  {
    @slept = ();
    my $dbh    = K46::Dbh->new('testdb');
    $dbh->{fail}{drop} = 1;
    $dbh->{in_use}     = 1000;
    my $deploy = deploy_for($dbh);

    ok(!eval { $deploy->_drop_temp_db($dbh, '_dbio_tmp_1_2'); 1 },
      'another error: it propagates');
    is(scalar(grep { /^DROP DATABASE/ } @{ stmts($dbh) }), 1,
      'another error: ... at once -- only Msg 3702 is repeated');
    is_deeply(\@slept, [], 'another error: ... without a wait');
  }

  # The cycle: core closes the temp session and drops at once. With the
  # database still in use at that moment the model comes back all the same,
  # and the database is gone.
  {
    my $dbh    = K46::Dbh->new('testdb');
    $dbh->{in_use} = 1;
    my $deploy = deploy_for($dbh);
    local *DBIO::Sybase::Deploy::_deploy_and_introspect_temp = sub { { tables => {} } };

    is_deeply($deploy->_build_target_model, { tables => {} },
      'cycle, in use once: the temp model is returned');
    my ($name) = stmts($dbh)->[1] =~ /^CREATE DATABASE (\S+) ON default = '\d+M'$/;
    is_deeply([ @{ stmts($dbh) }[-4 .. -1] ],
      [ 'USE master', ("DROP DATABASE $name") x 2, 'USE testdb' ],
      'cycle, in use once: ... and the temp database is dropped at the second try');
  }
}

# --- karr k69: the temp database gets 'abort tran on log full' ---------------
# A database made by a plain CREATE DATABASE has the server's default size and
# the options of `model`. When the desired schema does not fit into it, ASE
# does not refuse the statement that finds it full: it suspends the session
# until somebody frees log space, and nobody does -- diff() and upgrade() never
# returned (live: t/71-temp-db-log-full-live.t). With 'abort tran on log full'
# the statement dies of Msg 1105 instead. So the option is set, from master,
# before anything is deployed into the database, and a database it could not
# be set on is not handed on: it is dropped and the error raised.
{
  # set, looked at, and silent
  {
    my $dbh  = K46::Dbh->new('testdb');
    my $name = deploy_for($dbh)->_create_temp_db($dbh);

    ok($dbh->{option}{$name}, 'option: the temp database has it when it is handed on');
    is_deeply($dbh->{printed}, [],
      'option: what sp_dboption reports -- two messages of severity 10 -- is '
      . 'taken, not printed as warnings');
    is($dbh->{syb_err_handler}, undef,
      'option: ... by a handler that is gone from the handle afterwards');
  }

  # a handler of the caller's is put back, and keeps its say on errors
  {
    my @shown;
    my $own = sub { push @shown, $_[0]; 1 };

    my $dbh = K46::Dbh->new('testdb');
    $dbh->{syb_err_handler} = $own;
    deploy_for($dbh)->_create_temp_db($dbh);

    is($dbh->{syb_err_handler}, $own, 'option: a handler of the caller\'s is back afterwards');
    is_deeply(\@shown, [], 'option: ... and was not shown the report on a database it never heard of');
    is_deeply($dbh->{printed}, [], 'option: ... which is not printed either');

    $dbh = K46::Dbh->new('testdb');
    $dbh->{syb_err_handler} = $own;
    $dbh->{fail}{option}    = 1;
    eval { deploy_for($dbh)->_create_temp_db($dbh) };

    is_deeply(\@shown, [ 17424 ], 'option: a message above severity 10 does go to it');
    is($dbh->{syb_err_handler}, $own, 'option: ... and it is back after a failure too');
  }

  # CREATE DATABASE failed: there is nothing to set an option on, or to drop
  {
    my $dbh = K46::Dbh->new('testdb');
    $dbh->{fail}{create} = 1;
    eval { deploy_for($dbh)->_create_temp_db($dbh) };

    is(scalar(grep { /sp_dboption|^DROP DATABASE/ } @{ stmts($dbh) }), 0,
      'create failure: neither sp_dboption nor DROP DATABASE is sent');
  }

  # the option cannot be set: the database is dropped, the error raised
  for my $case (
    [ 'sp_dboption fails',     sub { $_[0]{fail}{option} = 1 }, qr/Msg 17424/ ],
    [ 'sp_dboption sets nothing', sub { $_[0]{deaf} = 1 },
      qr/'abort tran on log full' .* temporary database _dbio_tmp_\d+_\d+/ ],
  ) {
    my ($what, $arrange, $expected) = @$case;

    my $dbh = K46::Dbh->new('testdb');
    $arrange->($dbh);

    my $name = eval { deploy_for($dbh)->_create_temp_db($dbh) };
    my $err  = $@;
    my ($made) = map { /^CREATE DATABASE (\S+) ON default = '\d+M'$/ } @{ stmts($dbh) };

    is($name, undef, "$what: no temp database is handed on");
    like($err, $expected, "$what: ... the error says why");
    is(scalar(grep { $_ eq "DROP DATABASE $made" } @{ stmts($dbh) }), 1,
      "$what: ... the database just made is dropped");
    is_deeply($dbh->{there}, {}, "$what: ... and gone -- the drop ran from master");
    is($dbh->{log}[-1], 'USE testdb', "$what: USE <original> still ran last");
    is($dbh->{db}, 'testdb', "$what: the handle is back in the target database");
  }

  # ... dropped the way the temp database is always dropped (karr k74)
  {
    no warnings 'redefine';
    local *Time::HiRes::sleep = sub (;@) { };

    my $dbh = K46::Dbh->new('testdb');
    $dbh->{fail}{option} = 1;
    $dbh->{in_use}       = 2;
    eval { deploy_for($dbh)->_create_temp_db($dbh) };

    is_deeply($dbh->{there}, {},
      'option failure, database in use for a moment: the drop is repeated until it is taken');
  }

  # ... and when it cannot be dropped either, the error says so: nobody else will
  {
    my $dbh = K46::Dbh->new('testdb');
    $dbh->{fail}{option} = 1;
    $dbh->{fail}{drop}   = 1;

    my $ok  = eval { deploy_for($dbh)->_create_temp_db($dbh); 1 };
    my $err = $@;
    my ($made) = keys %{ $dbh->{there} };

    ok(!$ok, 'option and drop both fail: the error propagates');
    like($err, qr/Msg 17424/, 'option and drop both fail: ... it is the option\'s error');
    like($err, qr/\Q$made\E.*Msg 1810/s,
      'option and drop both fail: ... with the database left behind, by name, and why');
    is($dbh->{db}, 'testdb', 'option and drop both fail: the handle is back in the target database');
  }

  # the cycle: nothing is deployed into a database the option is not set on
  {
    my $dbh    = K46::Dbh->new('testdb');
    $dbh->{deaf} = 1;
    my $deploy = deploy_for($dbh);
    my $deployed = 0;
    no warnings 'redefine', 'once';
    local *DBIO::Sybase::Deploy::_deploy_and_introspect_temp = sub { $deployed++; { tables => {} } };

    my $model = eval { $deploy->_build_target_model };
    is($model, undef, 'cycle, option not set: no model comes back');
    is($deployed, 0, 'cycle, option not set: ... and nothing was deployed into the database');
    is_deeply($dbh->{there}, {}, 'cycle, option not set: ... which is gone');
    is($dbh->{db}, 'testdb', 'cycle, option not set: the handle is in the target database');
  }
}

# --- the temp DSN names the temp database in DBD::Sybase's own key ----------
{
  my $deploy = deploy_for(K46::Dbh->new('testdb'));

  is($deploy->_temp_dsn('dbi:Sybase:host=localhost;port=5000;database=testdb', 'tmp1'),
    'dbi:Sybase:host=localhost;port=5000;database=tmp1',
    'temp dsn: the FreeTDS host/port form has its database= replaced');
  is($deploy->_temp_dsn('dbi:Sybase:server=SYB;database=testdb;charset=utf8', 'tmp1'),
    'dbi:Sybase:server=SYB;database=tmp1;charset=utf8',
    'temp dsn: a database= in the middle is replaced in place');

  # A DSN without database= connects to the login's default database. The core
  # fallback appends ;dbname=, a key DBD::Sybase does not read -- the temp
  # connection would then land in that default database and deploy the
  # desired schema into it. DBD::Sybase's key is database=.
  is($deploy->_temp_dsn('dbi:Sybase:server=SYB', 'tmp1'),
    'dbi:Sybase:server=SYB;database=tmp1',
    'temp dsn: an absent database is appended as database=, not dbname=');
  is($deploy->_temp_dsn('dbi:Sybase:', 'tmp1'),
    'dbi:Sybase:database=tmp1',
    'temp dsn: an empty attribute part gets no leading separator');
}

done_testing;
