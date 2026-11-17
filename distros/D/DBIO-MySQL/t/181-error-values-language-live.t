use strict;
use warnings;
use Test::More;

# LIVE: the text of an error holds no bound value, whatever language the server
# reports in. MySQL and MariaDB word their messages in the language of the
# session (lc_messages): German "Doppelter Eintrag 'ab' für Schlüssel ...",
# French "Duplicata du champ 'ab' pour la clef ...". The English sentences the
# driver knows (t/179) do not match those, and a short value like 'ab' or 'xy' is
# below the length at which a bound value is looked for as it is, so it stood in
# the text. The driver masks by the error code of the server and the quote the
# server puts around a value, not by the wording; this test runs the real calls
# in each language and checks the exception for the value, for the key or column
# the reader needs, and for the quotes of the server.
# The language is set for the session (SET SESSION, never SET GLOBAL). Works in
# a database of its own, on MySQL and on MariaDB, through DBD::mysql and
# DBD::MariaDB, with client side and server side prepare, and over the future_io
# transport when it is installed.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use Time::HiRes ();

my $async = eval {
  require IO::Async::Loop;
  require Future::IO::Impl::IOAsync;
  Future::IO::Impl::IOAsync->import;
  require DBIO::MySQL::Storage::Async;
  1;
};

my $DB = "fw_lang_$$";
my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
my @schemas;
END {
  local ($@, $?);
  eval { $_->storage->disconnect } for @schemas;
  eval { drop_database() } if $raw;
}

