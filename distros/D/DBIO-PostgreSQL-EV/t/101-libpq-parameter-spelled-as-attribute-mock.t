use strict;
use warnings;
use Test::More;

# OFFLINE, karr k80 (maintainer's decisions 2026-10-15): a libpq connection
# parameter that stands where only DBI attributes are read is REFUSED, naming
# the key and never a value, where it used to be dropped without a word.
#
# WHY: the owning storage's DBI takes any name for an attribute, so the same
# connect info connected the schema's dbh and, through this transport, a pool
# that went without the parameter -- sslmode => 'require' that was never
# applied is a connection in clear text nobody was told about. Every place is
# held, for static connect info and for a broker's answer alike:
#
#   1. (d) among the attributes of the DBI form: \%attrs, \%extra_attributes,
#      the attributes in front of the DSN, a hash with a dsn key;
#   2. (c) a name spelled with a capital (Sslmode), which DBI takes for an
#      attribute and libpq reads lower case: in those attributes, in a hash of
#      libpq parameters, and beside the broker;
#   3. a DBI attribute beside a broker's dbh_maker answer is named in the
#      refusal (core refuses it since k310);
#   4. controls: what is DBI's -- AutoCommit, pg_enable_utf8, DBI's Password --
#      and what names nothing -- undef, '' -- is still taken, so the refusal is
#      the parameter's and not every attribute's.

BEGIN {
  package EV::Pg;
  our @NEW;
  sub new { my ($class, %args) = @_; push @NEW, \%args; bless {}, $class }
  $INC{'EV/Pg.pm'} = __FILE__;
}

use DBIO::PostgreSQL::EV::Storage;
use DBIO::PostgreSQL::EV::ConnectInfo 'is_libpq_parameter';

my $EV     = 'DBIO::PostgreSQL::EV::Storage';
my $DSN    = 'dbi:Pg:dbname=app;host=db1';
my $SECRET = 'k80-secret';
my $VALUE  = 'k80-value';

{
  package T101::Broker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer, asked => 0 }, $class }
  sub connect_info_for { my $s = shift; $s->{asked}++; return $s->{answer} }
}

# --- the list ----------------------------------------------------------------
ok is_libpq_parameter($_), "$_ is a libpq parameter" for qw( sslmode host dbname connect_timeout application_name Sslmode HOST );
ok !is_libpq_parameter($_), "$_ is none" for qw( pool_size AutoCommit pg_enable_utf8 LongReadLen async on_connect_do );

# connect_info as static info and as a broker's answer.
my @ORIGIN = (
  [ 'static',            sub { ref $_[0] eq 'ARRAY' ? $_[0] : [ $_[0] ] } ],
  [ 'a broker\'s answer', sub { [ T101::Broker->new($_[0]) ] } ],
);

sub refused_naming {
  my ($label, $info, $names, $unlike) = @_;
  my $s  = $EV->new(undef);
  my $ok = eval { $s->connect_info($info); 1 };
  my $err = "$@";
  ok !$ok, "$label: connect_info refuses it";
  like $err, qr/\Q($names)\E/, '... naming ' . $names;
  unlike $err, qr/\Q$VALUE\E|\Q$SECRET\E/, '... and no value';
  return $s;
}

# --- 1. the DBI form's attributes (d) and 2. their capitalised spelling (c) --
for my $origin (@ORIGIN) {
  my ($where, $wrap) = @$origin;
  my @FORMS = (
    [ 'sslmode in \\%attrs',         [ $DSN, 'u', $SECRET, { sslmode => $VALUE } ],              'sslmode' ],
    [ 'sslmode in \\%extra',         [ $DSN, 'u', $SECRET, {}, { sslmode => $VALUE } ],          'sslmode' ],
    [ 'sslmode in front of the DSN', [ "dbi:Pg(sslmode=>$VALUE):dbname=app", 'u', $SECRET ],      'sslmode' ],
    [ 'Sslmode in \\%attrs',         [ $DSN, 'u', $SECRET, { Sslmode => $VALUE } ],              'Sslmode' ],
    [ 'two, sorted',                 [ $DSN, 'u', $SECRET, { sslmode => $VALUE, Host => $VALUE } ], 'Host, sslmode' ],
  );
  for my $form (@FORMS) {
    my ($label, $info, $names) = @$form;
    refused_naming("$label, $where", $wrap->($info), $names);
  }
  # a hash with a dsn key is the same form
  refused_naming("sslmode beside the dsn of a hash, $where",
    $wrap->({ dsn => $DSN, user => 'u', password => $SECRET, sslmode => $VALUE }), 'sslmode');
  refused_naming("Sslmode beside the dsn of a hash, $where",
    $wrap->({ dsn => $DSN, user => 'u', password => $SECRET, Sslmode => $VALUE }), 'Sslmode');

  # controls
  for my $control (
    [ 'AutoCommit and pg_enable_utf8', { AutoCommit => 1, pg_enable_utf8 => 1, RaiseError => 1 } ],
    [ 'DBI\'s Password and Username',  { Username => 'u', Password => $SECRET } ],
    [ 'sslmode undef and empty',       { sslmode => undef, connect_timeout => '' } ],
    [ 'pool_size',                     { pool_size => 2 } ],
  ) {
    my ($label, $attrs) = @$control;
    my $s = $EV->new(undef);
    ok eval { $s->connect_info($wrap->([ $DSN, 'u', $SECRET, $attrs ])); 1 },
      "control, $label among the attributes, $where: taken" or diag $@;
  }
}

