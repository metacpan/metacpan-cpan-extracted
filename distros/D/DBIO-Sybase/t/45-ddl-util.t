use strict;
use warnings;
use Test::More;

# Offline coverage for the shared DDL emit helpers. These two functions are
# the single source of truth for Sybase type rendering and DEFAULT clauses --
# DBIO::Sybase::DDL (install_ddl) and DBIO::Sybase::Diff::{Table,Column} all
# route through them, so locking their behaviour here guards against the
# duplication regressing back into per-emitter copies.

use_ok 'DBIO::Sybase::DDL';

use DBIO::Sybase::DDL qw( sybase_column_type sybase_default_clause );

# --- sybase_column_type -------------------------------------------------
my %type_map = (
  integer          => 'INT',
  bigint           => 'BIGINT',
  smallint         => 'SMALLINT',
  tinyint          => 'SMALLINT',
  serial           => 'INT',
  bigserial        => 'BIGINT',
  varchar          => 'VARCHAR(255)',
  nvarchar         => 'VARCHAR(255)',
  char             => 'CHAR(1)',
  text             => 'TEXT',
  clob             => 'TEXT',
  date             => 'DATETIME',
  timestamp        => 'DATETIME',
  smalldatetime    => 'SMALLDATETIME',
  blob             => 'IMAGE',
  bytea            => 'IMAGE',
  numeric          => 'NUMERIC(18,6)',
  decimal          => 'NUMERIC(18,6)',
  float            => 'FLOAT',
  real             => 'FLOAT',
  'double precision' => 'DOUBLE PRECISION',
  boolean          => 'BIT',
);
is sybase_column_type($_), $type_map{$_}, "type: $_ -> $type_map{$_}"
  for sort keys %type_map;

is sybase_column_type('UNKNOWNTYPE'), 'UNKNOWNTYPE', 'unknown type passes through uppercased';
is sybase_column_type('weirdo'),      'WEIRDO',      'unknown lc type uppercased';
is sybase_column_type(undef),         'VARCHAR(255)', 'undef defaults to varchar';

# --- uniqueidentifier is VARCHAR(36) (karr k52) ---------------------------
# ASE has no GUID type: passed through like any unknown name it deployed as
# `UNIQUEIDENTIFIER`, which the server refuses with Msg 2715 "Can't find type"
# -- so a schema carrying one GUID column could not be installed at all. It is
# the one unknown name with a decided mapping; every other one still passes
# through (the two claims above), because a user-defined datatype is a name
# this map cannot know either. 36 is the hyphenated string form, which also
# holds newid()'s 32 characters, and the width is the type's own -- a declared
# size does not move it.
is sybase_column_type('uniqueidentifier'), 'VARCHAR(36)', 'uniqueidentifier -> VARCHAR(36)';
is sybase_column_type('UNIQUEIDENTIFIER'), 'VARCHAR(36)', 'UNIQUEIDENTIFIER -> VARCHAR(36)';
is sybase_column_type('uniqueidentifier', 16), 'VARCHAR(36)',
  'uniqueidentifier: a declared size does not change the width';
# Same round-trip claim as the integer widths below (karr k40): the deployed
# column reads back from the catalog as varchar with size 36, and that must
# render as the logical type did, or the diff never converges.
is sybase_column_type('uniqueidentifier'), sybase_column_type('varchar', 36),
  'round-trip: uniqueidentifier renders as its introspected varchar(36) does';

# --- integer widths round-trip through introspection (karr k40) ------------
# Two models are compared by their RENDERED type (karr k32), and the live side
# of that comparison is an ASE type name read out of the catalog -- `int`
# for an INT column, `bigint` for a BIGINT one -- not the logical name the
# schema declared. So each logical integer type must render to the same string
# as the ASE name its own DDL deploys to, or the deploy path diffs forever
# against its own output. `serial` failed exactly this before k40: it deployed
# BIGINT, read back as `bigint`, and re-rendered as INT.
is sybase_column_type('int'),    'INT',    'ASE name `int` renders INT (falls through uc)';
is sybase_column_type('bigint'), 'BIGINT', 'ASE name `bigint` renders BIGINT';
for my $pair ([integer => 'int'], [bigint => 'bigint'],
              [serial => 'int'],  [bigserial => 'bigint']) {
  my ($logical, $ase_name) = @$pair;
  is sybase_column_type($logical), sybase_column_type($ase_name),
    "round-trip: logical $logical renders as introspected $ase_name does";
}

