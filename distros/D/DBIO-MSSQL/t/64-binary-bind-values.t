use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::MSSQL::Storage;
use DBIO::MSSQL::Storage::ODBC;

# OFFLINE (karr k50). A value for a binary column did not arrive through a
# schema over either access path (measured 2026-10-08, SQL Server 2022,
# DBD::Sybase 1.27 / FreeTDS 1.3.17, DBD::ODBC 1.61 / tdsodbc 1.3.17): both
# storage classes bound it without a type, and without one it is text --
# varchar to the server, which refuses to make VARBINARY of that (Msg 257),
# and to the client library characters to convert, which most bytes are not.
#
# Each class now binds such a value in the way its DBD carries one:
#
#   DBD::ODBC    as SQL_LONGVARBINARY, the one type that arrives whole in
#                every position and at every size (SQL_VARBINARY and
#                SQL_BINARY are cut to 8000 bytes without an error);
#   DBD::Sybase  ignores a bind type, so the value is bound as its hex form
#                ("0x..."), in pieces of 1999 bytes, to placeholders the
#                statement turns back into bytes:
#                CONVERT(VARBINARY(MAX), ?, 1).
#
# NO VALUE IS PUT INTO A STATEMENT. That is the point of both: what this file
# pins for DBD::Sybase is that the bytes are in the bind values and the
# statement has nothing of them.
#
#   1. which data types are binary ones;
#   2. DBD::Sybase: the placeholder, the pieces, where the lines are;
#   3. what a binary value is: bytes, whatever form Perl holds the string in
#      -- and a character above 255 is none: refused, before anything is sent;
#   4. NULL and the empty value;
#   5. UPDATE, conditions, a binary primary key;
#   6. beside a value that is no binary one, and beside one over 4000 bytes
#      (karr k40), which still goes into the statement;
#   7. what is refused: an EXEC, placeholders that cannot be told apart, more
#      placeholders than the server takes;
#   8. the trace; the statement cache;
#   9. populate in void context;
#  10. DBD::ODBC: the bind type and the bytes, populate included;
#  11. what is NOT covered: the NoBindVars class; and the refusal of a
#      private subclass of the base class on a DBD::Sybase handle (karr k42).
#
# NOTHING HERE CONNECTS. DBI->connect is replaced by a fake handle that
# records what is prepared, bound and executed. That a server stores what is
# sent this way: t/65-binary-values-live.t.

my $HAVE_SYBASE = eval { require DBIO::Sybase::Storage; 1 };

