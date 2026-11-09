# ABSTRACT: A stack trace Carp wrote into a connect error names no password
use strict;
use warnings;
use utf8;

use Test::More;

use Carp ();
use DBI;
use DBIO::Util ();
use DBIO::Schema;

# OFFLINE (karr k314, karr k311). k297 keeps the password out of every message
# DBIO writes connect info into, k304 out of every stack trace DBIO has Carp
# write. This is the trace DBIO does not write: with $Carp::Verbose (perl
# -MCarp=verbose, as somebody looking for an error runs it) every croak is a
# full trace, DBI's too, and DBI->connect is called with the password as an
# argument. The storage hands that text on as "DBI Connection failed: ...",
# through DBIO::Util::mask_connect_secrets with the connect info -- which
# looked for the password the way it was given. Carp does not write it that
# way: it puts a backslash before " \ $ and @, writes \x{..} for what is not
# printable ASCII, and shows the first $Carp::MaxArgLen - 3 characters of a
# long argument, followed by "... . A password of more than 64 characters stood
# in the exception with its first 61 (k314), and a short one with an @ or a $
# in it stood there whole.
#
# What this file claims: what DBIO hands on through mask_connect_secrets with
# the connect info does not name the password -- not in the form Carp writes
# an argument in either.
#   1. The password argument and a Password attribute are masked where a trace
#      of Carp shows them: escaped, written as \x{..} -- from a character
#      string and from bytes --, shortened, with whatever $Carp::MaxArgLen the
#      trace was written.
#   2. So is the password inside a longer argument: its start where Carp
#      shortened the argument inside it, however little of it is left, and
#      all of it where the argument names it by a key -- a value found by its
#      key ends at whitespace or a ';', and a password may have either in it.
#   3. So is a password inside the DSN of the connect info, where Carp shows
#      the DSN escaped or shortened -- with and without its dbi:Driver: prefix.
#   4. Only that is masked: the frames, the files and lines, a DSN without a
#      password, the user name and an argument Carp shortened elsewhere stand.
#      Without a trace the message is what it was.
# Each case is run twice: DBI->connect dying and its error masked as a caller
# of mask_connect_secrets would, and a schema whose storage is asked for its
# dbh.
#
# THE SUBSTITUTIONS: none for Carp and none for DBI -- the traces are the real
# ones, and should a Carp write an argument otherwise this file fails. No
# database: the driver of the DSN is not installed, so DBI dies before any
# could be asked; where the frame of a driver is needed, it is DBD::K314Croaks
# below, a DBD of this file whose connect croaks. No real password: every
# secret is made of the three markers below with something between them, so
# that a leak shows wherever Carp escaped or cut it -- at its start, in its
# middle or at its end.

delete @ENV{qw( DBI_DSN DBI_DRIVER DBI_AUTOPROXY )};

# A DBD whose connect croaks: with $Carp::Verbose its frame is in the trace,
# and it is the one that has a Password attribute as an argument.
{
  package DBD::K314Croaks;
  our $drh;
  sub driver {
    return $drh ||= DBI::_new_drh("$_[0]::dr", { Name => 'K314Croaks', Version => '0.01' });
  }

  package DBD::K314Croaks::dr;
  our $imp_data_size = 0;
  sub connect { Carp::croak('k314 croaks') }

  package DBD::K314Croaks::db;
  our $imp_data_size = 0;

  package DBD::K314Croaks::st;
  our $imp_data_size = 0;
}
$INC{'DBD/K314Croaks.pm'} = __FILE__;

{
  # a driver of this file: a schema always declares one (ADR 0067)
  package T::K314::Storage;
  use base 'DBIO::Storage::DBI';
}

{
  package T::K314::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+T::K314::Storage');
}

my $SECRET = qr/k314-(?:head|mid|tail)/;
my $PLAIN  = 'k314-head-k314-mid-k314-tail';

my $USER   = 'k314-user';
my $DSN    = 'dbi:K314NoSuchDriver:dbname=app;host=db.example';
my $CROAKS = 'dbi:K314Croaks:dbname=app;host=db.example';
my %ATTRS  = (RaiseError => 1, PrintError => 0);
my $FILE   = quotemeta __FILE__;
my $HASH   = qr/HASH\(0x[0-9a-f]+\)/;

