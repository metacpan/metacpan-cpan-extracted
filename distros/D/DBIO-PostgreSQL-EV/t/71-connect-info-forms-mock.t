use strict;
use warnings;
use Test::More;

# OFFLINE test: connect info is read in one place, whatever form it comes in
# and wherever it comes from (karr k64, k66, k79).
#
# WHY: a schema connected with { async => 'ev' } opens connections from one
# connect info twice -- the owning sync storage its dbh, over DBI and DBD::Pg,
# and this transport every pooled connection and the listen connection, over
# libpq. The two must end up in the same place as the same user (karr k58),
# so the transport has to read connect info the way the owner does. It read it
# in two places by two measures. What a broker answers went through one
# reader, which refuses what it cannot read and names its shape (karr k61).
# Static connect info went past it: the 'dbi:Pg:' array was translated and
# everything else was taken as it came. And neither knew the forms the owner
# reads besides the array:
#
#   * the single hash with a dsn key, { dsn => 'dbi:Pg:...', user => ...,
#     password => ..., %attributes }, which the owner reads as the DBI form
#     and which core names to a broker as the answer that carries a libpq
#     parameter to both halves (core k298). The transport rendered it as libpq
#     parameters -- 'dsn=dbi:Pg:... async=ev user=...' -- and libpq refused
#     the first connection: invalid connection option "dsn" (k64, k79);
#   * the single hash of connection parameters with the owner's own keys in
#     it -- async, quote_names, AutoCommit, pg_enable_utf8 -- which reached
#     libpq as parameters too;
#   * a DSN with DBI attributes in front, 'dbi:Pg(RaiseError=>1):...', which
#     DBI reads and the transport refused; and DBI's Username and Password
#     attributes, which DBI connects with instead of the user and password
#     beside the DSN, and the transport did not read: the pool was opened as
#     another user than the dbh;
#   * a form nobody can read -- [ [ $dsn, $user, $pass ], {} ], a coderef --
#     was taken by connect_info and died at the first ->pool with Perl's "Not
#     a HASH reference" (k66).
#
# What this file claims:
#   1. every form the owner reads means one connection: as static connect
#      info and as a broker's answer, through a schema and on the transport
#      directly, a pooled connection and the listen connection are opened with
#      the same libpq parameters -- the ones the owner's own DBI->connect call
#      means -- and the pool has the size the connect info gives;
#   2. what the transport cannot connect from is refused by connect_info,
#      naming the form and never a value, with the same words for static
#      connect info and for a broker's answer; nothing reaches EV::Pg, and the
#      storage is left with nothing to connect from;
#   3. a connect_info call that throws leaves nothing of the call before it:
#      not its conninfo, not its pool size (the note of karr k67 on k66);
#   4. decided 2026-10-14 (k66): an empty conninfo on the static path is left
#      to libpq (a), pool_size= inside the DSN is refused naming it (b), and
#      DBI_USER and DBI_PASS are read as DBI reads them for static
#      connect info and never for a broker (d); DBI_DSN is not read at all:
#      core refuses a DSN that is not given;
#   5. a postgresql:// URI in the DSN's rest, decided 2026-10-09 (k66 (c)), is
#      read to the libpq parameters it stands for, from every form that
#      carries a DSN, and refused without a word of it where libpq cannot
#      read it.
#
# How a DSN with DBI attributes is taken apart is held against DBI itself in
# t/53-dbi-to-conninfo.t; a server is asked in t/72-connect-info-forms-live.t.
#
# WHAT RUNS FOR REAL: core's sync storage, its _async_storage and broker
# attach, this dist's Storage, ConnectInfo and Pool.
# THE SUBSTITUTIONS: EV::Pg records what it is constructed with (the test plays
# the server's connect); DBI->connect records what it is called with and
# reports that there is no server.

BEGIN {
  package EV::Pg;
  use Scalar::Util ();

  our @NEW;   # every EV::Pg->new: [ conninfo, the handle (weak) ]

  sub new {
    my ($class, %args) = @_;
    my $self = bless { args => { %args }, connected => 0 }, $class;
    # connect_timeout=10 is the transport's own default (karr k101, t/111): not part of what these tests compare
    push @NEW, [ $args{conninfo} =~ s/\s*connect_timeout=10\z//r, $self ];
    Scalar::Util::weaken($NEW[-1][1]);
    return $self;
  }

  for my $h (qw( on_connect on_error on_notify )) {
    no strict 'refs';
    *{"EV::Pg::$h"} = sub { my $s = shift; $s->{args}{$h} = $_[0] if @_; $s->{args}{$h} };
  }

  sub is_connected { $_[0]{connected} ? 1 : 0 }
  sub socket       { -1 }
  sub finish       { $_[0]{connected} = 0; return }

  # The server's side: the connect completes.
  sub t_connect {
    my ($s) = @_;
    $s->{connected} = 1;
    $s->{args}{on_connect}->() if $s->{args}{on_connect};
    return;
  }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use DBI;
use DBIO::AccessBroker;
use DBIO::PostgreSQL::EV::Storage;
use DBIO::PostgreSQL::EV::ConnectInfo qw( dbi_to_conninfo );

alarm 60;

my $EV = 'DBIO::PostgreSQL::EV::Storage';

# Every DBI->connect of this file: [ $dsn, $user, $password, \%attrs ]. There
# is no server to answer one.
my @DBI_CONNECT;
{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, @args) = @_;
    push @DBI_CONNECT, [ @args ];
    die "this test has no server\n";
  };
}

# A libpq conninfo string back into its parameters: key=value or
# key='quoted value' with \' and \\ escaped -- the syntax libpq reads. Dies on
# anything else, so a DSN string or a parameter libpq does not know is caught.
sub parse_conninfo {
  my ($str) = @_;
  die "no conninfo string\n" unless defined $str && !ref $str;
  my %h;
  pos($str) = 0;
  while ($str =~ /\G\s*([A-Za-z_]+)=(?:'((?:[^'\\]|\\.)*)'|([^\s']*))/gc) {
    my ($key, $quoted, $bare) = ($1, $2, $3);
    die "conninfo names '$key' twice\n" if exists $h{$key};
    $h{$key} = defined $quoted ? $quoted =~ s/\\(.)/$1/gr : $bare;
  }
  die "not a libpq conninfo string\n" unless $str =~ /\G\s*\z/gc;
  return \%h;
}