# --- sybase_column_type: declared size is honored, not silently dropped ---
is sybase_column_type('varchar', 100),     'VARCHAR(100)',  'varchar honors declared size';
is sybase_column_type('nvarchar', 50),     'VARCHAR(50)',   'nvarchar honors declared size';
is sybase_column_type('char', 10),         'CHAR(10)',      'char honors declared size';
is sybase_column_type('nchar', 4),         'CHAR(4)',       'nchar honors declared size';
is sybase_column_type('numeric', [10, 2]), 'NUMERIC(10,2)', 'numeric honors [precision,scale] size';
is sybase_column_type('decimal', [12, 4]), 'NUMERIC(12,4)', 'decimal honors [precision,scale] size';
is sybase_column_type('numeric', 8),       'NUMERIC(8,0)',  'numeric honors scalar precision (scale defaults to 0)';

# --- sybase_column_type: an arrayref size on a char type is READ, not numified ---
# VARCHAR/CHAR take exactly ONE scalar length in ASE, so an arrayref names the
# width in its first member. Before karr k33 the reference numified to its
# memory address and rendered as VARCHAR(94182096057624) -- warning-free, and a
# length the caller never wrote. These pin the EQUIVALENCE of each arrayref
# shape with its scalar counterpart, not the merit of the fallback default.
is sybase_column_type('varchar',  [64]),  'VARCHAR(64)',  'varchar reads arrayref size';
is sybase_column_type('nvarchar', [50]),  'VARCHAR(50)',  'nvarchar reads arrayref size';
is sybase_column_type('char',     [10]),  'CHAR(10)',     'char reads arrayref size';
is sybase_column_type('nchar',    [4]),   'CHAR(4)',      'nchar reads arrayref size';
is sybase_column_type('varchar',  [10, 2]), 'VARCHAR(10)',
  'surplus arrayref member dropped (a char type takes one length)';
is sybase_column_type('varchar',  []),       'VARCHAR(255)',
  'arrayref naming no width == absent size (varchar default)';
is sybase_column_type('char',     []),       'CHAR(1)',
  'arrayref naming no width == absent size (char default)';
is sybase_column_type('varchar',  [undef]),  'VARCHAR(255)',
  'arrayref holding undef == absent size';
is sybase_column_type('varchar',  [0]), sybase_column_type('varchar', 0),
  'a zero width renders the same wrapped or bare';
