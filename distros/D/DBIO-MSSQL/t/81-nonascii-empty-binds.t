use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::MSSQL::Storage;

# OFFLINE (karr k49, k55). Two defects of a value that is BOUND over
# DBD::Sybase and FreeTDS, both measured 2026-10-08 (DBD::Sybase 1.27,
# FreeTDS 1.3.17, SQL Server 2022) and both silent:
#
#   k49  A bound string with a character beyond ASCII arrives wrong at any
#        length: FreeTDS sends it as a fixed CHAR(n) of its length in client
#        bytes, converted to the server's code page, and the server pads it
#        with blanks (a-umlaut arrives as itself and a blank, the euro sign
#        with two). A character the code page lacks is refused by the client
#        library after the row is written, with blanks for the value. The
#        decision (maintainer, 2026-10-17): no rewriting, the storage
#        REFUSES such a value, loudly, before anything is sent, and names the
#        way out, DBD::ODBC. A value of more than 4000 bytes is a literal
#        (karr k40) and arrives exactly; a value for a binary column is its
#        hex form (karr k50); NULL is no string. None of these is refused.
#
#   k55  A bound empty string arrives as ONE blank: DBD::Sybase itself binds
#        " " for it. The decision: a bound '' is written into the statement
#        as the literal '' at the place of its placeholder, through the seam
#        of karr k40 (_rewrite_binds). Nothing of the value is in the
#        statement otherwise, the trace is as it was.
#
# NOTHING HERE CONNECTS. DBI->connect is replaced by a fake DBD::Sybase
# handle that records what is prepared, bound and executed (as in
# t/63-long-bind-values.t). What a server then holds is shown live:
# t/82-nonascii-empty-live.t.