unless (eval { drop_database(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own: $why";
}

my $dbd = $dsn =~ /\Adbi:(\w+):/i ? lc $1 : 'mysql';

$raw->do(<<"SQL");
CREATE TABLE `$DB`.fw_lang (
  id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(40) NULL,
  n INT NULL,
  d DATE NULL,
  PRIMARY KEY (id),
  UNIQUE KEY fw_lang_u (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
SQL

# language => [ word of the server's duplicate-entry message in it, as proof that
# the session really reports in that language ]
my %language = (
  en_US => qr/\ADuplicate entry/,
  de_DE => qr/\ADoppelter Eintrag/,
  fr_FR => qr/\ADuplicata du champ/,
);

my $n = 0;
sub connect_schema {
  my ($lang, %attrs) = @_;
  my $class = 'FwLang::Schema' . ++$n;
  eval "package $class; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  my $rc = "$class\::Result::Lang";
  eval "package $rc; use DBIO 'Core', -mysql; 1" or die $@;
  $rc->table('fw_lang');
  $rc->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 40, is_nullable => 1 },
    n    => { data_type => 'integer', is_nullable => 1 },
    d    => { data_type => 'date', is_nullable => 1 },
  );
  $rc->set_primary_key('id');
  $class->register_class(Lang => $rc);
  my $schema = $class->connect($dsn, $user, $pass, {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
    ($dbd eq 'mysql' ? (mysql_enable_utf8mb4 => 1) : ()),
    # MySQL reports in the language of the session
    on_connect_do => ["USE `$DB`", "SET SESSION lc_messages = '$lang'"],
    %attrs,
  });
  push @schemas, $schema;
  return $schema;
}

sub error_of {
  my ($code) = @_;
  local $@;
  return eval { $code->(); 1 } ? undef : "$@";
}

# One case: the error is a refusal, the values are not in it, nor the quotes
# the server put around them, and what the reader needs is.
sub refused {
  my ($label, $err, %want) = @_;
  unless (defined $err) {
    fail "$label: the statement was refused";
    return;
  }
  unlike $err, $_, "$label: no $_ in the text" for @{ $want{absent} };
  like $err, $want{present}, "$label: names " . ($want{what} // 'what the reader needs');
  # server side prepare sends the statement with its placeholders: the
  # expression has none of the value to mask
  like $err, qr/(?:'\*\*\*'|\*\*\*)/, "$label: the value is masked where the server quoted it"
    unless $want{expression} && !$want{in_text};
  unlike $err, qr/'\*\*\*'/, "$label: ... and the server quoted nothing in an expression" if $want{expression};
  return $err;
}

# The cases a schema runs: the call, what must be in the text, the forms of the
# value that must not. A case that needs a row finds it made first.
sub run_cases {
  my ($tag, $schema, $call) = @_;

  my $rs = $schema->resultset('Lang');
  $raw->do("DELETE FROM `$DB`.fw_lang");
  $call->(sub { $rs->create({ name => 'ab' }) });
  $call->(sub { $rs->create({ name => "it's, ab" }) });

  my %case = (
    'duplicate, short value'    => [
      sub { $rs->create({ name => 'ab' }) },
      qr/fw_lang_u/, [ qr/'ab'/, qr/\bab\b/ ],
    ],
    'duplicate, quote in value' => [
      sub { $rs->create({ name => "it's, ab" }) },
      qr/fw_lang_u/, [ qr/it's/, qr/'it's, ab'/ ],
    ],
    'integer, short value'      => [
      sub { $rs->create({ name => 'int1', n => 'xy' }) },
      qr/\bn\b/, [ qr/'xy'/, qr/\bxy\b/ ],
    ],
    'integer, quote in value'   => [
      sub { $rs->create({ name => 'int2', n => "x'y z" }) },
      qr/\bn\b/, [ qr/x'y/, qr/y z/ ],
    ],
    'date, short value'         => [
      sub { $rs->create({ name => 'date1', d => 'xy' }) },
      qr/\bd\b/, [ qr/'xy'/, qr/\bxy\b/ ],
    ],
  );

  # The overflow of an expression: the server quotes the expression, which
  # holds the bound value, in English in every language. The statement is run
  # on the handle of the storage, so its error handler is the one that masks.
  $case{'overflow in an expression'} = [
    sub { $schema->storage->dbh_do(sub { $_[1]->selectall_arrayref('SELECT EXP(?)', undef, 999) }) },
    qr/out of range/, [ qr/\b999\b/ ], 1,
  ];

  for my $name (sort keys %case) {
    my ($code, $present, $absent, $expression) = @{ $case{$name} };
    my $err = $call->($code);
    refused("$tag $name", $err, present => $present, absent => $absent,
      expression => $expression, in_text => ($tag =~ /client_prepare/));
  }
}

for my $lang (qw(en_US de_DE fr_FR)) {
  # the session of the test does report in this language: the proof that the
  # texts below are not the English ones by accident
  my $probe = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 0, PrintError => 0 });
  $probe->do("SET SESSION lc_messages = '$lang'");
  $probe->do("INSERT INTO `$DB`.fw_lang (name) VALUES ('probe')");
  $probe->do("INSERT INTO `$DB`.fw_lang (name) VALUES ('probe')");
  like $probe->errstr // '', $language{$lang}, "[$lang] the server reports in this language";
  $probe->do("DELETE FROM `$DB`.fw_lang");
  $probe->disconnect;

  for my $mode (qw(client_prepare server_prepare)) {
    my $schema = connect_schema(
      $lang,
      $mode eq 'server_prepare' ? ("${dbd}_server_prepare" => 1) : (),
    );

    run_cases("[$lang $mode]", $schema, sub {
      my ($code) = @_;
      return error_of($code);
    });
  }
}

SKIP: {
  skip 'DBIO::Async, IO::Async and Future::IO::Impl::IOAsync required for the future_io transport', 1
    unless $async;

  my $loop = IO::Async::Loop->new;
  my $settle = sub {
    my ($f) = @_;
    my $deadline = Time::HiRes::time() + 30;
    until ($f->is_ready) {
      die "a Future did not settle\n" if Time::HiRes::time() > $deadline;
      $loop->loop_once(0.05);
    }
    return $f;
  };

  for my $lang (qw(en_US de_DE fr_FR)) {
    my $schema = connect_schema($lang, async => 'future_io', pool_size => 2);
    my $rs = $schema->resultset('Lang');
    $raw->do("DELETE FROM `$DB`.fw_lang");
    $settle->($rs->create_async({ name => 'ab' }))->get;

    my @case = (
      [ 'duplicate',        sub { $rs->create_async({ name => 'ab' }) },            qr/fw_lang_u/, [ qr/'ab'/, qr/\bab\b/ ] ],
      [ 'integer',          sub { $rs->create_async({ name => 'int1', n => 'xy' }) }, qr/\bn\b/,      [ qr/'xy'/, qr/\bxy\b/ ] ],
      [ 'date',             sub { $rs->create_async({ name => 'date1', d => 'xy' }) }, qr/\bd\b/,     [ qr/'xy'/, qr/\bxy\b/ ] ],
    );
    for my $case (@case) {
      my ($name, $call, $present, $absent) = @$case;
      my $future = $settle->($call->());
      my $err = $future->is_failed ? join('', map { "$_" } $future->failure) : undef;
      refused("[$lang future_io] $name", $err, present => $present, absent => $absent);
    }
  }
}

done_testing;