# What the code dies with while Carp writes every croak as a full trace. The
# code comes as a closure and the connect info as a reference, so that no
# frame of this file holds a password unless the case puts one there.
sub trace_of {
  my ($code, $max_arg_len) = @_;
  local $Carp::Verbose   = 1;
  local $Carp::MaxArgLen = $max_arg_len if defined $max_arg_len;
  return eval { $code->(); 1 } ? undef : "$@";
}

# DBI->connect dying: what it died with, and that as a message carries it
sub from_dbi {
  my ($info, $max_arg_len) = @_;
  my $error = trace_of(sub { DBI->connect(@$info) }, $max_arg_len);
  return ("DBI Connection failed: $error", DBIO::Util::mask_connect_secrets("DBI Connection failed: $error", $info));
}

# ... and the same connection, a schema asked for its dbh
sub from_dbio {
  my ($info, $max_arg_len) = @_;
  return trace_of(sub { T::K314::Schema->connect(@$info)->storage->dbh }, $max_arg_len);
}

# An argument without anything to escape, as Carp shows it
sub shown {
  my ($argument, $max_arg_len) = @_;
  $max_arg_len //= 64;
  return qq{"$argument"} unless $max_arg_len and length $argument > $max_arg_len;
  return '"' . substr($argument, 0, $max_arg_len - 3) . '"...';
}

sub no_secret {
  my ($message, $what) = @_;
  ok defined $message && $message =~ /\bcalled at\b/, "$what: there is a stack trace"
    or diag $message;
  unlike $message, $SECRET, "$what: ... without the password";
}

# All of the trace but the frames that hold the password
sub other_lines {
  my ($message, $frame) = @_;
  return [ grep { $_ !~ $frame } split /\n/, $message ];
}

is $Carp::MaxArgLen, 64, 'Carp shows 64 characters of an argument unless told otherwise';

# ---------------------------------------------------------------------------
# 1. The password as Carp writes an argument.
# ---------------------------------------------------------------------------
my $encoded = 'k314-head-ä-k314-mid-ö-k314-tail';
utf8::encode($encoded);

my @PASSWORDS = (
  # [ what, the password, as the trace shows it, $Carp::MaxArgLen if not Carp's own ]
  [ 'a password Carp shows as it is',                        # control: this one never leaked
    $PLAIN, '"***"' ],
  [ 'a password longer than Carp shows (k314)',
    'k314-head-' . 'x' x 30 . '-k314-mid-' . 'y' x 30 . '-k314-tail', '"***"...' ],
  [ 'a password with @ $ " and \\ in it',
    'k314-head@k314-mid$"\\k314-tail', '"***"' ],
  [ 'a password with a tab and a newline in it',
    "k314-head\tk314-mid\nk314-tail", '"***"' ],
  [ 'a password of characters outside ASCII',
    'k314-head-ä-k314-mid-ö-k314-tail', '"***"' ],
  [ 'a password of characters outside Latin-1',
    'k314-head-€-k314-mid-✓-k314-tail', '"***"' ],
  [ 'a password of bytes outside ASCII',
    $encoded, '"***"' ],
  [ 'a long password Carp escapes and cuts among the escapes',
    'k314-head' . '@$' x 20 . 'k314-mid' . '"\\' x 20 . 'k314-tail', '"***"...' ],
  [ 'a password cut by a $Carp::MaxArgLen of 20',
    $PLAIN, '"***"...', 20 ],
  [ 'a long password not cut at all, $Carp::MaxArgLen being 0',
    'k314-head-' . 'x' x 30 . '-k314-mid-' . 'y' x 30 . '-k314-tail', '"***"', 0 ],
);

