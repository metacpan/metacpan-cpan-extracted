use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBI;
use DBD::Firebird;
use DBIO::Firebird::Deploy;

# OFFLINE (karr k39, from core k297): a message never quotes credentials.
#
# DBIO::Firebird::Deploy opens connections of its own -- it creates the
# temporary database, and connects to it once more to drop it -- and it reads
# the live DSN to find out where to put that database. Each of the three can
# fail with a text that is not this module's: DBI dies quoting the data source
# it was given, the engine's error is whatever the server and its client
# library make of the request, and the DSN is the caller's. All of it goes
# through core's DBIO::Util::mask_connect_secrets with the connect info of the
# connection the message is about.
#
# What this file claims, for each of the three sites:
#   - the password of the connect info is not in the message, wherever the
#     failure text repeats it;
#   - a password inside a DSN the message quotes is not in it either;
#   - the rest of the message is still there: which database, which user,
#     what the engine said. Masked is not the same as swallowed.
#
# THE SUBSTITUTIONS: the storage is a stand-in answering connect_info;
# DBI->connect and DBD::Firebird->create_database are replaced by subs that
# fail with a text repeating the password. Neither DBI nor DBD::Firebird does
# that in the failures that could be provoked without a server (measured for
# this ticket: a refused connection names the host and the user, never the
# password) -- the replacement stands for the failure that does, which is the
# one this file is about. No connection is opened.

{
  package Local::Storage; sub new { bless { ci => $_[1] }, $_[0] } sub connect_info { $_[0]{ci} }
  # core's _temp_connect_info reads the normalised [ $dsn, $user, $pass, \%attrs ]
  # (karr k56): the stand-in answers it from the connect info it was given
  sub _dbi_connect_info {
    my $ci = $_[0]{ci}[0];
    return ref $ci eq 'HASH' ? [ $ci->{dsn}, $ci->{user}, $ci->{password}, {} ] : [ @{ $_[0]{ci} }[0 .. 2], {} ];
  }
  package Local::Schema;  sub new { bless { st => $_[1] }, $_[0] } sub storage { $_[0]{st} }
}

sub deploy_for {
  my ($connect_info) = @_;
  return DBIO::Firebird::Deploy->new(
    schema => Local::Schema->new(Local::Storage->new($connect_info)),
  );
}

my ($USER, $SECRET, $CANARY) = ('k39-user', 'k39-secret', 'k39-canary');
my $LIVE_DSN = 'dbi:Firebird:dbname=db.example/3051:/data/x/live.fdb';
my $TEMP_ID  = 'db.example/3051:/data/x/_dbio_tmp_k39.fdb';

# ---------------------------------------------------------------------------
# 1. _live_db_location: the DSN it cannot read is quoted, without a password.
# ---------------------------------------------------------------------------
for my $case (
  [ 'array connect info' => sub { [ $_[0], $USER, $SECRET ] } ],
  [ 'hash connect info'  => sub { [ { dsn => $_[0], user => $USER, password => $SECRET } ] } ],
) {
  my ($shape, $connect_info) = @$case;

  {
    my $dsn = "dbi:Firebird:host=db.example;password=$CANARY;ib_charset=UTF8";
    throws_ok { deploy_for($connect_info->($dsn))->_live_db_location }
      qr{cannot find dbname=/database= in DSN},
      "$shape, a DSN without a database: refused, saying what is missing";
    unlike "$@", qr/\Q$CANARY\E/, '... without the password the DSN carries';
    like "$@", qr/host=db\.example;password=\*\*\*;ib_charset=UTF8/,
      '... and with the rest of the DSN, so the message still says which one';
  }

  # A password the mask cannot recognise by its key is known from the connect
  # info of the connection.
  {
    my $dsn = "dbi:Firebird:host=db.example;ib_role=$SECRET";
    throws_ok { deploy_for($connect_info->($dsn))->_live_db_location }
      qr{cannot find dbname=/database= in DSN},
      "$shape, a DSN repeating the password under another key: refused";
    unlike "$@", qr/\Q$SECRET\E/, '... without the password of the connect info';
    like "$@", qr/host=db\.example;ib_role=\*\*\*/, '... and with the rest of the DSN';
  }
}

