use strict;
use warnings;
use Test::More;

# OFFLINE test: no message of this transport about a connection quotes its
# password (karr k76; core k297 for the sync side).
#
# WHY: a message about a connection that cannot be opened ends where nobody
# guards it -- a log, a bug report, the exception page of a web application.
# Core masks the password wherever it writes connect info into a message, with
# one function for it, DBIO::Util::mask_connect_secrets. This transport writes
# connect info into messages of its own, and passes on the client library's
# and the server's, which quote what they were given:
#
#   1. dbi_to_conninfo reads 'dbi:mysql:<parameters>' and 'dbi:MariaDB:...'
#      and nothing else, and says so naming the DSN it got. A DSN is where a
#      password is written -- as password=, as DBI's Password attribute,
#      inside a URI;
#   2. through a schema that is the first ->async of a connection whose DBI
#      half may connect fine: DBI takes attributes in front of the parameters
#      ('dbi:mysql(RaiseError=>1):...'), this transport does not;
#   3. an AccessBroker's DBI-form answer with such a DSN is refused naming the
#      DBI driver -- and what stands between 'dbi:' and the next ':' is not
#      only a driver name: DBI reads attributes there, Password among them;
#   4. what an EV::MariaDB handle reports through on_error is the client
#      library's text, or the server's: the socket it cannot open, the host it
#      cannot resolve, the database the server does not know -- each quoted as
#      it was given, and a DSN with a separator gone wrong puts password=...
#      into one of them. That text fails the acquire of a pooled statement and
#      the open of the listen connection, and goes into the pool's warning. It
#      is masked where the handle is made, for the pool's connections and the
#      listen connection alike;
#   5. the seam itself: on_error's text with the password masked and its other
#      arguments as they came, a text without a password unchanged, and the
#      croak of the constructor rethrown masked.
#
# The claim each time: the password is not in the message, and the rest is --
# a message that says nothing would hide the password as well.
#
# WHAT RUNS FOR REAL: everything -- core's storage, pool and broker seams,
# this dist's Storage, Pool and ConnectInfo, EV::MariaDB and the client
# library. Nothing is connected: the handles of section 4 are given a unix
# socket in a directory that does not exist, which the client library refuses
# at once, and those of section 5 neither a host nor a user, so they start no
# connect at all. THE ONE SUBSTITUTION is in section 5, for the constructor's
# croak: EV::MariaDB 0.08 croaks naming argument names only, so a stand-in
# constructor croaks quoting what it was given.

use EV;
use EV::MariaDB;
use DBIO::AccessBroker;
use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::Pool;
use DBIO::MySQL::EV::ConnectInfo 'dbi_to_conninfo';

$SIG{ALRM} = sub { BAIL_OUT('t/40-no-password-in-messages-mock.t: alarm, a wait did not end') };
alarm 60;

my $EV     = 'DBIO::MySQL::EV::Storage';
my $SECRET = 'hunter2';

