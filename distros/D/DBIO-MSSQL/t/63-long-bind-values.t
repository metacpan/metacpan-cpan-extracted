use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::MSSQL::Storage;

# OFFLINE (karr k40). Over DBD::Sybase and FreeTDS every placeholder of a
# statement is declared to the server as varchar(4000) when the statement is
# prepared, whatever is bound to it later, and the server cuts a longer value
# to that size without an error (measured 2026-10-07, DBD::Sybase 1.27,
# FreeTDS 1.3.17, SQL Server 2022; in the protocol dump the prepare carries
# "@P1 varchar(4000)" and the execute the whole value). No bind type, no cast
# around the placeholder and no client setting changes the declaration.
#
# DBIO::MSSQL::Storage::Sybase therefore puts a value of more than 4000 bytes
# into the statement as a literal, where it arrives whole, and leaves every
# other value a bind. This file pins that decision without a server:
#
#   1. where the line is: 4000 bytes as DBD::Sybase sends them -- bytes, not
#      characters -- and only the value over it leaves the binds;
#   2. what the literal is: plain for a value of ASCII alone, a Unicode one
#      (N'...') for anything else, and at the byte level, so that a value
#      means the same in the statement as it meant as a bind;
#   3. what a literal must not do to a value: a quote ends nothing, a "?"
#      in a value is no placeholder, and the two things the server's reading
#      of a literal changes -- a backslash before a line break, a NUL -- are
#      written so that they arrive;
#   4. UPDATE and a condition, not INSERT alone;
#   5. a statement whose placeholders cannot be told apart is refused, loudly
#      and before anything is sent;
#   6. the trace still shows the placeholder and hands the value to
#      redact_bind_value; a statement carrying a value is never cached;
#   7. populate in void context: one prepared statement cannot carry a long
#      value for some rows, so those rows go one by one, each with its own;
#   8. the NoBindVars class is left to core, which interpolates everything.
#
# NOTHING HERE CONNECTS. DBI->connect is replaced by a fake DBD::Sybase handle
# that records what is prepared, bound and executed. So this file shows what
# the storage sends, and not that a server stores it whole:
# t/60-connect-params-live.t, part D, does that.

my $HAVE_SYBASE = eval { require DBIO::Sybase::Storage; 1 };