# --- 2. a hash of libpq parameters (c) ---------------------------------------
for my $origin (@ORIGIN) {
  my ($where, $wrap) = @$origin;
  refused_naming("Sslmode in a hash of libpq parameters, $where",
    $wrap->({ dbname => 'app', host => 'db1', user => 'u', password => $SECRET, Sslmode => $VALUE }), 'Sslmode');
  refused_naming("Sslmode and Connect_timeout, $where",
    $wrap->({ dbname => 'app', Sslmode => $VALUE, Connect_timeout => 5 }), 'Connect_timeout, Sslmode');

  for my $control (
    [ 'sslmode in lower case', { dbname => 'app', host => 'db1', sslmode => 'require' } ],
    [ 'AutoCommit and pg_enable_utf8 (the owner\'s)', { dbname => 'app', AutoCommit => 1, pg_enable_utf8 => 1 } ],
    [ 'Sslmode undef', { dbname => 'app', Sslmode => undef } ],
  ) {
    my ($label, $hash) = @$control;
    my $s = $EV->new(undef);
    ok eval { $s->connect_info($wrap->($hash)); 1 }, "control, $label, $where: taken" or diag $@;
  }
}

# --- 2. beside the broker (c) ------------------------------------------------
{
  my $answer = [ $DSN, 'u', $SECRET ];
  my $b      = T101::Broker->new($answer);
  my $s      = refused_naming('Sslmode beside the broker', [ $b, { Sslmode => $VALUE } ], 'Sslmode');
  is $b->{asked}, 0, '... before the broker is asked';

  @EV::Pg::NEW = ();
  for my $attempt (
    [ pool   => sub { my $f = $s->pool->acquire; die +($f->failure)[0] if $f->is_failed } ],
    [ listen => sub { $s->_listen_open } ],
  ) {
    my ($name, $code) = @$attempt;
    eval { $code->() };
    like "$@", qr/\(Sslmode\)/, "... $name connection: the key, again";
  }
  is scalar(@EV::Pg::NEW), 0, '... nothing reached EV::Pg';

  for my $ok ([ pg_enable_utf8 => 1 ], [ LongReadLen => 5 ], [ AutoCommit => 1 ], [ Sslmode => undef ]) {
    my $t = $EV->new(undef);
    ok eval { $t->connect_info([ T101::Broker->new($answer), { @$ok } ]); 1 },
      "control, $ok->[0] beside the broker: taken" or diag $@;
  }
}

# --- 3. a DBI attribute beside a dbh_maker answer ------------------------------
{
  my $answer = { dbh_maker => sub { die "never called\n" } };
  my $s  = $EV->new(undef);
  my $ok = eval { $s->connect_info([ T101::Broker->new($answer), { LongReadLen => 5, pool_size => 2 } ]); 1 };
  my $err = "$@";
  ok !$ok, 'LongReadLen beside a dbh_maker answer: connect_info refuses it';
  like $err, qr/\(dbh_maker\)/, '... as the code reference it is';
  like $err, qr/\bLongReadLen\b/, '... naming the attribute';
  unlike $err, qr/pool_size|\b5\b/, '... and neither pool_size, which is consumed, nor a value';

  my $plain = eval { $EV->new(undef)->connect_info([ T101::Broker->new($answer) ]); 1 } ? '' : "$@";
  like $plain, qr/\(dbh_maker\)/, 'control: without it the answer is refused alone';
  unlike $plain, qr/beside the broker/, '... with nothing said of attributes beside the broker';
}

done_testing;
