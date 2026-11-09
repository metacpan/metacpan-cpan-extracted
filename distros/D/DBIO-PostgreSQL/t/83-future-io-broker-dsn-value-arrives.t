use strict;
use warnings;
use Test::More;

# OFFLINE test: a libpq parameter an AccessBroker answers reaches libpq as the
# broker gave it, on the future_io transport (karr k96).
#
# WHY: a broker answering a hash of libpq parameters (Static, HostBound over
# it) names a database, a host and whatever else by VALUE. This transport
# writes those values into a dbi:Pg: DSN, and between that DSN and libpq sits
# DBD::Pg, which edits the DSN as text before libpq reads it. The writer
# protected a value against libpq's reading (blanks, ', \) and against
# DBD::Pg's ';' -- but not against DBD::Pg's two rewrites, which look at the
# whole DSN, the inside of a quoted value included:
#   * the first 'db=' or 'database=' anywhere becomes 'dbname=': an
#     application_name 'x db=1' arrived as 'x dbname=1';
#   * the first dbname="..." becomes dbname='...': a database named "app"
#     (with the quotes) was asked for as app, the same text inside another
#     value was rewritten too, and a dbname that only STARTS with a double
#     quote took everything up to the next one into the database name -- the
#     host among it, so the connection went wherever libpq's defaults point.
# No error anywhere: the connection is opened, with another value than the
# broker's. And a NUL in a value ends the DSN there (it is a C string from
# DBD::Pg on): every parameter sorted behind it is gone, a host just as
# silently.
#
# THE REFERENCE, read from source and measured on the installed DBD::Pg
# (3.20.2, linked against libpq 17), not guessed:
#   * Pg.pm 249-253, DBD::Pg::dr::connect: the two rewrites, each once;
#   * dbdimp.c, dbd_db_login6 (read in the 3.21.2 source, its behaviour
#     measured on 3.20.2): every ';' outside single quotes becomes a blank, a
#     backslash takes the next character along (so \' does not end a quoted
#     value there either); a user and a password that are not empty are
#     appended as user='...' password='...', ' and \ escaped;
#   * libpq, conninfo_parse (fe-connect.c): keyword = value separated by
#     whitespace, a value bare or in single quotes, \ taking the next
#     character in both; the later of two values for one keyword wins.
#
# HOW THIS FILE KNOWS WHAT ARRIVES. Two ways, because each alone is weak:
#   * a MODEL of the three steps above, in this file (dbd_pg_login_string,
#     libpq_reads). It runs everywhere and it can look at the cases a real
#     connect must not be tried with -- the ones where the host is lost;
#   * the REAL DBD::Pg and libpq, without a server: a connect to a unix
#     socket directory that does not exist fails in connect(2) and touches
#     nothing. DBD::Pg's 'pglogin' trace prints the string it hands libpq, and
#     libpq's error names the socket path it tried -- which is the host value
#     as libpq read it. A model nobody checks drifts with the next DBD::Pg, so
#     every string the model produces here is compared with the real one, and
#     a real connect is only tried when the model says the host is still the
#     dead socket directory. Where the trace is not there to read, those
#     comparisons skip and say so; the model's claims still run.
#
# What this file claims:
#   1. for each answer below, what libpq reads from the DSN this transport
#      writes is exactly the broker's parameters -- the values the writer
#      always protected, the two rewrites, and a user and password beside the
#      DSN (which never pass through it);
#   2. the model is DBD::Pg's and libpq's behaviour, not this file's idea of
#      it: for DSNs written out by hand here -- the rewrites firing, on
#      purpose -- the real DBD::Pg hands libpq the string the model says, and
#      libpq reads the host out of it the model reads;
#   3. the real thing agrees end to end: a value written by this transport as
#      part of the host is the socket directory libpq tries to connect to;
#   4. a value no connection string can carry -- one with a NUL -- is refused,
#      naming the parameter and never the value, and nothing is connected.
#
# WHAT RUNS FOR REAL: core's broker attach, this dist's shipped seams
# (_async_broker_conninfo, _pg_connect), DBI, DBD::Pg and libpq up to the
# failing connect(2).
# THE SUBSTITUTION: none in 1-3. In 4, DBI->connect counts its calls.

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

