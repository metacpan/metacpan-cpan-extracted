use strict;
use warnings;

use Test::More;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::Introspect::Normalize;
use DBIO::PostgreSQL::Adapter;
use DBIO::PostgreSQL::Util qw(dsn_names_target type_with_modifier);

# OFFLINE test for karr k156: five small rules, each of which used to let a
# value change the meaning of what is written around it.
#
# 1. The DSN of the temporary database keeps every parameter of the live DSN
#    but the database name. The live DSN may separate by blanks or hold a
#    quoted value with a ';'; reading it with a regex that stops at ';' ate the
#    host and port, and the connection went to libpq's environment.
# 2. An array literal is decoded by its grammar: a quoted element holds commas.
# 3. size, for_each, a policy's for and the keys of an index's with are not
#    SQL; they are checked, and a refusal names the option.
# 4. A plain string default is a value, never an expression.
# 5. The name of the temporary database cannot be known ahead.

# --- 1. _temp_dsn ------------------------------------------------------------
my $deploy = DBIO::PostgreSQL::Deploy->new(schema => undef);

sub temp_dsn { $deploy->_temp_dsn($_[0], '_dbio_tmp_1_2_abcd1234') }

# what libpq would read back: key => value of the parameters
sub params {
  my ($dsn) = @_;
  $dsn =~ s/\Adbi:\w*(?:\([^)]*\))?://i;
  my %p;
  while ($dsn =~ /\G[\s;]*([^\s;='\\]+)[\s;]*=[\s;]*((?:'(?:[^'\\]|\\.)*'|(?:\\.|[^\s;'\\])+)?)/gcs) {
    my ($k, $v) = ($1, $2);
    $v =~ s/\A'(.*)'\z/$1/s;
    $v =~ s/\\(.)/$1/gs;
    $p{$k} = $v;
  }
  return \%p;
}

is_deeply params(temp_dsn('dbi:Pg:dbname=app host=db.internal port=5433')),
  { dbname => '_dbio_tmp_1_2_abcd1234', host => 'db.internal', port => 5433 },
  'a DSN with blanks between parameters keeps host and port';

is_deeply params(temp_dsn(q{dbi:Pg:dbname='a;b';host=h})),
  { dbname => '_dbio_tmp_1_2_abcd1234', host => 'h' },
  'a quoted dbname holding ; is replaced whole, the host stays';

is_deeply params(temp_dsn(q{dbi:Pg:host='h;x' db=a DATABASE=b port=1})),
  { dbname => '_dbio_tmp_1_2_abcd1234', host => 'h;x', port => 1 },
  'db and database are the database name too; a quoted host with ; stays whole';

is_deeply params(temp_dsn('dbi:Pg:host=h;port=5')),
  { dbname => '_dbio_tmp_1_2_abcd1234', host => 'h', port => 5 },
  'a DSN without a database name gets one';

like temp_dsn('dbi:Pg(RaiseError=1):dbname=app;host=h'), qr/\Adbi:Pg\(RaiseError=1\):/,
  'the driver part with its attributes is kept';

is temp_dsn('dbi:Pg:dbname=app;host=h'), 'dbi:Pg:host=h;dbname=_dbio_tmp_1_2_abcd1234',
  'the plain form stays plain';

is temp_dsn('postgresql://u@h:5433/app?sslmode=require&dbname=zzz'),
  'postgresql://u@h:5433/_dbio_tmp_1_2_abcd1234?sslmode=require',
  'a libpq URI gets the name as its path, a dbname parameter is dropped';

ok dsn_names_target(temp_dsn('dbi:Pg:host=h')), 'the result names a target';

eval { $deploy->_temp_dsn('dbi:Pg:this is not a parameter list', 'x') };
like $@, qr/not a list of key=value parameters/, 'a DSN that is no parameter list is refused';
unlike $@, qr/this is not/, '... without quoting it';

# --- 2. array literal ---------------------------------------------------------
sub arr { DBIO::PostgreSQL::Introspect::Normalize->array($_[0]) }

is_deeply arr(q[{"app, admin","it's",plain}]), [ 'app, admin', "it's", 'plain' ],
  'a quoted element holds a comma and an apostrophe';
is_deeply arr(q[{"a\"b","c\\\\d"}]), [ 'a"b', 'c\\d' ],
  'backslash escapes of quote and backslash';
is_deeply arr(q[{a,NULL,"NULL",null}]), [ 'a', undef, 'NULL', undef ],
  'an unquoted NULL is undef, a quoted one is text';
is_deeply arr(q[{"{x}", b c , " q ", ""}]), [ '{x}', 'b c', ' q ', '' ],
  'braces in quotes, blanks around a bare element go, those in quotes stay, an empty string';
is_deeply arr('{}'), [], 'an empty array';
eval { arr('{"open') };
like $@, qr/not a PostgreSQL array literal/, 'a broken literal is refused';
unlike $@, qr/open/, '... without quoting it';

# --- 3. size, for_each, for, with ---------------------------------------------
is type_with_modifier('numeric', [ 10, 2 ]), 'numeric(10,2)', 'a numeric list';
is type_with_modifier('numeric', '10,2'),    'numeric(10,2)', 'digits joined by a comma';
for my $bad ('10) NOT NULL DEFAULT 1 -- ', '1;2', 'x', [ 1, 'y' ], '10,', '-1') {
  eval { type_with_modifier('character', $bad) };
  like $@, qr/a size must be digits/, 'size ' . (ref $bad ? 'list' : "'$bad'") . ' is refused';
  unlike $@, qr/NOT NULL|DEFAULT/, '... without quoting it';
}

# the column is named, the value never
eval { type_with_modifier('character', '10) NOT NULL', 'users.name') };
like $@, qr/a size must be digits.* for column users\.name at /, 'a refused size names the column';
unlike $@, qr/NOT NULL/, '... and not the value';
eval { type_with_modifier('character', {}, 'users.name') };
like $@, qr/got a HASH reference for column users\.name/, 'a reference size names the column';
eval { type_with_modifier('character', 'x') };
unlike $@, qr/for column/, 'without a context the message is as before';
eval { DBIO::PostgreSQL::Adapter->new->to_native({ base_type => 'char', size => 'x) DROP' }, 't.c') };
like $@, qr/for column t\.c/, 'the adapter passes the column on';
unlike $@, qr/DROP/, '... without the value';

my $n = 0;
sub ddl_of {
  my (%o) = @_;
  my $i = ++$n;
  my $result = "K156::S$i\::Result::T";
  my $schema = "K156::S$i";
  {
    no strict 'refs';
    @{"${result}::ISA"} = ('DBIO::Core');
    @{"${schema}::ISA"} = ('DBIO::Schema');
  }
  $schema->load_components('PostgreSQL');
  $result->load_components('PostgreSQL::Result');
  $result->table('t');
  $result->add_columns(
    id   => { data_type => 'bigint', is_nullable => 0 },
    name => { data_type => 'varchar', is_nullable => 1, ( $o{size} ? (size => $o{size}) : () ) },
  );
  $result->set_primary_key('id');
  $result->pg_index(i => { columns => ['name'], using => 'btree', with => $o{with} }) if $o{with};
  $result->pg_trigger(trg => { when => 'BEFORE', event => 'UPDATE', execute => 'f()',
    ( $o{for_each} ? (for_each => $o{for_each}) : () ) }) if $o{trigger};
  $result->pg_rls({ enable => 1, policies => { p => { for => $o{for}, using => 'true' } } })
    if exists $o{for};
  $schema->register_class(T => $result);
  my $sql = eval { DBIO::PostgreSQL::DDL->install_ddl($schema) };
  return ($sql, $@);
}

my ($sql, $err) = ddl_of(size => '10) NOT NULL DEFAULT 1 -- ');
like $err, qr/size/, 'DDL: an injected size is refused naming size';
like $err, qr/for column t\.name/, '... and the column';
unlike $err // '', qr/DEFAULT 1/, '... without the value';

($sql, $err) = ddl_of(size => 10);
like $sql, qr/character varying\(10\)/, 'DDL: a numeric size is written';

($sql, $err) = ddl_of(trigger => 1, for_each => 'ROW EXECUTE FUNCTION evil(); --');
like $err, qr/trigger 'trg'.*for_each is ROW or STATEMENT/, 'DDL: an injected for_each is refused naming the option';
unlike $err // '', qr/evil/, '... without the value';

($sql, $err) = ddl_of(trigger => 1, for_each => 'statement');
like $sql, qr/FOR EACH STATEMENT/, 'DDL: for_each is read in any case';
($sql, $err) = ddl_of(trigger => 1);
like $sql, qr/FOR EACH ROW/, 'DDL: for_each defaults to ROW';

($sql, $err) = ddl_of(for => 'ALL USING (true); DROP TABLE t; --');
like $err, qr/policy 'p'.*for is SELECT, INSERT, UPDATE, DELETE or ALL/, 'DDL: an injected policy for is refused naming the option';
unlike $err // '', qr/DROP TABLE/, '... without the value';

($sql, $err) = ddl_of(for => 'select');
like $sql, qr/FOR SELECT/, 'DDL: for is read in any case';
($sql, $err) = ddl_of(for => 'all');
unlike $sql, qr/ FOR /, 'DDL: ALL writes no FOR';

($sql, $err) = ddl_of(with => { 'fillfactor = 10) WHERE (true); --' => 1, lists => 100 });
like $err, qr/index 'i'.*a key of with/, 'DDL: an injected with key is refused naming the option';
unlike $err // '', qr/WHERE/, '... without the key';
($sql, $err) = ddl_of(with => { fillfactor => 70, 'toast.x' => 1 });
like $sql, qr/WITH \(fillfactor = 70, toast\.x = 1\)/, 'DDL: a storage parameter name is written as given';

# --- 4. plain string default --------------------------------------------------
sub dflt { DBIO::PostgreSQL::Diff::_format_pg_default(@_) }

is dflt('N/A (unknown)', 'text'), q{'N/A (unknown)'::text}, 'a plain string with parentheses is a literal';
is dflt(q{x'); DROP TABLE t; --}, 'text'), q{'x''); DROP TABLE t; --'::text}, 'an injected plain string is a literal';
is dflt('a::b', 'text'), q{'a::b'::text}, 'a plain string with :: is a literal';
is dflt(q{"quoted"}, 'text'), q{'"quoted"'::text}, 'a plain string with a leading quote is a literal';
is dflt('draft', 'text'), q{'draft'::text}, 'a plain word stays a literal';
is dflt(5, 'bigint'), q{'5'::bigint}, 'a number stays a literal with its cast';
is dflt('true', 'boolean'), 'true', 'a boolean column keeps true as pg_get_expr prints it';
is dflt(\'now()', 'timestamp'), 'now()', 'a scalar ref is an expression, written as given';
is dflt(\q{'x'::text}, 'text'), q{'x'::text}, '... also with a cast';

# --- 5. name of the temporary database ----------------------------------------
{
  package K156::Dbh;
  sub new { bless { AutoCommit => 1, pg_server_version => 140000 }, shift }
  sub do { 1 }
  sub selectrow_hashref { { encoding => 'UTF8', collate => 'C', ctype => 'C' } }
}

my %seen;
for (1 .. 5) {
  my $name = $deploy->_create_temp_db(K156::Dbh->new);
  like $name, qr/\A_dbio_tmp_\d+_\d+_[0-9a-f]{8}\z/, 'the name ends in 8 hex digits';
  ok length($name) <= 63, '... and is an identifier of at most 63 bytes';
  $seen{$name}++;
}
is scalar(keys %seen), 5, 'names made in the same second differ';

done_testing;