unlike sybase_column_type('varchar', [64]), qr/ARRAY\(0x|\d{10}/,
  'no stringified/numified reference leaks into the type name';

# The numeric branch is untouched by that reading -- pin it against a
# regression that would route [p, s] through the char-family length.
is sybase_column_type('numeric', [10, 2]), 'NUMERIC(10,2)',
  'numeric still reads BOTH arrayref members';

# --- sybase_default_clause ----------------------------------------------
is sybase_default_clause(undef),        '',                  'no default -> empty clause';
is sybase_default_clause('null'),       '',                  "literal 'null' -> empty clause";
is sybase_default_clause('hello'),      " DEFAULT 'hello'",  'string default quoted';
is sybase_default_clause(0),            " DEFAULT '0'",      'zero default quoted (defined)';
is sybase_default_clause(\'getdate()'), ' DEFAULT getdate()', 'scalar ref emitted verbatim';

# An embedded quote is doubled (karr k51). Written as-is, "it's" rendered
# DEFAULT 'it's' -- the literal ends after `it`, and install_ddl,
# Diff::Table::Create, Column::Add and the REPLACE all sent a syntax error.
# '' is the only escape a Transact-SQL string literal has.
is sybase_default_clause("it's"),       " DEFAULT 'it''s'",  'embedded quote doubled';
is sybase_default_clause("''"),         " DEFAULT ''''''",   'every quote doubled, not just the first';
is sybase_default_clause(\"'it''s'"),  " DEFAULT 'it''s'",  'scalar ref still verbatim (already SQL)';

# --- sybase_default_clause: numeric column types (karr k55) ---------------
# A literal default on a numeric column is rendered unquoted. Quoted, ASE
# accepts the CREATE TABLE but stores the default as a VARCHAR constant, and
# every INSERT that leaves the column out then fails -- live on ASE 16.0 SP02:
# Msg 257 "Implicit conversion from datatype 'VARCHAR' to 'NUMERIC' is not
# allowed" (same for BIT). The type decides, not the value: '0' on a varchar
# column is the string '0' and stays quoted. The set is every type
# sybase_column_type renders numeric, logical names and the systypes names
# introspection reports (uint/usmallint/ubigint are ASE's unsigned types).
for my $type (qw/integer serial smallint tinyint bigint bigserial numeric
                 decimal float real boolean int bit money smallmoney
                 uint usmallint ubigint utinyint/,
              'double precision', 'unsigned int', 'unsigned smallint',
              'unsigned bigint', 'INTEGER', 'Numeric') {
  is sybase_default_clause('0', $type), ' DEFAULT 0', "numeric type <$type>: 0 unquoted";
}
is sybase_default_clause(0,       'numeric'), ' DEFAULT 0',     'Perl number 0 unquoted';
is sybase_default_clause('1',     'boolean'), ' DEFAULT 1',     'boolean (BIT) default unquoted';
is sybase_default_clause('-1',    'integer'), ' DEFAULT -1',    'negative integer';
is sybase_default_clause('+.5',   'numeric'), ' DEFAULT +.5',   'signed fraction without integer part';
is sybase_default_clause('2.50',  'money'),   ' DEFAULT 2.50',  'text of the number kept as written (2.50, not 2.5)';
is sybase_default_clause('1.5e3', 'float'),   ' DEFAULT 1.5e3', 'exponent form';
is sybase_default_clause('0', 'varchar'),     " DEFAULT '0'",   "'0' on a character column stays a quoted string";
is sybase_default_clause('0', undef),         " DEFAULT '0'",   'no type: sybase_column_type reads it as varchar -> quoted';
is sybase_default_clause('0', 'datetime'),    " DEFAULT '0'",   'non-numeric type -> quoted';
is sybase_default_clause(\'getdate()', 'integer'), ' DEFAULT getdate()', 'scalar ref verbatim on a numeric column too';
is sybase_default_clause('null', 'integer'),  '',               "literal 'null' -> no clause on a numeric column too";

# A value that is not a number on a numeric column has no correct rendering:
# quoted it is the Msg 257 above on the first INSERT, unquoted it is a
# syntax error or an identifier. Refused, naming column, value and type,
# rather than deployed as a column that looks fine and breaks later.
for my $bad ('abc', '', ' 0', '0 ', '1,5', '$5', 'true', '0x10', '1e', '.') {
  eval { sybase_default_clause($bad, 'numeric', 'price') };
  like $@, qr/\Qprice\E.*not a number.*NUMERIC/s, "non-numeric <$bad> on a numeric column croaks";
}
eval { sybase_default_clause('abc', 'integer') };
like $@, qr/not a number/, 'croaks without a column name as well';

# --- install_ddl: missing is_nullable deploys as NOT NULL (karr k147, ADR 0043) ---
# A column_info without an is_nullable key must still deploy NOT NULL: the
# compiled model (DBIO::Schema::Type::canonical_column) already claims
# not_null => 1 for a missing key, so the deployed DDL must match or
# target_from_compiled diffs diverge on exactly that axis. The old gate --
# "defined && !" -- emitted nothing for a missing key.
{
  package Mock::Source;
  sub isa { 0 }   # never a DBIO::ResultSource::View
  sub name { 'mock_t' }
  sub result_class { 'Mock::Result' }
  sub primary_columns { @{ $_[0]->{pk} || [] } }
  sub columns { @{ $_[0]->{cols} } }
  sub column_info { $_[0]->{info}{ $_[1] } }
  # install_ddl reads these for FKs (karr k54) and unique constraints (k56);
  # the mock table has neither; nor does it declare an index (karr k88).
  sub relationships { () }
  sub unique_constraints { () }
  sub index_declarations_for { () }
}
{
  package Mock::Schema;
  sub sources { @{ $_[0]->{srcs} } }
  sub source  { $_[0]->{src}{ $_[1] } }
}

my $src = bless {
  cols => [qw/plain explicit_null explicit_not_null/],
  info => {
    plain             => { data_type => 'varchar', size => 50 }, # no is_nullable key
    explicit_null     => { data_type => 'integer', is_nullable => 1 },
    explicit_not_null => { data_type => 'integer', is_nullable => 0 },
  },
}, 'Mock::Source';
my $schema = bless {
  srcs => ['mock_t'],
  src  => { mock_t => $src },
}, 'Mock::Schema';

my $ddl = DBIO::Sybase::DDL->install_ddl($schema);
like($ddl, qr/plain VARCHAR\(50\) NOT NULL/,
  'missing is_nullable deploys NOT NULL');
# CLAIM REPLACED (karr k47): this used to read
#   like($ddl, qr/explicit_null INT(?! NOT NULL)/, '... stays nullable')
# -- "nullable" sampled as "NOT NULL is absent". On ASE that absence is not
# nullability: a column definition without null/not null takes the database's
# "allow nulls by default" option, which is OFF in model and therefore in every
# freshly created database, including the temp DB Deploy::diff deploys into.
# Live on ASE 16.0 SP02 the same DDL made the column nullable in testdb and
# NOT NULL in the temp DB. The claim now is the one that holds on any server:
# nullable is spelled NULL.
like($ddl, qr/explicit_null INT NULL\b/,
  'explicit is_nullable => 1 is spelled NULL, not left to the database option');
like($ddl, qr/explicit_not_null INT NOT NULL/,
  'explicit is_nullable => 0 deploys NOT NULL');

# --- install_ddl: column clause order and explicit nullability (karr k47) ---
# ASE's create table grammar is
#   column_name datatype [default {constant_expression | user | null}]
#     [{identity | null | not null}]
# -- the default comes BEFORE the nullability, and identity/null/not null are
# alternatives. Live on ASE 16.0 SP02, `name VARCHAR(32) NOT NULL DEFAULT 'old'`
# is Msg 156 "Incorrect syntax near the keyword 'DEFAULT'", so any table with a
# defaulted not-null column could not be deployed, neither by install nor into
# the temp DB of diff(). The whole statement is pinned byte for byte.
{
  my $k47_src = bless {
    pk   => ['id'],
    cols => [qw/id name code/],
    info => {
      id   => { data_type => 'integer', is_nullable => 0 },
      name => { data_type => 'varchar', size => 32, is_nullable => 0,
                default_value => 'old' },
      code => { data_type => 'varchar', size => 16, is_nullable => 1,
                is_unique => 1 },
    },
  }, 'Mock::Source';
  my $k47_ddl = DBIO::Sybase::DDL->install_ddl(bless {
    srcs => ['mock_t'],
    src  => { mock_t => $k47_src },
  }, 'Mock::Schema');

  is($k47_ddl, join("\n\n",
    "CREATE TABLE mock_t (\n"
    . "  id INT NOT NULL,\n"
    . "  name VARCHAR(32) DEFAULT 'old' NOT NULL,\n"
    . "  code VARCHAR(16) NULL,\n"
    . "  PRIMARY KEY (id)\n"
    . ");",
    'CREATE UNIQUE INDEX mock_t_code_idx ON mock_t (code);',
  ), 'install_ddl: DEFAULT before NOT NULL, nullable spelled NULL');

  # An IDENTITY column: identity is one of the three alternatives, so it
  # stands alone -- no null/not null beside it (an identity column is never
  # nullable) and no default (ASE assigns the value).
  my $id_src = bless {
    pk   => ['id'],
    cols => [qw/id/],
    info => {
      id => { data_type => 'integer', is_auto_increment => 1,
              is_nullable => 0, default_value => 'ignored' },
    },
  }, 'Mock::Source';
  my $id_ddl = DBIO::Sybase::DDL->install_ddl(bless {
    srcs => ['mock_t'],
    src  => { mock_t => $id_src },
  }, 'Mock::Schema');
  like($id_ddl, qr/^  id INT IDENTITY,\n/m,
    'install_ddl: identity column is TYPE IDENTITY, nothing else');
}

# --- install_ddl: IDENTITY is rendered on a numeric column only (karr k52) ---
# ASE takes the identity attribute on a numeric column and nowhere else, so an
# is_auto_increment column of any other type has no statement the server would
# run. It is refused here, naming table, column and type, rather than deployed
# as `VARCHAR(36) IDENTITY` and left to an ASE message naming none of them.
{
  my $ddl_for = sub {
    my (%info) = @_;
    return DBIO::Sybase::DDL->install_ddl(bless {
      srcs => ['mock_t'],
      src  => { mock_t => bless({
        pk => ['id'], cols => ['id'], info => { id => { %info } },
      }, 'Mock::Source') },
    }, 'Mock::Schema');
  };

  # What worked before k52 still does: the attribute alone, on every type that
  # renders numeric.
  for my $t ([ integer => 'INT' ], [ bigint => 'BIGINT' ], [ smallint => 'SMALLINT' ],
             [ serial => 'INT' ], [ int => 'INT' ],
             [ numeric => 'NUMERIC(10,0)', [ 10, 0 ] ]) {
    my ($data_type, $sql, $size) = @$t;
    like($ddl_for->(data_type => $data_type, size => $size, is_auto_increment => 1),
      qr/^  id \Q$sql\E IDENTITY,$/m,
      "install_ddl: is_auto_increment on $data_type is $sql IDENTITY");
  }

  # A name this map does not know is not known to be non-numeric either: a
  # user-defined datatype over numeric(n,0) is a legitimate identity column,
  # and unknown types pass through. Only a type known to be non-numeric is
  # refused.
  like($ddl_for->(data_type => 'my_id_type', is_auto_increment => 1),
    qr/^  id MY_ID_TYPE IDENTITY,$/m,
    'install_ddl: is_auto_increment on an unknown (user-defined) type still renders IDENTITY');

  for my $t ([ varchar => 'VARCHAR' ], [ char => 'CHAR' ], [ text => 'TEXT' ],
             [ datetime => 'DATETIME' ], [ blob => 'IMAGE' ],
             [ varbinary => 'VARBINARY' ], [ uniqueidentifier => 'VARCHAR(36)' ]) {
    my ($data_type, $sql) = @$t;
    my $got = eval { $ddl_for->(data_type => $data_type, is_auto_increment => 1) };
    my $err = $@;
    is($got, undef, "install_ddl: is_auto_increment on $data_type renders no DDL");
    like($err, qr/\bmock_t\b.*\bid\b|\bid\b.*\bmock_t\b/s,
      "install_ddl: ... the refusal names table and column ($data_type)");
    like($err, qr/\Q$data_type\E.*\Q$sql\E/s,
      "install_ddl: ... and the type, as declared and as rendered ($data_type)");
    like($err, qr/IDENTITY.*auto_nextval/s,
      "install_ddl: ... and points at auto_nextval ($data_type)");
  }
}

# --- install_ddl: the shared ArtistGUID shape (karr k52) ---
# DBIO::Test::Schema::ArtistGUID's columns, copied: a uniqueidentifier primary
# key marked is_auto_increment, and a nullable uniqueidentifier marked
# auto_nextval. The second deploys as an ordinary VARCHAR(36) column. The first
# is the refusal above -- so this result class does NOT install on ASE as it is
# declared, and that is pinned here as the state of things rather than worked
# around: what is_auto_increment on a GUID key should mean on ASE is an open
# maintainer question, not something the type map gets to decide.
{
  my %guid_info = (
    artistid  => { data_type => 'uniqueidentifier', is_auto_increment => 1 },
    name      => { data_type => 'varchar', size => 100, is_nullable => 1 },
    rank      => { data_type => 'integer', default_value => 13 },
    charfield => { data_type => 'char', size => 10, is_nullable => 1 },
    a_guid    => { data_type => 'uniqueidentifier', is_nullable => 1,
                   auto_nextval => 1 },
  );
  my $guid_schema = sub {
    my (%info) = @_;
    return bless {
      srcs => ['mock_t'],
      src  => { mock_t => bless({
        pk   => ['artistid'],
        cols => [qw/artistid name rank charfield a_guid/],
        info => { %info },
      }, 'Mock::Source') },
    }, 'Mock::Schema';
  };

  my $got = eval { DBIO::Sybase::DDL->install_ddl($guid_schema->(%guid_info)) };
  my $err = $@;
  is($got, undef, 'install_ddl: the ArtistGUID shape is refused, not deployed');
  like($err, qr/\bartistid\b.*uniqueidentifier.*VARCHAR\(36\).*auto_nextval/s,
    'install_ddl: ... naming the GUID key, its type and auto_nextval');

  # The same table once the key is no longer claimed as an identity: both GUID
  # columns are plain VARCHAR(36), each with its own nullability, and
  # auto_nextval renders nothing -- it is how the value gets there, not DDL.
  is(DBIO::Sybase::DDL->install_ddl($guid_schema->(
      %guid_info, artistid => { data_type => 'uniqueidentifier' })),
    "CREATE TABLE mock_t (\n"
    . "  artistid VARCHAR(36) NOT NULL,\n"
    . "  name VARCHAR(100) NULL,\n"
    . "  rank INT DEFAULT 13 NOT NULL,\n"
    . "  charfield CHAR(10) NULL,\n"
    . "  a_guid VARCHAR(36) NULL,\n"
    . "  PRIMARY KEY (artistid)\n"
    . ");",
    'install_ddl: uniqueidentifier + auto_nextval is VARCHAR(36) with its own nullability');
}

# --- install_ddl: numeric defaults unquoted (karr k55) ---
# The path a Result class's default_value => 0 actually takes. Before k55 this
# rendered DEFAULT '0' / DEFAULT '1' -- CREATE TABLE ran, every INSERT without
# price or flag failed with Msg 257.
{
  my $num_src = bless {
    cols => [qw/price flag label/],
    info => {
      price => { data_type => 'numeric', size => [10, 2], is_nullable => 1, default_value => 0 },
      flag  => { data_type => 'boolean', is_nullable => 0, default_value => 1 },
      label => { data_type => 'varchar', size => 8, is_nullable => 1, default_value => '0' },
    },
  }, 'Mock::Source';
  my $num_ddl = DBIO::Sybase::DDL->install_ddl(bless {
    srcs => ['mock_t'],
    src  => { mock_t => $num_src },
  }, 'Mock::Schema');
  like($num_ddl, qr/^  price NUMERIC\(10,2\) DEFAULT 0 NULL,$/m, 'install_ddl: numeric default unquoted');
  like($num_ddl, qr/^  flag BIT DEFAULT 1 NOT NULL,$/m,         'install_ddl: boolean default unquoted');
  like($num_ddl, qr/^  label VARCHAR\(8\) DEFAULT '0' NULL$/m,  "install_ddl: '0' on varchar stays quoted");
}

# --- install_ddl end-to-end: an arrayref size reaches the server as a length ---
# The unit assertions above cover the function; this covers the path a caller
# actually takes, since install_ddl is where a hand-written add_columns
# definition with a left-over size => [p, s] arrives (karr k33).
{
  my $arr_src = bless {
    cols => [qw/name code amount/],
    info => {
      name   => { data_type => 'varchar', size => [64], is_nullable => 1 },
      code   => { data_type => 'char',    size => [3],  is_nullable => 1 },
      amount => { data_type => 'numeric', size => [10, 2], is_nullable => 1 },
    },
  }, 'Mock::Source';
  my $arr_ddl = DBIO::Sybase::DDL->install_ddl(bless {
    srcs => ['mock_t'],
    src  => { mock_t => $arr_src },
  }, 'Mock::Schema');

  like($arr_ddl, qr/name VARCHAR\(64\)/,   'install_ddl: arrayref varchar size becomes a length');
  like($arr_ddl, qr/code CHAR\(3\)/,       'install_ddl: arrayref char size becomes a length');
  like($arr_ddl, qr/amount NUMERIC\(10,2\)/, 'install_ddl: numeric [p,s] unchanged');
  unlike($arr_ddl, qr/ARRAY\(0x/, 'install_ddl: no stringified arrayref in the DDL');
  unlike($arr_ddl, qr/\(\d{10,}\)/, 'install_ddl: no numified address as a column length');
}

# --- character / char varying are CHAR / VARCHAR; a passed-through type keeps its size (karr k70) ---
# FourKeys.sensors is `character`, size 10. Passed through as CHARACTER without
# the size it deployed as char(1) -- silently, so values were cut or refused --
# and the roundtrip never noticed, both sides reading char(1). The aliases map
# to the types they are, with the same length rules as char/varchar; any other
# name that passes through carries the size it was given.
{
  is sybase_column_type('character', 10),          'CHAR(10)',    'character, size 10 -> CHAR(10)';
  is sybase_column_type('character'),              'CHAR(1)',     'character, no size -> CHAR(1), as char';
  is sybase_column_type('char varying', 20),       'VARCHAR(20)', 'char varying, size 20 -> VARCHAR(20)';
  is sybase_column_type('char varying'),           'VARCHAR(255)', 'char varying, no size -> VARCHAR(255), as varchar';
  is sybase_column_type('CHARACTER', [ 7 ]),       'CHAR(7)',     'character reads an arrayref size like char';
  is sybase_column_type('character varying', 12),  'VARCHAR(12)', 'character varying, size 12 -> VARCHAR(12)';

  is sybase_column_type('binary', 16),     'BINARY(16)',     'passed-through binary keeps its size';
  is sybase_column_type('varbinary', 64),  'VARBINARY(64)',  'passed-through varbinary keeps its size';
  is sybase_column_type('unichar', 5),     'UNICHAR(5)',     'passed-through unichar keeps its size';
  is sybase_column_type('univarchar', 40), 'UNIVARCHAR(40)', 'passed-through univarchar keeps its size';
  is sybase_column_type('my_udt', 8),      'MY_UDT(8)',      'an unknown type keeps its size too';
  is sybase_column_type('varbinary'),      'VARBINARY',      'no size, none written';
  is sybase_column_type('my_udt'),         'MY_UDT',         'an unknown type without size is unchanged';

  # Types of ASE that take no length are not given one: a hand-written
  # `int, size => 11` must not become INT(11).
  is sybase_column_type($_, 11), uc($_), "$_ takes no length: size dropped"
    for qw(int money smallmoney bit image unitext time bigtime bigdatetime);
  is sybase_column_type('unsigned int', 4), 'UNSIGNED INT', 'unsigned int takes no length';

  my $ddl = DBIO::Sybase::DDL->install_ddl(bless {
    srcs => ['mock_t'],
    src  => { mock_t => bless({
      cols => [qw/sensors alt/],
      info => {
        sensors => { data_type => 'character', size => 10 },
        alt     => { data_type => 'char varying', size => 30, is_nullable => 1 },
      },
    }, 'Mock::Source') },
  }, 'Mock::Schema');
  like($ddl, qr/^  sensors CHAR\(10\) NOT NULL,$/m, 'install_ddl: character(10) is CHAR(10)');
  like($ddl, qr/^  alt VARCHAR\(30\) NULL$/m,       'install_ddl: char varying(30) is VARCHAR(30)');
}

# --- mediumtext is TEXT (karr k52) ---
# BindType.a_memo. Passed through, ASE refuses it: Msg 2715 "Can't find type".
is sybase_column_type('mediumtext'), 'TEXT', 'mediumtext -> TEXT';
is sybase_column_type('MEDIUMTEXT', 99), 'TEXT', 'mediumtext -> TEXT, whatever the size';

# --- IDENTITY only where ASE takes it (karr k52, live Msg 2764) ---
# ASE takes IDENTITY on the integer types and NUMERIC(p,0). Refused (Msg 2764
# "Identity field must be a numeric with a scale of 0"): NUMERIC with a scale,
# FLOAT, REAL, DOUBLE PRECISION, BIT, MONEY, SMALLMONEY. numeric/decimal
# without size is NUMERIC(18,6), so refused as well.
{
  my $ddl_for = sub {
    my (%info) = @_;
    return DBIO::Sybase::DDL->install_ddl(bless {
      srcs => ['mock_t'],
      src  => { mock_t => bless({
        pk => ['id'], cols => ['id'], info => { id => { %info } },
      }, 'Mock::Source') },
    }, 'Mock::Schema');
  };
  my @refused = (
    [ numeric            => 'NUMERIC(18,6)', undef ],
    [ decimal            => 'NUMERIC(18,6)', undef ],
    [ numeric            => 'NUMERIC(10,2)', [ 10, 2 ] ],
    [ decimal            => 'NUMERIC(12,3)', [ 12, 3 ] ],
    [ float              => 'FLOAT',            undef ],
    [ real               => 'FLOAT',            undef ],
    [ 'double precision' => 'DOUBLE PRECISION', undef ],
    [ boolean            => 'BIT',              undef ],
    [ money              => 'MONEY',            undef ],
    [ smallmoney         => 'SMALLMONEY',       undef ],
  );
  for my $t (@refused) {
    my ($data_type, $sql, $size) = @$t;
    my $got = eval { $ddl_for->(data_type => $data_type, size => $size, is_auto_increment => 1) };
    my $err = $@;
    is($got, undef, "install_ddl: is_auto_increment on $data_type ($sql) renders no DDL");
    like($err, qr/\bmock_t\b.*\bid\b|\bid\b.*\bmock_t\b/s, "install_ddl: ... names table and column ($data_type $sql)");
    like($err, qr/\Q$sql\E/, "install_ddl: ... and the rendered type ($data_type $sql)");
    like($err, qr/IDENTITY.*auto_nextval/s, "install_ddl: ... and points at auto_nextval ($data_type $sql)");
  }

  # Accepted, as live: the integers, unsigned variants and NUMERIC(p,0).
  for my $t ([ integer => 'INT' ], [ int => 'INT' ], [ smallint => 'SMALLINT' ],
             [ bigint => 'BIGINT' ], [ 'unsigned int' => 'UNSIGNED INT' ],
             [ uint => 'UINT' ], [ usmallint => 'USMALLINT' ], [ ubigint => 'UBIGINT' ],
             [ numeric => 'NUMERIC(10,0)', [ 10, 0 ] ],
             [ decimal => 'NUMERIC(9,0)', 9 ]) {
    my ($data_type, $sql, $size) = @$t;
    like($ddl_for->(data_type => $data_type, size => $size, is_auto_increment => 1),
      qr/^  id \Q$sql\E IDENTITY,$/m, "install_ddl: IDENTITY stays on $data_type ($sql)");
  }
}

# --- CURRENT_TIMESTAMP is getdate() (karr k52) ---
# TimestampPrimaryKey: default_value => \'current_timestamp'. ASE refuses it in
# a DEFAULT (Msg 128); getdate() is its function.
{
  is sybase_default_clause(\'current_timestamp'), ' DEFAULT getdate()', 'current_timestamp -> getdate()';
  is sybase_default_clause(\'CURRENT_TIMESTAMP', 'datetime'), ' DEFAULT getdate()', 'CURRENT_TIMESTAMP, any case';
  is sybase_default_clause(\' current_timestamp '), ' DEFAULT getdate()', 'surrounding blanks ignored';
  is sybase_default_clause(\'getdate()'), ' DEFAULT getdate()', 'getdate() unchanged';
  is sybase_default_clause(\'current_timestamp + 1'), ' DEFAULT current_timestamp + 1',
    'only the bare keyword is mapped; any other expression is verbatim';

  my $ddl = DBIO::Sybase::DDL->install_ddl(bless {
    srcs => ['mock_t'],
    src  => { mock_t => bless({
      cols => [qw/id stamp/],
      info => {
        id    => { data_type => 'integer' },
        stamp => { data_type => 'timestamp', default_value => \'current_timestamp' },
      },
    }, 'Mock::Source') },
  }, 'Mock::Schema');
  like($ddl, qr/^  stamp DATETIME DEFAULT getdate\(\) NOT NULL/m, 'install_ddl: the default is getdate()');
  unlike($ddl, qr/current_timestamp/i, 'install_ddl: no current_timestamp reaches the server');
}

done_testing;
