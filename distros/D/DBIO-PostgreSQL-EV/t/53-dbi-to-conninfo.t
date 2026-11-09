use strict;
use warnings;
use Test::More;

# OFFLINE test: dbi_to_conninfo reads a dbi:Pg: DSN the way DBD::Pg does
# (karr k58, measured in k54).
#
# WHY: connect info [ $dsn, $user, $pass ] is read twice. The owning sync
# storage hands it to DBD::Pg for its dbh; this transport hands it to
# dbi_to_conninfo for every pooled connection and for the listen connection.
# Two readers that disagree open two different connections from one DSN: the
# pool somewhere else than the dbh, or as someone else. dbi_to_conninfo split
# the DSN at every ';' and at the first '=' of each piece, which is not what
# DBD::Pg does, so they disagreed -- about a quoted value, a ';' inside one,
# 'db=', parameters separated by blanks, and about who wins when the user is
# named both in the DSN and beside it.
#
# THE REFERENCE, read from source and not guessed (DBD::Pg 3.20.2, the
# installed one; libpq 17):
#   * Pg.pm 249-253, DBD::Pg::dr::connect: the first 'db=' or 'database=' in
#     the DSN becomes 'dbname=', and a database name in double quotes one in
#     single quotes;
#   * dbdimp.c 229-242, dbd_db_login6: every ';' outside single quotes becomes
#     a space, a backslash taking the next character along;
#   * dbdimp.c 245-271: a user and a password that are not empty are appended
#     as user='...' and password='...';
#   * the string then goes to PQconnectdb. libpq's conninfo_parse
#     (fe-connect.c) reads keyword = value separated by whitespace, a value in
#     single quotes or bare, \ escaping the next character in both, and
#     conninfo_storeval lets the later of two values for one keyword win --
#     which is why the appended user and password beat the DSN's.
#
# Each case below names the string DBD::Pg hands to libpq for it ($conn_str,
# as its 'pglogin' trace prints it). What this file claims per case:
#   1. dbi_to_conninfo answers the parameters libpq reads out of that string;
#   2. the expectation is libpq's reading and not this file's: libpq itself
#      (PQconninfoParse, through EV::Pg->conninfo_parse) reads $conn_str to
#      the same parameters;
#   3. the way back holds: what conninfo_string renders from the answer -- the
#      string every pooled connection is opened with -- libpq reads to the
#      same parameters again. A value that lost its quotes on the way in gets
#      them back on the way out.
#
# Before DBD::Pg sees a DSN, DBI has read it: the driver, the attributes in
# parentheses behind it, and DBI's Username and Password attributes, which it
# connects with instead of the user and password beside the DSN. Section 7
# holds that part against DBI itself (karr k66).
#
# WHAT RUNS FOR REAL: ConnectInfo, the transport's connect_info, libpq's own
# conninfo parser, and in section 7 DBI->connect up to the driver. Nothing is
# connected: PQconninfoParse parses and returns, and DBD::Pg's connect is
# replaced by one that keeps what DBI handed it.

use EV::Pg;
use DBIO::PostgreSQL::EV::ConnectInfo qw( dbi_to_conninfo conninfo_string );
use DBIO::PostgreSQL::EV::Storage;

# libpq's reading of a conninfo string: the parameters it names. undef, with
# libpq's complaint as a diagnostic, when libpq refuses the string.
sub libpq_reads {
  my ($string) = @_;
  my $params = eval { EV::Pg->conninfo_parse($string) };
  diag "libpq refuses [$string]: $@" unless $params;
  return $params;
}