# A broker answering whatever the test puts in it.
{
  package AnswerBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

{
  package PlainSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');
}

# ---------------------------------------------------------------------------
# 1. A DSN dbi_to_conninfo does not read is named without its password.
# ---------------------------------------------------------------------------

for my $case (
  [ 'password= in a DSN with DBI attributes in front',
    [ "dbi:mysql(RaiseError=>1):database=appdb;password=$SECRET;host=db.example" ],
    qr/dbi:mysql\(RaiseError=>1\):database=appdb;password=\*\*\*;host=db\.example/ ],
  [ 'a quoted password= with a blank and a semicolon in it',
    [ "dbi:Pg:dbname=appdb;password='hun;ter2 $SECRET';host=db.example", 'app', undef ],
    qr/dbi:Pg:dbname=appdb;password=\*\*\*;host=db\.example/ ],
  [ q{DBI's Password attribute in the DSN},
    [ "dbi:MariaDB(Username=>app,Password=>$SECRET):database=appdb" ],
    qr/dbi:MariaDB\(Username=>app,Password=\*\*\*/ ],
  [ 'a URI behind another driver name',
    [ "dbi:Proxy:mysql://app:$SECRET\@db.example/appdb" ],
    qr{dbi:Proxy:mysql://app:\*\*\*\@db\.example/appdb} ],
  # The password beside the DSN is not in the message unless the DSN repeats
  # it -- under a key nothing would take for a password's.
  [ 'the password beside the DSN, repeated in it under another key',
    [ "dbi:Pg:dbname=appdb;token=$SECRET;host=db.example", 'app', $SECRET ],
    qr/dbi:Pg:dbname=appdb;token=\*\*\*;host=db\.example/ ],
  [ 'no DSN at all, a password beside it',
    [ undef, 'app', $SECRET ],
    qr/\(undef\)/ ],
) {
  my ($label, $info, $named_re) = @$case;

  my $ok  = eval { dbi_to_conninfo($info); 1 };
  my $err = $@;
  ok !$ok, "$label: dbi_to_conninfo dies";
  like $err, qr/^expected dbi:mysql:\/dbi:MariaDB:\.\.\. DSN, got: /, '... saying what it reads and what it got';
  unlike $err, qr/\Q$SECRET\E|hun;ter2/, '... without the password';
  like $err, $named_re, '... and with the rest of the DSN: the driver and the form are still there to see';

  # The same through the transport, which hands it every 'dbi:' connect info.
  next unless defined $info->[0];
  $ok  = eval { $EV->new(undef)->connect_info($info); 1 };
  $err = $@;
  ok !$ok, '... the transport refuses it as connect info';
  unlike $err, qr/\Q$SECRET\E|hun;ter2/, '... without the password';
  like $err, $named_re, '... and with the rest of the DSN';
}

{
  # What is no password stays: masking must not make the message useless.
  my $ok  = eval { dbi_to_conninfo([ 'dbi:Pg:dbname=appdb;host=db.example;user=app', 'app', undef ]); 1 };
  my $err = $@;
  ok !$ok, 'a DSN without a password: dbi_to_conninfo dies';
  is $err, "expected dbi:mysql:/dbi:MariaDB:... DSN, got: dbi:Pg:dbname=appdb;host=db.example;user=app\n",
    '... quoting it whole';
}

# ---------------------------------------------------------------------------
# 2. Through a schema: the first ->async.
# ---------------------------------------------------------------------------

{
  my $dsn    = "dbi:mysql(RaiseError=>1):database=appdb;host=db.example;password=$SECRET";
  my $schema = PlainSchema->connect($dsn, 'app', undef, { async => 'ev' });
  my $async  = eval { $schema->storage->async };
  my $err    = "$@";
  ok !$async, 'a dbi:mysql(...): DSN through a schema: the first ->async refuses it';
  like $err, qr/expected dbi:mysql:\/dbi:MariaDB:\.\.\. DSN, got: /, '... saying what the transport reads';
  unlike $err, qr/\Q$SECRET\E/, '... without the password in the DSN';
  like $err, qr/dbi:mysql\(RaiseError=>1\):database=appdb;host=db\.example;password=\*\*\*/,
    '... and with the rest of it';
}

# ---------------------------------------------------------------------------
# 3. A broker's DBI-form answer: the driver it names.
# ---------------------------------------------------------------------------

for my $case (
  [ q{DBI's Password attribute in front of the parameters},
    [ "dbi:mysql(Username=>app,Password=>$SECRET):database=appdb", undef, undef, {} ],
    qr/\(DBI driver 'mysql'\)/ ],
  [ 'a DSN with no colon behind the driver before its password',
    [ "dbi:MariaDB;database=appdb;password=$SECRET;host=[::1]", 'app', undef, {} ],
    qr/\(DBI driver 'MariaDB'\)/ ],
  [ 'another driver',
    [ "dbi:Pg:dbname=appdb;password=$SECRET", 'app', $SECRET, {} ],
    qr/\(DBI driver 'Pg'\)/ ],
) {
  my ($label, $answer, $driver_re) = @$case;

  my $ok  = eval { $EV->new(undef)->connect_info([ AnswerBroker->new($answer) ]); 1 };
  my $err = $@;
  ok !$ok, "a broker answering $label: attaching it croaks";
  like $err, qr/a DBI-form arrayref whose DSN is not dbi:mysql:<parameters> or dbi:MariaDB:<parameters>/,
    '... naming the shape';
  like $err, $driver_re, '... and the DBI driver';
  unlike $err, qr/\Q$SECRET\E/, '... never the password';
}

# ---------------------------------------------------------------------------
# 4. What a handle reports about its connection.
# ---------------------------------------------------------------------------

# How a pool spawn and a listen open end on this storage: the error of each,
# and the pool's warnings. A connect that is refused at once is reported from
# inside the constructor; one that is not is waited for, bounded.
sub connection_errors {
  my ($s) = @_;
  my (%err, @warned);
  local $SIG{__WARN__} = sub { push @warned, @_ };
  my $settled = sub {
    my ($f) = @_;
    my $late  = 0;
    my $timer = EV::timer(10, 0, sub { $late = 1 });
    EV::run(EV::RUN_ONCE) until $f->is_ready || $late;
    return $f->is_failed ? ($f->failure)[0] : $f->is_ready ? 'no error' : 'it did not settle';
  };
  $err{pool}   = eval { $settled->($s->pool->acquire) } // $@;
  $err{listen} = eval { $settled->($s->_listen_open) } // $@;
  $err{warned} = join '', @warned;
  return \%err;
}

{
  # The directory does not exist, so the client library refuses the connect
  # at once and nothing is sent anywhere. Its message quotes the socket as it
  # was given -- here with what a DSN with a separator gone wrong leaves in
  # it: 'dbi:mysql:database=appdb;mysql_socket=/run/mysqld.sock,password=...'
  # for the ';' that was meant.
  my $socket = "/nonexistent/dbio-k76/mysqld.sock,password=$SECRET";
  my %named  = (host => 'localhost', user => 'app', password => $SECRET, unix_socket => $socket);

  my @raw;
  my $mdb = EV::MariaDB->new(%named, on_error => sub { push @raw, $_[0] });
  like $raw[0] // '', qr/\Q$SECRET\E/,
    'the client library quotes the socket it cannot open, as given: what must not be passed on'
    or diag 'it reported: ' . ($raw[0] // 'nothing');
  $mdb->finish;

  for my $case (
    [ 'static connect info', [ { %named }, {} ] ],
    [ 'a broker\'s answer',  [ AnswerBroker->new({ %named }) ] ],
  ) {
    my ($label, $info) = @$case;
    my $s = $EV->new(undef);
    ok eval { $s->connect_info($info); 1 }, "that socket as $label: it is taken, nothing has read it yet"
      or diag $@;

    my $err = connection_errors($s);
    for my $what (qw( pool listen )) {
      like $err->{$what}, qr/through socket/, "$label, $what: opening a connection fails with the client library's words";
      unlike $err->{$what}, qr/\Q$SECRET\E/, '... without the password';
      like $err->{$what}, qr{'/nonexistent/dbio-k76/mysqld\.sock,password=\*\*\*},
        '... and with the rest of what it quotes';
    }
    like $err->{warned}, qr/DBIO::MySQL::EV pool error: .*through socket/, "$label: the pool warns about it";
    unlike $err->{warned}, qr/\Q$SECRET\E/, '... and no warning carries the password either';
    eval { $s->disconnect };
  }
}

# ---------------------------------------------------------------------------
# 5. The seam: where every handle is made.
# ---------------------------------------------------------------------------

{
  # A handle given neither a host nor a user starts no connect; its on_error
  # is called by hand, with a text as the server writes one.
  my $text = qq{Unknown database 'appdb&password=$SECRET'};
  my $want = qq{Unknown database 'appdb&password=***};

  my @listen_got;
  my $listen_mdb = DBIO::MySQL::EV::Pool->_mysql_new_handle(on_error => sub { push @listen_got, [ @_ ] });
  $listen_mdb->on_error->($text, 'second argument');
  is_deeply \@listen_got, [ [ $want, 'second argument' ] ],
    'a handle made as the listen connection\'s is: its on_error gets the text with the password masked, '
  . 'and what else it was called with';
  $listen_mdb->finish;

  my (@pool_got, @ready_got);
  my $pool = DBIO::MySQL::EV::Pool->new(
    conninfo => { host => 'never used' }, size => 1, on_error => sub { push @pool_got, @_ },
  );
  my $pool_mdb = $pool->_new_connection(on_error => sub { push @ready_got, @_ });
  $pool_mdb->on_error->($text);
  is_deeply \@ready_got, [ $want ],
    'a pooled handle: the same, for what core fails the connection\'s Future with';
  $pool_mdb->finish;
  $pool->shutdown;

  # Nothing to mask: the text is handed on as it came -- 'using password: YES'
  # names no password.
  my @plain;
  my $mdb = DBIO::MySQL::EV::Pool->_mysql_new_handle(on_error => sub { push @plain, @_ });
  $mdb->on_error->(q{Access denied for user 'app'@'db.example' (using password: YES)});
  is_deeply \@plain, [ q{Access denied for user 'app'@'db.example' (using password: YES)} ],
    'a message without a password is handed on unchanged';
  $mdb->finish;
}

{
  # The constructor's croak. EV::MariaDB 0.08 names argument names only, so
  # nothing of it needs masking today; what is held is that a croak passes
  # through the same seam, should a later one quote what it was given.
  no warnings 'redefine';
  local *EV::MariaDB::new = sub {
    my ($class, %args) = @_;
    die "cannot connect as $args{user} with $args{password} (password=$args{password};host=$args{host})\n";
  };

  my $ok  = eval { DBIO::MySQL::EV::Pool->_mysql_new_handle(host => 'db.example', user => 'app', password => $SECRET); 1 };
  my $err = $@;
  ok !$ok, 'a constructor that croaks: the croak is rethrown';
  is $err, "cannot connect as app with *** (password=***;host=db.example)\n",
    '... with the password the handle was given masked wherever the text repeats it, and the rest as it came';

  my $object = bless {}, 'SomeException';
  local *EV::MariaDB::new = sub { die $object };
  $ok = eval { DBIO::MySQL::EV::Pool->_mysql_new_handle(host => 'db.example', password => $SECRET); 1 };
  ok !$ok && ref $@ && $@ == $object, 'an exception that is no string is rethrown as it came';
}

done_testing;