use DBI;
use DBD::Pg;
use DBIO::Util ();

{
  package HashBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

# A unix socket directory that does not exist: the only place a connection of
# this file may be tried at.
my $DEAD = '/nonexistent/dbio-postgresql-k96';

# The conninfo hash a connection is opened from for this broker answer:
# _pg_connect hands its dsn, user and password to DBI->connect as they are.
sub conninfo_for {
  my ($answer) = @_;
  my $s = DBIO::PostgreSQL::Storage::Async->new(undef);
  $s->connect_info([ HashBroker->new($answer) ]);
  return $s->_async_broker_conninfo('write');
}

# ---------------------------------------------------------------------------
# THE MODEL. Not the code under test: an image of DBD::Pg and libpq, checked
# against both in section 2.
# ---------------------------------------------------------------------------

# The string DBD::Pg hands to PQconnectdb for DBI->connect($dsn, $user, $pass).
sub dbd_pg_login_string {
  my ($dsn, $user, $pass) = @_;
  $dsn =~ s/\Adbi:Pg://i
    or die DBIO::Util::mask_connect_secrets("not a dbi:Pg: DSN: $dsn", [ $dsn, $user, $pass ]);

  # Pg.pm, DBD::Pg::dr::connect -- copied, each applies once.
  $dsn =~ s/\b(?:db|database)\s*=/dbname=/;
  $dsn =~ s/dbname\s*=\s*"(.+?)"/dbname='$1'/;

  # dbdimp.c, dbd_db_login6. It walks a C string: a NUL ends it.
  $dsn =~ s/\0.*\z//s;
  my @c = split //, $dsn;
  my ($string, $inquote) = ('', 0);
  for (my $i = 0; $i < @c; $i++) {
    if ($c[$i] eq ';' && !$inquote) { $string .= ' '; next }
    if    ($c[$i] eq '\\' && $i < $#c) { $string .= $c[$i++] }
    elsif ($c[$i] eq q{'})             { $inquote = !$inquote }
    $string .= $c[$i];
  }
  for my $beside ([ user => $user ], [ password => $pass ]) {
    my ($keyword, $value) = @$beside;
    next unless defined $value && length $value;
    $value =~ s/(['\\])/\\$1/g;
    $string .= " $keyword='$value'";
  }
  return $string;
}

# What libpq's conninfo_parse reads from such a string: ( \%parameters ), or
# ( undef, $why ) where libpq refuses it. It does not know libpq's keywords:
# an unknown one is refused by libpq and read here.
sub libpq_reads {
  my ($string) = @_;
  return (undef, 'no string') unless defined $string;
  my @c = split //, $string;
  my $i = 0;
  my $blank = sub { $i < @c && $c[$i] =~ /\A[ \t\n\r\f\x0B]\z/ };   # C isspace
  my %param;
  while ($i < @c) {
    $i++ while $blank->();
    last if $i >= @c;
    my $keyword = '';
    while ($i < @c && $c[$i] ne '=') {
      if ($blank->()) { $i++ while $blank->(); last }
      $keyword .= $c[$i++];
    }
    return (undef, qq{missing "=" after "$keyword"}) unless $i < @c && $c[$i] eq '=';
    $i++;
    $i++ while $blank->();
    my $value = '';
    if ($i < @c && $c[$i] eq q{'}) {
      $i++;
      while (1) {
        return (undef, 'unterminated quoted string') if $i >= @c;
        if ($c[$i] eq '\\') { $i++; $value .= $c[$i++] if $i < @c; next }
        if ($c[$i] eq q{'}) { $i++; last }
        $value .= $c[$i++];
      }
    }
    else {
      while ($i < @c) {
        if ($blank->()) { $i++; last }
        if ($c[$i] eq '\\') { $i++; $value .= $c[$i++] if $i < @c }
        else                { $value .= $c[$i++] }
      }
    }
    $param{$keyword} = $value;
  }
  return \%param;
}

# ---------------------------------------------------------------------------
# THE REAL THING, without a server.
# ---------------------------------------------------------------------------

# One real DBI->connect through the transport's own _pg_connect, failing in
# connect(2): ( the string DBD::Pg handed libpq, libpq's error ). libpq reads
# its environment for what a string leaves out, so none of it is there.
sub real_login {
  my ($conninfo) = @_;
  delete local @ENV{ grep { /^PG/ } keys %ENV };
  my $flag = DBD::Pg->parse_trace_flag('pglogin') or return;
  my $trace = '';
  open my $fh, '>', \$trace or die "in-memory trace handle: $!";
  my $level = DBI->trace($flag, $fh);
  my $conn = eval { DBIO::PostgreSQL::Storage::Async->_pg_connect($conninfo) };
  my $error = $DBI::errstr;
  DBI->trace($level, 'STDERR');
  close $fh;
  if ($conn) {
    $conn->{dbh}->disconnect;
    BAIL_OUT(DBIO::Util::mask_connect_secrets(
      "a connection was opened from [$conninfo->{dsn}] -- this file must never reach a server",
      [ @{$conninfo}{qw( dsn user password )} ],
    ));
  }
  my ($string) = $trace =~ /Login connection string: \((.*)\)\n(?:Connection complete\n|\z)/s;
  return ($string, $error);
}

# The socket directory libpq tried, out of its error: the host as libpq read
# it. undef when libpq tried none -- it refused the string before connecting.
sub socket_dir_tried {
  my ($error) = @_;
  return defined $error && $error =~ m{(\Q$DEAD\E.*)/\.s\.PGSQL\.\d+}s ? $1 : undef;
}

# May the real libpq be given this string? Only when the reading of it leaves
# no way to anything but the dead socket directory: a host that is it, or is
# under it, alone (a ',' would start a second host), and no hostaddr or
# service beside it. A string libpq refuses is opened nowhere; it still has
# to name the dead directory first, in case the model is wrong about that.
sub dead_end {
  my ($string, $read) = @_;
  return 0 unless defined $string;
  return $string =~ /\Ahost=\Q$DEAD\E / ? 1 : 0 unless $read;
  return 0 if exists $read->{hostaddr} || exists $read->{service};
  return defined $read->{host} && $read->{host} =~ m{\A\Q$DEAD\E(?:/[^,]*)?\z}s ? 1 : 0;
}

my $UNMEASURED = do {
  my ($string, $error) = -e $DEAD ? () : real_login({
    dsn => "dbi:Pg:host=$DEAD;dbname=appdb", user => 'app', password => 's3cret',
  });
  -e $DEAD
    ? "$DEAD exists on this machine"
    : !defined $string
      ? "DBD::Pg $DBD::Pg::VERSION prints no login string under its 'pglogin' trace flag"
      : $string ne "host=$DEAD dbname=appdb user='app' password='s3cret'"
        ? "DBD::Pg $DBD::Pg::VERSION hands libpq [$string] for a plain DSN"
        : (socket_dir_tried($error) // '') ne $DEAD
          ? "libpq's error names no socket path: [" . ($error // 'none') . ']'
          : undef;
};
diag "the real DBD::Pg and libpq are NOT consulted, the model stands unchecked: $UNMEASURED"
  if $UNMEASURED;

# ---------------------------------------------------------------------------
# 1. What libpq reads from the DSN is the broker's parameters.
# ---------------------------------------------------------------------------

my @CASES = (
  # The values the writer always protected (karr k80): they stay right.
  [ 'plain values',
    { dbname => 'appdb', port => 5433, sslmode => 'require' } ],
  [ 'a blank in a value',
    { dbname => 'my db' } ],
  [ q{a quote, a ';' and a blank -- the quote BEFORE the ';'},
    { dbname => q{it's; my db} } ],
  [ q{a ';' alone, which would end the parameter},
    { application_name => 'a;b' } ],
  [ 'a backslash, inside a value and at its end',
    { application_name => 'back\\slash', options => 'tail\\' } ],
  [ 'a tab and a newline',
    { application_name => "two\tcolumns\nand lines" } ],
  [ 'blanks around a value',
    { application_name => ' padded ' } ],

  # DBD::Pg's first rewrite: 'db=' / 'database=' becomes 'dbname='.
  [ q{'db=' in a value},
    { application_name => 'x db=1' } ],
  [ q{a value that is nothing but 'db=...'},
    { application_name => 'db=1' } ],
  [ q{'database=' in a value},
    { application_name => 'my database=prod' } ],
  [ q{'db =', a blank before the '='},
    { application_name => 'db = 1' } ],
  [ q{'db=' in a value sorted BEHIND dbname ('dbname=' is no match for the rewrite, so it does not shield it)},
    { dbname => 'appdb', options => '--app.db=1' } ],
  [ q{'db=' in two values},
    { application_name => 'job/db=7', options => '-c app.db=1' } ],

  # DBD::Pg's second rewrite: dbname="..." becomes dbname='...'.
  [ 'a database name in double quotes: they are part of the name',
    { dbname => '"appdb"' } ],
  [ 'a database name in double quotes with a blank',
    { dbname => '"my db"' } ],
  [ q{a database name that starts with a double quote, and one more later in the DSN: the host does not disappear into the name},
    { dbname => '"app', options => '--x="' } ],
  [ q{'dbname = "..."' inside another value},
    { application_name => 'dbname = "y"' } ],

  # What the protection against both is made of.
  [ q{a '=' alone},
    { options => '-csearch_path=app' } ],
  [ 'a double quote alone',
    { application_name => 'say"hi' } ],
  [ 'everything at once',
    { application_name => q{db=1; it's "x" \\ database = 2},
      dbname           => '"db=3"',
      options          => q{-c app.db=4 -c x='y'} } ],

  # Not in the DSN at all: DBD::Pg appends them itself, escaped.
  [ 'a user and a password with all of it: they go beside the DSN, not through it',
    { user => 'db=1', password => q{p'w\\ db=2; dbname="x"} } ],
);

for my $case (@CASES) {
  my ($label, $given) = @$case;
  my %answer = (dbname => 'appdb', host => $DEAD, user => 'app', password => 's3cret', %$given);

  my $conninfo = eval { conninfo_for(\%answer) };
  my $refused  = $@;
  my $string   = $conninfo ? dbd_pg_login_string(@{$conninfo}{qw( dsn user password )}) : undef;
  my ($read, $why) = libpq_reads($string);

  is_deeply $read, \%answer, "$label: libpq reads what the broker answered"
    or diag $conninfo
      ? "DSN [$conninfo->{dsn}]\nDBD::Pg hands libpq [$string]" . ($why ? "\nlibpq refuses it: $why" : '')
      : "no conninfo: $refused";

  SKIP: {
    skip "not measured: $UNMEASURED", 1 if $UNMEASURED;
    skip 'not given to the real libpq: the model reads another way out of it than the dead socket directory', 1
      unless dead_end($string, $read);
    my ($real) = real_login($conninfo);
    is $real, $string, '... and that is the string the installed DBD::Pg hands libpq';
  }
}

# ---------------------------------------------------------------------------
# 2. The model against the real DBD::Pg and libpq, on DSNs written by hand.
#
# After the fix the transport writes no DSN a rewrite fires on, so section 1
# no longer shows the real DBD::Pg rewriting anything. These do, whatever the
# writer does -- they are what the model's two rewrites, its ';' walk and its
# reader are an image of. The host comes first in each, so that it survives
# whatever is done to the rest.
# ---------------------------------------------------------------------------

for my $case (
  [ q{the first 'db=' becomes 'dbname=', inside a quoted value, and only the first},
    "host=$DEAD;application_name='x db=1';options=a-db=2" ],
  [ q{'database =' with blanks, in a bare value's place},
    "host=$DEAD;application_name=x database = 1;dbname=appdb" ],
  [ q{'-cdb=1': no word boundary before 'db', no rewrite},
    "host=$DEAD;dbname=appdb;options=-cdb=1" ],
  [ 'dbname in double quotes becomes single-quoted',
    qq{host=$DEAD;dbname="x"} ],
  [ q{'dbname = "y"' inside a quoted value is rewritten as well, and libpq refuses the result},
    qq{host=$DEAD;application_name='dbname = "y"';dbname=appdb} ],
  [ 'the double-quoted span runs to the NEXT double quote, across parameters',
    qq{host=$DEAD;dbname="x;application_name=a"} ],
  [ '... and no further than the next one',
    qq{host=$DEAD;dbname="x";application_name=a"b} ],
  [ q{an escaped '=' stops both rewrites},
    qq{host=$DEAD;application_name='x db\\=1';dbname='"x"';options='dbname \\= "y"'} ],
  [ q{a ';' inside single quotes stays, also behind an escaped quote},
    "host=$DEAD;application_name='it\\'s; here';dbname=appdb" ],
  [ 'an escaped backslash ends nothing',
    "host=$DEAD;application_name='tail\\\\';dbname=appdb" ],
  [ 'a NUL ends the DSN: what follows is gone',
    "host=$DEAD;application_name=a\0b;dbname=appdb" ],
  [ 'the host as libpq reads it: quoted, with every escape',
    qq{dbname=appdb;host='$DEAD/x db\\=1; it\\'s \\\\ "q"'} ],
  [ 'the host as libpq reads it: bare, with escapes',
    "dbname=appdb;host=$DEAD/x\\ y\\=z" ],
  [ 'the host as libpq reads it: a newline in quotes',
    "dbname=appdb;host='$DEAD/l1\nl2'" ],
) {
  my ($label, $dsn) = @$case;
  my %conninfo = (dsn => "dbi:Pg:$dsn", user => q{o'neil}, password => q{p\\w; 'x'});
  my $string = dbd_pg_login_string(@conninfo{qw( dsn user password )});
  my ($read) = libpq_reads($string);

  SKIP: {
    skip "not measured: $UNMEASURED", 2 if $UNMEASURED;
    BAIL_OUT(DBIO::Util::mask_connect_secrets(
      "a hand-written DSN of this file leads somewhere else than $DEAD: [$dsn]",
      [ @conninfo{qw( dsn user password )} ],
    )) unless dead_end($string, $read);
    my ($real, $error) = real_login(\%conninfo);
    is $real, $string, "DBD::Pg, $label: the model hands libpq what DBD::Pg does";
    is socket_dir_tried($error), ($read ? $read->{host} : undef),
      $read ? '... and libpq reads the host out of it the model reads'
            : '... and libpq refuses it, as the model does: it tries no socket';
  }
}

# ---------------------------------------------------------------------------
# 3. End to end, for real: the value this transport writes is the socket
#    directory libpq goes to.
# ---------------------------------------------------------------------------

for my $value (
  'plain',
  'x db=1',
  'my database = prod',
  'a=b',
  'say "hi"',
  'dbname = "y"',
  q{it's; here},
  'back\\slash',
) {
  my $host     = "$DEAD/$value";
  my $conninfo = eval { conninfo_for({ dbname => 'appdb', host => $host, user => 'app', password => 's3cret' }) };

  SKIP: {
    skip "not measured: $UNMEASURED", 1 if $UNMEASURED;
    my $string = $conninfo ? dbd_pg_login_string(@{$conninfo}{qw( dsn user password )}) : undef;
    skip "[$value] not given to the real libpq: the model reads another way out of it than the dead socket directory", 1
      unless dead_end($string, (libpq_reads($string))[0]);
    my (undef, $error) = real_login($conninfo);
    is socket_dir_tried($error), $host, "libpq itself reads [$value] as the transport was given it";
  }
}

# ---------------------------------------------------------------------------
# 4. A NUL: no connection string can carry it.
#
# Written into the DSN it would end it (section 2 shows DBD::Pg doing that):
# here the host would be gone and libpq would connect by its defaults.
# ---------------------------------------------------------------------------

{
  my $connects = 0;
  no warnings 'redefine';
  local *DBI::connect = sub { $connects++; die "DBI->connect was reached\n" };

  my $s = DBIO::PostgreSQL::Storage::Async->new(undef);
  $s->connect_info([ HashBroker->new({
    application_name => "nul\0inside", dbname => 'appdb', host => $DEAD,
    user => 'app', password => 'hunter2',
  }) ]);

  my $ok  = eval { $s->_listen_open; 1 };
  my $err = $@;
  ok !$ok, 'a value with a NUL: opening a connection croaks';
  like $err, qr/PostgreSQL future_io cannot connect from what the AccessBroker returned/,
    '... saying what it could not connect from';
  like $err, qr/parameter 'application_name' contains a NUL/, '... naming the parameter';
  unlike $err, qr/inside|hunter2/, '... and neither its value nor the password';
  is $connects, 0, '... and nothing was sent to DBI->connect';
}

done_testing;