# Only "not installed" is a reason to skip. With DBIO::Sybase there, this
# distribution's own class not loading is a failure.
die $@ unless $HAVE_SYBASE or $@ =~ m{\ACan't locate DBIO/Sybase/Storage\.pm };

plan skip_all => 'DBIO::Sybase is not installed (optional, cpanfile '
  . 'recommends): half of what this test is about is built on it'
  unless $HAVE_SYBASE;

require DBIO::MSSQL::Storage::Sybase;

our $PLACEHOLDERS = 1;

# Every statement a fake handle was given, in order.
my @SENT;

{
  package T::K50::STH;

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
  sub fetchrow_arrayref  { return }
  sub fetch              { return }
  sub fetchall_arrayref  { [] }
  sub finish             { 1 }
  sub err                { undef }
  sub errstr             { undef }
  sub FETCH              { $_[0]{$_[1]} }
}

{
  package T::K50::DBH;

  sub new {
    my ($class, $driver) = @_;
    bless {
      Active => 1, AutoCommit => 1, RaiseError => 1, PrintError => 0,
      Driver => { Name => $driver },
      syb_oc_version => 'freetds v1.3.17',
    }, $class;
  }
  sub FETCH      { $_[0]{$_[1]} }
  sub ping       { 1 }
  sub disconnect { 1 }
  sub get_info   { undef }

  # BEGIN TRAN, COMMIT and the placeholder probe are do()s.
  sub do {
    my ($self, $sql) = @_;
    T::K50::STH->new(do => $sql)->execute;
    die "this connection takes no placeholders\n"
      if $sql =~ /\?/ and not $PLACEHOLDERS;
    return 1;
  }
  # DBD::ODBC's transactions go through the handle, not through do()
  sub begin_work { T::K50::STH->new(do => 'begin_work')->execute; 1 }
  sub commit     { T::K50::STH->new(do => 'commit')->execute; 1 }
  sub rollback   { T::K50::STH->new(do => 'rollback')->execute; 1 }
  sub selectrow_array    { return 1 }    # select @@identity
  sub selectrow_arrayref { [ 1 ] }
  sub prepare        { T::K50::STH->new(prepare        => $_[1]) }
  sub prepare_cached { T::K50::STH->new(prepare_cached => $_[1]) }

  # Core's last resort for quoting a value it interpolates (NoBindVars).
  sub quote { (my $value = $_[1]) =~ s/'/''/g; "'$value'" }
}

no warnings 'redefine';
local *DBI::connect = sub {
  my ($class, $dsn) = @_;
  T::K50::DBH->new( $dsn =~ /\Adbi:(\w+):/ ? $1 : 'Sybase' );
};
use warnings 'redefine';

{
  package T::K50::Result::Blob;
  use base 'DBIO::Core';
  __PACKAGE__->table('k50_blob');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    title => { data_type => 'varchar', size => 100, is_nullable => 1 },
    body  => { data_type => 'varbinary', size => -1, is_nullable => 1 },
    thumb => { data_type => 'image', is_nullable => 1 },
    text  => { data_type => 'nvarchar', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  # a binary primary key
  package T::K50::Result::Hashed;
  use base 'DBIO::Core';
  __PACKAGE__->table('k50_hashed');
  __PACKAGE__->add_columns(
    digest => { data_type => 'binary', size => 32 },
    note   => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('digest');
}

{
  package T::K50::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_class($_ => "T::K50::Result::$_") for qw(Blob Hashed);
}

# The DBD::Sybase class announces its FreeTDS workaround once per process.
my $FREETDS_NOTICE = qr/compiled against buggy FreeTDS version/;
my @warnings;
local $SIG{__WARN__} = sub {
  push @warnings, $_[0] unless $_[0] =~ $FREETDS_NOTICE;
};

my @KEEP;   # a storage holds its schema weakly

sub connected {
  my ($dsn, $class) = @_;
  my $schema = ( $class || 'T::K50::Schema' )->connect(
    $dsn || 'dbi:Sybase:server=k50srv', 'k50', 'k50',
  );
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

# All 256 byte values, FF 00 80 first, as often as it takes.
my $PATTERN = join '', "\xFF\x00\x80", map { chr } 0 .. 255;
sub bytes {
  my $size  = shift;
  my $value = substr $PATTERN x ( 1 + int( $size / length $PATTERN ) ), 0, $size;
  utf8::downgrade($value);
  return $value;
}

# The bytes a list of bound hex pieces stands for.
sub from_hex { join '', map { /\A0x([0-9A-F]*)\z/ ? pack('H*', $1) : die "not a hex piece: $_" } @_ }

my $ONE = 'CONVERT(VARBINARY(MAX), ?, 1)';

my $schema  = connected();
my $storage = $schema->storage;
my $rs      = $schema->resultset('Blob');

is ref $storage, 'DBIO::MSSQL::Storage::Sybase::FreeTDS',
  '(the DBD::Sybase storage under test is the class a schema declaring '
. 'MSSQL gets on a dbi:Sybase: DSN)';

# ============================================ 1. which data types are binary

ok $storage->_is_binary_data_type($_), "'$_' is a binary data type"
  for 'binary', 'varbinary', 'VARBINARY', 'varbinary(max)', 'binary(16)',
      'binary varying', 'image', 'blob', 'bytea', 'longblob';

# "bit" is a boolean on this server and "timestamp" a date and time to DBIO;
# core's own classifier takes the first for a binary type.
ok !$storage->_is_binary_data_type($_),
  ( defined $_ ? "'$_'" : 'no data type' ) . ' is not'
  for 'bit', 'timestamp', 'varchar', 'nvarchar(max)', 'text', 'integer',
      'uniqueidentifier', '', undef;

# ================================= 2. DBD::Sybase: placeholder, pieces, lines

{
  my $value = bytes(300);
  my ($sth) = sent { $rs->create({ title => 'a title', body => $value }) };

  is $sth->{Statement},
    "INSERT INTO [k50_blob] ([body], [title]) VALUES ($ONE, ?)\nSELECT SCOPE_IDENTITY()",
    'a value for a binary column: its placeholder is an expression that '
  . 'makes bytes of a hex string, and the statement has nothing of the value';
  is_deeply $sth->{bound}, [ '0x' . uc unpack('H*', $value), 'a title' ],
    '... which is bound: "0x" and the hex digits, in the place of the value, '
  . 'the other value as it was';
  is $sth->{executed}, 1, '... the statement is executed once';
}

# One placeholder is varchar(4000) to the server: "0x" and the digits of 1999
# bytes. One hex digit more, and the server would cut the piece -- silently.
{
  my $value = bytes(1999);
  my ($sth) = sent { $rs->create({ body => $value }) };

  like $sth->{Statement}, qr/VALUES \(\Q$ONE\E\)/,
    '1999 bytes are one piece: one placeholder';
  is length $sth->{bound}[0], 4000,
    '... of 4000 characters, which is what a placeholder takes whole';

  $value = bytes(2000);
  ($sth) = sent { $rs->create({ body => $value }) };

  like $sth->{Statement}, qr/VALUES \(\(\Q$ONE + $ONE\E\)\)/,
    '2000 bytes are two pieces, joined by the statement';
  is_deeply [ map { length } @{ $sth->{bound} } ], [ 4000, 4 ],
    '... 1999 bytes in the first and one in the second';
  is from_hex(@{ $sth->{bound} }), $value, '... which together are the value';
}

# Past 8000 bytes, where a bound binary value was cut over DBD::ODBC, and far
# past it. Joined as a balanced tree: one after the other, the server copies
# what it has so far for every piece (measured: 3 MB in 77 s, against 1.1 s).
{
  my $value = bytes(9000);
  my ($sth) = sent { $rs->create({ body => $value }) };

  like $sth->{Statement},
    qr/VALUES \(\(\(\(\Q$ONE + $ONE\E\) \+ \Q$ONE\E\) \+ \(\Q$ONE + $ONE\E\)\)\)/,
    '9000 bytes are five pieces, joined as a tree';
  is from_hex(@{ $sth->{bound} }), $value, '... and the pieces are the value';

  $value = bytes(100_000);
  ($sth) = sent { $rs->create({ body => $value }) };

  is scalar @{ $sth->{bound} }, 51, '100000 bytes are 51 pieces';
  is scalar( () = $sth->{Statement} =~ /\?/g ), 51, '... and 51 placeholders';
  is_deeply [ grep { length > 4000 } @{ $sth->{bound} } ], [],
    '... none of more than 4000 characters: nothing the server would cut, '
  . 'and nothing that goes into the statement as a long value does (karr k40)';
  is from_hex(@{ $sth->{bound} }), $value, '... and together they are the value';
  unlike $sth->{Statement}, qr/'|0x/i,
    '... of which the statement has nothing: no literal of any kind';
}

# The type decides, not what the value looks like: a value of plain ASCII in
# a binary column is bytes as well -- bound as text, the server refuses it.
{
  my ($sth) = sent { $rs->create({ body => 'plain ascii', text => 'plain ascii' }) };

  is $sth->{Statement},
    "INSERT INTO [k50_blob] ([body], [text]) VALUES ($ONE, ?)\nSELECT SCOPE_IDENTITY()",
    'the same value in a binary column and in a text column: the one is '
  . 'rewritten, the other is not';
  is_deeply $sth->{bound}, [ '0x' . uc unpack('H*', 'plain ascii'), 'plain ascii' ],
    '... and bound as its hex form there, as itself here';
}

{
  my ($sth) = sent { $rs->create({ thumb => bytes(50) }) };

  like $sth->{Statement}, qr/\(\[thumb\]\) VALUES \(\Q$ONE\E\)/,
    'an IMAGE column is a binary column too';
}

# ============================================== 3. what a binary value is

{
  my $flagged = bytes(600);
  utf8::upgrade($flagged);

  my ($sth) = sent { $rs->create({ body => $flagged }) };

  is from_hex(@{ $sth->{bound} }), bytes(600),
    'a value Perl holds with the UTF-8 flag on is the same bytes: its '
  . 'characters 0 to 255, not the bytes of its UTF-8 form';
}

{
  my @sent;

  throws_ok {
    @sent = sent { $rs->create({ title => 'sekrit50', body => "sekrit50\x{20AC}" }) };
  } qr/binary column 'body' has a character above 255 \(U\+20AC at position 8 of 9\)/,
    'a value with a character above 255 is no binary value: refused, with '
  . 'the column and the place';

  unlike "$@", qr/sekrit50/, '... and without the value';
  is_deeply \@sent, [], '... before anything was prepared';
}

# An object is bound as its string form; that form is the bytes.
{
  package T::K50::Stringy;
  use overload '""' => sub { ${ $_[0] } }, fallback => 1;
}
{
  my $object = bless \( my $string = "\x00\xFFobject" ), 'T::K50::Stringy';
  my ($sth) = sent { $rs->create({ body => $object }) };

  is from_hex(@{ $sth->{bound} }), "\x00\xFFobject",
    'an object that stringifies goes in as the bytes of its string form';
}

# ========================================== 4. NULL and the empty value

{
  my ($sth) = sent { $rs->create({ title => 't', body => undef }) };

  like $sth->{Statement}, qr/VALUES \(\Q$ONE\E, \?\)/,
    'NULL for a binary column has the same placeholder: a plain one is '
  . 'varchar, and the server refuses that for the column whatever the value';
  is_deeply $sth->{bound}, [ undef, 't' ], '... with NULL bound to it';
}

# DBD::Sybase binds an empty string as one blank (karr k55), or as NULL when
# told to. "0x" is neither empty nor a blank, and it is the empty value.
{
  my ($sth) = sent { $rs->create({ body => '' }) };

  like $sth->{Statement}, qr/VALUES \(\Q$ONE\E\)/, 'an empty value: one placeholder';
  is_deeply $sth->{bound}, [ '0x' ],
    '... bound as "0x", which is no empty string for DBD::Sybase to make a '
  . 'blank of';
}

# =========================== 5. UPDATE, conditions, a binary primary key

{
  my $value = bytes(4000);

  my ($sth) = sent { $rs->search({ title => 't' })->update({ body => $value }) };

  like $sth->{Statement},
    qr/\AUPDATE \[k50_blob\] SET \[body\] = \(\(\Q$ONE + $ONE\E\) \+ \Q$ONE\E\) WHERE \[title\] = \?\z/,
    'UPDATE: the binary value in its pieces, the condition as it was';
  is from_hex(@{ $sth->{bound} }[0 .. 2]), $value, '... the pieces first';
  is $sth->{bound}[3], 't', '... then the value of the condition';
}

{
  my $value = bytes(2500);

  my ($sth) = sent { $rs->search({ body => $value, title => 't' })->all };

  like $sth->{Statement},
    qr/WHERE \( \[body\] = \(\Q$ONE + $ONE\E\) AND \[title\] = \? \)\z/,
    'a condition on a binary column is rewritten the same way';
  is from_hex(@{ $sth->{bound} }[0, 1]), $value, '... with the value in its pieces';

  ($sth) = sent { $rs->search({ body => { -in => [ "\x01", "\x02\xFF" ] } })->all };

  like $sth->{Statement}, qr/\[body\] IN \( \Q$ONE, $ONE\E \)/,
    '... and so is every value of an IN list';
  is_deeply $sth->{bound}, [ '0x01', '0x02FF' ], '... each bound as its own';
}

{
  my $digest = bytes(32);
  my $hashed = $schema->resultset('Hashed');

  my ($sth) = sent { $hashed->find($digest) };

  like $sth->{Statement}, qr/WHERE \( \[me\]\.\[digest\] = \Q$ONE\E \)\z/,
    'find() by a binary primary key';
  is from_hex(@{ $sth->{bound} }), $digest, '... bound as the key';

  my $row = $hashed->new_result({ digest => $digest });
  $row->in_storage(1);

  ($sth) = sent { $row->update({ note => 'changed' }) };

  is $sth->{Statement},
    "UPDATE [k50_hashed] SET [note] = ? WHERE [digest] = $ONE",
    'the WHERE of $row->update on a table with a binary primary key';
  is_deeply $sth->{bound}, [ 'changed', '0x' . uc unpack('H*', $digest) ],
    '... the new value as it is, the key as its hex form';

  ($sth) = sent { $hashed->search({ digest => $digest })->delete };

  like $sth->{Statement}, qr/\ADELETE FROM \[k50_hashed\] WHERE \[digest\] = \Q$ONE\E\z/,
    '... and a DELETE by it';
}

# A type given with a bind value in literal SQL counts as the column's does.
{
  my ($sth) = sent {
    $rs->search(\[ 'HASHBYTES(?, body) = ?',
      [ {} => 'SHA2_256' ], [ { sqlt_datatype => 'varbinary' } => "\xAB\xCD" ],
    ])->all;
  };

  like $sth->{Statement}, qr/HASHBYTES\(\?, body\) = \Q$ONE\E/,
    'a bind value of literal SQL that says it is binary is rewritten, one '
  . 'that says nothing is not';
  is_deeply $sth->{bound}, [ 'SHA2_256', '0xABCD' ], '... and both are bound';
}

# =================== 6. beside other values, and beside a long one (k40)

{
  my $long = 'x' x 5000;

  my ($sth) = sent {
    $rs->create({ title => 'a title', body => bytes(3000), text => $long });
  };

  like $sth->{Statement},
    qr/\(\[body\], \[text\], \[title\]\) VALUES \(\(\Q$ONE + $ONE\E\), 'x{5000}', \?\)/,
    'a binary value, a text value over 4000 bytes and a short one: pieces, '
  . 'the literal of karr k40, a placeholder';
  is scalar @{ $sth->{bound} }, 3, '... three values bound';
  is from_hex(@{ $sth->{bound} }[0, 1]), bytes(3000), '... the two pieces';
  is $sth->{bound}[2], 'a title', '... and the title';
}

# ================================================== 7. what is refused

# DBD::Sybase sends a statement that begins with EXEC as a remote procedure
# call and reads nothing of it but the name and the placeholders. Measured
# with the same rewriting (2026-10-08, karr k49): no error, and the procedure
# is handed the hex string.
{
  my @sent;

  throws_ok {
    @sent = sent {
      $storage->_execute_rendered(
        'EXEC k50_store ?', [ [ { sqlt_datatype => 'varbinary' } => "sekrit50\xFF" ] ],
      );
    };
  } qr/begins with EXEC as a remote procedure call/,
    'an EXEC with a bind value for a binary column: refused -- the '
  . 'procedure would be handed the hex string';

  unlike "$@", qr/sekrit50|k50_store/, '... without the value and the statement';
  is_deeply \@sent, [], '... before anything was prepared';

  lives_ok {
    @sent = sent { $storage->_execute_rendered('EXEC k50_store ?', [ [ {} => 'text' ] ]) };
  } 'an EXEC without one is not this class\'s business';
  is $sent[0]{Statement}, 'EXEC k50_store ?', '... and goes out as it is';
}

{
  my @sent;

  throws_ok {
    @sent = sent {
      $storage->_execute_rendered(
        q{SELECT ?, ? WHERE note = 'what?'},
        [ [ { sqlt_datatype => 'varbinary' } => "sekrit50\xFF" ] ],
      );
    };
  } qr/2 placeholders and 1 bind value/,
    'a statement whose placeholders and bind values differ in number, and a '
  . 'binary value: refused, saying what does not add up';

  like "$@", qr/binary column/, '... and why the placeholder matters';
  unlike "$@", qr/sekrit50|what\?/, '... without the value and the statement';
  is_deeply \@sent, [], '... before anything was prepared';
}

# A "?" in a string literal or in a quoted name is part of the text.
{
  my ($sth) = sent {
    $storage->_execute_rendered(
      q{SELECT ? FROM [odd?name] WHERE note = 'what?' AND "q?" = ?},
      [ [ { sqlt_datatype => 'varbinary' } => "\x01\x02" ], [ {} => 'tail' ] ],
    );
  };

  is $sth->{Statement},
    qq{SELECT $ONE FROM [odd?name] WHERE note = 'what?' AND "q?" = ?},
    'a "?" in a literal and in quoted names stays; the placeholder of the '
  . 'binary value is rewritten';
  is $sth->{bound}[-1], 'tail', '... and the other value is bound';
}

# The server takes 2100 parameters and the handle of the prepared statement
# is one: 2099 placeholders (measured: 2099 pieces, 4195901 bytes, arrive;
# 2100 are Msg 8003).
{
  my $fits = 'f' x ( 2098 * 1999 );
  my ($sth) = sent { $rs->create({ title => 't', body => $fits }) };

  is scalar @{ $sth->{bound} }, 2099,
    '2098 pieces and one other value are 2099 placeholders: sent';

  my $too_much = 'm' x ( 2098 * 1999 + 1 );
  my @sent;

  throws_ok {
    @sent = sent { $rs->create({ title => 't', body => $too_much }) };
  } qr/would have 2100 placeholders, and the server takes 2099/,
    'one byte more is one piece more, and one placeholder too many: refused';

  like "$@", qr/\(column 'body'\) has 4193903 bytes and needs 2099/,
    '... naming the column, its size and what it needs';
  like "$@", qr/about 4195901 bytes of binary values/,
    '... and what one statement carries';
  unlike "$@", qr/mmmm/, '... without the value';
  is_deeply \@sent, [], '... before anything was prepared';
}

# ================================================ 8. the trace, the cache

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
  my ($sth) = sent { $rs->create({ body => "sekrit50\xFF" }) };
  $storage->debug(0);
  $storage->debugcb(undef);
  DBIO::Storage::DBI->redact_bind_value($redactor);

  like $traced[0], qr/VALUES \(\?\)\nSELECT SCOPE_IDENTITY\(\): 'REDACTED'/,
    'the trace shows the statement as it was built, with its placeholder, '
  . 'and the value as redact_bind_value returns it';
  is_deeply \@redacted, [ 'body', 'body' ],
    '... which was asked, with the column, at the start and at the end';
  is_deeply [ grep { /sekrit50|73656B726974/i } @traced ], [],
    '... so neither the value nor its hex form reaches the trace';
}

{
  my $caching = connected();
  $caching->storage->disable_sth_caching(0);

  my ($sth) = sent { $caching->resultset('Blob')->create({ body => bytes(10) }) };

  is $sth->{how}, 'prepare_cached',
    'with statement caching on, a statement with a binary value is cached '
  . 'like any other: it has placeholders only, and comes again';
}

# ============================================ 9. populate, void context

# The fast path prepares one statement from the first row and executes it for
# every row. How many placeholders a binary value takes depends on its size,
# so such a data set goes row by row, each with its own statement.
{
  my @sent = sent {
    $rs->populate([
      { title => 'one',   body => bytes(10) },
      { title => 'two',   body => bytes(5000) },
      { title => 'three', body => '' },
    ]);
  };

  is scalar @sent, 3, 'populate with a binary column: one statement per row';
  like $sent[0]{Statement}, qr/VALUES \(\Q$ONE\E, \?\)/, '... the first of one piece';
  like $sent[1]{Statement}, qr/VALUES \(\(\(\Q$ONE + $ONE\E\) \+ \Q$ONE\E\), \?\)/,
    '... the second of three';
  is from_hex(@{ $sent[1]{bound} }[0 .. 2]), bytes(5000), '... its own value';
  is_deeply $sent[2]{bound}, [ '0x', 'three' ], '... the third with its empty one';
  is_deeply [ map { $_->{executed} } @sent ], [ 1, 1, 1 ], '... each executed once';

  is_deeply
    [ map { $_->{Statement} } grep { $_->{how} eq 'do' } @SENT ],
    [ 'BEGIN TRAN', 'COMMIT' ],
    '... and all of them in one transaction, as the fast path has it';
}

{
  my @sent;

  throws_ok {
    @sent = sent {
      $rs->populate([
        { title => 'one', body => bytes(10) },
        { title => 'two', body => "no bytes \x{263A}" },
      ]);
    };
  } qr/binary column 'body' has a character above 255/,
    'populate with a value that is no binary value in a later row: refused';

  is_deeply [ @SENT ], [],
    '... before the first row was sent, and before a transaction was begun';
}

{
  my @sent = sent {
    $rs->populate([ { title => 'one', text => 'a' }, { title => 'two', text => 'b' } ]);
  };

  is scalar @sent, 1,
    'populate without a binary column is the fast path it was: one statement';
}

# ==================================================== 10. DBD::ODBC

{
  my $odbc    = connected('dbi:ODBC:DSN=k50');
  my $ostore  = $odbc->storage;
  my $ors     = $odbc->resultset('Blob');
  my $LONGVAR = DBI::SQL_LONGVARBINARY();

  is ref $ostore, 'DBIO::MSSQL::Storage::ODBC',
    '(over a dbi:ODBC: DSN the storage is the DBD::ODBC class)';

  is $ostore->bind_attribute_by_data_type($_), $LONGVAR,
    "DBD::ODBC: a '$_' value is bound as SQL_LONGVARBINARY -- the type that "
  . 'is not cut at 8000 bytes'
    for qw(varbinary binary image blob);

  is $ostore->bind_attribute_by_data_type($_), undef,
    "... a '$_' value without a type, as before"
    for qw(bit integer), "varchar(50)";   # a varchar(n) is a real VARCHAR; varchar, text, nvarchar are national, karr k58 (t/75)

  my $value = bytes(9000);
  my ($sth) = sent { $ors->create({ title => 'a title', body => $value }) };

  like $sth->{Statement}, qr/\AINSERT INTO \[k50_blob\] \(\[body\], \[title\]\) VALUES \(\?, \?\)/,
    'DBD::ODBC: the statement is what it was -- the DBD carries a binary value';
  is_deeply [ @{ $sth->{bound} }[0, 1] ], [ $value, 'a title' ],
    '... the value bound whole, as its bytes';
  is_deeply [ @{ $sth->{attrs} }[0, 1] ], [ $LONGVAR, DBI::SQL_WLONGVARCHAR() ],
    "... with the type, and the title (a varchar is an NVARCHAR on the server, karr k58) as Unicode";

  ($sth) = sent { $ors->search({ body => $value })->all };

  is_deeply [ $sth->{bound}[0], $sth->{attrs}[0] ], [ $value, $LONGVAR ],
    '... the same in a condition';

  # DBD::ODBC sends a string with the UTF-8 flag on as the bytes of its UTF-8
  # form (measured: 600 bytes arrived as 862).
  my $flagged = bytes(600);
  utf8::upgrade($flagged);

  ($sth) = sent { $ors->create({ body => $flagged }) };

  ok !utf8::is_utf8($sth->{bound}[0]),
    'DBD::ODBC: a value Perl holds with the UTF-8 flag on is handed to the '
  . 'DBD without it';
  is $sth->{bound}[0], bytes(600), '... the same bytes';

  my @sent;

  throws_ok {
    @sent = sent { $ors->create({ body => "sekrit50\x{20AC}" }) };
  } qr/binary column 'body' has a character above 255/,
    'DBD::ODBC: a character above 255 is refused here too';
  unlike "$@", qr/sekrit50/, '... without the value';
  is_deeply \@sent, [], '... before anything was prepared';

  # populate in void context stays one statement: the type is bound once,
  # with the first row, and holds for the rows that follow.
  my $second = bytes(700);
  utf8::upgrade($second);

  @sent = sent {
    $ors->populate([
      { title => 'one', body => bytes(9000) },
      { title => 'two', body => $second },
    ]);
  };

  is scalar @sent, 1, 'DBD::ODBC: populate with a binary column is one statement';
  is $sent[0]{attrs}[0], $LONGVAR, '... with the type bound for the column';
  is_deeply $sent[0]{tuples}, [ [ bytes(9000), 'one' ], [ bytes(700), 'two' ] ],
    '... executed for every row with its bytes';
  ok !utf8::is_utf8($sent[0]{tuples}[1][0]),
    '... a row\'s value with the UTF-8 flag on handed over without it';

  throws_ok {
    @sent = sent {
      $ors->populate([
        { title => 'one', body => bytes(10) },
        { title => 'two', body => "no bytes \x{263A}" },
      ]);
    };
  } qr/binary column 'body' has a character above 255/,
    'DBD::ODBC: populate with a value that is no binary value: refused';
  is_deeply [ @SENT ], [], '... before anything was sent';
}

# ================================================ 11. what is not covered

# No placeholders, no binds: core puts every value into the statement as a
# text literal, and this class adds nothing to that. A binary value does not
# arrive that way (measured: Msg 257 or a conversion error for every size
# but an empty IMAGE).
{
  local $ENV{DBIO_MSSQL_FREETDS_LOWVER_NOWARN} = 1;
  local $PLACEHOLDERS = 0;

  my $no_binds = connected();

  is ref $no_binds->storage,
    'DBIO::MSSQL::Storage::Sybase::NoBindVars::FreeTDS',
    '(a connection that takes no placeholders gets the NoBindVars class)';

  my ($sth) = sent { $no_binds->resultset('Blob')->create({ body => 'abc' }) };

  like $sth->{Statement}, qr/VALUES \('abc'\)/,
    'there a binary value is a text literal like every other value: not '
  . 'covered';
  is_deeply $sth->{bound}, [], '... and nothing is bound';
}

# The base class knows no transport. A private subclass of it on a
# DBD::Sybase handle is refused (karr k42; before, it bound a binary value as
# text, as it always did): there is no binary bind there to promise.
{
  package T::K50::Private::Storage;
  use base 'DBIO::MSSQL::Storage';
  use mro 'c3';

  package T::K50::Private::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+T::K50::Private::Storage');
  __PACKAGE__->register_class(Blob => 'T::K50::Result::Blob');
}
{
  throws_ok { connected(undef, 'T::K50::Private::Schema') }
    qr/T::K50::Private::Storage.*DBD::Sybase.*DBIO::MSSQL::Storage::Sybase/s,
    'a private subclass of the base class on a DBD::Sybase handle is refused, '
  . 'naming the class to derive from';
}

is_deeply \@warnings, [], 'no warning on the way';

done_testing;