# Only "not installed" is a reason to skip. With DBIO::Sybase there, this
# distribution's own class not loading is a failure.
die $@ unless $HAVE_SYBASE or $@ =~ m{\ACan't locate DBIO/Sybase/Storage\.pm };

plan skip_all => 'DBIO::Sybase is not installed (optional, cpanfile '
  . 'recommends): the class this test is about is built on it'
  unless $HAVE_SYBASE;

require DBIO::MSSQL::Storage::Sybase;

our $PLACEHOLDERS = 1;

# Every statement a fake handle was given, in order.
my @SENT;

{
  package T::K40::STH;

  sub new {
    my ($class, $how, $sql) = @_;
    my $self = bless {
      how => $how, Statement => $sql, bound => [], executed => 0, tuples => [],
    }, $class;
    push @SENT, $self;
    return $self;
  }
  sub bind_param {
    my ($self, $position, $value, $attrs) = @_;
    $self->{bound}[ $position - 1 ] = $value;
    return 1;
  }
  sub execute { $_[0]{executed}++; return 1 }

  # What DBI's execute_for_fetch does with the storage's row dispenser.
  sub execute_for_fetch {
    my ($self, $fetch_tuple, $tuple_status) = @_;
    while (my $tuple = $fetch_tuple->()) {
      push @{ $self->{tuples} }, [ @$tuple ];
      push @$tuple_status, 1;
    }
    return scalar @{ $self->{tuples} };
  }
  sub fetchrow_array     { return }
  sub fetchall_arrayref  { [] }
  sub finish             { 1 }
  sub err                { undef }
  sub errstr             { undef }
}

{
  package T::K40::DBH;

  sub new {
    bless {
      Active => 1, AutoCommit => 1, RaiseError => 1, PrintError => 0,
      Driver => { Name => 'Sybase' },
      syb_oc_version => 'freetds v1.3.17',
    }, shift;
  }
  sub FETCH      { $_[0]{$_[1]} }
  sub ping       { 1 }
  sub disconnect { 1 }

  # BEGIN TRAN, COMMIT and the placeholder probe are do()s.
  sub do {
    my ($self, $sql) = @_;
    T::K40::STH->new(do => $sql)->execute;
    die "this connection takes no placeholders\n"
      if $sql =~ /\?/ and not $PLACEHOLDERS;
    return 1;
  }
  sub selectrow_array { return 1 }    # select @@identity
  sub prepare        { T::K40::STH->new(prepare        => $_[1]) }
  sub prepare_cached { T::K40::STH->new(prepare_cached => $_[1]) }

  # Core's last resort for quoting a value it interpolates (NoBindVars).
  sub quote { (my $value = $_[1]) =~ s/'/''/g; "'$value'" }
}

no warnings 'redefine';
local *DBI::connect = sub { T::K40::DBH->new };
use warnings 'redefine';

{
  package T::K40::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->table('k40_doc');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    title => { data_type => 'varchar', size => 100, is_nullable => 1 },
    body  => { data_type => 'nvarchar', is_nullable => 1 },
    note  => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K40::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_class(Doc => 'T::K40::Result::Doc');
}

# The DBD::Sybase class announces its FreeTDS workaround once per process.
my $FREETDS_NOTICE = qr/compiled against buggy FreeTDS version/;
my @warnings;
local $SIG{__WARN__} = sub {
  push @warnings, $_[0] unless $_[0] =~ $FREETDS_NOTICE;
};

my @KEEP;   # a storage holds its schema weakly

sub connected {
  my $schema = T::K40::Schema->connect('dbi:Sybase:server=k40srv', 'k40', 'k40');
  push @KEEP, $schema;
  $schema->storage->ensure_connected;
  return $schema;
}

# What $code made the storage prepare: the statements with a result source's
# table in them, not the session set-up around them.
sub sent (&) {
  my $code = shift;
  @SENT = ();
  $code->();
  return grep { $_->{how} ne 'do' } @SENT;
}

sub utf8_bytes { my $string = shift; utf8::encode($string); return $string }

my $schema  = connected();
my $storage = $schema->storage;
my $rs      = $schema->resultset('Doc');

is ref $storage, 'DBIO::MSSQL::Storage::Sybase::FreeTDS',
  '(the storage under test is the DBD::Sybase class of this driver, as a '
. 'schema declaring MSSQL gets it on a dbi:Sybase: DSN)';

# ======================================================= 1. where the line is

{
  my ($sth) = sent { $rs->create({ body => 'x' x 4000 }) };

  like $sth->{Statement}, qr/VALUES \(\?\)/,
    'a value of 4000 bytes stays a placeholder -- that is what the server '
  . 'takes whole';
  is_deeply $sth->{bound}, [ 'x' x 4000 ], '... and is bound to it';
}

{
  my ($sth) = sent { $rs->create({ body => 'x' x 4001 }) };

  like $sth->{Statement}, qr/VALUES \('x{4001}'\)/,
    'a value of 4001 bytes is in the statement, as a literal: bound, the '
  . 'server would store 4000 of it and say nothing';
  is_deeply $sth->{bound}, [], '... and nothing is bound in its place';
  is $sth->{executed}, 1, '... the statement is executed once';
}

{
  my ($sth) = sent {
    $rs->create({ title => 'a title', body => 'x' x 5000, note => 'a note' });
  };

  like $sth->{Statement},
    qr/\(\[body\], \[note\], \[title\]\) VALUES \('x{5000}', \?, \?\)/,
    'of several values only the one over the line leaves the binds';
  is_deeply $sth->{bound}, [ 'a note', 'a title' ],
    '... and the others are bound to the placeholders that are left, in '
  . 'their order';
}

# Bytes, not characters: the euro sign is one character and three bytes on
# the way to DBD::Sybase, and the server counts what arrives.
{
  my $under = "\x{20AC}" x 1333;    # 3999 bytes
  my $over  = "\x{20AC}" x 1334;    # 4002 bytes, 1334 characters

  # Until karr k49 this was a placeholder. A bound value beyond ASCII is
  # refused now (t/81-nonascii-empty-binds.t): bound, it arrives padded with
  # blanks. The claim of this block -- the line is drawn in bytes -- holds: a
  # euro sign counts three, 1333 of them stay under the line and are refused
  # (a bind), 1334 are over it and are a literal, which arrives exactly.
  throws_ok { $rs->create({ body => $under }) } qr/beyond ASCII/,
    '1333 euro signs are 3999 bytes: under the line, so a bind -- which a '
  . 'value beyond ASCII may not be (karr k49)';

  my ($sth) = sent { $rs->create({ body => $over }) };

  unlike $sth->{Statement}, qr/\?/,
    '1334 euro signs are 4002 bytes and 1334 characters: a literal -- the '
  . 'line is drawn in bytes';

  ($sth) = sent { $rs->create({ body => utf8_bytes($over) }) };

  unlike $sth->{Statement}, qr/\?/,
    '... and the same value given as the bytes of its UTF-8 form: a literal';
}

# A value that is an object is bound as its string form; that form is what
# is measured.
{
  package T::K40::Stringy;
  use overload '""' => sub { ${ $_[0] } }, fallback => 1;
}
{
  my $object = bless \( my $string = 'o' x 4500 ), 'T::K40::Stringy';

  my ($sth) = sent { $rs->create({ body => $object }) };

  like $sth->{Statement}, qr/VALUES \('o{4500}'\)/,
    'an object that stringifies to more than 4000 bytes goes in as its '
  . 'string form';
}

# ================================================== 2. what the literal is

# The statements below are rendered by hand and sent through the storage's
# seam for rendered statements, so that each one is compared whole.
sub rendered {
  my ($sql, @values) = @_;
  my ($sth) = sent {
    $storage->_execute_rendered($sql, [ map { [ {} => $_ ] } @values ]);
  };
  return $sth;
}

my $pad = 'p' x 4000;   # brings every value below over the line

{
  my $sth = rendered('SELECT ?', "plain $pad");

  is $sth->{Statement}, "SELECT 'plain $pad'",
    'a value of ASCII alone is a plain literal: the varchar the placeholder '
  . 'was declared as';
}

{
  my $value = "\x{E4} \x{20AC} \x{4E2D} \x{1F600} $pad";
  my $bytes = utf8_bytes($value);

  my $sth = rendered('SELECT ?', $value);

  is $sth->{Statement}, "SELECT N'$bytes'",
    'a value with anything beyond ASCII is a Unicode literal, N\'...\': a '
  . 'plain one would go through the code page of the database, and a '
  . 'character that is not in it would be stored as "?" without an error';
  ok !utf8::is_utf8($sth->{Statement}),
    '... and the statement is handed to the DBD as bytes: the UTF-8 form of '
  . 'the value, which is what the DBD sends of a bound string too';

  $sth = rendered('SELECT ?', $bytes);

  is $sth->{Statement}, "SELECT N'$bytes'",
    'the same value given as the bytes of its UTF-8 form makes the same '
  . 'statement -- bound, both forms are the same bytes on the wire as well';
}

# Perl holds a string of characters below 256 as one byte each, and
# DBD::Sybase sends those bytes when it is bound.
{
  my $sth = rendered('SELECT ?', "\xE4 $pad");

  is $sth->{Statement}, "SELECT N'\xE4 $pad'",
    'a string Perl holds as bytes goes in as those bytes: no encoding is '
  . 'guessed for it that a bind would not have had';
}

# Perl would re-encode a byte string joined to a character string; the two
# values here are in one statement and must each arrive as they would alone.
{
  my $as_characters = "\x{4E2D} $pad";
  my $as_bytes      = utf8_bytes("\x{E4} $pad");

  my $sth = rendered('SELECT ?, ?', $as_characters, $as_bytes);

  is $sth->{Statement},
    "SELECT N'" . utf8_bytes($as_characters) . "', N'$as_bytes'",
    'a character string and a byte string in one statement: neither is '
  . 'encoded a second time for the other\'s sake';
}

# ================================ 3. what a literal must not do to a value

{
  my $sth = rendered('SELECT ?', "it's ''quoted'' $pad");

  is $sth->{Statement}, "SELECT 'it''s ''''quoted'''' $pad'",
    'every quote in the value is doubled';
}

{
  my $attack = "x'); DROP TABLE k40_doc; -- $pad";
  my $sth = rendered('INSERT INTO k40_doc (body) VALUES (?)', $attack);

  is $sth->{Statement},
    "INSERT INTO k40_doc (body) VALUES ('x''); DROP TABLE k40_doc; -- $pad')",
    'a value that tries to end the literal does not: it is one literal, to '
  . 'its last character';
}

{
  my $sth = rendered('SELECT ?, ?, ?', 'first', "is this a ? or two ?? $pad", 'last');

  is $sth->{Statement}, "SELECT ?, 'is this a ? or two ?? $pad', ?",
    'a "?" inside a value is no placeholder';
  is_deeply $sth->{bound}, [ 'first', 'last' ],
    '... and moves no other value to another place';
}

# Transact-SQL reads a backslash before a line break inside a literal as
# "the literal goes on in the next line" and drops both (measured: 'a\<LF>b'
# is stored as 'ab'). Closed after the backslash and opened again, the
# literal keeps them. The pieces are joined onto a value of the MAX type:
# joined to each other alone they would be cut at 8000 bytes (measured).
{
  my $sth = rendered('SELECT ?', "a\\\nb\\\r\nc\\\rd\\e $pad");

  is $sth->{Statement},
    "SELECT (CAST('' AS VARCHAR(MAX)) + 'a\\' + '\nb\\' + '\r\nc\\' + '\rd\\e $pad')",
    'a backslash before a line break is kept from the server\'s line '
  . 'continuation; a backslash anywhere else is left alone';
}

# A NUL ends the statement text for the server (measured: Msg 105, unclosed
# quotation mark).
{
  my $sth = rendered('SELECT ?', "a\0b $pad");

  is $sth->{Statement},
    "SELECT (CAST('' AS VARCHAR(MAX)) + 'a' + CHAR(0) + 'b $pad')",
    'a NUL in the value is written as CHAR(0), not sent inside the literal';
}

{
  my $sth = rendered('SELECT ?', "\x{20AC}\0\\\n $pad");

  is $sth->{Statement},
    "SELECT (CAST(N'' AS NVARCHAR(MAX)) + N'" . utf8_bytes("\x{20AC}")
  . "' + NCHAR(0) + N'\\' + N'\n $pad')",
    'the same in a Unicode literal: every piece is one, and so is the NUL';
}

# ==================================== 4. UPDATE and a condition, not INSERT

{
  my $old = 'o' x 5000;
  my $new = 'n' x 5000;

  my ($sth) = sent { $rs->search({ body => $old, note => 'kept' })->update({ body => $new }) };

  like $sth->{Statement},
    qr/\AUPDATE \[k40_doc\] SET \[body\] = 'n{5000}' WHERE \( \[body\] = 'o{5000}' AND \[note\] = \? \)/,
    'an UPDATE with a long value to set and a long value to find the row '
  . 'by: both are in the statement';
  is_deeply $sth->{bound}, [ 'kept' ], '... and the short condition is bound';
}

{
  my ($sth) = sent { $rs->search({ body => 'w' x 5000 })->all };

  like $sth->{Statement}, qr/\ASELECT .* WHERE \( \[body\] = 'w{5000}' \)/s,
    'a search for a long value compares with the whole value -- bound, it '
  . 'was cut to 4000 and compared as that, and found the wrong row';
}

{
  my ($sth) = sent { $rs->search({ body => 'd' x 5000 })->delete };

  like $sth->{Statement}, qr/\ADELETE FROM \[k40_doc\] WHERE \[body\] = 'd{5000}'/,
    'a DELETE by a long value names the whole value: cut, it would delete '
  . 'another row';
}

# ======================= 5. placeholders that cannot be told apart: refused

{
  my $secret = "sekrit40 $pad";

  throws_ok {
    sent {
      $storage->_execute_rendered(
        q{SELECT ?, ? WHERE note = 'what?'}, [ [ {} => $secret ] ],
      );
    };
  } qr/2 placeholders and 1 bind value/,
    'a statement whose placeholders and bind values differ in number, with '
  . 'a long value: refused, saying what does not add up';

  my $error = "$@";

  like $error, qr/4000 bytes/, '... and why the value cannot simply be bound';
  unlike $error, qr/sekrit40|what\?/,
    '... without the value and without the statement';
  is_deeply [ grep { $_->{how} ne 'do' } @SENT ], [],
    '... and before anything was prepared: nothing reached the server';
}

# A "?" in a string literal or in a quoted name is part of the text, not a
# placeholder (DBIO::Storage::DBI::NoBindVars::split_at_placeholders).
{
  my $sth = rendered(
    q{SELECT ? FROM [odd?name] WHERE note = 'what?' AND "q?" = ? AND x = ?},
    "long $pad", 'tail', 'last',
  );

  is $sth->{Statement},
    q{SELECT 'long } . $pad . q{' FROM [odd?name] WHERE note = 'what?' AND "q?" = ? AND x = ?},
    'a "?" in a literal and in quoted names stays where it is; only the '
  . 'placeholder of the long value becomes a literal';
  is_deeply $sth->{bound}, [ 'tail', 'last' ], '... and the others are bound in order';
}

{
  my $sth;
  lives_ok {
    $sth = rendered(q{SELECT ? WHERE note = 'what?'}, 'short');
  } 'the same statement with a value under the line is not this class\'s '
  . 'business: it is prepared as it is';
  is $sth->{Statement}, q{SELECT ? WHERE note = 'what?'}, '... unchanged';
}

# ================================================= 6. the trace, the cache

{
  my @traced;
  my @redacted;

  my $redactor = DBIO::Storage::DBI->redact_bind_value;
  DBIO::Storage::DBI->redact_bind_value(sub {
    push @redacted, $_[0];
    return 'REDACTED';
  });

  $storage->debugcb(sub { push @traced, $_[1] });
  $storage->debug(2);
  my ($sth) = sent { $rs->create({ body => "sekrit40 $pad" }) };
  $storage->debug(0);
  $storage->debugcb(undef);
  DBIO::Storage::DBI->redact_bind_value($redactor);

  like $sth->{Statement}, qr/'sekrit40 p{4000}'/,
    '(the value went to the server in the statement)';
  like $traced[0], qr/VALUES \(\?\)\nSELECT SCOPE_IDENTITY\(\): 'REDACTED'/,
    'the trace shows the statement with its placeholder and the value as '
  . 'redact_bind_value returns it';
  is_deeply \@redacted, [ 'body', 'body' ],
    '... which was asked, with the column, at the start and at the end of '
  . 'the statement';
  is_deeply [ grep { /sekrit40/ } @traced ], [],
    '... so a long value does not reach the trace by another way than a '
  . 'short one';
}

# Level 1 traces the statement alone: no bind values, so nothing to redact.
{
  my @traced;
  my @redacted;
  my $redactor = DBIO::Storage::DBI->redact_bind_value;
  DBIO::Storage::DBI->redact_bind_value(sub { push @redacted, $_[0]; 'REDACTED' });

  $storage->debugcb(sub { push @traced, $_[1] });
  $storage->debug(1);
  sent { $rs->create({ body => "sekrit40 $pad" }) };
  $storage->debug(0);
  $storage->debugcb(undef);
  DBIO::Storage::DBI->redact_bind_value($redactor);

  like $traced[0], qr/VALUES \(\?\)\nSELECT SCOPE_IDENTITY\(\): \s*\z/,
    'trace level 1 shows the statement with its placeholder and no bind value';
  is_deeply [ grep { /sekrit40|REDACTED/ } @traced ], [],
    '... and no value reaches the trace on that level';
}

{
  my $caching = connected();
  $caching->storage->disable_sth_caching(0);

  my ($short) = sent { $caching->resultset('Doc')->create({ body => 'short' }) };
  my ($long)  = sent { $caching->resultset('Doc')->create({ body => 'x' x 5000 }) };

  is $short->{how}, 'prepare_cached',
    '(with statement caching on, a statement of placeholders is cached)';
  is $long->{how}, 'prepare',
    'a statement with a value in it is not: it will not come again, and '
  . 'the cache would keep one for every value';
  is $caching->storage->disable_sth_caching, 0,
    '... and the setting is what it was afterwards';
}

# ================================================ 7. populate, void context

# The fast path prepares one statement and executes it once per row, so a
# long value cannot be in the statement for one row and a placeholder for the
# next.
{
  my @sent = sent {
    $rs->populate([
      { title => 'one',   body => 'short' },
      { title => 'two',   body => 'b' x 5000 },
      { title => 'three', body => 'c' x 6000 },
    ]);
  };

  is scalar @sent, 3, 'populate with a long value in a later row: one '
    . 'statement per row';
  like $sent[0]{Statement}, qr/VALUES \(\?, \?\)/,
    '... the row of short values with placeholders';
  is_deeply $sent[0]{bound}, [ 'short', 'one' ], '... and its own values';
  like $sent[1]{Statement}, qr/VALUES \('b{5000}', \?\)/,
    '... the second row with its long value';
  is_deeply $sent[1]{bound}, [ 'two' ], '... and its own title';
  like $sent[2]{Statement}, qr/VALUES \('c{6000}', \?\)/,
    '... the third with its own: no row is sent with another row\'s value';
  is_deeply [ map { $_->{executed} } @sent ], [ 1, 1, 1 ],
    '... each executed once';

  is_deeply
    [ map { $_->{Statement} } grep { $_->{how} eq 'do' } @SENT ],
    [ 'BEGIN TRAN', 'COMMIT' ],
    '... and all of them in one transaction, as the fast path has it';
}

{
  my @sent = sent {
    $rs->populate([
      { title => 'one', body => 'short' },
      { title => 'two', body => 'x' x 4000 },
    ]);
  };

  is scalar @sent, 1,
    'populate without a value over the line is the fast path it was: one '
  . 'statement';
  is_deeply $sent[0]{tuples}, [ [ 'short', 'one' ], [ 'x' x 4000, 'two' ] ],
    '... executed for every row';
}

# The first row is the one the fast path renders its statement from. A long
# value there, put into that statement, would be every row's value.
{
  my @sent = sent {
    $rs->populate([
      { title => 'one', body => 'a' x 5000 },
      { title => 'two', body => 'short' },
    ]);
  };

  is scalar @sent, 2,
    'populate with the long value in the first row: one statement per row';
  like $sent[0]{Statement}, qr/VALUES \('a{5000}', \?\)/, '... the first';
  like $sent[1]{Statement}, qr/VALUES \(\?, \?\)/,
    '... and the second with its own short value, not the first row\'s';
  is_deeply $sent[1]{bound}, [ 'short', 'two' ], '... bound';
}

# ============================================ 8. NoBindVars is core's to do

{
  local $ENV{DBIO_MSSQL_FREETDS_LOWVER_NOWARN} = 1;
  local $PLACEHOLDERS = 0;

  my $no_binds = connected();

  is ref $no_binds->storage,
    'DBIO::MSSQL::Storage::Sybase::NoBindVars::FreeTDS',
    '(a connection that takes no placeholders gets the NoBindVars class)';

  my $value = "\x{E4} it's ? $pad";

  my ($sth) = sent {
    $no_binds->resultset('Doc')->create({ title => 'short', body => $value });
  };

  (my $quoted = $value) =~ s/'/''/g;

  like $sth->{Statement}, qr/VALUES \(\Q'$quoted'\E, 'short'\)/,
    'there every value is in the statement, long or short, as core puts it '
  . 'there -- this class adds nothing to that';
  is_deeply $sth->{bound}, [], '... and nothing is bound';
}

is_deeply \@warnings, [], 'no warning on the way';

done_testing;