# One new pool connection: what EV::Pg was constructed with.
sub spawn_conninfo {
  my ($s) = @_;
  my $before = @EV::Pg::NEW;
  my $f = $s->pool->acquire;
  die "acquire failed: " . ($f->failure)[0] if $f->is_failed;
  die scalar(@EV::Pg::NEW) - $before . " EV::Pg handles made for one spawn\n" unless @EV::Pg::NEW == $before + 1;
  my ($conninfo, $pg) = @{ $EV::Pg::NEW[-1] };
  $pg->t_connect;
  die "the spawned connection was not handed out\n" unless $f->is_done && $f->get == $pg;
  return $conninfo;
}

# One open of the listen connection: what EV::Pg was constructed with.
sub listen_conninfo {
  my ($s) = @_;
  my $before = @EV::Pg::NEW;
  my $f = $s->_listen_open;
  die scalar(@EV::Pg::NEW) - $before . " EV::Pg handles made for one listen open\n" unless @EV::Pg::NEW == $before + 1;
  my ($conninfo, $pg) = @{ $EV::Pg::NEW[-1] };
  $pg->t_connect;
  $s->_listen_close($f->get);
  return $conninfo;
}

# How a pool spawn and a listen open end on this storage: the error of each
# ('no error' when it went through) and what EV::Pg was constructed with.
sub connection_attempts {
  my ($s) = @_;
  @EV::Pg::NEW = ();
  my %got;
  local $SIG{__WARN__} = sub { };
  $got{pool} = eval {
    my $f = $s->pool->acquire;
    $f->is_failed ? ($f->failure)[0] : 'no error';
  } // $@;
  $got{listen} = eval { $s->_listen_open; 'no error' } // $@;
  s/ at \S+ line \d+\.?\n?\z// for @got{qw( pool listen )};
  $got{handles} = [ map { $_->[0] } @EV::Pg::NEW ];
  return \%got;
}

# A storage never given connect info: what "nothing to connect from" looks
# like.
my $UNCONFIGURED = connection_attempts($EV->new(undef));
is_deeply $UNCONFIGURED->{handles}, [], 'control: a storage never given connect info opens nothing';

# What the owner's dbh is opened with, read as this distribution reads the DBI
# form (held against DBD::Pg and libpq in t/53): the parameters the sync
# storage's own DBI->connect call means.
sub owner_means {
  my ($schema) = @_;
  @DBI_CONNECT = ();
  eval { $schema->storage->dbh };
  die scalar(@DBI_CONNECT) . " DBI->connect calls for one dbh\n" unless @DBI_CONNECT == 1;
  my $h = dbi_to_conninfo($DBI_CONNECT[0])->[0];
  delete $h->{pool_size};
  return $h;
}