my $HAVE_SYBASE = eval { require DBIO::Sybase::Storage; 1 };
die $@ unless $HAVE_SYBASE or $@ =~ m{\ACan't locate DBIO/Sybase/Storage\.pm };

plan skip_all => 'DBIO::Sybase is not installed (optional, cpanfile '
  . 'recommends): the class this test is about is built on it'
  unless $HAVE_SYBASE;

require DBIO::MSSQL::Storage::Sybase;

our $PLACEHOLDERS = 1;

# Every statement a fake handle was given, in order.
my @SENT;

{
  package T::K49::STH;

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
  package T::K49::DBH;

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
  sub do {
    my ($self, $sql) = @_;
    T::K49::STH->new(do => $sql)->execute;
    die "this connection takes no placeholders\n"
      if $sql =~ /\?/ and not $PLACEHOLDERS;
    return 1;
  }
  sub selectrow_array { return 1 }
  sub prepare        { T::K49::STH->new(prepare        => $_[1]) }
  sub prepare_cached { T::K49::STH->new(prepare_cached => $_[1]) }
  sub quote { (my $value = $_[1]) =~ s/'/''/g; "'$value'" }
}

no warnings 'redefine';
local *DBI::connect = sub { T::K49::DBH->new };
use warnings 'redefine';

{
  package T::K49::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->table('k49_doc');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    title => { data_type => 'varchar', size => 100, is_nullable => 1 },
    body  => { data_type => 'nvarchar', is_nullable => 1 },
    note  => { data_type => 'varchar', size => 100, is_nullable => 1 },
    bin   => { data_type => 'varbinary', size => 'max', is_nullable => 1 },
    num   => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K49::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_class(Doc => 'T::K49::Result::Doc');
}

my $FREETDS_NOTICE = qr/compiled against buggy FreeTDS version/;
my @warnings;
local $SIG{__WARN__} = sub {
  push @warnings, $_[0] unless $_[0] =~ $FREETDS_NOTICE;
};

my @KEEP;

sub connected {
  my $schema = T::K49::Schema->connect('dbi:Sybase:server=k49srv', 'k49', 'k49pw');
  push @KEEP, $schema;
  $schema->storage->ensure_connected;
  return $schema;
}

# The statements $code made the storage prepare, without the session set-up.
sub sent (&) {
  my $code = shift;
  @SENT = ();
  $code->();
  return grep { $_->{how} ne 'do' } @SENT;
}

# How much reached the server although $code threw: anything prepared, and
# any BEGIN TRAN.
sub reached (&) {
  my $code = shift;
  @SENT = ();
  eval { $code->(); 1 };
  return scalar grep { $_->{Statement} ne 'select 1' } @SENT;   # the liveness ping
}

sub utf8_bytes { my $string = shift; utf8::encode($string); return $string }

my $schema  = connected();
my $storage = $schema->storage;
my $rs      = $schema->resultset('Doc');

is ref $storage, 'DBIO::MSSQL::Storage::Sybase::FreeTDS',
  '(the storage under test is the DBD::Sybase class of this driver)';

# ================================================ 1. k49: a refusal, loudly

for my $case (
  [ 'a-umlaut, a character string'        => "\x{E4}" ],
  [ 'a-umlaut as the byte Perl holds it'  => "\xE4" ],
  [ 'the same as the bytes of UTF-8'      => utf8_bytes("\x{E4}") ],
  [ 'the euro sign'                       => "\x{20AC}" ],
  [ 'a CJK character'                     => "\x{4E2D}" ],
  [ 'beyond the BMP'                      => "\x{1F600}" ],
  [ 'beyond ASCII among ASCII'            => "caf\x{E9} au lait" ],
  [ 'the first character past ASCII'      => "\x80" ],
) {
  my ($what, $value) = @$case;

  is reached { $rs->create({ title => $value }) }, 0,
    "$what: an INSERT is refused before anything is sent";
}

{
  my $secret = "sekrit49 \x{20AC}";

  throws_ok { $rs->create({ note => 'fine', title => $secret }) }
    qr/DBD::Sybase/, 'a bound value beyond ASCII throws';
  my $error = "$@";

  like $error, qr/column 'title'/, '... naming the column';
  like $error, qr/bind value 2 of 2/, '... and the position';
  like $error, qr/DBD::ODBC/, '... saying DBD::ODBC is the way out';
  like $error, qr/DBIO::MSSQL::Storage::ODBC/, '... and the class that is it';
  like $error, qr/FreeTDS/, '... and where the corruption comes from';
  unlike $error, qr/sekrit49|k49pw|k49srv|dbi:Sybase/,
    '... without the value, the password or the DSN';
}

# Where a value is bound, not only in an INSERT.
{
  is reached { $rs->search({ id => 1 })->update({ title => "\x{E4}" }) }, 0,
    'an UPDATE is refused';

  is reached { $rs->search({ title => "\x{E4}" })->all }, 0,
    'a condition is refused: bound, it would match another row or none';

  is reached { $rs->search({ title => { -like => "%\x{E4}%" } })->all }, 0,
    '... a LIKE too';

  is reached { $rs->search({ title => "\x{E4}" })->delete }, 0,
    '... and a DELETE: it would delete another row';

  is reached {
    $storage->_execute_rendered('SELECT ?', [ [ {} => "\x{E4}" ] ]);
  }, 0, 'a rendered statement with an untyped bind value too';

  is reached {
    $storage->_execute_rendered('EXEC proc ?', [ [ {} => "\x{E4}" ] ]);
  }, 0, 'an EXEC as well: it is sent as an RPC with the same CHAR(n)';
}

# An object is bound as its string form.
{
  package T::K49::Stringy;
  use overload '""' => sub { ${ $_[0] } }, fallback => 1;
}
{
  my $object = bless \( my $string = "o\x{E4}" ), 'T::K49::Stringy';
  is reached { $rs->create({ title => $object }) }, 0,
    'an object that stringifies to something beyond ASCII is refused';

  my $plain = bless \( my $ascii = 'ascii' ), 'T::K49::Stringy';
  my ($sth) = sent { $rs->create({ title => $plain }) };
  is_deeply $sth->{bound}, [ $plain ], 'one that stringifies to ASCII is bound';
}

# What is not refused.
{
  my ($sth) = sent { $rs->create({ title => 'plain ASCII', note => undef }) };
  like $sth->{Statement}, qr/VALUES \(\?, \?\)/,
    'ASCII and NULL are bound as before';

  ($sth) = sent { $rs->create({ title => "tab\there \x7F" }) };
  is_deeply $sth->{bound}, [ "tab\there \x7F" ],
    '... the last ASCII character too (U+007F)';

  ($sth) = sent { $rs->create({ bin => "\xE4\x80\xFF" }) };
  like $sth->{Statement}, qr/CONVERT\(VARBINARY\(MAX\), \?, 1\)/,
    'a value for a binary column is bytes, not text: its hex form is bound';
  is_deeply $sth->{bound}, [ '0xE480FF' ], '... and that is ASCII';

  my $long = "\x{E4}" x 4001;
  ($sth) = sent { $rs->create({ body => $long }) };
  like $sth->{Statement}, qr/VALUES \(N'/,
    'a value beyond ASCII of more than 4000 bytes is still a literal '
  . '(karr k40): it arrives whole, so it needs no refusal';
  is_deeply $sth->{bound}, [], '... nothing of it is bound';
}

# populate in void context binds its rows too.
{
  is reached {
    $rs->populate([
      { title => 'one' },
      { title => "two \x{E4}" },
    ]);
  }, 0, 'populate in void context refuses a value beyond ASCII before the '
      . 'first row is sent -- not a transaction begun and rolled back';

  is reached {
    $rs->populate([
      { title => 'one', bin => "\xE4" },
      { title => "two \x{E4}", bin => "\xE5" },
    ]);
  }, 0, '... with a binary value in the data, too';

  my @sent = sent {
    $rs->populate([ { bin => "\xE4" }, { bin => "\xE5\xFF" } ]);
  };
  is scalar @sent, 2,
    '(binary values alone are no reason: that data set goes row by row)';
}

# ======================================================= 2. k55: ''

{
  my ($sth) = sent { $rs->create({ title => '' }) };

  like $sth->{Statement}, qr/VALUES \(''\)/,
    "a bound '' is written into the statement as '': DBD::Sybase binds it "
  . 'as one blank';
  is_deeply $sth->{bound}, [], '... and nothing is bound in its place';
}

{
  my ($sth) = sent { $rs->create({ title => '', note => 'kept', body => ' ' }) };

  like $sth->{Statement},
    qr/\(\[body\], \[note\], \[title\]\) VALUES \(\?, \?, ''\)/,
    'of several values only the empty one leaves the binds';
  is_deeply $sth->{bound}, [ ' ', 'kept' ],
    '... a value of one blank is a value, and stays a bind';
}

{
  my ($sth) = sent { $rs->create({ title => undef }) };
  like $sth->{Statement}, qr/VALUES \(\?\)/, 'NULL stays a placeholder';
}

{
  my ($sth) = sent { $rs->search({ id => 3 })->update({ title => '' }) };
  like $sth->{Statement}, qr/SET \[title\] = '' WHERE \[id\] = \?/,
    "an UPDATE to '' writes the literal";
  is_deeply $sth->{bound}, [ 3 ], '... and the condition stays bound';

  ($sth) = sent { $rs->search({ title => '' })->all };
  like $sth->{Statement}, qr/WHERE \( \[title\] = '' \)/,
    "a condition on '' writes it";

  ($sth) = sent { $rs->search({ title => { -like => '' } })->all };
  like $sth->{Statement}, qr/\[title\] LIKE ''/,
    "... LIKE '' too: bound, it found the row of one blank";

  ($sth) = sent { $rs->search({ title => { -in => [ '', 'a' ] } })->all };
  like $sth->{Statement}, qr/\[title\] IN \( '', \? \)/, '... and IN';
}

{
  my $object = bless \( my $string = '' ), 'T::K49::Stringy';
  my ($sth) = sent { $rs->create({ title => $object }) };
  like $sth->{Statement}, qr/VALUES \(''\)/,
    "an object that stringifies to '' is one";
}

{
  my ($sth) = sent { $rs->create({ bin => '' }) };
  like $sth->{Statement}, qr/CONVERT\(VARBINARY\(MAX\), \?, 1\)/,
    "an empty value for a binary column keeps its way (karr k50)";
  is_deeply $sth->{bound}, [ '0x' ], "... '0x' is bound, never an empty string";
}

{
  my ($sth) = sent {
    $storage->_execute_rendered(
      q{SELECT ? WHERE note = 'plain'}, [ [ {} => '' ] ],
    );
  };
  is $sth->{Statement}, q{SELECT '' WHERE note = 'plain'},
    'a rendered statement: the literal stands where the placeholder stood';
}

# ================== refused: where the literal cannot stand in for a bind

{
  is reached {
    $storage->_execute_rendered('EXEC proc ?', [ [ {} => '' ] ]);
  }, 0, "an EXEC with '' is refused before anything is sent";

  throws_ok {
    $storage->_execute_rendered('EXEC proc ?', [ [ {} => '' ] ]);
  } qr/EXEC/, '... saying what it is';
  like "$@", qr/DBD::ODBC/, '... that DBD::ODBC is a way out';
  like "$@", qr/literal/, '... and so is a literal in the statement';

  my ($ok) = sent {
    $storage->_execute_rendered('EXEC proc ?', [ [ {} => 'x' ] ]);
  };
  is $ok->{Statement}, 'EXEC proc ?',
    'an EXEC with a value that is not empty is sent as before';
}

{
  is reached {
    $storage->_execute_rendered(
      q{SELECT ?, ? WHERE note = 'what?'}, [ [ {} => '' ] ],
    );
  }, 0, 'a statement whose placeholders and bind values differ in number, '
      . "beside '', is refused before anything is sent";

  throws_ok {
    $storage->_execute_rendered(
      q{SELECT ?, ? WHERE note = 'what?'}, [ [ {} => '' ] ],
    );
  } qr/2 placeholders and 1 bind value/, '... saying what does not add up';
  unlike "$@", qr/what\?/, '... without the statement';
}

# A "?" in a string literal or in a quoted name is part of the text.
{
  my ($sth) = sent {
    $storage->_execute_rendered(
      q{SELECT ? FROM [odd?name] WHERE note = 'what?' AND "q?" = ?},
      [ [ {} => '' ], [ {} => 'tail' ] ],
    );
  };
  is $sth->{Statement},
    q{SELECT '' FROM [odd?name] WHERE note = 'what?' AND "q?" = ?},
    "a '?' in a literal and in quoted names stays; the placeholder of '' "
  . 'becomes the literal';
  is_deeply $sth->{bound}, ['tail'], '... and the other value is bound';
}

# ==================================================== the trace, populate

{
  my @traced;
  $storage->debugcb(sub { push @traced, $_[1] });
  $storage->debug(2);
  my ($sth) = sent { $rs->create({ title => '' }) };
  $storage->debug(0);
  $storage->debugcb(undef);

  like $traced[0], qr/VALUES \(\?\)\nSELECT SCOPE_IDENTITY\(\): ''/,
    'the trace shows the statement with its placeholder and the value';
}

{
  my @sent = sent {
    $rs->populate([
      { title => 'one',   note => 'a' },
      { title => '',      note => 'b' },
      { title => 'three', note => '' },
    ]);
  };

  is scalar @sent, 3, "populate with '' in a later row: one statement per row";
  like $sent[0]{Statement}, qr/VALUES \(\?, \?\)/, '... the first with binds';
  like $sent[1]{Statement}, qr/VALUES \(\?, ''\)/, "... the second with ''";
  like $sent[2]{Statement}, qr/VALUES \('', \?\)/, '... the third with its own';
  is_deeply [ map { $_->{bound} } @sent ], [ [ 'a', 'one' ], [ 'b' ], [ 'three' ] ],
    '... each bound its own values';
  is_deeply
    [ map { $_->{Statement} } grep { $_->{how} eq 'do' } @SENT ],
    [ 'BEGIN TRAN', 'COMMIT' ],
    '... in one transaction';
}

{
  my @sent = sent {
    $rs->populate([ { title => 'one' }, { title => ' ' }, { title => undef } ]);
  };
  is scalar @sent, 1, "populate without '' is the fast path: one statement";
}

# =============================================== NoBindVars: core's to do

{
  local $ENV{DBIO_MSSQL_FREETDS_LOWVER_NOWARN} = 1;
  local $PLACEHOLDERS = 0;

  my $no_binds = connected();

  is ref $no_binds->storage,
    'DBIO::MSSQL::Storage::Sybase::NoBindVars::FreeTDS',
    '(a connection that takes no placeholders gets the NoBindVars class)';

  my ($sth) = sent {
    $no_binds->resultset('Doc')->create({ title => '', note => "\x{E4}" });
  };
  like $sth->{Statement}, qr/VALUES \('[^']+', ''\)/,
    'there core puts every value into the statement; this class neither '
  . "refuses nor rewrites it (karr k49: a plain literal is core's)";
  is_deeply $sth->{bound}, [], '... and nothing is bound';
}

is_deeply \@warnings, [], 'no warning on the way';

done_testing;