# ---------------------------------------------------------------------------
# 2. _drop_temp_db: the connection to the temporary database fails.
# ---------------------------------------------------------------------------
{
  my $deploy = deploy_for([ $LIVE_DSN, $USER, $SECRET ]);
  my @connects;

  # as DBI dies with RaiseError, the DBD's text repeating the password
  {
    no warnings 'redefine';
    local *DBI::connect = sub {
      shift;
      push @connects, [ @_ ];
      my ($dsn, $user, $password) = @_;
      $dsn =~ s/^dbi:[^:]*://;
      die "DBI connect('$dsn','$user',...) failed: login of $user with $password rejected at t/k39 line 1.\n";
    };

    throws_ok { $deploy->_drop_temp_db(undef, $TEMP_ID) } qr/DBI connect\(/,
      'the connection for the drop fails: _drop_temp_db dies';
  }
  my $error = "$@";

  is_deeply [ @{ $connects[0] || [] }[0 .. 2] ], [ "dbi:Firebird:dbname=$TEMP_ID", $USER, $SECRET ],
    '... having tried the temporary database with the credentials of the live one';
  unlike $error, qr/\Q$SECRET\E/, '... and the message is without the password';
  like $error, qr/\Qdbname=$TEMP_ID\E/, '... naming the database';
  like $error, qr/login of \Q$USER\E with \*\*\* rejected/, '... the user, and what the driver said';
}

# DBI->connect answering false without dying: the message is this module's,
# built from DBI's last error.
{
  my $deploy = deploy_for([ $LIVE_DSN, $USER, $SECRET ]);
  my $drh    = DBI->install_driver('Firebird');

  {
    no warnings 'redefine';
    local *DBI::connect = sub {
      local $drh->{PrintError} = 0;
      local $drh->{RaiseError} = 0;
      $drh->set_err(335544472, "login with $SECRET rejected");
      return undef;
    };

    throws_ok { $deploy->_drop_temp_db(undef, $TEMP_ID) }
      qr/Cannot connect to temp database for drop: login with \*\*\* rejected/,
      'the connection for the drop answers false: _drop_temp_db dies with its own message, the password masked';
  }
  unlike "$@", qr/\Q$SECRET\E/, '... and without the password anywhere in it';
}

# ---------------------------------------------------------------------------
# 3. _create_temp_db: the engine refuses to create the temporary database.
# ---------------------------------------------------------------------------
# DBD::Firebird builds CREATE DATABASE '...' USER '...' PASSWORD '...' and
# hands it to the client library; create_database croaks with the engine's
# text, which for a statement it cannot parse names a token of it.
{
  my $deploy = deploy_for([ $LIVE_DSN, $USER, $SECRET ]);
  my @created;

  {
    no warnings 'redefine';
    local *DBD::Firebird::create_database = sub {
      push @created, $_[1];
      die "Dynamic SQL Error\n-SQL error code = -104\n-Token unknown - line 1, column 71\n-$_[1]{password} at t/k39 line 1.\n";
    };

    throws_ok { $deploy->_create_temp_db(undef) } qr/Token unknown/,
      'create_database croaks: _create_temp_db dies with what the engine said';
  }
  my $error = "$@";

  is $created[0]{password}, $SECRET, '... having handed the password to create_database';
  unlike $error, qr/\Q$SECRET\E/, '... and the message is without it';
  like $error, qr/SQL error code = -104/, '... the rest of it intact';

  # control: a create_database that answers nothing is no failure
  my $id;
  {
    no warnings 'redefine';
    local *DBD::Firebird::create_database = sub { return };
    lives_ok { $id = $deploy->_create_temp_db(undef) }
      'create_database returning nothing, as it does on success: _create_temp_db lives';
  }
  like $id, qr{^db\.example/3051:/data/x/_dbio_tmp_\d+_\d+\.fdb\z},
    '... and answers the identifier of the database beside the live one';
}

done_testing;
