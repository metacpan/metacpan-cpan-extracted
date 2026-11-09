use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Core;
use DBIO::Schema;
use DBIO::Sybase::Storage::ASE::NoBindVars;

# LIVE (karr k81). The counterpart of t/84-lob-populate-mixed.t. populate() in
# void context with rows that are undef in a TEXT/IMAGE column in some and a
# value in others used to die in core's _insert_bulk ("Inconsistent literal SQL
# value"); now the column goes in with one literal, and the rows that were
# undef are set to NULL afterwards.
#
# CLAIMED: after populate() of such a slice the table holds, per row, NULL for
# undef and the empty value (one space in TEXT, 0x20 in IMAGE, t/68) for '',
# in both orders and for a slice that is all undef; with the key of the rows
# taken from the server and with the key in the slice. For the storage the DSN
# leads to and the NoBindVars class (which has no placeholder, so only the
# slice of LOB columns without the key).
#
# NOT CLAIMED, and held offline only (t/84): a row with CONTENT in the mixed
# slice. FreeTDS cannot write a LOB's content (ct_data_info, t/68), so what is
# run here are undef and '' rows, which need no content. That the content
# lands in the right row of a mixed slice, and that the NULLing UPDATE leaves
# it alone, is shown by the fake handle of t/84 and not by a server.
#
# Makes one table in the database of the DSN, named after this process, and
# drops it.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_ase')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_ase');

$ENV{DBIO_SYBASE_FREETDS_NOWARN} = 1;

my $TABLE = "dbio_k81_lob_$$";

{
  package T::K81L::Result::Lob;
  use base 'DBIO::Core';
  __PACKAGE__->table($TABLE);
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    c_image => { data_type => 'image', is_nullable => 1 },
    c_text  => { data_type => 'text',  is_nullable => 1 },
    name    => { data_type => 'varchar', size => 40, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K81L::Declared;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Lob => 'T::K81L::Result::Lob');
}

{
  package T::K81L::NoBindVars;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Lob => 'T::K81L::Result::Lob');
  __PACKAGE__->storage_type('+DBIO::Sybase::Storage::ASE::NoBindVars');
}

