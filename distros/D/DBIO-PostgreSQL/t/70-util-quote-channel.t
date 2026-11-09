use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k82: DBIO::PostgreSQL::Util::quote_channel, the one
# implementation of the LISTEN channel rule.
#
# WHY IT MATTERS: the rule was written for the future_io transport (karr k77)
# and copied verbatim into the ev transport of dbio-postgresql-ev. It now lives
# here as a public helper both can use. Its contract is what keeps LISTEN and
# pg_notify meeting on the same channel: the name quoted as ONE exact
# identifier, and a name PostgreSQL would truncate refused rather than sent --
# a truncated LISTEN can never deliver. The ev transport does not inherit the
# future_io storage and must be able to load the helper without dbio-async or
# Future::IO, so that is pinned too.

use Scalar::Util ();
use DBIO::PostgreSQL::Util qw(quote_channel);

# -----------------------------------------------------------------------
# 0. Loading the helper pulls in no transport
# -----------------------------------------------------------------------
ok !$INC{$_}, "loading DBIO::PostgreSQL::Util does not load $_"
  for qw( DBIO/PostgreSQL/Storage/Async.pm DBIO/Async/Storage.pm Future/IO.pm );

{
  package NoImport;
  use DBIO::PostgreSQL::Util;
}
ok !NoImport->can('quote_channel'), 'quote_channel is not exported by default';
ok defined &main::quote_channel,     '... but on request';

# -----------------------------------------------------------------------
# 1. Quoting: one exact identifier
# -----------------------------------------------------------------------
my %quoted = (
  jobs          => '"jobs"',
  Jobs          => '"Jobs"',                    # case kept, not folded
  'Mixed Case'  => '"Mixed Case"',
  'a"b'         => '"a""b"',                    # embedded quote doubled
  '"'           => '""""',
  'app.events'  => '"app.events"',              # one identifier, not schema-qualified
  q{x'); DROP TABLE t; --} => q{"x'); DROP TABLE t; --"},
  ('x' x 63)    => '"' . ('x' x 63) . '"',      # the longest ASCII name
);
is quote_channel($_), $quoted{$_}, "'$_' quoted as $quoted{$_}"
  for sort keys %quoted;

my $arg = 'a"b';
quote_channel($arg);
is $arg, 'a"b', 'the argument is left as it was';

# -----------------------------------------------------------------------
# 2. The limit is 63 BYTES in UTF-8, not 63 characters
# -----------------------------------------------------------------------
my %at_63 = (
  'a . 31 x U+00E9 (2-byte)' => 'a' . ("\x{e9}" x 31),
  '21 x U+20AC (3-byte)'     => "\x{20ac}" x 21,
);
for my $what (sort keys %at_63) {
  my $name = $at_63{$what};
  my $bytes = $name;
  utf8::encode($bytes);
  is length $bytes, 63, "$what is 63 UTF-8 bytes";
  is quote_channel($name), qq{"$name"}, '... and accepted';
}

my %at_64 = (
  '32 x U+00E9 (2-byte)'      => "\x{e9}" x 32,
  '21 x U+20AC . a (3-byte)'  => ("\x{20ac}" x 21) . 'a',
  '64 ASCII'                  => 'x' x 64,
);
for my $what (sort keys %at_64) {
  my $name = $at_64{$what};
  ok !eval { quote_channel($name); 1 }, "$what (64 UTF-8 bytes) is refused, not truncated";
  like $@, qr/is 64 bytes long.*at most 63 bytes/s, '... naming its byte length and the limit';
}

# -----------------------------------------------------------------------
# 3. The other refusals
# -----------------------------------------------------------------------
my @refused = (
  [ "a\0b",     qr/cannot contain a NUL byte/, 'a NUL byte' ],
  [ '',         qr/non-empty string/,          'the empty string' ],
  [ undef,      qr/non-empty string/,          'undef' ],
  [ [ 'jobs' ], qr/non-empty string/,          'a reference' ],
);
for my $case (@refused) {
  my ($channel, $re, $what) = @$case;
  ok !eval { quote_channel($channel); 1 }, "refused: $what";
  like $@, $re, '... saying why';
}

# -----------------------------------------------------------------------
# 4. The future_io transport answers through it: one implementation
# -----------------------------------------------------------------------
SKIP: {
  skip 'DBIO::Async not installed (recommends only) -- future_io transport unavailable', 4
    unless eval { require DBIO::PostgreSQL::Storage::Async; 1 };

  my $PG = 'DBIO::PostgreSQL::Storage::Async';
  my @names = (
    sort(keys %quoted), values(%at_63), values(%at_64), map { $_->[0] } @refused,
  );
  my (@differs, @not_exception, $n);
  for my $name (@names) {
    my ($want, $got);
    my $want_ok = eval { $want = quote_channel($name); 1 };
    my $want_err = $@;
    my $got_ok  = eval { $got = $PG->_pg_quote_channel($name); 1 };
    my $got_err = $@;
    # the helper croaks and names its caller; the storage raises the refusal
    # again as one of its own, a DBIO::Exception with core's origin in front
    # and the caller's place behind (karr k120, maintainer's decision
    # 2026-10-16). Both places go, and the origin: the reason must be the same.
    push @not_exception, $name
      if !$want_ok && !(Scalar::Util::blessed($got_err) && $got_err->isa('DBIO::Exception'));
    $got_err = "$got_err";
    $got_err =~ s/\A[\w:]+\(\): //;
    s/(?: at \S+ line \d+\.?)?\n\z// for $want_err, $got_err;
    $n++;
    # the names as perl would write them: a refused one may be no printable text
    push @differs, sprintf '%vd', $name // 'undef'
      unless ($want_ok ? $got_ok && $got eq $want : !$got_ok && $got_err eq $want_err);
  }
  is_deeply \@differs, [],
    "the storage's _pg_quote_channel answers exactly as quote_channel for all $n names";
  is_deeply \@not_exception, [],
    '... and each name it refuses, it refuses as a DBIO::Exception';

  # Equal answers would also come from a second copy of the rule; the point is
  # that there is none.
  my @seen;
  {
    no warnings 'redefine';
    local *DBIO::PostgreSQL::Util::quote_channel = sub { push @seen, $_[0]; '"spy"' };
    is $PG->_pg_quote_channel('jobs'), '"spy"',
      '... because it delegates to DBIO::PostgreSQL::Util::quote_channel';
  }
  is_deeply \@seen, ['jobs'], '... handing the channel through unchanged';
}

done_testing;