sub reads_like_dbd_pg {
  my ($label, $info, $conn_str, $want) = @_;
  my $got = eval { dbi_to_conninfo($info)->[0] };
  is_deeply $got, $want, $label or diag $@ || explain $got;
  is_deeply libpq_reads($conn_str), $want,
    '... which is what libpq reads from the string DBD::Pg hands it';
  is_deeply libpq_reads(conninfo_string($got // {})), $want,
    '... and what libpq reads from the string a pooled connection is opened with';
  return;
}

# ---------------------------------------------------------------------------
# 1. Who the connection is opened as: the user and password beside the DSN
#    against the ones in it.
# ---------------------------------------------------------------------------
#
# The case that matters most. DBD::Pg appends its $user and $pass arguments
# behind the DSN's parameters and libpq takes the later one, so the arguments
# win. dbi_to_conninfo let the DSN win: with a user in both places the dbh was
# opened as one role and every pooled connection as the other -- statements
# through the pool ran with another role's rights than the ones through the
# dbh, on one schema object, from one connect call. The same for a broker: a
# Vault broker answers [ $dsn, $leased_user, $leased_password ], and a DSN
# naming a user pinned the pool to that one while the lease rotated.

{
  my $dsn = 'dbi:Pg:dbname=appdb;host=db.example;user=dsn-user;password=dsn-pw';
  my %where = (dbname => 'appdb', host => 'db.example');

  reads_like_dbd_pg(
    'a user and password beside the DSN win over the ones in it: the pool connects as the dbh does',
    [ $dsn, 'arg-user', 'arg-pw' ],
    q{dbname=appdb host=db.example user=dsn-user password=dsn-pw user='arg-user' password='arg-pw'},
    { %where, user => 'arg-user', password => 'arg-pw' },
  );

  # Not appended at all when undefined or empty (dbdimp.c: "if (*uid)"), so
  # the DSN's stay. Each on its own: a user beside the DSN does not bring a
  # password with it.
  reads_like_dbd_pg(
    'no user and no password beside the DSN: the ones in it are used',
    [ $dsn, undef, undef ],
    q{dbname=appdb host=db.example user=dsn-user password=dsn-pw},
    { %where, user => 'dsn-user', password => 'dsn-pw' },
  );
  reads_like_dbd_pg(
    'an empty user and password beside the DSN count as none',
    [ $dsn, '', '' ],
    q{dbname=appdb host=db.example user=dsn-user password=dsn-pw},
    { %where, user => 'dsn-user', password => 'dsn-pw' },
  );
  reads_like_dbd_pg(
    'a user alone beside the DSN wins, and the password in the DSN stays',
    [ $dsn, 'arg-user', undef ],
    q{dbname=appdb host=db.example user=dsn-user password=dsn-pw user='arg-user'},
    { %where, user => 'arg-user', password => 'dsn-pw' },
  );

  # An empty user is not "user=''". libpq fills a parameter that is absent
  # from PGUSER, and one that is given empty from the operating system's user
  # name without looking at PGUSER (conninfo_add_defaults skips a parameter
  # that has a value). The dbh gets no user parameter here, so the pool must
  # get none either, or the two connect as different users wherever PGUSER is
  # set.
  reads_like_dbd_pg(
    'an empty user and password, none in the DSN: no user and no password parameter at all',
    [ 'dbi:Pg:dbname=appdb;host=db.example', '', '' ],
    q{dbname=appdb host=db.example},
    { %where },
  );

  # DBD::Pg appends them as text. A DSN ending in 'keyword=' has no value for
  # libpq to end at, so the appended user is read as that value: the dbh gets
  # the application name "user='arg-user'" and no user, and connects as
  # whoever PGUSER or the operating system names. Set as a parameter of its
  # own here, the pool would connect as arg-user where the dbh does not.
  reads_like_dbd_pg(
    q{a DSN ending in 'keyword=' takes the user beside it for that value, as it does for the dbh},
    [ 'dbi:Pg:dbname=appdb;application_name=', 'arg-user', undef ],
    q{dbname=appdb application_name= user='arg-user'},
    { dbname => 'appdb', application_name => q{user='arg-user'} },
  );

  # The arguments are values, whatever is in them: DBD::Pg quotes and escapes
  # them into its string, so nothing in a password is read as syntax.
  reads_like_dbd_pg(
    q{a quote, a backslash, a blank, a ';' and a '=' in the user and password beside the DSN are part of them},
    [ 'dbi:Pg:dbname=appdb', q{o'neil}, q{p\\w; host=evil 'x'} ],
    q{dbname=appdb user='o\\'neil' password='p\\\\w; host=evil \\'x\\''},
    { dbname => 'appdb', user => q{o'neil}, password => q{p\\w; host=evil 'x'} },
  );

  # Through the transport, as the owning sync storage hands its connect info
  # on: what a new pooled connection is opened with.
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ $dsn, 'arg-user', 'arg-pw' ]);
  is_deeply libpq_reads($storage->_conninfo_string),
    { %where, user => 'arg-user', password => 'arg-pw' },
    'through the transport: a pooled connection is opened as the user beside the DSN';
}

# ---------------------------------------------------------------------------
# 2. Where the connection goes: the DSN's own parameters.
# ---------------------------------------------------------------------------

for my $case (
  # A value in single quotes arrived with them: libpq was asked for a database
  # called 'my db', quotes included, which does not exist.
  [ 'a value in single quotes is the value without them',
    q{dbi:Pg:dbname='my db';host='db.example'},
    q{dbname='my db' host='db.example'},
    { dbname => 'my db', host => 'db.example' } ],

  # The ';' cut the value in two: password was "'se", and "cret'" became a
  # parameter name of its own -- a truncated password and a parameter nobody
  # gave.
  [ q{a ';' inside single quotes is part of the value and separates nothing},
    q{dbi:Pg:dbname=appdb;password='se;cret';host=db.example},
    q{dbname=appdb password='se;cret' host=db.example},
    { dbname => 'appdb', password => 'se;cret', host => 'db.example' } ],

  # 'db' is no libpq keyword: left alone it is refused, while the dbh connects.
  [ q{'db=' names the database},
    'dbi:Pg:db=appdb;host=db.example',
    'dbname=appdb host=db.example',
    { dbname => 'appdb', host => 'db.example' } ],
  [ q{'database=' names the database, with blanks around the '=' too},
    'dbi:Pg:host=db.example;database = appdb',
    'host=db.example dbname= appdb',
    { dbname => 'appdb', host => 'db.example' } ],
  [ 'a database name in double quotes is one in single quotes',
    'dbi:Pg:dbname="my db";host=db.example',
    q{dbname='my db' host=db.example},
    { dbname => 'my db', host => 'db.example' } ],

  # Blanks separate parameters for libpq, and DBD::Pg only ever adds some.
  # Glued together, host and port became part of the database name.
  [ 'parameters separated by blanks are separate parameters',
    'dbi:Pg:dbname=appdb host=db.example port=5433',
    'dbname=appdb host=db.example port=5433',
    { dbname => 'appdb', host => 'db.example', port => 5433 } ],
  [ q{... by any whitespace, mixed with ';'},
    "dbi:Pg:dbname=appdb;\n  host=db.example\tport=5433;",
    "dbname=appdb \n  host=db.example\tport=5433 ",
    { dbname => 'appdb', host => 'db.example', port => 5433 } ],
  [ q{blanks around '=' belong to neither the name nor the value},
    'dbi:Pg:dbname = appdb;host= db.example;port =5433',
    'dbname = appdb host= db.example port =5433',
    { dbname => 'appdb', host => 'db.example', port => 5433 } ],

  # \ takes the next character as it is, inside quotes and outside.
  [ q{\\' and \\\\ inside single quotes are a quote and a backslash},
    q{dbi:Pg:dbname=appdb;password='it\\'s a \\\\ path'},
    q{dbname=appdb password='it\\'s a \\\\ path'},
    { dbname => 'appdb', password => q{it's a \\ path} } ],
  [ q{... and in a bare value, where an escaped ';' or blank does not end it},
    q{dbi:Pg:dbname=it\\'s;password=a\\;b\\ c;host=db.example},
    q{dbname=it\\'s password=a\\;b\\ c host=db.example},
    { dbname => q{it's}, password => 'a;b c', host => 'db.example' } ],

  # An empty value is given as ''. Without the quotes libpq skips the blanks
  # behind the '=' and takes what follows as the value: 'host=;port=5433' is
  # the host "port=5433" for the dbh, which fails to resolve. Read as an empty
  # host and port 5433, the pool would connect to the local socket instead --
  # somewhere the dbh never goes.
  [ q{an empty value is ''},
    q{dbi:Pg:dbname=appdb;password='';host=db.example},
    q{dbname=appdb password='' host=db.example},
    { dbname => 'appdb', password => '', host => 'db.example' } ],
  [ q{a value left out before the next parameter swallows it, as libpq reads it},
    'dbi:Pg:dbname=appdb;host=;port=5433',
    'dbname=appdb host= port=5433',
    { dbname => 'appdb', host => 'port=5433' } ],
  [ 'a value left out at the end is empty',
    'dbi:Pg:dbname=appdb;application_name=',
    'dbname=appdb application_name=',
    { dbname => 'appdb', application_name => '' } ],

  [ 'a parameter named twice has its later value',
    'dbi:Pg:host=old.example;dbname=appdb;host=new.example',
    'host=old.example dbname=appdb host=new.example',
    { dbname => 'appdb', host => 'new.example' } ],
) {
  my ($label, $dsn, $conn_str, $want) = @$case;
  reads_like_dbd_pg($label, [ $dsn, undef, undef ], $conn_str, $want);
}

# ---------------------------------------------------------------------------
# 3. What the dbh cannot connect from, the pool does not connect from either.
# ---------------------------------------------------------------------------
#
# libpq refuses these, so the dbh never opens. dbi_to_conninfo read each of
# them as something libpq accepts -- a different connection than the one that
# was asked for, instead of none.

{
  # A parameter name is as it is written: libpq compares keywords exactly, and
  # DBD::Pg rewrites only a lower-case 'db' / 'database'. Lower-cased here,
  # 'Host=' reached a server the dbh was refused for.
  my $got = eval { dbi_to_conninfo([ 'dbi:Pg:DBNAME=appdb;Host=db.example', undef, undef ])->[0] };
  is_deeply $got, { DBNAME => 'appdb', Host => 'db.example' },
    'a parameter name keeps its case' or diag $@ || explain $got;
  ok !eval { EV::Pg->conninfo_parse(conninfo_string($got // {})) },
    '... so libpq refuses it for the pool as it does for the dbh';

  # 'password=two words': libpq ends the value at the blank and finds 'words'
  # without a '='. Glued, the pool logged in with a password the dbh never
  # sent; and a parameter without '=' on its own was dropped without a word.
  # libpq's own complaint quotes the piece it stopped at, which may be half a
  # password; dbi_to_conninfo says which rule was broken and nothing of the
  # DSN.
  for my $case (
    [ q{a parameter without '='},
      [ 'dbi:Pg:dbname=appdb;host', 'app', 'hunter2' ],
      q{dbname=appdb host user='app' password='hunter2'},
      qr/missing "="/ ],
    [ 'a bare value with a blank in it',
      [ 'dbi:Pg:dbname=appdb;password=two words', 'app', 'hunter2' ],
      q{dbname=appdb password=two words user='app' password='hunter2'},
      qr/missing "="/ ],
    [ 'a quote that is never closed',
      [ q{dbi:Pg:dbname=appdb;password='two words}, undef, undef ],
      q{dbname=appdb password='two words},
      qr/unterminated quoted/ ],
  ) {
    my ($label, $info, $conn_str, $error_re) = @$case;
    ok !eval { EV::Pg->conninfo_parse($conn_str) },
      "$label: libpq refuses the string DBD::Pg hands it";
    like $@, $error_re, '... for what it is';

    my $ok  = eval { dbi_to_conninfo($info); 1 };
    my $err = $@;
    ok !$ok, '... and dbi_to_conninfo dies';
    like $err, $error_re, '... of the same';
    unlike $err, qr/hunter2|two|words|appdb/, '... without a word of the DSN or the password in it';
  }
}

# ---------------------------------------------------------------------------
# 4. The connect info it reads is the caller's, and stays as it was.
# ---------------------------------------------------------------------------
#
# The array is the sync storage's stored connect info, or what a broker
# answered. Looking for the attribute hashes in slots [3] and [4] made those
# slots: a three-element array came back with five, so the next reader of the
# same array -- the dbh's own connect, a describe of the broker's answer --
# saw a shape nobody had given.

for my $case (
  [ 'three elements',             [ 'dbi:Pg:dbname=appdb', 'app', 'pw' ] ],
  [ 'a DSN alone',                [ 'dbi:Pg:dbname=appdb' ] ],
  [ 'four, with attributes',      [ 'dbi:Pg:dbname=appdb', 'app', 'pw', { pool_size => 3, AutoCommit => 1 } ] ],
  [ 'five, the fourth undefined', [ 'dbi:Pg:dbname=appdb', 'app', 'pw', undef, { pool_size => 3 } ] ],
) {
  my ($label, $info) = @$case;
  my @before = map { ref $_ eq 'HASH' ? { %$_ } : $_ } @$info;

  dbi_to_conninfo($info);

  is scalar(@$info), scalar(@before), "connect info of $label: still as many elements";
  is_deeply $info, \@before, '... holding what they held';
}

# ---------------------------------------------------------------------------
# 5. The way round: a DSN written from libpq parameters reads back to them.
# ---------------------------------------------------------------------------
#
# The sync driver's future_io transport writes libpq parameters into a
# dbi:Pg: DSN for DBD::Pg (dbio-postgresql k80, _pg_dsn_value: a value is bare
# unless it holds whitespace, ';', a quote or a backslash, then single-quoted
# with ' and \ escaped; the parameters joined with ';'). A DSN written that
# way reaches this transport as a broker's DBI-form answer or as plain connect
# info, and must come back as the values that went in. $written is that rule
# applied by hand; the writer itself is asked too, where it is installed, so
# the two cannot drift apart unseen.

{
  my $writer = eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    && DBIO::PostgreSQL::Storage::Async->can('_pg_dsn_value');

  for my $case (
    [ 'appdb',          'appdb' ],
    [ 'my db',          q{'my db'} ],
    [ ' padded ',       q{' padded '} ],
    [ 'a;b',            q{'a;b'} ],
    [ q{it's},          q{'it\\'s'} ],
    [ 'back\\slash',    q{'back\\\\slash'} ],
    [ 'a=b',            'a=b' ],
    [ "tab\there",      qq{'tab\there'} ],
    [ q{'q' \\ ; = "},  q{'\\'q\\' \\\\ ; = "'} ],
  ) {
    my ($value, $written) = @$case;
    (my $shown = $value) =~ s/\t/\\t/;
    my $want = { dbname => $value, host => 'db.example' };

    my $got = eval { dbi_to_conninfo([ "dbi:Pg:dbname=$written;host=db.example" ])->[0] };
    is_deeply $got, $want, "a DSN value written for [$shown] reads back as it" or diag $@ || explain $got;

    SKIP: {
      skip 'DBIO::PostgreSQL::Storage::Async with _pg_dsn_value is not installed', 1 unless $writer;
      my $dsn = 'dbi:Pg:dbname=' . DBIO::PostgreSQL::Storage::Async->$writer($value) . ';host=db.example';
      $got = eval { dbi_to_conninfo([ $dsn ])->[0] };
      is_deeply $got, $want, '... and so does what the sync driver writes for it' or diag $@ || explain $got;
    }
  }
}

# ---------------------------------------------------------------------------
# 6. A DSN it does not read is named without its password (karr k78).
# ---------------------------------------------------------------------------
#
# dbi_to_conninfo reads a DSN for DBD::Pg -- 'dbi:Pg:<parameters>', with or
# without DBI attributes in front (section 7) -- and nothing else, and says so
# naming the DSN it got: that is how its caller sees that it wrote another
# driver's. The DSN was quoted as it came. A DSN is where a password is
# written -- as password=, as DBI's Password attribute, inside a URI -- and
# this message ends in a log, a bug report, the exception page of a web
# application. So it names the DSN the way core names connect info in a
# message (DBIO::Util::mask_connect_secrets, core k297): the password as ***,
# and everything else as it was, or the message says nothing.
#
# The transport does not pass that message on. Its connect_info reads every
# form of connect info in one place and names the form of what it cannot
# read, with the DBI driver, and nothing of the DSN (karr k66;
# t/71-connect-info-forms-mock.t).

{
  my $SECRET = 'hunter2';

  for my $case (
    [ 'a quoted password= with a blank and a semicolon in it',
      [ "dbi:mysql:database=appdb;password='hun;ter2 $SECRET';host=db.example", 'app', undef ],
      qr/dbi:mysql:database=appdb;password=\*\*\*;host=db\.example/, 'mysql' ],
    [ q{DBI's Password attribute in front of the driver's name and no colon (nothing behind dbi:Pg: is read since k66)},
      [ "dbi:Pg(Username=>app,Password=>$SECRET)" ],
      qr/dbi:Pg\(Username=>app,Password=\*\*\*/, 'Pg' ],
    [ 'a DSN with no colon behind the driver',
      [ "dbi:Pg;dbname=appdb;password=$SECRET;host=db.example" ],
      qr/dbi:Pg;dbname=appdb;password=\*\*\*;host=db\.example/, 'Pg' ],
    [ 'a URI behind another driver name',
      [ "dbi:PgPP:postgresql://app:$SECRET\@db.example/appdb" ],
      qr{dbi:PgPP:postgresql://app:\*\*\*\@db\.example/appdb}, 'PgPP' ],
    # The password beside the DSN is not in the message unless the DSN repeats
    # it -- under a key nothing would take for a password's.
    [ 'the password beside the DSN, repeated in it under another key',
      [ "dbi:mysql:database=appdb;token=$SECRET;host=db.example", 'app', $SECRET ],
      qr/dbi:mysql:database=appdb;token=\*\*\*;host=db\.example/, 'mysql' ],
    [ 'no DSN at all, a password beside it',
      [ undef, 'app', $SECRET ],
      qr/\(undef\)/ ],
  ) {
    my ($label, $info, $named_re, $driver) = @$case;

    my $ok  = eval { dbi_to_conninfo($info); 1 };
    my $err = $@;
    ok !$ok, "$label: dbi_to_conninfo dies";
    like $err, qr/^expected dbi:Pg:\.\.\. DSN, got: /, '... saying what it reads and what it got';
    unlike $err, qr/\Q$SECRET\E|hun;ter2/, '... without the password';
    like $err, $named_re, '... and with the rest of the DSN: the driver and the form are still there to see';

    # The same through the transport, which reads every 'dbi:' connect info
    # itself and names its form.
    next unless defined $info->[0];
    $ok  = eval { DBIO::PostgreSQL::EV::Storage->new(undef)->connect_info($info); 1 };
    $err = $@;
    ok !$ok, '... the transport refuses it as connect info';
    unlike $err, qr/\Q$SECRET\E|hun;ter2/, '... without the password';
    like $err, qr/a DBI-form arrayref whose DSN is not dbi:Pg:<parameters> \(DBI driver '\Q$driver\E'\)/,
      '... naming the form and the DBI driver';
    unlike $err, qr/appdb|db\.example/, '... and nothing of the DSN';
  }

  # What is no password stays: masking must not make the message useless.
  my $ok  = eval { dbi_to_conninfo([ 'dbi:mysql:database=appdb;host=db.example;user=app', 'app', undef ]); 1 };
  my $err = $@;
  ok !$ok, 'a DSN without a password: dbi_to_conninfo dies';
  is $err, "expected dbi:Pg:... DSN, got: dbi:mysql:database=appdb;host=db.example;user=app\n",
    '... quoting it whole';
}

# ---------------------------------------------------------------------------
# 7. DBI's part: the attributes in front of the DSN, Username and Password.
# ---------------------------------------------------------------------------
#
# DBD::Pg is handed a DSN that DBI has read first (DBI.pm, DBI->connect and
# parse_dsn; DBI 1.651, the installed one):
#   * $dsn =~ s/^dbi:(\w*?)(?:\((.*?)\))?://i -- the driver, and in
#     parentheses behind it attributes; what is left is the driver's;
#   * %attributes = (PrintError => 1, AutoCommit => 1, %$attr,
#     split /\s*=>?\s*|\s*,\s*/, $driver_attrib_spec, -1) -- the attributes in
#     the DSN over those of the attribute hash;
#   * $user = $attr->{Username} if defined $attr->{Username}, and the same
#     for $pass and Password -- over the user and password beside the DSN;
#   * $drh->connect($dsn, $user, $pass, $attr).
# The transport read none of it. 'dbi:Pg(RaiseError=>1):...' connected the
# sync half of a schema and stopped its first ->async; and with Username
# among the attributes the dbh was opened as that user and every pooled
# connection as the one beside the DSN.
#
# THE REFERENCE is DBI: for each case DBI->connect runs with the connect info,
# and DBD::Pg's connect is replaced by one that keeps what DBI hands it. What
# this section claims per case:
#   1. DBI hands DBD::Pg the DSN, user and password this file expects;
#   2. dbi_to_conninfo reads the connect info to the parameters it reads from
#      that hand-over written as the plain DBI form -- the reading sections 1
#      to 5 hold against DBD::Pg and libpq.

SKIP: {
  skip 'DBI and DBD::Pg are needed to ask DBI how it reads a DSN', 1
    unless eval { require DBI; require DBD::Pg; DBI->install_driver('Pg'); 1 };

  # What DBI->connect hands DBD::Pg: [ $dsn, $user, $password ]. Called as
  # the sync storage calls it, the two attribute hashes merged, the later
  # winning (DBIO::Storage::DBI::_normalize_connect_info).
  my $dbi_hands_dbd_pg = sub {
    my ($info) = @_;
    my ($dsn, $user, $pass, $attrs, $extra_attrs) = @$info;
    my %attr = (%{ $attrs || {} }, %{ $extra_attrs || {} });
    no warnings qw( redefine once );
    local *DBD::Pg::dr::connect = sub { shift; die bless [ @_[0 .. 2] ], 'K66::Handed' };
    delete local @ENV{qw( DBI_DSN DBI_USER DBI_PASS DBI_DRIVER DBI_AUTOPROXY )};
    local $SIG{__WARN__} = sub { };   # an odd number of attributes in the DSN
    eval { DBI->connect($dsn, $user, $pass, \%attr) };
    die "DBI did not reach DBD::Pg: $@" unless ref $@ eq 'K66::Handed';
    return [ @{$@} ];
  };

  my $PARAMS = 'dbname=appdb;host=db.example';
  my %where  = (dbname => 'appdb', host => 'db.example');

  for my $case (
    # [ label, connect info, what DBI hands DBD::Pg, the parameters, the pool size ]
    [ 'DBI attributes in front of the DSN are no part of it',
      [ "dbi:Pg(RaiseError=>1):$PARAMS", 'app', 'pw' ],
      [ $PARAMS, 'app', 'pw' ], { %where, user => 'app', password => 'pw' } ],
    [ 'several of them',
      [ "dbi:Pg(RaiseError=>1,AutoCommit=>0,PrintError=>0):$PARAMS", 'app', 'pw' ],
      [ $PARAMS, 'app', 'pw' ], { %where, user => 'app', password => 'pw' } ],
    [ 'empty parentheses',
      [ "dbi:Pg():$PARAMS", 'app', 'pw' ],
      [ $PARAMS, 'app', 'pw' ], { %where, user => 'app', password => 'pw' } ],
    [ 'DBI: in capitals',
      [ "DBI:Pg(RaiseError=>1):$PARAMS", 'app', 'pw' ],
      [ $PARAMS, 'app', 'pw' ], { %where, user => 'app', password => 'pw' } ],
    [ 'Username and Password in front of the DSN win over the ones beside it',
      [ "dbi:Pg(Username=>dsn-user,Password=>dsn-pw):$PARAMS", 'arg-user', 'arg-pw' ],
      [ $PARAMS, 'dsn-user', 'dsn-pw' ], { %where, user => 'dsn-user', password => 'dsn-pw' } ],
    [ 'Username alone in front of the DSN: the password beside it stays',
      [ "dbi:Pg(Username=>dsn-user):$PARAMS", 'arg-user', 'arg-pw' ],
      [ $PARAMS, 'dsn-user', 'arg-pw' ], { %where, user => 'dsn-user', password => 'arg-pw' } ],
    [ 'written with a single = they are read the same',
      [ "dbi:Pg(Username=dsn-user,Password=dsn-pw):$PARAMS", 'arg-user', 'arg-pw' ],
      [ $PARAMS, 'dsn-user', 'dsn-pw' ], { %where, user => 'dsn-user', password => 'dsn-pw' } ],
    [ 'Username and Password among the attributes win over the ones beside the DSN',
      [ "dbi:Pg:$PARAMS", 'arg-user', 'arg-pw', { Username => 'attr-user', Password => 'attr-pw' } ],
      [ $PARAMS, 'attr-user', 'attr-pw' ], { %where, user => 'attr-user', password => 'attr-pw' } ],
    [ '... and those in front of the DSN win over them',
      [ "dbi:Pg(Username=>dsn-user,Password=>dsn-pw):$PARAMS", 'arg-user', 'arg-pw',
        { Username => 'attr-user', Password => 'attr-pw' } ],
      [ $PARAMS, 'dsn-user', 'dsn-pw' ], { %where, user => 'dsn-user', password => 'dsn-pw' } ],
    [ 'of the two attribute hashes the later one wins',
      [ "dbi:Pg:$PARAMS", 'arg-user', 'arg-pw', { Username => 'attr-user' }, { Username => 'extra-user' } ],
      [ $PARAMS, 'extra-user', 'arg-pw' ], { %where, user => 'extra-user', password => 'arg-pw' } ],
    [ '... an undefined Username in it too, which leaves the user beside the DSN',
      [ "dbi:Pg:$PARAMS", 'arg-user', 'arg-pw', { Username => 'attr-user' }, { Username => undef } ],
      [ $PARAMS, 'arg-user', 'arg-pw' ], { %where, user => 'arg-user', password => 'arg-pw' } ],
    # Defined is enough for DBI: an empty Username replaces the user beside
    # the DSN, and DBD::Pg appends no empty one -- the DSN's own user counts.
    [ 'an empty Username takes the user beside the DSN away',
      [ "dbi:Pg(Username=>):$PARAMS;user=in-dsn", 'arg-user', 'arg-pw' ],
      [ "$PARAMS;user=in-dsn", '', 'arg-pw' ], { %where, user => 'in-dsn', password => 'arg-pw' } ],
    [ 'an empty Password among the attributes takes the password beside the DSN away',
      [ "dbi:Pg:$PARAMS", 'arg-user', 'arg-pw', { Password => '' } ],
      [ $PARAMS, 'arg-user', '' ], { %where, user => 'arg-user' } ],
    # DBI splits at the arrows and commas and trims around them only: a blank
    # behind the opening parenthesis belongs to the first name, one before the
    # closing parenthesis to the last value.
    [ 'blanks inside the parentheses: " Username" is no Username, and the password ends in a blank',
      [ "dbi:Pg( Username => dsn-user , Password => dsn-pw ):$PARAMS", 'arg-user', 'arg-pw' ],
      [ $PARAMS, 'arg-user', 'dsn-pw ' ], { %where, user => 'arg-user', password => 'dsn-pw ' } ],
    [ 'a name without a value is an attribute that is undefined',
      [ "dbi:Pg(Username):$PARAMS", 'arg-user', 'arg-pw' ],
      [ $PARAMS, 'arg-user', 'arg-pw' ], { %where, user => 'arg-user', password => 'arg-pw' } ],
    [ 'parentheses holding nothing but 0 hold no attributes',
      [ "dbi:Pg(0):$PARAMS", 'arg-user', 'arg-pw' ],
      [ $PARAMS, 'arg-user', 'arg-pw' ], { %where, user => 'arg-user', password => 'arg-pw' } ],
    [ 'a closing parenthesis inside a value: the attributes end at the first "):"',
      [ "dbi:Pg(Password=>a)b):$PARAMS", 'arg-user', 'arg-pw' ],
      [ $PARAMS, 'arg-user', 'a)b' ], { %where, user => 'arg-user', password => 'a)b' } ],
    [ 'a password libpq would misread unquoted, among the attributes',
      [ "dbi:Pg:$PARAMS", 'arg-user', 'arg-pw', { Password => q{it's a \\ pw} } ],
      [ $PARAMS, 'arg-user', q{it's a \\ pw} ], { %where, user => 'arg-user', password => q{it's a \\ pw} } ],
    # pool_size is this distribution's own attribute: read wherever an
    # attribute is, the DSN's over the hashes'.
    [ 'pool_size in front of the DSN sizes the pool',
      [ "dbi:Pg(pool_size=>3):$PARAMS", 'app', 'pw' ],
      [ $PARAMS, 'app', 'pw' ], { %where, user => 'app', password => 'pw' }, 3 ],
    [ '... over the one among the attributes',
      [ "dbi:Pg(pool_size=>3):$PARAMS", 'app', 'pw', { pool_size => 7 } ],
      [ $PARAMS, 'app', 'pw' ], { %where, user => 'app', password => 'pw' }, 3 ],
  ) {
    my ($label, $info, $want_handed, $want, $want_pool_size) = @$case;
    my @before = map { ref $_ eq 'HASH' ? { %$_ } : $_ } @$info;

    my $handed = eval { $dbi_hands_dbd_pg->($info) };
    is_deeply $handed, $want_handed, "$label: what DBI hands DBD::Pg" or diag $@ || explain $handed;

    my @warned;
    my $got = do {
      local $SIG{__WARN__} = sub { push @warned, @_ };
      eval { dbi_to_conninfo($info)->[0] } || {};
    };
    my $err = $@;
    is_deeply \@warned, [], '... dbi_to_conninfo reads it without a warning';
    is delete $got->{pool_size}, $want_pool_size, '... the pool size';
    is_deeply $got, $want, '... dbi_to_conninfo reads the parameters of that connection'
      or diag $err || explain $got;
    is_deeply $got,
      scalar eval { dbi_to_conninfo([ 'dbi:Pg:' . $handed->[0], @{$handed}[1, 2] ])->[0] },
      '... the ones it reads from what DBI hands DBD::Pg';
    is_deeply libpq_reads(conninfo_string($got)), $want,
      '... and libpq reads them back from the string a pooled connection is opened with';
    is_deeply $info, \@before, '... leaving the connect info as it was';
  }

  # The DSN taken apart: the driver, the attributes as written, the rest --
  # for every DSN what DBI's own parse_dsn answers, and nothing where DBI
  # finds no 'dbi:driver:' in front.
  delete local $ENV{DBI_DRIVER};
  for my $dsn (
    "dbi:Pg:$PARAMS",
    "dbi:Pg(RaiseError=>1):$PARAMS",
    "dbi:Pg():$PARAMS",
    "DBI:Pg(a=>b,c=>d):$PARAMS",
    'dbi:Pg:',
    'dbi:Pg(a=>b):',
    'dbi:mysql:database=appdb',
    'dbi::dbname=appdb',
    "dbi:Pg(Password=>a)b):$PARAMS",
    "dbi:Pg(a=>b):x):$PARAMS",
    'dbi:Pg:dbname=a(b):c',
    'dbi:Pg;dbname=appdb',
    'dbi:Pg',
    'dbname=appdb',
    "dbi:Pg(a=>\nb):$PARAMS",
    "dbi:Pg:dbname=appdb\nhost=db.example",
  ) {
    (my $shown = $dsn) =~ s/\n/\\n/g;
    my @want = (DBI->parse_dsn($dsn))[1, 2, 4];
    my @got  = eval { DBIO::PostgreSQL::EV::ConnectInfo::dbi_dsn_parts($dsn) };
    is_deeply \@got, \@want, "dbi_dsn_parts takes [$shown] apart as DBI->parse_dsn does"
      or diag $@ || explain \@got;
  }
  is_deeply [ eval { DBIO::PostgreSQL::EV::ConnectInfo::dbi_dsn_parts(undef) } ], [],
    'dbi_dsn_parts answers nothing for no DSN at all';
}

# ---------------------------------------------------------------------------
# 8. A postgresql:// URI where the parameters stand (karr k66, decided
#    2026-10-09).
# ---------------------------------------------------------------------------
#
# DBD::Pg hands a DSN's rest to libpq, and libpq takes a URI whole as a
# conninfo. Before, the transport died of it for want of a "=", or -- with a
# query in it -- made a keyword of the text in front of the "=" for libpq to
# refuse. It is read now, into the parameters libpq reads from it
# (conninfo_uri_parse); the answer must be libpq's own reading, so each case
# here asks libpq (PQconninfoParse) for it and does not carry its own.
#
# What stands beside the URI, a user and a password, is read as it is beside
# "keyword=value" parameters (section 1): when not empty it wins over the
# URI's. The dbh does not do that -- it appends them to the URI, which is
# then no URI, and libpq refuses the connection -- so for these cases the
# expectation is libpq's reading of the URI with them put over it.
{
  my $SECRET = 'p@ss:w/rd?#[x]%1';
  (my $coded = $SECRET) =~ s/([^A-Za-z0-9])/sprintf '%%%02X', ord $1/ge;
  my $uri_user = 'app';

  for my $case (
    [ 'host, port and database',
      'postgresql://db.example:5433/appdb',
      { host => 'db.example', port => 5433, dbname => 'appdb' } ],
    [ 'the postgres:// scheme',
      'postgres://db.example/appdb',
      { host => 'db.example', dbname => 'appdb' } ],
    [ 'a user and a password with characters that are percent-encoded',
      "postgresql://$uri_user:$coded\@db.example/appdb",
      { user => $uri_user, password => $SECRET, host => 'db.example', dbname => 'appdb' } ],
    [ 'a "+" and a space in a percent-encoded password',
      'postgresql://app:a%2Bb+c%20d@db.example/appdb',
      { user => 'app', password => 'a+b+c d', host => 'db.example', dbname => 'appdb' } ],
    [ 'a user without a password',
      'postgresql://app@db.example/appdb',
      { user => 'app', host => 'db.example', dbname => 'appdb' } ],
    [ 'a query: sslmode and application_name',
      'postgresql://db.example/appdb?sslmode=verify-full&application_name=my%20app',
      { host => 'db.example', dbname => 'appdb', sslmode => 'verify-full', application_name => 'my app' } ],
    [ 'a query holding the host, the user and the password, and no authority',
      "postgresql:///appdb?host=%2Fvar%2Frun%2Fpostgresql&user=app&password=$coded",
      { host => '/var/run/postgresql', dbname => 'appdb', user => 'app', password => $SECRET } ],
    [ 'ssl=true, which libpq has for JDBC, is sslmode=require',
      'postgresql://db.example/appdb?ssl=true',
      { host => 'db.example', dbname => 'appdb', sslmode => 'require' } ],
    [ 'an IPv6 host in brackets',
      'postgresql://[::1]/appdb',
      { host => '::1', dbname => 'appdb' } ],
    [ 'an IPv6 host in brackets, with a port and a login',
      "postgresql://app:$coded\@[2001:db8::7]:5433/appdb",
      { user => 'app', password => $SECRET, host => '2001:db8::7', port => 5433, dbname => 'appdb' } ],
    [ 'several hosts, each with its port',
      'postgresql://h1.example:5432,h2.example:5433/appdb',
      { host => 'h1.example,h2.example', port => '5432,5433', dbname => 'appdb' } ],
    [ 'several hosts, the port of the second only',
      'postgresql://h1.example,h2.example:5433/appdb',
      { host => 'h1.example,h2.example', port => ',5433', dbname => 'appdb' } ],
    [ 'nothing but the scheme and a database',
      'postgresql:///appdb',
      { dbname => 'appdb' } ],
    [ 'empty parts set nothing',
      'postgresql://@db.example:/?application_name=',
      { host => 'db.example', application_name => '' } ],
    [ 'a "?" in front of the "@" is part of the login, as libpq reads it',
      'postgresql://db.example:5433?x=a@h/appdb',
      { user => 'db.example', password => '5433?x=a', host => 'h', dbname => 'appdb' } ],
    [ 'a keyword given twice has its later value',
      'postgresql://db.example/appdb?application_name=a&application_name=b',
      { host => 'db.example', dbname => 'appdb', application_name => 'b' } ],
  ) {
    my ($label, $uri, $want) = @$case;
    is_deeply libpq_reads($uri), $want, "control, $label: libpq reads the URI to the parameters expected here"
      or diag "the expectation of this test is not libpq's";

    my $got = eval { dbi_to_conninfo([ "dbi:Pg:$uri" ])->[0] };
    is_deeply $got, $want, "$label: dbi_to_conninfo reads it to those" or diag $@ || explain $got;
    is_deeply libpq_reads(conninfo_string($got // {})), $want,
      '... and a pooled connection is opened with them';
  }

  # The URI carries no more than what the DSN's own parameters would.
  my $uri = "postgresql://$uri_user:$coded\@db.example:5433/appdb?application_name=x";
  my %uri = (user => $uri_user, password => $SECRET, host => 'db.example', port => 5433,
             dbname => 'appdb', application_name => 'x');
  is_deeply eval { dbi_to_conninfo([ "dbi:Pg:$uri" ])->[0] }, \%uri,
    'control: the URI with a login of its own' or diag $@;

  is_deeply eval { dbi_to_conninfo([ "dbi:Pg:$uri", 'beside', 'other-secret' ])->[0] },
    { %uri, user => 'beside', password => 'other-secret' },
    'a user and a password beside the URI win over its own, as beside keyword=value parameters'
    or diag $@;
  is_deeply eval { dbi_to_conninfo([ "dbi:Pg:$uri", 'beside', undef ])->[0] },
    { %uri, user => 'beside' },
    '... each one for itself: no password beside it leaves the URI\'s';
  is_deeply eval { dbi_to_conninfo([ "dbi:Pg:$uri", '', '' ])->[0] }, \%uri,
    '... and an empty one counts as none';
  is_deeply eval { dbi_to_conninfo([ "dbi:Pg:$uri", 'beside', 'other-secret' ])->[0] },
    eval { dbi_to_conninfo([ "dbi:Pg:" . join(';', 'host=db.example', 'port=5433', 'dbname=appdb',
        'application_name=x', "user=$uri_user"), 'beside', 'other-secret' ])->[0] },
    '... exactly as they win over a user= in keyword=value parameters';
  is_deeply eval { dbi_to_conninfo([ "dbi:Pg(Username=>dbiuser,Password=>dbipass):$uri", 'beside', 'x' ])->[0] },
    { %uri, user => 'dbiuser', password => 'dbipass' },
    '... DBI\'s Username and Password in their place, as for any DSN' or diag $@;
  is_deeply eval { dbi_to_conninfo([ "dbi:Pg(pool_size=>4):$uri" ])->[0] },
    { %uri, pool_size => 4 },
    'pool_size among the DBI attributes in front of the URI is read as for any DSN' or diag $@;

  # The rewrites DBD::Pg makes of any DSN's rest come first, as they do for
  # the dbh: a "db=" in the query names the database, and a ";" outside of
  # quotes is a blank.
  is_deeply eval { dbi_to_conninfo([ 'dbi:Pg:postgresql://db.example/appdb?db=other' ])->[0] },
    { host => 'db.example', dbname => 'other' },
    'a "db=" in the query is "dbname=", as DBD::Pg rewrites it' or diag $@;
  is_deeply libpq_reads('postgresql://db.example/appdb?dbname=other'), { host => 'db.example', dbname => 'other' },
    '... which libpq reads as stated';

  # What libpq refuses. It quotes the URI whole, password included; this
  # says why and nothing else.
  for my $case (
    [ 'an IPv6 host that is not closed',  "postgresql://app:$coded\@[::1/appdb", 'not closed' ],
    [ 'an empty IPv6 host',               "postgresql://app:$coded\@[]/appdb", 'is empty' ],
    [ 'text behind the IPv6 host',        "postgresql://app:$coded\@[::1]x/appdb", 'must be followed' ],
    [ 'a percent sign without two digits', "postgresql://app:$coded\@db.example/appdb?application_name=%zz", 'percent-encoded' ],
    [ 'a percent-encoded NUL',            "postgresql://app:$coded\@db.example/appdb?application_name=a%00b", 'NUL' ],
    [ 'a query parameter without "="',    "postgresql://app:$coded\@db.example/appdb?sslmode", 'without "="' ],
  ) {
    my ($label, $bad, $why) = @$case;
    my $ok = eval { EV::Pg->conninfo_parse($bad); 1 };
    ok !$ok, "control, $label: libpq refuses it";
    $ok = eval { dbi_to_conninfo([ "dbi:Pg:$bad" ]); 1 };
    my $err = $@;
    ok !$ok, "$label: dbi_to_conninfo refuses it too";
    like $err, qr/cannot be read as a libpq URI: .*\Q$why\E/, '... saying why';
    unlike $err, qr/\Q$SECRET\E|\Q$coded\E|appdb|db\.example/, '... and nothing of the URI';
  }
}

# ---------------------------------------------------------------------------
# 9. Decided 2026-10-14 (karr k66 (a), (b), (d)).
# ---------------------------------------------------------------------------
#
# (a) dbi:Pg: with nothing behind it is read: the dbh connects from it, libpq
#     filling the rest from its environment.
# (b) pool_size among the DSN's parameters is refused, naming pool_size: the
#     dbh fails of it (libpq: invalid connection option "pool_size").
# (d) DBI_USER and DBI_PASS are read as DBI reads them -- for what is
#     undefined -- when asked for (env => 1), never otherwise: the broker's
#     answers are read without.
{
  my $pw = 'k66-secret';
  is_deeply eval { dbi_to_conninfo([ 'dbi:Pg:' ])->[0] }, {}, '(a) dbi:Pg: alone is no parameter' or diag $@;
  is_deeply eval { dbi_to_conninfo([ 'dbi:Pg:', 'app', $pw ])->[0] }, { user => 'app', password => $pw },
    '(a) dbi:Pg: with a user and a password: those only' or diag $@;
  is_deeply eval { dbi_to_conninfo([ 'dbi:Pg(Username=>app,Password=>x):' ])->[0] }, { user => 'app', password => 'x' },
    '(a) ... DBI attributes in front of nothing as well' or diag $@;
  ok !eval { dbi_to_conninfo([ 'dbi:mysql:' ]); 1 }, '(a) another driver\'s empty DSN is still no DSN for this';
  ok !eval { dbi_to_conninfo([ undef ]); 1 }, '(a) ... nor is none at all, without the environment';

  for my $dsn ("dbi:Pg:dbname=appdb;pool_size=3", "dbi:Pg:dbname=appdb pool_size=3",
               "dbi:Pg:postgresql://db.example/appdb?pool_size=3") {
    my $ok = eval { dbi_to_conninfo([ $dsn, 'app', $pw ]); 1 };
    my $err = $@;
    ok !$ok, "(b) $dsn: refused";
    like $err, qr/pool_size/, '... naming pool_size';
    unlike $err, qr/\Q$pw\E|appdb|db\.example/, '... and nothing of the DSN';
  }
  is_deeply eval { dbi_to_conninfo([ 'dbi:Pg:dbname=appdb', 'app', $pw, { pool_size => 3 } ])->[0] },
    { dbname => 'appdb', user => 'app', password => $pw, pool_size => 3 },
    '(b) pool_size among the attributes still sizes the pool' or diag $@;

  {
    delete local @ENV{qw( DBI_DSN DBI_USER DBI_PASS DBI_DRIVER )};
    local @ENV{qw( DBI_DSN DBI_USER DBI_PASS )} = ('dbi:Pg:dbname=envdb', 'envuser', 'envpass');

    is_deeply eval { dbi_to_conninfo([ 'dbi:Pg:dbname=appdb' ])->[0] }, { dbname => 'appdb' },
      '(d) without env => 1 the environment is not read' or diag $@;
    is_deeply eval { dbi_to_conninfo([ 'dbi:Pg:dbname=appdb' ], env => 1)->[0] },
      { dbname => 'appdb', user => 'envuser', password => 'envpass' },
      '(d) with it, DBI_USER and DBI_PASS stand for an undefined user and password' or diag $@;
    is_deeply eval { dbi_to_conninfo([ 'dbi:Pg:dbname=appdb', 'app', '' ], env => 1)->[0] },
      { dbname => 'appdb', user => 'app' },
      '(d) ... only for what is undefined: an empty password is a given one' or diag $@;
    ok !eval { dbi_to_conninfo([ undef, undef, undef ], env => 1); 1 },
      '(d) ... DBI_DSN is not read: core refuses a DSN that is not given';
    is_deeply eval { dbi_to_conninfo([ 'dbi:Pg:dbname=appdb;user=dsnuser;password=dsnpw' ], env => 1)->[0] },
      { dbname => 'appdb', user => 'envuser', password => 'envpass' },
      '(d) ... what DBI hands DBD::Pg is read like a user and a password beside the DSN: over the DSN\'s own'
      or diag $@;
    is_deeply eval { dbi_to_conninfo([ 'dbi:Pg(Username=>attr):dbname=appdb' ], env => 1)->[0] },
      { dbname => 'appdb', user => 'attr', password => 'envpass' },
      '(d) ... DBI\'s Username attribute is a given user, before the environment' or diag $@;
    ok !eval { dbi_to_conninfo([ undef ]); 1 }, '(d) ... and without env => 1 no DSN is none';
  }

  {
    delete local @ENV{qw( DBI_DSN DBI_USER DBI_PASS DBI_DRIVER )};
    local $ENV{DBI_DRIVER} = 'Pg';
    ok !eval { dbi_to_conninfo([ 'dbi::dbname=appdb' ], env => 1); 1 }, '(d) DBI_DRIVER is not read';
  }
}

done_testing;