# The server's address and the login stay out of the output: of an error,
# what the server said -- "Msg <number>: <text>" -- or one line of it.
sub said {
  my $text = shift // '';

  my (@messages, %seen);
  while ($text =~ /
    Server\ message\ number=(\d+) [^\n]*? \btext=(.*?) \s*
    (?= Server\ message\ number= | \[for\ Statement | \ at\ \S+\ line\ \d+ | \z )
  /gsx) {
    push @messages, "Msg $1: $2" unless $seen{"$1: $2"}++;
  }
  return join ' | ', @messages if @messages;

  $text =~ s/ at \S+ line \d+.*//s;
  $text =~ s/\b(host|port)=[^;\s]*/$1=../g;
  $text =~ s/\Q$pass\E/../g if length $pass;
  $text =~ s/\s+/ /g;
  return length $text > 400 ? substr($text, 0, 400) . ' ...' : $text;
}

my $why;
sub tried (&) {
  my $code = shift;
  undef $why;
  my $value;
  eval { $value = $code->(); 1 } or $why = said($@);
  return $value;
}
sub why { diag '  ' . ( $why // '(it did not die)' ) }

# Plain DBI, beside every storage under test: makes the table and reads what
# the server holds. A lock wait, so a row somebody left locked fails.
my $raw = DBI->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1,
});
$raw->do('set lock wait 10');

my $live = 1;   # past every skip_all: from here on there is a table to drop

sub table_there {
  ( $raw->selectrow_array(
    "select count(*) from sysobjects where type = 'U' and name = '$TABLE'"
  ) )[0];
}

# [ length of the TEXT, the TEXT, length of the IMAGE, the IMAGE in hex ] of
# the rows $where selects, by id
sub held {
  my $where = shift;
  return $raw->selectall_arrayref(
    "select datalength(c_text), convert(varchar(30), c_text), "
  . "datalength(c_image), bintostr(convert(varbinary(30), c_image)) "
  . "from $TABLE where $where order by id"
  );
}

sub last_id { ( $raw->selectrow_array("select isnull(max(id), 0) from $TABLE") )[0] }

my @SPACE_TEXT  = ( 1, ' ' );
my @SPACE_IMAGE = ( 1, '20' );
my @NULL        = ( undef, undef );

$raw->do(<<"SQL");
CREATE TABLE $TABLE (
  id      INT IDENTITY PRIMARY KEY,
  c_image IMAGE NULL,
  c_text  TEXT NULL,
  name    VARCHAR(40) NULL
)
SQL

# [ name, the values per row ] -- both LOB columns get the same pattern
my @CASES = (
  [ 'undef, empty, undef', [ undef, '', undef ] ],
  [ 'empty, undef',        [ '', undef ]        ],
  [ 'undef, empty',        [ undef, '' ]        ],
  [ 'all undef',           [ undef, undef ]     ],
  [ 'all empty',           [ '', '' ]           ],
);

for my $schema_class (qw(T::K81L::Declared T::K81L::NoBindVars)) {
  my ($tag) = $schema_class =~ /(\w+)\z/;

  my $schema = tried {
    my $schema = $schema_class->connect($dsn, $user, $pass, {
      on_connect_do => [ 'set lock wait 10' ],
    });
    $schema->storage->ensure_connected;
    $schema;
  };

  ok $schema, "$tag: a storage is connected" or do { why(); next };

  my $storage = $schema->storage;
  my $by      = ref $storage;
  my $rs      = $schema->resultset('Lob');
  my $binds   = !$storage->isa('DBIO::Sybase::Storage::ASE::NoBindVars');

  note $by;

  for my $case (@CASES) {
    my ($what, $vals) = @$case;
    my @expected = map {
      defined $_ ? [ @SPACE_TEXT, @SPACE_IMAGE ] : [ @NULL, @NULL ]
    } @$vals;

    # the key from the server; LOB columns only, and (placeholders) with a name
    for my $with_name ($binds ? (0, 1) : (0)) {
      my $after = last_id();
      my $lived = tried {
        $rs->populate([
          [ 'c_text', 'c_image', ( $with_name ? 'name' : () ) ],
          map { [ $_, $_, ( $with_name ? "$tag $what" : () ) ] } @$vals,
        ]);
        1;
      };

      is_deeply [ $lived ? 'lived' : 'died', held("id > $after") ],
        [ 'lived', \@expected ],
        "$by: populate() $what" . ( $with_name ? ' with a name' : '' )
      . ': NULL for undef, the empty value for the empty string' or why();
    }

    # the key in the slice
    SKIP: {
      skip "$by: core's _insert_bulk needs a placeholder for the key", 1
        unless $binds;

      my $first = last_id() + 100;
      my $lived = tried {
        $rs->populate([
          [qw(id c_text c_image)],
          map { [ $first + $_, $vals->[$_], $vals->[$_] ] } 0 .. $#$vals,
        ]);
        1;
      };

      is_deeply [ $lived ? 'lived' : 'died', held("id >= $first") ],
        [ 'lived', \@expected ],
        "$by: populate() $what with the key in the slice: each row has "
      . 'its own value' or why();
    }
  }

  $storage->disconnect;
}

ok tried { $raw->do("DROP TABLE $TABLE"); 1 }, 'the table of this test is dropped'
  or why();
is table_there(), 0, 'nothing of this test is left on the server';

done_testing;

END {
  if ($live && $raw) {
    local $?;
    my $kept = eval { table_there() && !eval { $raw->do("DROP TABLE $TABLE"); 1 } };
    diag "Could not clean up after this test: table $TABLE is still there"
      if $kept;
    $raw->disconnect;
  }
}
