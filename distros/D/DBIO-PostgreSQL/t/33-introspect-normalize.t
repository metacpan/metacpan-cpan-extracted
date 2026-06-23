use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Introspect::Normalize ();

# --- name ---

is(DBIO::PostgreSQL::Introspect::Normalize->name('Foo'),     'foo', 'lowercase by default');
is(DBIO::PostgreSQL::Introspect::Normalize->name('Foo', 1),  'Foo', 'preserve case when flag set');
is(DBIO::PostgreSQL::Introspect::Normalize->name(undef),    undef,  'undef stays undef');
is(DBIO::PostgreSQL::Introspect::Normalize->name(undef, 1), undef,  'undef stays undef even with preserve_case');

# --- array ---

my $arr = DBIO::PostgreSQL::Introspect::Normalize->array('{a,b,c}');
is_deeply($arr, ['a', 'b', 'c'], 'decodes {a,b,c}');

is_deeply(DBIO::PostgreSQL::Introspect::Normalize->array([1, 2, 3]),
  [1, 2, 3], 'arrayref passthrough');

is(DBIO::PostgreSQL::Introspect::Normalize->array(undef), undef, 'undef array');

my $empty = DBIO::PostgreSQL::Introspect::Normalize->array('{}');
is_deeply($empty, [], 'empty array');

# --- data_type ---

sub _norm {
  my ($column) = @_;
  my %info;
  DBIO::PostgreSQL::Introspect::Normalize->data_type(\%info, $column);
  return \%info;
}

# Plain text
is(_norm({ data_type => 'text' })->{data_type}, 'text', 'plain text');
is(_norm({ data_type => 'TEXT' })->{data_type}, 'text', 'text lowercased');

# varchar(N)
is_deeply(_norm({ data_type => 'character varying(50)' }),
  { data_type => 'varchar', size => 50 }, 'varchar(50)');
is_deeply(_norm({ data_type => 'varchar(255)' }),
  { data_type => 'varchar', size => 255 }, 'varchar(255) alias');

# Bare character varying -> text with original
is_deeply(_norm({ data_type => 'character varying' }),
  { data_type => 'text', original => { data_type => 'varchar' } },
  'bare character varying -> text (with original)');

# char(N)
is_deeply(_norm({ data_type => 'character(10)' }),
  { data_type => 'char', size => 10 }, 'char(10)');

# numeric(p,s)
is_deeply(_norm({ data_type => 'numeric(10,2)' }),
  { data_type => 'numeric', size => [10, 2] }, 'numeric(10,2)');

# bit / varbit
is_deeply(_norm({ data_type => 'bit(8)' }),
  { data_type => 'bit', size => 8 }, 'bit(8)');
is_deeply(_norm({ data_type => 'bit varying(64)' }),
  { data_type => 'varbit', size => 64 }, 'bit varying(64)');

# pgvector
is_deeply(_norm({ data_type => 'vector(1536)' }),
  { data_type => 'vector', size => 1536 }, 'vector(1536)');

# timestamp with/without tz
is_deeply(_norm({ data_type => 'timestamp(6) without time zone' }),
  { data_type => 'timestamp', size => 6 }, 'timestamp(6) without tz');
is(_norm({ data_type => 'timestamp without time zone' })->{data_type},
  'timestamp', 'timestamp without tz (no size)');
is(_norm({ data_type => 'time without time zone' })->{data_type},
  'time', 'time without tz');
is_deeply(_norm({ data_type => 'interval(3)' }),
  { data_type => 'interval', size => 3 }, 'interval(3)');
is_deeply(_norm({ data_type => 'timestamp with time zone(6)' }),
  { data_type => 'timestamp with time zone', size => 6 },
  'timestamp(6) with tz (keeps full type name)');

# bare character -> char
is(_norm({ data_type => 'character' })->{data_type}, 'char', 'bare character -> char');