# A broker answering every storage alike, whatever the test puts in it.
{
  package AnswerBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

{
  package FormSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

my $SECRET = 'k64-hunter2';
my $OTHER  = 'k64-other-pw';
my $LEAK   = qr/\Q$SECRET\E|\Q$OTHER\E/;
my $PARAMS = 'dbname=appdb;host=db.example;port=5433';
my $DSN    = "dbi:Pg:$PARAMS";
my %WANT   = (dbname => 'appdb', host => 'db.example', port => 5433, user => 'app', password => $SECRET);

# ---------------------------------------------------------------------------
# 1. Every form the owner reads means one connection.
# ---------------------------------------------------------------------------

# [ label, the connect info as the arguments of connect, the pool size it
#   gives, its attribute hash -- where a schema's { async => 'ev' } goes ].
# A hash form carries the async mode in the hash itself.
my @FORMS = (
  [ 'the DBI form',
    [ $DSN, 'app', $SECRET, { pool_size => 3 } ], 3 ],
  [ 'a hash with a dsn key',
    [ { dsn => $DSN, user => 'app', password => $SECRET, pool_size => 3 } ], 3 ],
  [ 'a hash with a dsn key and attributes of the owner\'s',
    [ { dsn => $DSN, user => 'app', password => $SECRET,
        AutoCommit => 1, RaiseError => 1, pg_enable_utf8 => 1, quote_names => 1 } ], 5 ],
  [ 'a hash whose dbname is the DSN',
    [ { dbname => $DSN, user => 'app', password => $SECRET } ], 5 ],
  [ 'a hash of connection parameters',
    [ { dbname => 'appdb', host => 'db.example', port => 5433, user => 'app', password => $SECRET, pool_size => 3 } ], 3 ],
  [ 'a hash of connection parameters and attributes of the owner\'s',
    [ { dbname => 'appdb', host => 'db.example', port => 5433, user => 'app', password => $SECRET,
        AutoCommit => 1, RaiseError => 1, pg_enable_utf8 => 1, private_tag => 'x', quote_names => 1 } ], 5 ],
  [ 'a DSN with DBI attributes in front',
    [ "dbi:Pg(RaiseError=>1,AutoCommit=>1):$PARAMS", 'app', $SECRET ], 5 ],
  [ 'a DSN with DBI\'s Username and Password in front, over the ones beside it',
    [ "dbi:Pg(Username=>app,Password=>$SECRET):$PARAMS", 'other', $OTHER ], 5 ],
  [ 'DBI\'s Username and Password among the attributes, over the ones beside the DSN',
    [ $DSN, 'other', $OTHER, { Username => 'app', Password => $SECRET } ], 5 ],
  [ 'a hash with a dsn key and DBI\'s Username and Password, over its user and password',
    [ { dsn => $DSN, user => 'other', password => $OTHER, Username => 'app', Password => $SECRET } ], 5 ],
  [ 'a DSN with pool_size among the DBI attributes in front',
    [ "dbi:Pg(pool_size=>3):$PARAMS", 'app', $SECRET ], 3 ],
);

# The connect info with the async mode in it, as Schema->connect takes it.
sub with_async {
  my ($info) = @_;
  my @info = @$info;
  if (ref $info[0] eq 'HASH') { $info[0] = { %{ $info[0] }, async => 'ev' } }
  else                        { $info[3] = { %{ $info[3] || {} }, async => 'ev' } }
  return @info;
}

# What a broker answers for a form: the hash itself, or the array.
sub as_answer { my ($info) = @_; ref $info->[0] eq 'HASH' ? { %{ $info->[0] } } : [ @$info ] }

for my $form (@FORMS) {
  my ($label, $info, $size) = @$form;

  for my $origin (
    [ 'static, through a schema',  sub { FormSchema->connect(with_async($info)) } ],
    [ 'a broker\'s answer, through a schema',
      sub { FormSchema->connect(AnswerBroker->new(as_answer($info)), { async => 'ev' }) } ],
  ) {
    my ($where, $connect) = @$origin;
    @EV::Pg::NEW = @DBI_CONNECT = ();

    my $schema = eval { $connect->() };
    ok $schema, "$label, $where: the schema is connected" or diag $@;
    SKIP: {
      skip 'the connect was refused', 5 unless $schema;
      my $async = eval { $schema->storage->async };
      isa_ok $async, $EV, '... ->async: the transport' or diag $@;
      skip 'the transport was refused', 4 unless $async;

      is_deeply scalar eval { parse_conninfo(spawn_conninfo($async)) }, \%WANT,
        '... a pooled connection is opened with the libpq parameters the form means' or diag $@;
      is_deeply scalar eval { parse_conninfo(listen_conninfo($async)) }, \%WANT,
        '... and so is the listen connection' or diag $@;
      is scalar eval { $async->pool->max_size }, $size, "... the pool has $size connections" or diag $@;
      is_deeply scalar eval { owner_means($schema) }, \%WANT,
        '... and they are what the owner\'s own DBI->connect call means: one place, one user' or diag $@;
    }
  }

  for my $origin (
    [ 'static, on the transport',           sub { [ @$info ] } ],
    [ 'a broker\'s answer, on the transport', sub { [ AnswerBroker->new(as_answer($info)) ] } ],
  ) {
    my ($where, $given) = @$origin;
    @EV::Pg::NEW = ();

    my $s = $EV->new(undef);
    ok eval { $s->connect_info($given->()); 1 }, "$label, $where: connect_info takes it" or diag $@;
    is_deeply scalar eval { parse_conninfo(spawn_conninfo($s)) }, \%WANT,
      '... a pooled connection is opened with the libpq parameters the form means' or diag $@;
    is_deeply scalar eval { parse_conninfo(listen_conninfo($s)) }, \%WANT,
      '... and so is the listen connection' or diag $@;
    is scalar eval { $s->pool->max_size }, $size, "... the pool has $size connections" or diag $@;
  }
}

# A hash with a dsn key is the DBI form, and a connection parameter beside the
# dsn is an attribute of it. The owner's DBI keeps a lowercase attribute it
# does not know without a word and opens the dbh from the DSN alone, so a
# pooled connection from the DSN alone went where the dbh goes -- and the
# caller who wrote host or sslmode there was connected without it, unheard.
# karr k80 (4): refused, naming the key and never a value, for static connect
# info and for a broker's answer alike. (Was: taken, and read from the DSN
# alone; turned to the refusal on the maintainer's decision.)
for my $origin (
  [ 'static',            sub { [ { @_ } ] } ],
  [ 'a broker\'s answer', sub { [ AnswerBroker->new({ @_ }) ] } ],
) {
  my ($where, $given) = @$origin;
  for my $key (qw( host dbname port sslmode )) {
    my $s  = $EV->new(undef);
    my $ok = eval {
      $s->connect_info($given->(dsn => $DSN, user => 'app', password => $SECRET, $key => 'k80-value'));
      1;
    };
    my $err = "$@";
    ok !$ok, "a hash with a dsn key and $key beside it, $where: connect_info refuses it";
    like $err, qr/\($key\)/, '... naming the parameter';
    unlike $err, qr/k80-value|\Q$SECRET\E/, '... and no value';
  }
}

# The same, with the one name that is DBI's as well: Username and Password
# among the attributes are read, as above, and are no parameter.
for my $origin (
  [ 'static',            sub { [ { @_ } ] } ],
  [ 'a broker\'s answer', sub { [ AnswerBroker->new({ @_ }) ] } ],
) {
  my ($where, $given) = @$origin;
  my $s = $EV->new(undef);
  ok eval {
    $s->connect_info($given->(dsn => $DSN, user => 'app', Password => $SECRET, AutoCommit => 1));
    1;
  }, "a hash with a dsn key and DBI's Password and AutoCommit beside it, $where: it is taken" or diag $@;
}

# The pool size among the DBI attributes in front of a broker's DSN is the
# answer's pool size like one anywhere else in it: the size beside the broker
# has to agree with it (core k245).
{
  my $answer = [ "dbi:Pg(pool_size=>3):$PARAMS", 'app', $SECRET ];

  my $s = $EV->new(undef);
  ok eval { $s->connect_info([ AnswerBroker->new($answer), { pool_size => 3 } ]); 1 },
    'pool_size in front of a broker\'s DSN and beside the broker, alike: it is taken' or diag $@;
  is scalar eval { $s->pool->max_size }, 3, '... and the pool has three connections';

  my $ok  = eval { $EV->new(undef)->connect_info([ AnswerBroker->new($answer), { pool_size => 4 } ]); 1 };
  my $err = "$@";
  ok !$ok, '... with another size beside the broker: connect_info throws';
  like $err, qr/Connection setting 'pool_size' is given both beside the AccessBroker and in the broker's answer/,
    '... naming pool_size, as for a size anywhere else in the answer';
}

# The options hash behind a hash stays what it is in [ \%conninfo, \%opts ].
{
  my $s = $EV->new(undef);
  ok eval { $s->connect_info([ { dsn => $DSN, user => 'app', password => $SECRET, pool_size => 2 }, { k64_option => 1 } ]); 1 },
    'a hash with a dsn key, followed by an options hash: it is taken' or diag $@;
  is_deeply scalar eval { parse_conninfo(spawn_conninfo($s)) }, \%WANT,
    '... and read the same' or diag $@;
  is scalar eval { $s->pool->max_size }, 2, '... with the pool size of the hash';
  is_deeply $s->_current_async_connect_info('write')->[1], { k64_option => 1 },
    '... and the options are the options: what core\'s seam answers for them';
}

# connect_info reads; it does not rewrite what it was given.
{
  my %hash  = (dsn => $DSN, user => 'app', password => $SECRET, AutoCommit => 1, async => 'ev');
  my %attrs = (Username => 'app', Password => $SECRET, async => 'ev');
  my @array = ("dbi:Pg(RaiseError=>1):$PARAMS", 'other', $OTHER, \%attrs);
  my @hash_form = (\%hash);
  ok eval { $EV->new(undef)->connect_info($_) for \@hash_form, \@array; 1 },
    'a hash and an array with attributes, each given to connect_info: taken' or diag $@;
  is_deeply \%hash, { dsn => $DSN, user => 'app', password => $SECRET, AutoCommit => 1, async => 'ev' },
    '... the hash is left as it was';
  is_deeply [ \@array, \%attrs ],
    [ [ "dbi:Pg(RaiseError=>1):$PARAMS", 'other', $OTHER, \%attrs ], { Username => 'app', Password => $SECRET, async => 'ev' } ],
    '... and so are an array and its attribute hash';
}

# ---------------------------------------------------------------------------
# 2. What the transport cannot connect from is refused by connect_info.
# ---------------------------------------------------------------------------

# A refusal of the transport's own is a DBIO::Exception since karr k88
# (maintainer's decision 2026-10-16): core's origin -- the transport's method
# that refused -- stands in front of the words, the caller's place behind
# them. Until then the words began the message.
my $STATIC = qr/^DBIO::PostgreSQL::EV::Storage::\w+\(\): PostgreSQL ev cannot connect from this connect info: /;
my $BROKER = qr/^DBIO::PostgreSQL::EV::Storage::\w+\(\): PostgreSQL ev cannot connect from what the AccessBroker returned: /;

# [ label, the connect info, the shape the refusal names, whether a broker
#   can answer it (connect info that is no array or hash is only ever given
#   to connect_info; a broker's plain hash is the hash form) ]
my @UNREADABLE = (
  [ 'an array holding the DBI form as an array',
    sub { [ [ $DSN, 'app', $SECRET ], {} ] },
    qr/: an arrayref of \(ARRAY ref, HASH ref\)\. It takes/, 1 ],
  [ 'a code reference',
    sub { [ sub { die "never called\n" }, { AutoCommit => 1 } ] },
    qr/: a code reference that makes a DBI handle -- this transport opens its own connections, from libpq parameters\. It takes/, 1 ],
  [ 'a hash with a dbh_maker',
    sub { [ { dbh_maker => sub { die "never called\n" }, dsn => $DSN, password => $SECRET } ] },
    qr/: a code reference that makes a DBI handle \(dbh_maker\) -- this transport opens its own connections, from libpq parameters\. It takes/, 1 ],
  [ 'a libpq conninfo string with a user and a password beside it',
    sub { [ "host=db.example dbname=appdb password=$SECRET", 'app', $SECRET ] },
    qr/: an arrayref of \(string, string, string\)\. It takes/, 1 ],
  [ 'a user and a password with no DSN',
    sub { [ undef, 'app', $SECRET ] },
    qr/: an arrayref of \(undef, string, string\)\. It takes/, 1 ],
  [ 'a hash with a reference for a parameter',
    sub { [ { dbname => 'appdb', host => [ 'a', 'b' ], password => $SECRET } ] },
    qr/: its libpq connection parameter 'host' is a reference, not a value\. It takes/, 1 ],
  [ 'an object that is no broker',
    sub { [ bless { password => $SECRET }, 'K64::NoBroker' ] },
    qr/: an arrayref of \(K64::NoBroker ref\)\. It takes/, 1 ],
  [ 'the DBI form for another driver',
    sub { [ "dbi:mysql:database=appdb;password=$SECRET", 'app', $SECRET ] },
    qr/: a DBI-form arrayref whose DSN is not dbi:Pg:<parameters> \(DBI driver 'mysql'\)\. It takes/, 1 ],
  [ 'the DBI form with DBI attributes in front and no colon behind them (dbi:Pg: with nothing behind it is read since k66)',
    sub { [ "dbi:Pg(Password=>$SECRET)", 'app', $SECRET ] },
    qr/: a DBI-form arrayref whose DSN is not dbi:Pg:<parameters> \(DBI driver 'Pg'\)\. It takes/, 1 ],
  [ 'a DSN libpq cannot read',
    sub { [ "dbi:Pg:dbname=appdb;password=$SECRET x", 'app' ] },
    qr/: a DBI-form arrayref -- the dbi:Pg: DSN cannot be read as libpq parameters: missing "=" after a parameter name\. It takes/, 1 ],
  [ 'a hash with another driver\'s DSN as its dsn',
    sub { [ { dsn => "dbi:mysql:database=appdb;password=$SECRET", user => 'app', password => $SECRET } ] },
    qr/: a hashref with a dsn key whose DSN is not dbi:Pg:<parameters> \(DBI driver 'mysql'\)\. It takes/, 1 ],
  [ 'a hash whose dsn is no DSN',
    sub { [ { dsn => "host=db.example password=$SECRET", user => 'app' } ] },
    qr/: a hashref with a dsn key whose DSN is not dbi:Pg:<parameters>\. It takes/, 1 ],
  [ 'a hash whose dsn is undefined',
    sub { [ { dsn => undef, user => 'app', password => $SECRET } ] },
    qr/: a hashref with a dsn key whose DSN is not dbi:Pg:<parameters>\. It takes/, 1 ],
  [ 'a hash with a dsn libpq cannot read',
    sub { [ { dsn => "dbi:Pg:dbname=appdb;password=$SECRET x", user => 'app' } ] },
    qr/: a hashref with a dsn key -- the dbi:Pg: DSN cannot be read as libpq parameters: missing "=" after a parameter name\. It takes/, 1 ],
  [ 'a hash whose dbname is a DSN, with a host beside it',
    sub { [ { dbname => $DSN, host => 'elsewhere.example', user => 'app', password => $SECRET } ] },
    qr/: a hashref whose dbname is a whole DSN, with host beside it\. It takes/, 1 ],
  [ 'a plain string',
    sub { "host=db.example password=$SECRET" },
    qr/: a plain string\. It takes/, 0 ],
  [ 'a hash that is not in an array',
    sub { { host => 'db.example', password => $SECRET } },
    qr/: a hashref with keys \(host, password\)\. It takes/, 0 ],
);

for my $case (@UNREADABLE) {
  my ($label, $build, $shape_re, $answerable) = @$case;

  # A storage that is connected, so that "nothing reaches EV::Pg" and
  # "nothing to connect from" are said of one that had something.
  my $s = $EV->new(undef);
  $s->connect_info([ $DSN, 'app', 'earlier-pw' ]);
  spawn_conninfo($s);

  @EV::Pg::NEW = ();
  my $ok  = eval { $s->connect_info($build->()); 1 };
  my $err = "$@";
  ok !$ok, "$label, static: connect_info refuses it";
  like $err, $STATIC, '... saying that it cannot connect from this connect info';
  like $err, $shape_re, '... naming its form, and what the transport takes';
  unlike $err, $LEAK, '... and no value of it';
  is scalar(@EV::Pg::NEW), 0, '... nothing reaches EV::Pg';
  is_deeply connection_attempts($s), $UNCONFIGURED,
    '... and the storage has nothing to connect from: not the connect info before it either';

  next unless $answerable;

  # The same answer from a broker: the same reader, the same words for the
  # form.
  my $given  = $build->();
  my $answer = @$given == 1 && ref $given->[0] eq 'HASH' ? $given->[0] : $given;
  @EV::Pg::NEW = ();
  $ok  = eval { $EV->new(undef)->connect_info([ AnswerBroker->new($answer) ]); 1 };
  $err = "$@";
  ok !$ok, "$label, a broker's answer: attaching the broker croaks";
  like $err, $BROKER, '... saying that it cannot connect from what the broker returned';
  like $err, $shape_re, '... naming the same form';
  unlike $err, $LEAK, '... and no value of it';
  is scalar(@EV::Pg::NEW), 0, '... nothing reaches EV::Pg';
}

# Through a schema the owner connects with a code reference, and this
# transport cannot: the first ->async says so, instead of a pool that dies of
# "Not a HASH reference".
for my $case (
  [ 'a connection coderef',  sub { FormSchema->connect(sub { die "no server\n" }, { async => 'ev' }) } ],
  [ 'a hash with a dbh_maker', sub { FormSchema->connect({ dbh_maker => sub { die "no server\n" }, async => 'ev' }) } ],
) {
  my ($label, $connect) = @$case;
  @EV::Pg::NEW = ();
  my $schema = eval { $connect->() };
  ok $schema, "$label, through a schema: the schema is connected" or diag $@;
  my $async = eval { $schema->storage->async };
  my $err   = "$@";
  ok !$async, '... and the first ->async refuses it';
  like $err, qr/PostgreSQL ev cannot connect from this connect info: a code reference that makes a DBI handle/,
    '... naming the form';
  is scalar(@EV::Pg::NEW), 0, '... nothing reaches EV::Pg';
}

# ---------------------------------------------------------------------------
# 3. A connect_info call that throws leaves nothing of the call before it.
# ---------------------------------------------------------------------------

# A broker that cannot be reached: asking it throws.
{
  package ThrowingBroker;
  use base 'DBIO::AccessBroker';
  sub new { bless {}, shift }
  sub connect_info_for { die "k66 vault unreachable\n" }
}

my %BROKER_ANSWER = (dbname => 'brokerdb', user => 'broker-user', password => 'broker-pw');

for my $case (
  # [ label, the call that throws, its error, whether its broker stays
  #   attached with an answer a connection can be opened from ]
  [ 'the pool size in the answer and the one beside the broker disagree',
    sub { [ AnswerBroker->new({ %BROKER_ANSWER, pool_size => 2 }), { pool_size => 4 } ] },
    qr/Connection setting 'pool_size' is given both beside the AccessBroker and in the broker's answer/, 1 ],
  [ 'the broker throws',
    sub { [ ThrowingBroker->new ] },
    qr/^k66 vault unreachable/, 0 ],
  [ 'the broker answers what the transport cannot read',
    sub { [ AnswerBroker->new("host=db.example password=$SECRET") ] },
    $BROKER, 0 ],
  [ 'static connect info the transport cannot read',
    sub { [ [ $DSN, 'app', $SECRET ], {} ] },
    $STATIC, 0 ],
) {
  my ($label, $build, $error_re, $connects) = @$case;

  my $s = $EV->new(undef);
  $s->connect_info([ $DSN, 'app', 'earlier-pw', { pool_size => 3 } ]);
  is $s->pool->max_size, 3, "$label: the connect info before it gave a pool of three";

  ok !eval { $s->connect_info($build->()); 1 }, '... the next connect_info throws';
  like "$@", $error_re, '... with its error';

  is_deeply [ @{$s}{qw( _conninfo _pool_size _opts )} ], [ undef, undef, undef ],
    '... the conninfo, the pool size and the options of the call before are gone';
  if ($connects) {
    # The refused call's broker stays attached (karr k67), and a pool built
    # now is its pool -- not one with the size the earlier call gave.
    is scalar eval { $s->pool->max_size }, 5,
      '... and a pool built now has the default size, not the one of the call before' or diag $@;
    is_deeply scalar eval { parse_conninfo(spawn_conninfo($s)) }, \%BROKER_ANSWER,
      '... and is opened from the broker that stayed attached' or diag $@;
  }
  else {
    my $after = connection_attempts($s);
    is_deeply $after->{handles}, [], '... and no connection is opened: not from the connect info before';
    unlike "$after->{pool} $after->{listen}", qr/earlier-pw/, '... nor does an error carry its password';
  }
}

# Static connect info that is refused takes the broker of the call before
# with it: nothing connects as that broker's user either.
{
  my $s = $EV->new(undef);
  $s->connect_info([ AnswerBroker->new({ %BROKER_ANSWER }) ]);
  ok !eval { $s->connect_info([ [ $DSN, 'app', $SECRET ], {} ]); 1 },
    'a broker, then static connect info the transport cannot read: connect_info throws';
  ok !$s->access_broker && !$s->_conninfo_provider, '... the broker and its provider are gone';
  is_deeply connection_attempts($s), $UNCONFIGURED, '... and the storage has nothing to connect from';

  ok eval { $s->connect_info([ $DSN, 'app', $SECRET ]); 1 }, '... then connect info it reads: it is taken'
    or diag $@;
  is_deeply scalar eval { parse_conninfo(spawn_conninfo($s)) }, \%WANT,
    '... and a pooled connection is opened from it' or diag $@;
}

# ---------------------------------------------------------------------------
# 4. Decided 2026-10-14 (karr k66 (a), (b), (d)).
# ---------------------------------------------------------------------------

# karr k66 (a): an empty conninfo on the static path is read as the dbh reads
# dbi:Pg: -- libpq fills it from its environment (PGHOST, PGUSER, ...) --
# whatever it is empty as. A broker's answer that renders to the empty
# conninfo stays refused (karr k61): there the environment must not decide
# where the broker's answer goes.
# (What EV::Pg is given is the blank conninfo plus the transport's own
# connect_timeout=10, karr k101; the recorder strips that, so a blank shows as empty.)
{
  my $s = $EV->new(undef);
  ok eval { $s->connect_info([ '   ' ]); 1 }, 'static, a blank conninfo string: it is taken' or diag $@;
  is scalar eval { spawn_conninfo($s) }, '',
    '... and a pooled connection is opened from it: libpq fills it from its environment' or diag $@;
  is scalar eval { listen_conninfo($s) }, '', '... and so is the listen connection' or diag $@;

  for my $case (
    [ 'an empty hash',              [ {} ] ],
    [ 'a hash with only pool_size', [ { pool_size => 3 } ] ],
    [ 'an empty string',            [ '' ] ],
    [ 'an empty array',             [] ],
  ) {
    my ($label, $info) = @$case;
    my $s = $EV->new(undef);
    ok eval { $s->connect_info($info); 1 }, "static, $label: it is taken" or diag $@;
    my $got = connection_attempts($s);
    is_deeply $got->{handles}, [ '', '' ],
      '... a pooled and the listen connection are opened from the empty conninfo, left to libpq';
    is $got->{pool}, 'no error', '... the pool is built';
  }

  my $sized = $EV->new(undef);
  $sized->connect_info([ { pool_size => 3 } ]);
  is scalar eval { $sized->pool->max_size }, 3, 'static, a hash with only pool_size: it still sizes the pool';

  # karr k95 (maintainer's decision 2026-10-24): a DBI-form 'dbi:Pg:' DSN that
  # names no dbname, host, port, service or hostaddr is refused, static and as
  # a broker's answer alike, with the words of the sync storage and of
  # future_io (DBIO::PostgreSQL::Util::dsn_names_target, t/174 of the driver).
  # Not the empty or blank conninfo STRING above: that stays left to libpq.
  my @NO_TARGET = (
    'dbi:Pg:', 'dbi:Pg:;', 'dbi:Pg:  ', 'DBI:Pg:', 'dbi:Pg(PrintError=>0):',
    'dbi:Pg(RaiseError=>1):', 'dbi:Pg:sslmode=require',
    'dbi:Pg:sslmode=require;application_name=x', 'dbi:Pg:dbname=',
    q{dbi:Pg:dbname='';host=}, 'dbi:Pg:user=app;options=-c',
  );
  my @TARGET = (
    'dbi:Pg:dbname=app', 'dbi:Pg:host=db.example', 'dbi:Pg:port=5433',
    'dbi:Pg:service=prod', 'dbi:Pg:hostaddr=192.0.2.1', 'dbi:Pg:db=app',
    'dbi:Pg:sslmode=require;host=db.example',
  );
  my $NO_TARGET_RE = qr/names no dbname, host or port/;

  for my $dsn (@NO_TARGET) {
    for my $case (
      [ 'a DBI-form arrayref',       sub { [ $dsn, 'app', $SECRET ] } ],
      [ 'a DBI-form arrayref, bare', sub { [ $dsn ] } ],
      [ 'a hash with a dsn',         sub { [ { dsn => $dsn, user => 'app', password => $SECRET } ] } ],
    ) {
      my ($label, $info) = @$case;
      my $s = $EV->new(undef);
      delete local @ENV{qw( DBI_DSN DBI_USER DBI_PASS )};
      my $ok  = eval { $s->connect_info($info->()); 1 };
      my $err = $@;
      ok !$ok, "static, $label '$dsn': connect_info refuses it";
      isa_ok $err, 'DBIO::Exception', '... the refusal';
      like "$err", $NO_TARGET_RE, '... with the sync storage\'s words';
      unlike "$err", $LEAK, '... and no password';
      like "$err", qr/\Q@{[ __FILE__ ]}\E/, '... at the caller\'s place';
      is_deeply connection_attempts($s), $UNCONFIGURED, '... and nothing is left to connect from';

      my $b = $EV->new(undef);
      my $answer = ref $info->()->[0] eq 'HASH' ? { %{ $info->()->[0] } } : $info->();
      ok !eval { $b->connect_info([ AnswerBroker->new($answer) ]); 1 },
        "a broker's answer, $label '$dsn': refused as well";
      isa_ok $@, 'DBIO::Exception', '... the refusal';
      like "$@", $NO_TARGET_RE, '... with the same words';
      unlike "$@", $LEAK, '... and no password';
      is_deeply connection_attempts($b)->{handles}, [], '... and nothing reaches EV::Pg';
    }
  }

  for my $dsn (@TARGET) {
    my $s = $EV->new(undef);
    ok eval { $s->connect_info([ $dsn, 'app', $SECRET ]); 1 }, "static, '$dsn': it is taken" or diag $@;
    my $b = $EV->new(undef);
    ok eval { $b->connect_info([ AnswerBroker->new([ $dsn, 'app', $SECRET ]) ]); 1 },
      "a broker's answer, '$dsn': it is taken" or diag $@;
  }

  # A broker's answer that renders to nothing stays refused (karr k61).
  {
    my $s = $EV->new(undef);
    ok !eval { $s->connect_info([ AnswerBroker->new({}) ]); 1 },
      'a broker\'s answer of no parameters: refused';
    like "$@", qr/answered no connect info/, '... as an answer of no parameters';
  }
}

# karr k66 (b): pool_size= among the parameters of the DSN. DBD::Pg hands it
# to libpq, which refuses the connection (invalid connection option
# "pool_size"): the same connect info opens no dbh, so the transport refuses it
# as well, naming pool_size (it belongs among the attributes) and no value.
{
  for my $case (
    [ 'keyword=value',            [ "$DSN;pool_size=3", 'app', $SECRET ] ],
    [ 'whitespace-separated',     [ "$DSN pool_size=3", 'app', $SECRET ] ],
    [ 'a hash with a dsn',        [ { dsn => "$DSN;pool_size=3", user => 'app', password => $SECRET } ] ],
    [ 'a postgresql:// URI query', [ 'dbi:Pg:postgresql://db.example/appdb?pool_size=3', 'app', $SECRET ] ],
  ) {
    my ($label, $info) = @$case;
    my $s = $EV->new(undef);
    my $ok  = eval { $s->connect_info($info); 1 };
    my $err = "$@";
    ok !$ok, "static, pool_size= inside the DSN ($label): connect_info refuses it";
    like $err, qr/pool_size/, '... naming pool_size';
    unlike $err, $LEAK, '... and no value';
    is_deeply connection_attempts($s), $UNCONFIGURED, '... and nothing is left to connect from';

    my $b = $EV->new(undef);
    my $answer = ref $info->[0] eq 'HASH' ? { %{ $info->[0] } } : [ @$info ];
    ok !eval { $b->connect_info([ AnswerBroker->new($answer) ]); 1 }, '... as a broker\'s answer: refused as well';
    like "$@", qr/pool_size/, '... naming pool_size';
  }

  # pool_size where it belongs still sizes the pool.
  my $s = $EV->new(undef);
  ok eval { $s->connect_info([ $DSN, 'app', $SECRET, { pool_size => 3 } ]); 1 }, 'pool_size as an attribute: it is taken';
  is scalar eval { $s->pool->max_size }, 3, '... and sizes the pool';
}

# karr k66 (d): DBI takes DBI_USER and DBI_PASS for a user and a password that
# are undefined. Read the same for static connect info, in dbi_to_conninfo and
# nowhere else; never for a broker's answer (core k271). DBI_DRIVER is not
# read, and neither is DBI_DSN: core refuses a DSN that is not given.
{
  my %BASE = (dbname => 'appdb', host => 'db.example', port => 5433);
  my $given = sub {
    my ($info, %env) = @_;
    my $s = $EV->new(undef);
    delete local @ENV{qw( DBI_DSN DBI_USER DBI_PASS DBI_DRIVER DBI_DBNAME )};
    local @ENV{ keys %env } = values %env;
    ok eval { $s->connect_info($info); 1 }, '... connect_info takes it' or diag $@;
    return scalar eval { parse_conninfo(spawn_conninfo($s)) };
  };
  my %ENV_LOGIN = (DBI_USER => 'envuser', DBI_PASS => 'envpass');

  is_deeply $given->([ $DSN, undef, undef ], %ENV_LOGIN), { %BASE, user => 'envuser', password => 'envpass' },
    'static, undefined user and password: DBI_USER and DBI_PASS are the user and the password';
  is_deeply $given->([ $DSN ], %ENV_LOGIN), { %BASE, user => 'envuser', password => 'envpass' },
    'static, no user and password at all: the same';
  is_deeply $given->([ $DSN, 'app', undef ], %ENV_LOGIN), { %BASE, user => 'app', password => 'envpass' },
    'static, a user and no password: each is taken for itself';
  is_deeply $given->([ $DSN, 'app', $SECRET ], %ENV_LOGIN), \%WANT,
    'static, a user and a password given: the environment is not asked';
  is_deeply $given->([ $DSN, '', '' ], %ENV_LOGIN), \%BASE,
    'static, an empty user and password are given, not undefined: the environment is not asked';
  is_deeply $given->([ "dbi:Pg(Username=>attruser):$PARAMS", undef, undef ], %ENV_LOGIN),
    { %BASE, user => 'attruser', password => 'envpass' },
    'DBI\'s Username attribute comes before the environment, as in DBI->connect';

  # DBI_DSN is not read: core refuses a DSN that is not given, for the owner's
  # dbh, and a pool must not connect where there is no dbh. Nothing is
  # taken from it, and the empty conninfo is left to libpq (a).
  {
    delete local @ENV{qw( DBI_DSN DBI_USER DBI_PASS )};
    local @ENV{qw( DBI_DSN DBI_USER DBI_PASS )} = ('dbi:Pg:dbname=envdb', 'envuser', 'envpass');
    my $s = $EV->new(undef);
    ok !eval { $s->connect_info([ undef, undef, undef ]); 1 },
      'static, no DSN at all, DBI_DSN set: refused as the owner refuses it, DBI_DSN is not the DSN';
    unlike "$@", qr/envdb|envuser|envpass/, '... and nothing of the environment';
  }
  is_deeply $given->([ $DSN, 'app', $SECRET ], DBI_DSN => 'dbi:Pg:dbname=other'), \%WANT,
    'static, a DSN given: DBI_DSN is not asked';

  # DBI_DRIVER only fills in the driver of a DSN that names none; not read.
  {
    delete local @ENV{qw( DBI_DSN DBI_USER DBI_PASS )};
    local $ENV{DBI_DRIVER} = 'Pg';
    my $s = $EV->new(undef);
    ok !eval { $s->connect_info([ "dbi::$PARAMS", 'app', $SECRET ]); 1 },
      'static, a DSN that names no driver: DBI_DRIVER does not fill it in';
    unlike "$@", $LEAK, '... and no value';
  }

  # A broker's answer is read as it is: the environment decides nothing.
  {
    local @ENV{qw( DBI_USER DBI_PASS DBI_DSN )} = ('envuser', 'envpass', 'dbi:Pg:dbname=envdb');
    my $s = $EV->new(undef);
    ok eval { $s->connect_info([ AnswerBroker->new([ $DSN, undef, undef ]) ]); 1 },
      'a broker\'s answer with no user and password: connect_info takes it';
    is_deeply scalar eval { parse_conninfo(spawn_conninfo($s)) }, \%BASE,
      '... and a pooled connection is opened without them: DBI_USER and DBI_PASS are not the broker\'s';
    my $none = $EV->new(undef);
    ok !eval { $none->connect_info([ AnswerBroker->new([ undef, 'app', $SECRET ]) ]); 1 },
      'a broker\'s answer with no DSN: refused, DBI_DSN is not the broker\'s';
  }
}

# ---------------------------------------------------------------------------
# 5. A postgresql:// URI in the DSN's rest (karr k66 (c), decided 2026-10-09).
# ---------------------------------------------------------------------------
#
# Was listed as a question in k66, with no claim here: the transport died of
# a URI for want of a "=" and connected from one with a query by accident.
# The URI is read now (ConnectInfo, held against libpq in t/53 section 8);
# here it is held through the transport: every form that carries a DSN, from
# static connect info and from a broker, reaches the pool and the listen
# connection as the parameters of the URI, a user and a password beside it
# over the URI's own.
{
  my $URI_SECRET = 'k66:uri/p@ss?w%rd';
  (my $coded = $URI_SECRET) =~ s/([^A-Za-z0-9])/sprintf '%%%02X', ord $1/ge;
  my $URI  = "postgresql://uriuser:$coded\@db.example:5433/appdb?sslmode=disable&application_name=uri%20app";
  my %PARAMS = (host => 'db.example', port => 5433, dbname => 'appdb',
                sslmode => 'disable', application_name => 'uri app');
  my %BY_URI = (%PARAMS, user => 'uriuser', password => $URI_SECRET);
  my %BESIDE = (%PARAMS, user => 'app',     password => $SECRET);

  for my $case (
    [ 'the DBI form, the URI alone',
      sub { [ "dbi:Pg:$URI" ] }, \%BY_URI ],
    [ 'the DBI form, a user and a password beside the URI',
      sub { [ "dbi:Pg:$URI", 'app', $SECRET ] }, \%BESIDE ],
    [ 'a hash with a dsn key',
      sub { [ { dsn => "dbi:Pg:$URI", user => 'app', password => $SECRET } ] }, \%BESIDE ],
    [ 'DBI attributes in front of the URI',
      sub { [ "dbi:Pg(RaiseError=>1):$URI" ] }, \%BY_URI ],
  ) {
    my ($label, $info, $want) = @$case;

    for my $origin (
      [ 'static',            sub { $info->() } ],
      [ 'a broker\'s answer', sub { my $i = $info->(); [ AnswerBroker->new(ref $i->[0] eq 'HASH' ? { %{ $i->[0] } } : [ @$i ]) ] } ],
    ) {
      my ($where, $given) = @$origin;
      my $s = $EV->new(undef);
      ok eval { $s->connect_info($given->()); 1 }, "$label, $where: connect_info takes it" or diag $@;
      is_deeply scalar eval { parse_conninfo(spawn_conninfo($s)) }, $want,
        '... a pooled connection is opened with the parameters of the URI' or diag $@;
      is_deeply scalar eval { parse_conninfo(listen_conninfo($s)) }, $want,
        '... and so is the listen connection' or diag $@;
    }
  }

  # A URI that is no URI: refused by connect_info with the form named and
  # nothing of the URI -- libpq's message would quote it with the password.
  for my $bad ("postgresql://uriuser:$coded\@[::1/appdb", "postgresql://uriuser:$coded\@db.example/appdb?sslmode=%zz") {
    for my $origin (
      [ 'static',            sub { [ [ "dbi:Pg:$bad", 'app', $SECRET ] ] } ],
      [ 'a broker\'s answer', sub { [ AnswerBroker->new([ "dbi:Pg:$bad", 'app', $SECRET ]) ] } ],
    ) {
      my ($where, $given) = @$origin;
      my $s = $EV->new(undef);
      my $info = $given->();
      $info = $info->[0] if $where eq 'static';
      my $ok  = eval { $s->connect_info($info); 1 };
      my $err = "$@";
      ok !$ok, "an unreadable URI, $where: connect_info refuses it";
      like $err, qr/a DBI-form arrayref -- the dbi:Pg: DSN cannot be read as a libpq URI/, '... naming the form and why';
      unlike $err, qr/\Q$URI_SECRET\E|\Q$coded\E|\Q$SECRET\E|uriuser|appdb|db\.example/, '... and nothing of it';
    }
  }
}

done_testing;
