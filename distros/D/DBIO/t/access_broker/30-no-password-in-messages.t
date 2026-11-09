# ABSTRACT: No message about a connection quotes its password
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Util ();
use DBIO::Storage::DBI;
use DBIO::AccessBroker;
use DBIO::Replicated::Pool;
use DBIO::Replicated::Balancer;
use DBIO::Replicated::Backend::Master;
use DBIO::Replicated::Backend::Replicant;
use DBIO::Replicated::DebugProxy;
use DBIO::Deploy::Base::TempDatabase;

# OFFLINE (karr k297; maintainer's decision 2026-10-06). An AccessBroker that
# answers every storage [ 'host=... password=...' ] -- the form an ev transport
# takes -- is an answer the sync owner's DBI->connect dies of. That is as it
# should be, and stays so: the answer is not refused earlier and not
# translated. But DBI dies quoting the data source it could not use, the
# storage hands that text on as "DBI Connection failed: ...", and the password
# stood in the error in the clear (seen live, dbio-postgresql-ev k59).
#
# The decision: a message never quotes credentials. The password is masked at
# every place that writes connect info into a message -- an exception, a
# warning, a trace line, a diagnostic structure. It hangs on the message, not
# on the broker: static connect info is masked the same way.
#
# What this file claims:
#   1. DBIO::Util::mask_connect_secrets is the one place that knows how: it
#      replaces the VALUE of a password with '***' and leaves the key, the user
#      name and the rest of the text standing, so the message stays usable. A
#      password the connect info names is masked as a whole wherever the text
#      repeats it (karr k314) -- whatever stands around it, and whatever it
#      has in it that would end a value found by its key.
#   2. A connection DBI->connect dies of -- no driver in the data source, a
#      driver that refuses -- throws without the password: not the one inside
#      the data source, not the password argument, not a Password attribute,
#      even where the DBD repeats them in its own error text. With a broker and
#      without, in every connect-info form.
#   3. The warning about a driver that cannot be determined, and the
#      description of the connection it dumps (_describe_connection), carry no
#      password.
#   4. DBIO::Replicated does not write one into the trace: not when a replicant
#      fails to connect, not as the [DSN_...=...] prefix of a traced statement,
#      not when naming a replicant that does not exist.
#   5. DBIO::Deploy::Base::TempDatabase, which calls DBI->connect itself, dies
#      without one.
#   6. DBIO::Test::Util's connect trace (DBIO_TEST_DEBUG_CONCURRENCY_LOCKS)
#      prints none.
#
# THE SUBSTITUTIONS: none for DBI itself -- DBI->connect is the real one, and
# for the card's own case nothing else is involved: DBI dies working out the
# driver, before any database could be asked. Where a driver has to load and
# then refuse, it is DBD::K297Refuse below, a DBD of this file whose connect
# always fails and repeats everything it was given in its error text -- the
# worst a real DBD or server could do. One storage (T::NamesItsDSN) answers
# get_info in the place of a connected handle; the trace objects are
# recorders. No database is involved anywhere, and no real password: the
# secrets are marker strings.

delete @ENV{qw( DBI_DSN DBI_DRIVER DBI_AUTOPROXY )};

# A DBD that refuses every connection and says what it was asked with.
{
  package DBD::K297Refuse;
  our $drh;
  sub driver {
    return $drh ||= DBI::_new_drh("$_[0]::dr", { Name => 'K297Refuse', Version => '0.01' });
  }

  package DBD::K297Refuse::dr;
  our $imp_data_size = 0;
  our $SAYS = 'refused [%s] [%s] [%s]';
  sub connect {
    my ($drh, $dsn, $user, $auth) = @_;
    $drh->set_err(1, sprintf $SAYS, map { $_ // '' } $dsn, $user, $auth);
    return;
  }

  package DBD::K297Refuse::db;
  our $imp_data_size = 0;

  package DBD::K297Refuse::st;
  our $imp_data_size = 0;
}
$INC{'DBD/K297Refuse.pm'} = __FILE__;

# A broker answering whatever it was built with.
{
  package T::AnswerBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]->{answer} }
}