# Enum
my $enum_info = _norm({
  data_type     => 'role_type',
  type_category => 'e',
  enum_type     => 'role_type',
  type_schema   => 'public',
});
is($enum_info->{data_type}, 'enum', 'enum data_type');
is($enum_info->{pg_enum_type}, 'role_type', 'enum: public schema stripped from pg_enum_type');
is($enum_info->{extra}{custom_type_name}, 'role_type', 'enum: custom_type_name');

# Enum in non-public schema: keep the prefix
my $enum_info2 = _norm({
  data_type     => 'auth.role_type',
  type_category => 'e',
  enum_type     => 'role_type',
  type_schema   => 'auth',
});
is($enum_info2->{pg_enum_type}, 'auth.role_type', 'enum: non-public schema kept');

# Enum with values passed in
my $enum_info3;
my %info3;
DBIO::PostgreSQL::Introspect::Normalize->data_type(\%info3, {
  data_type     => 'role_type',
  type_category => 'e',
  enum_type     => 'role_type',
  type_schema   => 'public',
}, '{admin,user,guest}');
is_deeply($info3{extra}{list}, ['admin', 'user', 'guest'], 'enum values decoded');

# --- default_value ---

sub _norm_default {
  my ($expr, $is_pk) = @_;
  my %info;
  DBIO::PostgreSQL::Introspect::Normalize->default_value(\%info, $expr, $is_pk);
  return \%info;
}

# nextval
my $ai = _norm_default(q{nextval('public.users_id_seq'::regclass)}, 1);
is($ai->{is_auto_increment}, 1, 'nextval -> is_auto_increment');
is($ai->{sequence}, 'public.users_id_seq', 'nextval -> sequence');
is($ai->{retrieve_on_insert}, 1, 'nextval on PK -> retrieve_on_insert');

# Quoted string
is(_norm_default(q{'draft'})->{default_value}, 'draft', 'quoted string');
is(_norm_default(q{'draft'::text})->{default_value}, 'draft', 'quoted string + cast');

# Negative number
is_deeply(_norm_default(q{(-5)}), { default_value => '-5' }, 'parenthesized number');
is(_norm_default(q{42})->{default_value}, 42, 'plain number');

# NULL
my $null_info = _norm_default('NULL');
is(ref $null_info->{default_value}, 'SCALAR', 'NULL -> SCALAR ref');
is(${$null_info->{default_value}}, 'null', 'NULL -> "null"');

# Expression: now() / SQL literal
my $now_info = _norm_default('now()');
is(ref $now_info->{default_value}, 'SCALAR', 'now() -> SCALAR ref');
is(${$now_info->{default_value}}, 'current_timestamp', 'now() -> current_timestamp');

# Boolean special-case: 0/1 become false/true
my %bool_info;
$bool_info{data_type} = 'boolean';
DBIO::PostgreSQL::Introspect::Normalize->default_value(\%bool_info, '0');
is(${$bool_info{default_value}}, 'false', 'boolean 0 -> false');

%bool_info = (data_type => 'boolean');
DBIO::PostgreSQL::Introspect::Normalize->default_value(\%bool_info, '1');
is(${$bool_info{default_value}}, 'true', 'boolean 1 -> true');

# Non-boolean numeric stays numeric
my %int_info;
$int_info{data_type} = 'integer';
DBIO::PostgreSQL::Introspect::Normalize->default_value(\%int_info, '5');
is($int_info{default_value}, 5, 'integer default 5 stays numeric');

# Undef
my %no_default;
DBIO::PostgreSQL::Introspect::Normalize->default_value(\%no_default, undef);
ok(!exists $no_default{default_value}, 'undef default produces no fields');

# Trim whitespace
is(_norm_default("  'hello'  ")->{default_value}, 'hello', 'whitespace trimmed');

# retrieve_on_insert on PK without auto_increment
my %pk_info;
DBIO::PostgreSQL::Introspect::Normalize->default_value(\%pk_info, q{'foo'}, 1);
is($pk_info{retrieve_on_insert}, 1, 'PK + non-AI default -> retrieve_on_insert');

done_testing;