for my $case (@PASSWORDS) {
  my ($what, $password, $masked, $max_arg_len) = @$case;
  my ($user, $dsn, $rest) = map { quotemeta shown($_, $max_arg_len) } $USER, $DSN, 'dbname=app;host=db.example';
  $masked = quotemeta $masked;

  # -- the password argument: the frame of DBI->connect ------------------------
  {
    my $info  = [ $DSN, $USER, $password, { %ATTRS } ];
    my $frame = qr/^\tDBI::connect\(/;

    my ($error, $message) = from_dbi($info, $max_arg_len);
    like $error, $SECRET, "$what: Carp writes it into the trace of DBI->connect";
    no_secret($message, "$what, masked");
    like $message, qr/^\tDBI::connect\("DBI", $dsn, $user, $masked, $HASH\) called at $FILE line \d+$/m,
      "$what, masked: the frame stands, and the DSN and the user name in it";
    is_deeply other_lines($message, $frame), other_lines($error, $frame),
      "$what, masked: every other line is as Carp wrote it";

    $message = from_dbio($info, $max_arg_len);
    like $message, qr/DBI Connection failed: install_driver\(K314NoSuchDriver\) failed/,
      "$what, through a schema: dies of the driver that is not installed";
    no_secret($message, "$what, through a schema");
    like $message, qr/^\tDBI::connect\("DBI", $dsn, $user, $masked, $HASH\) called at \S*Storage\/DBI\.pm line \d+$/m,
      "$what, through a schema: the frame stands, and the DSN and the user name in it";
  }

  # -- a Password attribute: the frame of the driver ---------------------------
  {
    my $info  = [ $CROAKS, $USER, undef, { %ATTRS, Password => $password } ];
    my $frame = qr/^\tDBD::K314Croaks::dr::connect\(/;
    my $shown = qr/^\tDBD::K314Croaks::dr::connect\(DBI::dr=$HASH, $rest, $user, $masked, $HASH\) called at \S*DBI\.pm line \d+$/m;

    my ($error, $message) = from_dbi($info, $max_arg_len);
    like $error, $SECRET, "$what, as a Password attribute: Carp writes it into the trace of the driver";
    no_secret($message, "$what, as a Password attribute, masked");
    like $message, $shown, "$what, as a Password attribute, masked: the frame of the driver stands";
    is_deeply other_lines($message, $frame), other_lines($error, $frame),
      "$what, as a Password attribute, masked: every other line is as Carp wrote it";

    $message = from_dbio($info, $max_arg_len);
    like $message, qr/DBI Connection failed: k314 croaks/,
      "$what, as a Password attribute, through a schema: dies of the driver";
    no_secret($message, "$what, as a Password attribute, through a schema");
    like $message, $shown, "$what, as a Password attribute, through a schema: the frame of the driver stands";
  }
}

# -- a password argument and a Password attribute, one the start of the other --
# DBI connects with the attribute; the argument is still in the frame of
# DBI->connect, shortened. Masked first, the attribute would take the start of
# it and leave nothing to tell the rest by.
{
  my $long = 'k314-head-' . 'x' x 30 . '-k314-mid-' . 'y' x 30 . '-k314-tail';
  my $info = [ $CROAKS, $USER, $long, { %ATTRS, Password => 'k314-head' } ];

  for my $run ([ 'masked', (from_dbi($info))[1] ], [ 'through a schema', from_dbio($info) ]) {
    my ($how, $trace) = @$run;
    no_secret($trace, "a password and a Password attribute it starts with, $how");
    like $trace, qr/^\tDBI::connect\("DBI", "\Q$CROAKS\E", "\Q$USER\E", "\*\*\*"\.\.\., $HASH\) called at /m,
      "a password and a Password attribute it starts with, $how: the password is masked as a whole";
    like $trace, qr/^\tDBD::K314Croaks::dr::connect\(DBI::dr=$HASH, "dbname=app;host=db\.example", "\Q$USER\E", "\*\*\*", $HASH\) called at /m,
      "a password and a Password attribute it starts with, $how: the attribute in the frame of the driver too";
  }
}

# ---------------------------------------------------------------------------
# 2. The password inside a longer argument.
# ---------------------------------------------------------------------------
# The frame of a caller that holds the password at the end of a longer
# argument: "login:password", or a string that names it by a key.
my $LOGIN = 'k314-login-with-a-name-of-some-length';

sub dbi_with_login {
  my ($password) = $_[0] =~ /(k314-head.*)\z/s;
  my $info = [ $DSN, $USER, $password, { %ATTRS } ];
  my $died = eval { DBI->connect(@$info); 1 } ? undef : "$@";
  return ("DBI Connection failed: $died", DBIO::Util::mask_connect_secrets("DBI Connection failed: $died", $info));
}

sub dbio_with_login {
  my ($password) = $_[0] =~ /(k314-head.*)\z/s;
  T::K314::Schema->connect($DSN, $USER, $password)->storage->dbh;
}

for my $case (
  # [ what, the argument up to the password, the password, the argument as the frame shows it masked,
  #   $Carp::MaxArgLen if not Carp's own ]

  # Shortened inside the password: what is left of it is its start, and
  # nothing in the trace says how much of it that is.
  [ 'cut inside the password',
    "$LOGIN:", $PLAIN, qq{"$LOGIN:***"...)} ],
  [ 'cut inside a password Carp escapes',
    "$LOGIN:", 'k314-head@k314-mid$"\\k314-tail', qq{"$LOGIN:***"...)} ],
  [ 'cut two characters into the password',
    "$LOGIN:", $PLAIN, qq{"$LOGIN:***"...)}, length("$LOGIN:") + 2 + 3 ],
  [ 'cut one character into the password',
    "$LOGIN:", $PLAIN, qq{"$LOGIN:***"...)}, length("$LOGIN:") + 1 + 3 ],

  # Named by a key. A value found by its key ends at the next whitespace or
  # ';' as in any text, what closes the argument going with it -- and the
  # password has both in it. It is masked for being the password, whole or
  # as far as Carp shows it, whatever the key takes of it.
  [ 'cut inside a password with spaces in it, behind password=',
    "$LOGIN password=", 'k314-head k314-mid k314-tail and some more of it', qq{"$LOGIN password=***}, 80 ],
  [ 'a password with spaces in it, behind password=',
    'k314-login password=', 'k314-head k314-mid k314-tail', '"k314-login password=***' ],
  [ 'a password with a ; in it, behind PWD=',
    'UID=k314-login;PWD=', 'k314-head;k314-mid;k314-tail', '"UID=k314-login;PWD=***' ],
  [ 'a password with spaces in it that Carp escapes, behind password => ',
    'user => k314-login, password => ', 'k314-head k314-mid@k314-tail', '"user => k314-login, password =***' ],
  [ 'a password with spaces in it, in a DSN that is not the one connected with',
    'dbi:K314Other:db=other;password=', 'k314-head k314-mid k314-tail', '"dbi:K314Other:db=other;password=***' ],
) {
  my ($what, $before, $password, $shown, $max_arg_len) = @$case;
  my $login = "$before$password";

  my ($error, $message);
  trace_of(sub { ($error, $message) = dbi_with_login($login) }, $max_arg_len);
  like $error, qr/^\tmain::dbi_with_login\("\Q$before\Ek/m,
    "a longer argument, $what: Carp writes the password into the frame of the caller";
  no_secret($message, "a longer argument, $what, masked");
  like $message, qr/^\tmain::dbi_with_login\(\Q$shown\E called at $FILE line \d+$/m,
    "a longer argument, $what, masked: the frame stands, and what the argument starts with";

  $message = trace_of(sub { dbio_with_login($login) }, $max_arg_len);
  no_secret($message, "a longer argument, $what, through a schema");
  like $message, qr/^\tmain::dbio_with_login\(\Q$shown\E called at $FILE line \d+$/m,
    "a longer argument, $what, through a schema: the frame stands, and what the argument starts with";
}

# ---------------------------------------------------------------------------
# 3. A password inside the DSN of the connect info.
# ---------------------------------------------------------------------------
# Carp escapes and shortens the DSN like any argument. Escaped, it is no
# longer the DSN the connect info names, and what is taken for the end of a
# value in a text -- whitespace -- is not the end of this one; shortened, what
# says where the value ends may be what was cut off. From the first masked
# value on nothing of a shortened DSN is shown.
my @IN_DSN = (
  # [ what, the DSN, as the frame of DBI->connect shows it, as the frame of the driver shows it ]
  [ 'a DSN part Carp escapes',
    'dbi:K314Croaks:dbname=app;password=k314-head@k314-mid$k314-tail',
    '"dbi:K314Croaks:dbname=app;password=***"',
    '"dbname=app;password=***"' ],
  [ 'a DSN part with spaces in it that Carp escapes',
    'dbi:K314Croaks:password=k314-head k314-mid@k314-tail;host=h',
    '"dbi:K314Croaks:password=***;host=h"',
    '"password=***;host=h"' ],
  [ 'a DSN Carp cut inside a password with spaces in it',
    'dbi:K314Croaks:dbname=app;password=k314-head k314-mid k314-tail and long enough to be cut;host=db.example',
    '"dbi:K314Croaks:dbname=app;password=***"...',
    '"dbname=app;password=***"...' ],
  [ 'a DSN Carp cut behind its password',
    'dbi:K314Croaks:password=k314-head k314-mid k314-tail;dbname=app;host=a-host-with-a-long-name.db.example',
    '"dbi:K314Croaks:password=***"...',
    '"password=***"...' ],
  [ 'a URI in a DSN, cut inside its password',
    'dbi:K314Croaks:postgresql://k314-user:k314-head-k314-mid-k314-tail-and-long-enough-to-be-cut@db.example/app',
    '"dbi:K314Croaks:postgresql://k314-user:***"...',
    '"postgresql://k314-user:***"...' ],
  # no dbi: in front: DBI dies working out the driver, and no driver has a frame
  [ 'a libpq string cut inside a quoted password',
    q{host=db.example user=k314-user password='k314-head k314-mid k314-tail and a lot more of it'},
    '"host=db.example user=k314-user password=***"...' ],
  [ 'a URI with an @ in its password',
    'postgresql://u:k314-head@k314-mid$k314-tail@db/app',
    '"postgresql://u:***\\@db/app"' ],
  [ 'a URI cut inside its password',
    'postgresql://k314-user:k314-head-k314-mid-k314-tail-and-long-enough-to-be-cut@db.example/app',
    '"postgresql://k314-user:***"...' ],
  [ 'a URI cut inside its password, behind an @ in it',
    'postgresql://k314-user:k314-head@k314-mid-k314-tail-and-long-enough-to-be-cut@db.example/app',
    '"postgresql://k314-user:***"...' ],
);

for my $case (@IN_DSN) {
  my ($what, $dsn, $in_dbi, $in_driver) = @$case;
  my $info = [ $dsn, $USER, undef, { %ATTRS } ];

  my ($error, $message) = from_dbi($info);
  like $error, qr/^\tDBI::connect\("DBI", "[^\n]*$SECRET/m, "in the DSN, $what: Carp writes it into the trace of DBI->connect";

  # a password not given is "" once it went through the storage (karr k392)
  for my $run ([ 'masked', $message, $FILE, 'undef' ], [ 'through a schema', from_dbio($info), qr/\S*Storage\/DBI\.pm/, '""' ]) {
    my ($how, $trace, $caller, $none) = @$run;

    no_secret($trace, "in the DSN, $what, $how");
    like $trace, qr/^\tDBI::connect\("DBI", \Q$in_dbi\E, "\Q$USER\E", $none, $HASH\) called at $caller line \d+$/m,
      "in the DSN, $what, $how: the frame stands, the key and what is before it too";
    like $trace, qr/^\tDBD::K314Croaks::dr::connect\(DBI::dr=$HASH, \Q$in_driver\E, "\Q$USER\E", $none, $HASH\) called at /m,
      "in the DSN, $what, $how: the frame of the driver as well, the DSN without its prefix"
      if defined $in_driver;
  }
}

# ---------------------------------------------------------------------------
# 4. What is left alone.
# ---------------------------------------------------------------------------

# -- the frames, with files and lines -------------------------------------------
{
  my $message = from_dbio([ $DSN, $USER, 'k314-head@k314-mid$"\\k314-tail' ]);
  no_secret($message, 'the frames');
  like $message, qr/^\tDBI::install_driver\("DBI", "K314NoSuchDriver"\) called at \S*DBI\.pm line \d+$/m,
    'the frames: the one of DBI above the connect, with its argument, file and line';
  like $message, qr/^\tDBIO::Storage::DBI::_connect\(T::K314::Storage=$HASH\) called at \S*Storage\/DBI\.pm line \d+$/m,
    'the frames: the one of the storage below it';
  like $message, qr/^\tDBIO::Storage::DBI::dbh\(T::K314::Storage=$HASH\) called at $FILE line \d+$/m,
    'the frames: down to the caller in this file';
}

# -- an argument Carp shortened that has nothing of the password ---------------
{
  my $user  = 'k314-user-' . 'u' x 70;
  my $shown = quotemeta shown($user);
  my $info  = [ $DSN, $user, $PLAIN, { %ATTRS } ];

  for my $run ([ 'masked', (from_dbi($info))[1] ], [ 'through a schema', from_dbio($info) ]) {
    my ($how, $trace) = @$run;
    no_secret($trace, "a long user name, $how");
    like $trace, qr/^\tDBI::connect\("DBI", "\Q$DSN\E", $shown, "\*\*\*", $HASH\) called at /m,
      "a long user name, $how: shortened by Carp and left as that, the password beside it masked";
  }
}

# -- a DSN Carp cut before its password ------------------------------------------
{
  my $dsn  = 'dbi:K314Croaks:dbname=app;host=a-host-with-a-rather-long-name.db.example;password=k314-head k314-mid';
  my $info = [ $dsn, $USER, undef, { %ATTRS } ];
  my ($in_dbi, $in_driver) = map { quotemeta shown($_) } $dsn, $dsn =~ /^dbi:K314Croaks:(.+)/;

  for my $run ([ 'masked', (from_dbi($info))[1], 'undef' ], [ 'through a schema', from_dbio($info), '""' ]) {
    my ($how, $trace, $none) = @$run;
    no_secret($trace, "a DSN cut before its password, $how");
    like $trace, qr/^\tDBI::connect\("DBI", $in_dbi, "\Q$USER\E", $none, $HASH\) called at /m,
      "a DSN cut before its password, $how: what Carp shows of it stands";
    like $trace, qr/^\tDBD::K314Croaks::dr::connect\(DBI::dr=$HASH, $in_driver, "\Q$USER\E", $none, $HASH\) called at /m,
      "a DSN cut before its password, $how: without its prefix too";
    unlike $trace, qr/\*\*\*/, "a DSN cut before its password, $how: nothing masked";
  }
}

# -- no password ----------------------------------------------------------------
for my $none ([ 'an empty password', '', '""' ], [ 'no password', undef, '""' ]) {   # undef is "" in the storage (karr k392)
  my ($what, $password, $shown) = @$none;
  my $info = [ $DSN, $USER, $password, { %ATTRS } ];

  my ($error, $message) = from_dbi($info);
  is $message, $error, "$what: the trace is as Carp wrote it";

  $message = from_dbio($info);
  like $message, qr/^\tDBI::connect\("DBI", "\Q$DSN\E", "\Q$USER\E", $shown, $HASH\) called at /m,
    "$what, through a schema: the arguments as they were";
  unlike $message, qr/\*\*\*/, "$what, through a schema: nothing masked";
}

# -- without a trace -------------------------------------------------------------
# $Carp::Verbose off: DBI dies with its message and the place, as ever.
for my $case (@PASSWORDS) {
  my ($what, $password) = @$case;
  my $info = [ $DSN, $USER, $password, { %ATTRS } ];

  my $error = eval { DBI->connect(@$info); 1 } ? undef : "$@";
  is DBIO::Util::mask_connect_secrets("DBI Connection failed: $error", $info), "DBI Connection failed: $error",
    "without a trace, $what: the message is what DBI died with";

  my $message = eval { T::K314::Schema->connect(@$info)->storage->dbh; 1 } ? undef : "$@";
  like $message, qr/DBI Connection failed: install_driver\(K314NoSuchDriver\) failed: Can't locate DBD\/K314NoSuchDriver\.pm /,
    "without a trace, $what, through a schema: dies of the driver that is not installed";
  unlike $message, qr/\bcalled at\b|\*\*\*/, "without a trace, $what, through a schema: no frames, nothing masked";
  unlike $message, $SECRET, "without a trace, $what, through a schema: no password";
}

done_testing;