# A trace object that keeps what it is given.
{
  package T::Trace;
  sub new         { bless { printed => [], started => [] }, shift }
  sub print       { push @{ $_[0]->{printed} }, $_[1] }
  sub query_start { push @{ $_[0]->{started} }, $_[1] }
  sub query_end   { }
}

# The secrets. Each stands in one place only, so a leak names where it came from.
my $IN_DSN  = 'k297-secret-in-the-dsn';
my $AS_ARG  = 'k297-secret-as-argument';
my $AS_ATTR = 'k297-secret-as-attribute';
my $SECRET  = qr/k297-secret/;

my $USER    = 'k297-user';
my $LIBPQ   = "host=db.example dbname=app user=$USER password=$IN_DSN";
my $REFUSED = "dbi:K297Refuse:dbname=app;password=$IN_DSN;host=db.example";

# ---------------------------------------------------------------------------
# 1. The masking itself.
# ---------------------------------------------------------------------------
my @MASKED = (
  # [ what, text, connect info or undef, the text as a message may show it ]
  [ 'a libpq keyword/value string',
    'host=db.example dbname=app user=app password=s3cret sslmode=require', undef,
    'host=db.example dbname=app user=app password=*** sslmode=require' ],
  [ 'a quoted libpq value, spaces and an escaped quote in it',
    q{host=h password='two wo\\'rds' dbname=app}, undef,
    'host=h password=*** dbname=app' ],
  [ 'a double-quoted value',
    'password="two words" host=h', undef,
    'password=*** host=h' ],
  [ 'spaces around the equals sign',
    'host=h password = s3cret dbname=app', undef,
    'host=h password = *** dbname=app' ],
  [ 'a DSN part',
    'dbi:mysql:database=app;password=s3cret;host=h', undef,
    'dbi:mysql:database=app;password=***;host=h' ],
  [ 'the last DSN part',
    'dbi:mysql:database=app;host=h;password=s3cret', undef,
    'dbi:mysql:database=app;host=h;password=***' ],
  [ 'ODBC PWD, upper case',
    'dbi:ODBC:DSN=app;UID=app;PWD=s3cret;APP=x', undef,
    'dbi:ODBC:DSN=app;UID=app;PWD=***;APP=x' ],
  [ 'ODBC pwd, lower case, value in braces',
    'dbi:ODBC:DSN=app;pwd={s3;cr}}et};uid=app', undef,
    'dbi:ODBC:DSN=app;pwd=***;uid=app' ],
  [ 'pass and passwd',
    'dbi:X:db=app;pass=s3cret;passwd=s3cret2', undef,
    'dbi:X:db=app;pass=***;passwd=***' ],
  [ 'a key that ends in a password word',
    'host=h sslpassword=s3cret NEWPWD=s3cret2 mysql_ssl_pass=s3cret3', undef,
    'host=h sslpassword=*** NEWPWD=*** mysql_ssl_pass=***' ],
  [ 'mixed case keys',
    'Password=s3cret;PassWord=s3cret2', undef,
    'Password=***;PassWord=***' ],
  [ 'the password of a URI',
    'postgresql://app:s3cret@db.example:5432/app?sslmode=require', undef,
    'postgresql://app:***@db.example:5432/app?sslmode=require' ],
  [ 'the password of a URI, an @ in it',
    'mysql://app:s3@cret@db.example/app', undef,
    'mysql://app:***@db.example/app' ],
  [ 'a URI with a password and no user',
    'redis://:s3cret@cache.example', undef,
    'redis://:***@cache.example' ],
  [ 'a password in the query of a URI',
    'postgresql://db.example/app?user=app&password=s3cret', undef,
    'postgresql://db.example/app?user=app&password=***' ],
  [ 'a dumped hash',
    q[{ dsn => "dbi:Pg:dbname=app", password => "s3cret", user => "app" }], undef,
    q[{ dsn => "dbi:Pg:dbname=app", password =***, user => "app" }] ],
  [ 'a dumped hash, the key quoted',
    q[{ 'password' => 's3 cret', 'user' => 'app' }], undef,
    q[{ 'password' =***, 'user' => 'app' }] ],
  [ 'a value starting with a > keeps nothing of itself',
    'host=h password=>s3cret dbname=app', undef,
    'host=h password=*** dbname=app' ],
  [ 'the text DBI dies with, quoting a data source without a driver',
    "Can't connect to data source 'host=h user=app password=s3cret' because I can't work out what driver to use",
    [ 'host=h user=app password=s3cret' ],
    "Can't connect to data source 'host=h user=app password=***' because I can't work out what driver to use" ],
  [ 'the text DBI dies with, quoting the data source after the driver',
    "DBI connect('dbname=app;password=s3cret','app',...) failed: no route to host",
    [ 'dbi:Pg:dbname=app;password=s3cret', 'app' ],
    "DBI connect('dbname=app;password=***','app',...) failed: no route to host" ],
  [ 'a password with spaces in the DSN of the connect info',
    "DBI connect('dbname=app;password=two words;host=h','app',...) failed: refused",
    [ 'dbi:mysql:dbname=app;password=two words;host=h', 'app' ],
    "DBI connect('dbname=app;password=***;host=h','app',...) failed: refused" ],
  # Without the connect info nothing says where a value ends: it runs to the
  # next whitespace or ';', and what closed the DSN in the text goes with it.
  [ 'the text DBI dies with, the connect info not at hand',
    "DBI connect('dbname=app;password=s3cret','app',...) failed: no route to host", undef,
    "DBI connect('dbname=app;password=*** failed: no route to host" ],
  # ... and so where the text quotes another DSN, one that only starts like
  # the one at hand: masked as the one at hand, the rest of its password
  # would stay.
  [ 'a text quoting a longer DSN than the one in the connect info',
    "DBI connect('dbname=app;password=s3cret-and-more','app',...) failed: no route to host",
    [ 'dbi:Pg:dbname=app;password=s3cret', 'app' ],
    "DBI connect('dbname=app;password=*** failed: no route to host" ],
  [ 'the password argument, wherever the text repeats it',
    'login failed for app using s3cret (s3cret)', [ 'dbi:Pg:dbname=app', 'app', 's3cret' ],
    'login failed for app using *** (***)' ],
  [ 'a Password among the DBI attributes',
    'login failed for app using s3cret', [ 'dbi:Pg:dbname=app', 'app', undef, { Password => 's3cret' } ],
    'login failed for app using ***' ],
  [ 'a password argument that is part of the DSN (Oracle user/password@db)',
    "DBI connect('app/s3cret\@db','',...) failed", [ 'dbi:Oracle:app/s3cret@db', '', 's3cret' ],
    "DBI connect('app/***\@db','',...) failed" ],
);

for my $case (@MASKED) {
  my ($what, $text, $info, $shown) = @$case;
  lives_and { is DBIO::Util::mask_connect_secrets($text, $info), $shown } "masked: $what";
}

# A password the connect info names (karr k314). Where a text names it by a
# key, the key alone says where the value starts, and it is guessed to end at
# the next whitespace or ';' -- which a password may have in it. The password
# argument was looked for after that, in a text that no longer had it whole,
# and its rest stood in the message. What is known is masked where it stands,
# and a value goes on through it.
my $APP = 'dbi:Pg:dbname=app';
my @KNOWN = (
  # [ what, text, connect info, the text as a message may show it ]
  [ 'with spaces in it, behind password= at the end of the text',
    'FATAL: no login with dbname=app user=app password=two words', [ $APP, 'app', 'two words' ],
    'FATAL: no login with dbname=app user=app password=***' ],
  [ 'with spaces in it, behind password= and more of the text after it',
    'conninfo was password=two words dbname=app', [ $APP, 'app', 'two words' ],
    'conninfo was password=*** dbname=app' ],
  [ 'with spaces in it, as a Password attribute',
    'conninfo was password=two words dbname=app', [ $APP, 'app', undef, { Password => 'two words' } ],
    'conninfo was password=*** dbname=app' ],
  [ 'with spaces in it, behind PWD=',
    'dbi:ODBC:DSN=app;UID=app;PWD=two words;APP=x', [ $APP, 'app', 'two words' ],
    'dbi:ODBC:DSN=app;UID=app;PWD=***;APP=x' ],
  # a value without quotes runs to the next whitespace: the comma goes with it
  [ 'with spaces in it, behind password => without quotes',
    'connect( dsn => dbi:Pg:dbname=app, password => two words, user => app )', [ $APP, 'app', 'two words' ],
    'connect( dsn => dbi:Pg:dbname=app, password =*** user => app )' ],
  [ 'with spaces in it, in a DSN that is not the one of the connect info',
    "DBI connect('database=other;password=two words;host=h','app',...) failed", [ $APP, 'app', 'two words' ],
    "DBI connect('database=other;password=***;host=h','app',...) failed" ],
  [ 'with a ; in it, in a DSN that is not the one of the connect info',
    "DBI connect('database=other;password=s3;cret;host=h','app',...) failed", [ $APP, 'app', 's3;cret' ],
    "DBI connect('database=other;password=***;host=h','app',...) failed" ],
  [ 'with a ; in it, in the DSN of the connect info',
    "DBI connect('dbname=app;password=s3;cret;host=h','app',...) failed",
    [ 'dbi:mysql:dbname=app;password=s3;cret;host=h', 'app', 's3;cret' ],
    "DBI connect('dbname=app;password=***;host=h','app',...) failed" ],
  [ 'with spaces in it, as the password of a URI',
    'tried postgresql://app:two words@db.example/app', [ $APP, 'app', 'two words' ],
    'tried postgresql://app:***@db.example/app' ],
  # ... and nothing of a value is shown for it that was not shown before
  [ 'a value that only starts with the password',
    'password=two wordsANDMORE host=h', [ $APP, 'app', 'two words' ],
    'password=*** host=h' ],
  [ 'a quoted value with the password in it',
    q{password='x two words y' host=h}, [ $APP, 'app', 'two words' ],
    'password=*** host=h' ],
  [ 'a quoted value, the password being its quote and its first character',
    q{password='a b c' host=h}, [ $APP, 'app', q{'a} ],
    'password=*** host=h' ],
  [ 'nothing but the password behind the key: one mask',
    'password=two words', [ $APP, 'app', 'two words' ],
    'password=***' ],
  [ 'a password starting with what ends a value: one mask',
    'password=;abc', [ $APP, 'app', ';abc' ],
    'password=***' ],
  # two passwords: the argument and a Password attribute
  [ 'two passwords overlapping in the text',
    'login abcdef failed', [ $APP, 'app', 'abcd', { Password => 'cdef' } ],
    'login *** failed' ],
  [ 'a password overlapping itself in the text',
    'login ababa failed', [ $APP, 'app', 'aba' ],
    'login *** failed' ],
  [ 'two passwords side by side: two masks',
    'login abcdcdef failed', [ $APP, 'app', 'abcd', { Password => 'cdef' } ],
    'login ****** failed' ],
  # The DSN of the connect info is masked on its own where the text quotes it.
  # Not where the password goes across its border: there the DSN is text.
  [ 'the end of the quoted DSN and what the text goes on with',
    "DBI connect('password=s3cret;host=db','app',...) failed",
    [ 'dbi:mysql:password=s3cret;host=db', 'app', q{db','app} ],
    "DBI connect('password=***;host=***',...) failed" ],
  [ 'what the text has before the quoted DSN and its start',
    "DBI connect('password=s3cret;host=db','app',...) failed",
    [ 'dbi:mysql:password=s3cret;host=db', 'app', q{connect('pass} ],
    "DBI ***word=***;host=db','app',...) failed" ],
);

for my $case (@KNOWN) {
  my ($what, $text, $info, $shown) = @$case;
  lives_and { is DBIO::Util::mask_connect_secrets($text, $info), $shown } "masked, a known password: $what";
}

# What it leaves alone. A masker that rewrites everything would pass every
# "no secret in it" test in this file.
my @UNTOUCHED = (
  [ 'a text without credentials',
    'FATAL: password authentication failed for user "app"', undef ],
  [ 'a DSN without a password',
    'dbi:Pg:dbname=app;host=db.example;port=5432', [ 'dbi:Pg:dbname=app;host=db.example;port=5432', 'app', 's3cret' ] ],
  [ 'the user name',
    "DBI connect('dbname=app','app',...) failed: role \"app\" does not exist", [ 'dbi:Pg:dbname=app', 'app', 's3cret' ] ],
  [ 'a URI without a password',
    'see https://db.example:5432/app for app@db.example', undef ],
  [ 'a key that only starts like a password',
    'passfile=/home/app/.pgpass password_file=/run/secrets/db', undef ],
  [ 'an empty password argument', 'no password given', [ 'dbi:Pg:dbname=app', 'app', '' ] ],
  [ 'an undefined password argument', 'no password given', [ 'dbi:Pg:dbname=app', 'app', undef ] ],
);

for my $case (@UNTOUCHED) {
  my ($what, $text, $info) = @$case;
  lives_and { is DBIO::Util::mask_connect_secrets($text, $info), $text } "left as it is: $what";
}

lives_and { is DBIO::Util::mask_connect_secrets(undef), undef } 'left as it is: undef';
{
  my $code = sub { 1 };
  lives_and { is DBIO::Util::mask_connect_secrets($code, [ $code ]), $code }
    'left as it is: a reference (a connection coderef in the place of a DSN)';
}

# ---------------------------------------------------------------------------
# 2. A connection DBI->connect dies of.
# ---------------------------------------------------------------------------
# The connect info of one failure, in every form a storage takes it. The same
# connection each time: [ $dsn, $user, $password, \%attrs ].
sub connect_forms {
  my ($dsn, $user, $password, $attrs) = @_;
  my @dbi = ($dsn, $user, $password, $attrs ? $attrs : ());
  my %hash = (dsn => $dsn, %{ $attrs || {} });
  $hash{user}     = $user     if defined $user;
  $hash{password} = $password if defined $password;

  return (
    'static, the DBI form'       => [ @dbi ],
    'static, a hash'             => [ { %hash } ],
    'a broker, the DBI form'     => [ T::AnswerBroker->new([ @dbi ]) ],
    'a broker, a hash'           => [ T::AnswerBroker->new({ %hash }) ],
    'a broker through HostBound' => [ T::AnswerBroker->new({ %hash })->for_host('db.example') ],
  );
}

# -- the card's case: a libpq string where a DSN belongs --------------------
{
  my %forms = connect_forms($LIBPQ);
  # as dbio-postgresql-ev k59 saw it: the one-element answer, no user, no password
  $forms{'a broker, the answer an ev transport takes'} = [ T::AnswerBroker->new([ $LIBPQ ]) ];
  delete $forms{'a broker through HostBound'};   # the view rewrites no libpq string; nothing of its own to see

  for my $form (sort keys %forms) {
    my $storage = DBIO::Storage::DBI->new(undef);
    lives_ok { $storage->connect_info($forms{$form}) } "libpq string, $form: connect_info takes it";

    for my $how (qw( ensure_connected dbh _connect )) {
      throws_ok { $storage->$how }
        qr/DBI Connection failed: Can't connect to data source .* because I can't work out what driver to use/,
        "libpq string, $form, $how: still dies of DBI not finding a driver";
      unlike "$@", $SECRET, "libpq string, $form, $how: ... without the password";
      like "$@", qr/'host=db\.example dbname=app user=\Q$USER\E password=\*\*\*'/,
        "libpq string, $form, $how: ... the key, the user and the rest of the data source stand";
    }
  }
}

# -- a driver that refuses, and repeats what it was given -------------------
{
  my %forms = connect_forms($REFUSED, $USER, $AS_ARG, { Password => $AS_ATTR });

  for my $form (sort keys %forms) {
    my $storage = DBIO::Storage::DBI->new(undef);
    lives_ok { $storage->connect_info($forms{$form}) } "refusing driver, $form: connect_info takes it";

    throws_ok { $storage->ensure_connected }
      qr/DBI Connection failed: DBI connect\('dbname=app;password=\*\*\*;host=db\.example','\Q$USER\E',\.\.\.\) failed: refused/,
      "refusing driver, $form: dies of the refusal, the data source masked, the user standing";
    unlike "$@", $SECRET,
      "refusing driver, $form: ... no password of the three, not even where the driver repeats them";
  }
}

# -- a driver that names the password by a key -------------------------------
# Spaces in the password argument: the key says where it starts, nothing in
# the text says where it ends -- the connect info does.
{
  local $DBD::K297Refuse::dr::SAYS = 'refused %s for user=%s password=%s';
  my $dsn   = 'dbi:K297Refuse:dbname=app;host=db.example';
  my %forms = connect_forms($dsn, $USER, 'k297-secret one k297-secret two');

  for my $form (sort keys %forms) {
    my $storage = DBIO::Storage::DBI->new(undef);
    $storage->connect_info($forms{$form});
    throws_ok { $storage->ensure_connected }
      qr/DBI Connection failed: DBI connect\(.* failed: refused dbname=app;host=db\.example for user=\Q$USER\E password=\*\*\* at /,
      "driver naming the password by a key, $form: dies of the refusal, the key and the user standing";
    unlike "$@", $SECRET, "driver naming the password by a key, $form: ... neither word of the password";
  }
}

# -- a password with spaces in it, in a DSN ----------------------------------
{
  my $dsn = "dbi:K297Refuse:dbname=app;password=k297-secret one k297-secret two;host=db.example";
  my %forms = connect_forms($dsn, $USER);

  for my $form (sort keys %forms) {
    my $storage = DBIO::Storage::DBI->new(undef);
    $storage->connect_info($forms{$form});
    throws_ok { $storage->ensure_connected } qr/DBI Connection failed: DBI connect\('dbname=app;password=\*\*\*;host=db\.example'/,
      "password with spaces in the DSN, $form: dies of the refusal";
    unlike "$@", $SECRET, "password with spaces in the DSN, $form: ... neither word of it";
  }
}

# -- a driver that is not installed (control: DBI never quoted this one) ----
{
  my %forms = connect_forms("dbi:NoSuchDriverK297:dbname=app;password=$IN_DSN", $USER, $AS_ARG);

  for my $form (sort keys %forms) {
    my $storage = DBIO::Storage::DBI->new(undef);
    $storage->connect_info($forms{$form});
    throws_ok { $storage->_connect } qr/DBI Connection failed: install_driver\(NoSuchDriverK297\) failed/,
      "driver not installed, $form: dies of the missing driver";
    unlike "$@", $SECRET, "driver not installed, $form: ... without a password";
  }
}

# -- a connection coderef that dies of its own DBI->connect ------------------
{
  for my $form (
    [ 'a coderef'     => [ sub { DBI->connect($REFUSED, $USER, undef, { RaiseError => 1, PrintError => 0 }) } ] ],
    [ 'a dbh_maker'   => [ { dbh_maker => sub { DBI->connect($REFUSED, $USER, undef, { RaiseError => 1, PrintError => 0 }) } } ] ],
  ) {
    my ($name, $info) = @$form;
    my $storage = DBIO::Storage::DBI->new(undef);
    $storage->connect_info($info);
    throws_ok { $storage->_connect } qr/DBI Connection failed: DBI connect\(.*failed: refused/,
      "$name dying of its own DBI->connect: dies of the refusal";
    unlike "$@", $SECRET, "$name dying of its own DBI->connect: ... without the password in its data source";
  }
}

# ---------------------------------------------------------------------------
# 3. The driver that cannot be determined, and the connection described.
# ---------------------------------------------------------------------------
for my $form (
  [ 'static'   => 'db-static.example', sub { [ @_ ] } ],
  [ 'a broker' => 'db-broker.example', sub { [ T::AnswerBroker->new([ @_ ]) ] } ],
) {
  my ($name, $host, $as) = @$form;

  # Each form its own host, so the description names which one it is.
  my $libpq = "host=$host dbname=app user=$USER password=$IN_DSN";
  my $info  = $as->($libpq, $USER, $AS_ARG);

  # The generic storage has no driver and none is guessed from the DSN
  # (ADR 0067): asking it for what needs the driver is refused, and the
  # refusal quotes nothing of the connection.
  {
    my $storage = DBIO::Storage::DBI->new(undef);
    $storage->connect_info($info);

    my @warnings;
    {
      local $SIG{__WARN__} = sub { push @warnings, @_ };
      throws_ok { $storage->sql_maker } qr/DBIO::Storage::DBI has no driver/,
        "undetermined driver, $name: asking for the SQL maker is refused";
    }
    unlike "$@", $SECRET, "undetermined driver, $name: ... without a password";
    unlike "$@", qr/\Q$host\E/, "undetermined driver, $name: ... and without the data source";
    unlike join('', @warnings), $SECRET, "undetermined driver, $name: ... nor in a warning";
  }

  {
    my $storage = DBIO::Storage::DBI->new(undef);
    $storage->connect_info($info);
    my $described = $storage->_describe_connection;
    is $described->{DBIO_DSN}, "host=$host dbname=app user=$USER password=***",
      "_describe_connection, $name: DBIO_DSN is the data source, masked";
    unlike DBIO::Util::dump_value($described), $SECRET, "_describe_connection, $name: no password anywhere in it";
  }
}

{
  my $code = sub { die "no connection in this test\n" };
  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ $code ]);
  is $storage->_describe_connection->{DBIO_DSN}, $code,
    '_describe_connection: a connection coderef is still described as the coderef';
}

# What the DBD says of itself is in the description too, and a DBD may name
# its data source by the DSN it was given (DBD::Pg does).
{
  package T::NamesItsDSN;
  use base 'DBIO::Storage::DBI';
  sub ensure_connected { 1 }
  sub _dbh_get_info {
    return $_[1] eq 'SQL_DATA_SOURCE_NAME' ? $_[0]->_dbi_connect_info->[0]
         : $_[1] eq 'SQL_DBMS_NAME'        ? 'K297'
         :                                   undef;
  }
}

{
  my $storage = T::NamesItsDSN->new(undef);
  $storage->connect_info([ "dbi:Pg:dbname=app;password=$IN_DSN;host=db.example", $USER, $AS_ARG ]);
  my $described = $storage->_describe_connection;
  is $described->{SQL_DATA_SOURCE_NAME}, 'dbi:Pg:dbname=app;password=***;host=db.example',
    '_describe_connection: the data source the DBD names is masked too';
  is $described->{SQL_DBMS_NAME}, 'K297', '_describe_connection: ... what else it says stands';
  unlike DBIO::Util::dump_value($described), $SECRET, '_describe_connection: ... no password anywhere in it';
}

# ---------------------------------------------------------------------------
# 4. DBIO::Replicated.
# ---------------------------------------------------------------------------
# -- a replicant that cannot connect ----------------------------------------
{
  my $trace   = T::Trace->new;
  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ $REFUSED, $USER, $AS_ARG ]);
  $storage->debugobj($trace);
  my $replicant = DBIO::Replicated::Backend::Replicant->new(storage => $storage);

  my $pool = DBIO::Replicated::Pool->new;
  ok !$pool->_safely_ensure_connected($replicant), 'replicant that cannot connect: reported as not connected';
  is scalar @{ $trace->{printed} }, 1, 'replicant that cannot connect: ... and traced once';
  like $trace->{printed}[0],
    qr/Exception trying to ->ensure_connected for replicant dbi:K297Refuse:dbname=app;password=\*\*\*;host=db\.example, error is /,
    'replicant that cannot connect: ... naming its data source, masked';
  unlike $trace->{printed}[0], $SECRET, 'replicant that cannot connect: ... without a password';
}

# -- the backend named in a traced statement --------------------------------
for my $case (
  [ 'the DSN the pool recorded'
    => { dsn => "dbi:Pg:dbname=app;password=$IN_DSN;host=replica.example" }, [ 'dbi:Pg:dbname=other', $USER, $AS_ARG ] ],
  [ 'the DSN of the storage'
    => {}, [ "dbi:Pg:dbname=app;password=$IN_DSN;host=replica.example", $USER, $AS_ARG ] ],
) {
  my ($name, $backend_args, $info) = @$case;

  my $trace   = T::Trace->new;
  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info($info);
  my $backend = DBIO::Replicated::Backend::Replicant->new(storage => $storage, %$backend_args);
  my $proxy   = DBIO::Replicated::DebugProxy->new(backend => $backend, target => $trace);

  $proxy->query_start('SELECT me.id FROM artist me');
  is $trace->{started}[0],
    'SELECT [DSN_REPLICANT=dbi:Pg:dbname=app;password=***;host=replica.example] me.id FROM artist me',
    "traced statement, $name: names the backend by its data source, masked";
  unlike $trace->{started}[0], $SECRET, "traced statement, $name: ... without a password";
}

# -- a replicant that does not exist ----------------------------------------
{
  my $master = DBIO::Replicated::Backend::Master->new(storage => DBIO::Storage::DBI->new(undef));
  my $balancer = DBIO::Replicated::Balancer->new(master => $master);
  $balancer->pool(DBIO::Replicated::Pool->new);

  # a replicant is named after its DSN, the part after dbi:Driver:
  throws_ok { $balancer->_get_forced_pool("dbname=app;password=$IN_DSN;host=replica.example") }
    qr/'dbname=app;password=\*\*\*;host=replica\.example' is not a named replicant/,
    'no such replicant: throws, naming what was asked for, masked';
  unlike "$@", $SECRET, 'no such replicant: ... without a password';
}

# ---------------------------------------------------------------------------
# 5. DBIO::Deploy::Base::TempDatabase.
# ---------------------------------------------------------------------------
{
  package T::ConnectInfoOnly;
  sub new          { my ($class, $info) = @_; bless { info => $info }, $class }
  sub storage      { $_[0] }
  sub connect_info { $_[0]->{info} }
  sub access_broker { undef }
  sub _dbi_connect_info {
    my @i = @{ $_[0]->{info} };
    return [ @i ] unless ref $i[0] eq 'HASH';
    return [ $i[0]{dsn}, $i[0]{user}, $i[0]{password}, {} ];
  }
}

for my $form (
  [ 'the DBI form' => [ $REFUSED, $USER, $AS_ARG ] ],
  [ 'a hash'       => [ { dsn => $REFUSED, user => $USER, password => $AS_ARG } ] ],
) {
  my ($name, $info) = @$form;
  my $deploy = DBIO::Deploy::Base::TempDatabase->new(schema => T::ConnectInfoOnly->new($info));

  throws_ok { $deploy->_deploy_and_introspect_temp('k297_tmp') }
    qr/DBI connect\('dbname=k297_tmp;password=\*\*\*;host=db\.example','\Q$USER\E',\.\.\.\) failed: refused/,
    "temp database, $name: dies of the refusal, the data source masked";
  unlike "$@", $SECRET, "temp database, $name: ... without a password";
}

# ---------------------------------------------------------------------------
# 6. DBIO::Test::Util's connect trace.
# ---------------------------------------------------------------------------
# The trace is installed when DBIO::Test::Util is loaded with the variable
# set, and it wraps DBI::connect for good: asked of another perl, so that this
# one keeps the DBI->connect everything above is about.
{
  local $ENV{DBIO_TEST_DEBUG_CONCURRENCY_LOCKS} = 1;
  local $ENV{K297_DSN} = $REFUSED;

  my $code = join ' ',
    'open STDERR, q{>&}, \*STDOUT or die $!;',
    'require DBIO::Test::Util;',
    'eval { DBI->connect($ENV{K297_DSN}, q{u}, undef, { PrintError => 0, RaiseError => 0 }) };',
    'print qq{\ndone\n};';

  open my $perl, '-|', $^X, (map { "-I$_" } grep { !ref } @INC), '-e', $code
    or die "cannot run $^X: $!";
  my $out = do { local $/; <$perl> };
  close $perl;

  like $out, qr/^done$/m, 'connect trace: the other perl ran to its end';
  like $out, qr/Connecting to dbi:K297Refuse:dbname=app;password=\*\*\*;host=db\.example/,
    'connect trace: names the data source, masked';
  unlike $out, $SECRET, 'connect trace: ... without a password';
}

done_testing;
