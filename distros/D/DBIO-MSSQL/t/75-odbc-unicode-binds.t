use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Schema;
use DBIO::MSSQL::Storage::ODBC;

# OFFLINE (karr k58). A bound string with characters beyond the code page of
# the database did not arrive over DBD::ODBC (measured 2026-10-17, DBD::ODBC
# 1.61 built WITHOUT Unicode support, FreeTDS ODBC driver 1.3.17, SQL Server
# 2022, code page 1252): bound without a type the string is a CHAR to the
# driver, which converts it into the code page whatever the column is, and
# refuses CJK and an emoji even for an NVARCHAR column.
#
# DBIO::MSSQL::Storage::ODBC now
#
#   1. binds a value for an NCHAR, NVARCHAR or NTEXT column as
#      SQL_WLONGVARCHAR -- the Unicode type that is not cut at 4000
#      characters (SQL_WVARCHAR) and does not pad (SQL_WCHAR);
#   2. hands the driver a text string beyond ASCII with the UTF-8 flag on
#      (a string is its characters), a binary value untouched;
#   3. asks the connection, once per handle (when it is made, since karr k81;
#      before that only ahead of the first string beyond ASCII), what it
#      holds for an a-umlaut, and REFUSES a string beyond ASCII
#      when that is not an a-umlaut: the client character set is not UTF-8,
#      and the driver would store the UTF-8 bytes as other characters,
#      silently. A DBD::ODBC with Unicode support is not asked.
#
# NOTHING HERE CONNECTS. DBI->connect is replaced by a fake handle. What a
# server holds: t/76-odbc-unicode-binds-live.t.

our $PROBE_ANSWER = 0xE4;     # what the connection says it holds for U+00E4
our $UNICODE      = 0;        # odbc_has_unicode of the fake handle

my @SENT;

{
  package T::K58::STH;

  sub new {
    my ($class, $how, $sql) = @_;
    my $self = bless {
      how => $how, Statement => $sql, bound => [], attrs => [], executed => 0,
      tuples => [],
    }, $class;
    push @SENT, $self;
    return $self;
  }
  sub bind_param {
    my ($self, $position, $value, $attrs) = @_;
    $self->{bound}[ $position - 1 ] = $value;
    $self->{attrs}[ $position - 1 ] = $attrs;
    return 1;
  }
  sub execute { $_[0]{executed}++; return 1 }
  sub execute_for_fetch {
    my ($self, $fetch_tuple, $tuple_status) = @_;
    while (my $tuple = $fetch_tuple->()) {
      push @{ $self->{tuples} }, [ @$tuple ];
      push @$tuple_status, 1;
    }
    return scalar @{ $self->{tuples} };
  }
  sub fetchrow_array     { $_[0]{Statement} =~ /UNICODE\(/ ? ($main::PROBE_ANSWER) : () }
  sub fetchrow_arrayref  { return }
  sub fetch              { return }
  sub fetchall_arrayref  { [] }
  sub finish             { 1 }
  sub err                { undef }
  sub errstr             { undef }
  sub FETCH              { $_[0]{$_[1]} }
}

{
  package T::K58::DBH;

  sub new {
    bless { Active => 1, AutoCommit => 1, RaiseError => 1, PrintError => 0,
            Driver => { Name => 'ODBC' }, odbc_has_unicode => $main::UNICODE },
      shift;
  }
  sub FETCH      { $_[0]{$_[1]} }
  sub ping       { 1 }
  sub disconnect { 1 }
  sub get_info   { undef }
  sub do         { T::K58::STH->new(do => $_[1])->execute; 1 }
  sub begin_work { T::K58::STH->new(do => 'begin_work')->execute; 1 }
  sub commit     { T::K58::STH->new(do => 'commit')->execute; 1 }
  sub rollback   { T::K58::STH->new(do => 'rollback')->execute; 1 }
  sub selectrow_array    { return 1 }
  sub selectrow_arrayref { [ 1 ] }
  sub prepare        { T::K58::STH->new(prepare        => $_[1]) }
  sub prepare_cached { T::K58::STH->new(prepare_cached => $_[1]) }
}

no warnings 'redefine';
local *DBI::connect = sub { T::K58::DBH->new };
use warnings 'redefine';

{
  package T::K58::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->table('k58_doc');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    v     => { data_type => 'varchar', size => 100, is_nullable => 1 },
    rv    => { data_type => 'varchar(100)', is_nullable => 1 },
    nv    => { data_type => 'nvarchar', size => 100, is_nullable => 1 },
    nvm   => { data_type => 'nvarchar', size => -1, is_nullable => 1 },
    nt    => { data_type => 'ntext', is_nullable => 1 },
    nc    => { data_type => 'nchar', size => 10, is_nullable => 1 },
    body  => { data_type => 'varbinary', size => -1, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K58::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_class(Doc => 'T::K58::Result::Doc');
}

my @KEEP;    # a storage holds its schema weakly

sub connected {
  my $schema = T::K58::Schema->connect('dbi:ODBC:DSN=k58', 'k58', 'k58');
  push @KEEP, $schema;
  $schema->storage->ensure_connected;
  return $schema;
}

# What $code made the storage prepare: no set-up, no probe.
sub sent (&) {
  my $code = shift;
  @SENT = ();
  $code->();
  return grep { $_->{how} ne 'do' and $_->{Statement} !~ /UNICODE\(/ } @SENT;
}
sub probes { scalar grep { ($_->{Statement} // '') =~ /UNICODE\(/ and $_->{executed} } @SENT }

my $WLONG = DBI::SQL_WLONGVARCHAR();

my $schema  = connected();
my $storage = $schema->storage;
my $rs      = $schema->resultset('Doc');

is ref $storage, 'DBIO::MSSQL::Storage::ODBC',
  '(over a dbi:ODBC: DSN the storage is the DBD::ODBC class)';

# ===================================================== 1. which columns, which type

is $storage->bind_attribute_by_data_type($_), $WLONG,
  "a value for '$_' is bound as SQL_WLONGVARCHAR"
  for 'nchar', 'nvarchar', 'ntext', 'NVARCHAR', 'nvarchar(max)', 'nchar(10)',
      'national character varying', 'national char(10)',
      # DBIO deploys these as NCHAR / NVARCHAR / NVARCHAR(MAX)
      # (DBIO::MSSQL::Adapter, DBIO::MSSQL::DDL): national on the server (k58)
      'varchar', 'char', 'text', 'TEXT', 'string';

is $storage->bind_attribute_by_data_type($_), undef,
  "a value for '$_' is bound as it was: untyped (the driver's refusal of what "
. 'the code page lacks stays)'
  for 'varchar(50)', 'char(10)', 'varchar(max)', 'integer', 'bit', 'datetime';

is $storage->bind_attribute_by_data_type($_), DBI::SQL_LONGVARBINARY(),
  "'$_' is still SQL_LONGVARBINARY (karr k50)"
  for 'varbinary', 'image';

is $WLONG, -10, '(SQL_WLONGVARCHAR is -10: SQL_WVARCHAR -9 cuts at 4000 characters, silently)';

# ============================================================ 2. the statement

{
  my $cjk = "a\x{4e2d}\x{1F600}";
  my ($sth) = sent { $rs->create({ nv => $cjk, nvm => $cjk, nt => $cjk, v => $cjk, rv => 'plain' }) };

  like $sth->{Statement}, qr/\AINSERT INTO \[k58_doc\] \(\[nt\], \[nv\], \[nvm\], \[rv\], \[v\]\) VALUES \(\?, \?, \?, \?, \?\)/,
    'the statement is what it was -- nothing of a value in it';
  is_deeply $sth->{attrs}, [ ($WLONG) x 3, undef, $WLONG ],
    '... the Unicode columns, and the varchar one (an NVARCHAR on the server), bound as '
  . 'SQL_WLONGVARCHAR; the real varchar(100) without a type';
  is_deeply $sth->{bound}, [ $cjk, $cjk, $cjk, 'plain', $cjk ], '... the values as they are';
  ok utf8::is_utf8($sth->{bound}[0]), '... with the UTF-8 flag';
}

# conditions and a literal with a typed bind
{
  my $cjk = "\x{4e2d}";
  my ($sth) = sent { $rs->search({ nv => $cjk })->all };
  is_deeply [ $sth->{bound}[0], $sth->{attrs}[0] ], [ $cjk, $WLONG ],
    'a condition on an NVARCHAR column: bound as SQL_WLONGVARCHAR';

  ($sth) = sent { $rs->search({ nvm => 'ascii only' })->all };
  is_deeply [ $sth->{bound}[0], $sth->{attrs}[0] ], [ 'ascii only', $WLONG ],
    '... ASCII too (the type belongs to the column)';
}

# ========================================== 3. a string is its characters

{
  # "\x{E4}" has no UTF-8 flag; Perl holds the a-umlaut as one byte
  my $umlaut = "\x{E4}\x{F6}";
  ok !utf8::is_utf8($umlaut), '(an a-umlaut made with \x{E4} has no UTF-8 flag)';

  my ($sth) = sent { $rs->create({ nv => $umlaut, v => $umlaut }) };

  is_deeply [ map { utf8::is_utf8($_) ? 1 : 0 } @{ $sth->{bound} } ], [ 1, 1 ],
    'the driver is given such a string with the flag on, for NVARCHAR and VARCHAR '
  . '(it would take the one byte for a broken UTF-8 sequence and refuse it)';
  is_deeply $sth->{bound}, [ $umlaut, $umlaut ], '... the same characters';
  ok !utf8::is_utf8($umlaut), '... the caller\'s string is not touched';

  # a binary value is bytes: untouched
  my $bytes = "\xE4\xF6\x00\xFF";
  ($sth) = sent { $rs->create({ body => $bytes }) };
  my ($i) = grep { $sth->{attrs}[$_] == DBI::SQL_LONGVARBINARY() } 0 .. $#{ $sth->{attrs} };
  is $sth->{bound}[$i], $bytes, 'a binary value is handed over as its bytes';
  ok !utf8::is_utf8($sth->{bound}[$i]), '... without the flag';
}

# ====================================== 4. the question about the client charset

{
  # Since karr k81 the question is asked when the connection is made, once per
  # handle: the answer also decides odbc_utf8_on for reading (t/124). It is the
  # same probe the write path used to ask before its first string beyond ASCII.
  @SENT = ();
  my $fresh = connected();
  is probes(), 1, 'the connection asks once, when it is made';
  my ($probe) = grep { ($_->{Statement} // '') =~ /UNICODE\(/ } @SENT;
  is_deeply [ $probe->{bound}[0], $probe->{attrs}[0] ], [ "\x{E4}", $WLONG ],
    '... what it holds for an a-umlaut, sent as Unicode (the code page of the '
  . 'server is no part of the question)';
  ok utf8::is_utf8($probe->{bound}[0]), '... with the flag on';

  @SENT = ();
  $fresh->resultset('Doc')->create({ nv => 'ascii only', v => 'x' });
  $fresh->resultset('Doc')->create({ nv => undef, nvm => '' });
  is probes(), 0, 'ASCII, NULL and an empty string do not ask the connection anything';

  @SENT = ();
  $fresh->resultset('Doc')->create({ nv => "\x{4e2d}" });
  is probes(), 0, 'the first string beyond ASCII does not ask again';

  @SENT = ();
  $fresh->resultset('Doc')->create({ nv => "\x{1F600}" });
  $fresh->resultset('Doc')->populate([ { nv => "\x{4e2d}" } ]);
  is probes(), 0, 'and not again on the same connection';
}

{
  local $PROBE_ANSWER = 0xC3;   # a client character set that reads UTF-8 as Latin-1
  my $latin = connected();
  my $lrs   = $latin->resultset('Doc');
  my $secret = "sekrit58\x{4e2d}";

  my @sent;
  throws_ok { @sent = sent { $lrs->create({ nv => $secret }) } }
    qr/client character set of the ODBC driver is not UTF-8/,
    'a string beyond ASCII is REFUSED when the connection reads UTF-8 as something else';
  like "$@", qr/ClientCharset=UTF-8/, '... the message says what to set';
  like "$@", qr/column 'nv'/, '... and names the column';
  unlike "$@", qr/sekrit58|dbi:ODBC|\bk58\b/, '... and not the value, a password or the DSN';
  is_deeply [ grep { $_->{how} ne 'do' and $_->{Statement} !~ /UNICODE\(/ } @SENT ], [],
    '... before the statement was prepared';

  lives_ok { @sent = sent { $lrs->create({ nv => 'ascii only' }) } }
    '... while ASCII goes through';
  is scalar @sent, 1, '...';

  throws_ok { $lrs->search({ nv => $secret })->all }
    qr/not UTF-8/, '... a condition is refused too';
  throws_ok { $lrs->search({ nvm => { -like => "%$secret%" } })->all }
    qr/not UTF-8/, '... LIKE';

  throws_ok { sent { $lrs->populate([ { nv => 'ascii' }, { nv => $secret } ]) } }
    qr/column 'nv'.*not UTF-8|not UTF-8/s, '... populate in void context: before the first row';
  is_deeply [ grep { $_->{how} ne 'do' and $_->{Statement} !~ /UNICODE\(/ } @SENT ], [],
    '... nothing prepared';

  # a binary value is no text: no question, no refusal
  lives_ok { sent { $lrs->create({ body => "\xE4\xF6" }) } }
    'a binary value with high bytes is not refused (it is bytes, not text)';
}

# DBD::ODBC with Unicode support sends wide strings: no question
{
  local $UNICODE      = 1;
  local $PROBE_ANSWER = 0xC3;
  my $wide = connected();
  my @sent;
  lives_ok { @sent = sent { $wide->resultset('Doc')->create({ nv => "\x{4e2d}" }) } }
    'DBD::ODBC built with Unicode support: not asked, nothing refused';
  is probes(), 0, '... no probe was run';
}

done_testing;
