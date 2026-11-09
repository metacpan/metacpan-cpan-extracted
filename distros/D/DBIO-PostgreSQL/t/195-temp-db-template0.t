use strict;
use warnings;
use Test::More;

# Offline test for karr k151: the temporary database of a deploy is an empty
# database from template0, and it is checked to be empty.
#
# Claim: CREATE DATABASE of the temporary database names TEMPLATE template0
# and carries the encoding and collation of the live database, so that the
# target model is what the schema declares and nothing a template1 holds. The
# catalog query names only the columns the server version has. Every catalog
# value is a literal. The emptiness check lets public and plpgsql pass and
# names every other object it finds.

use DBIO::PostgreSQL::Deploy;

my $deploy = DBIO::PostgreSQL::Deploy->new(schema => undef);

sub sql {
  my ($version, %row) = @_;
  return $deploy->_create_database_sql('tmp_db', $version, {
    encoding => 'UTF8', collate => 'en_US.UTF-8', ctype => 'en_US.UTF-8', %row,
  });
}

# --- the statement per version and provider ---------------------------------
is sql(130005),
  q{CREATE DATABASE tmp_db TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8'},
  'PG13: template0, ENCODING, LC_COLLATE, LC_CTYPE and nothing else';
is sql(140010, provider => 'i', locale => 'x'), sql(130005),
  'PG14: no provider clause, whatever the row says';

is sql(150004, provider => 'c'),
  q{CREATE DATABASE tmp_db TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8' LOCALE_PROVIDER libc},
  'PG15 libc: LOCALE_PROVIDER libc';
is sql(150004, provider => 'i', locale => 'de-DE', icu_rules => '&a<b'),
  q{CREATE DATABASE tmp_db TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8' LOCALE_PROVIDER icu ICU_LOCALE 'de-DE'},
  'PG15 icu: ICU_LOCALE, no ICU_RULES (not there before 16)';
is sql(160002, provider => 'i', locale => 'de-DE', icu_rules => '&a<b'),
  q{CREATE DATABASE tmp_db TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8' LOCALE_PROVIDER icu ICU_LOCALE 'de-DE' ICU_RULES '&a<b'},
  'PG16 icu: ICU_LOCALE and ICU_RULES';
unlike sql(160002, provider => 'i', locale => 'de-DE', icu_rules => ''), qr/ICU_RULES/,
  'PG16 icu without rules: no ICU_RULES';
is sql(170000, provider => 'b', locale => 'C.UTF-8'),
  q{CREATE DATABASE tmp_db TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8' LOCALE_PROVIDER builtin BUILTIN_LOCALE 'C.UTF-8'},
  'PG17 builtin: BUILTIN_LOCALE, no ICU_LOCALE';
like sql(180000, provider => 'i', locale => 'de-DE'), qr/LOCALE_PROVIDER icu ICU_LOCALE 'de-DE'/,
  'PG18 icu: ICU_LOCALE';

# --- quoting ----------------------------------------------------------------
{
  my $s = sql(160000, collate => q{a'b}, ctype => q{c''d}, provider => 'i',
              locale => q{l'x}, icu_rules => q{&'a});
  like $s, qr/LC_COLLATE 'a''b' LC_CTYPE 'c''''d'/, 'quotes in collation and ctype are doubled';
  like $s, qr/ICU_LOCALE 'l''x' ICU_RULES '&''a'/, 'quotes in locale and rules are doubled';
  like $deploy->_create_database_sql('we"ird', 130000,
    { encoding => 'UTF8', collate => 'C', ctype => 'C' }),
    qr/^CREATE DATABASE "we""ird" TEMPLATE/, 'the name is an identifier';
}

# --- the catalog query names the columns the version has ---------------------
{
  my $q13 = $deploy->_locale_catalog_sql(130000);
  unlike $q13, qr/datlocprovider|daticulocale|datlocale|daticurules/, 'PG13: none of the newer columns';
  like $q13, qr/pg_encoding_to_char\(encoding\).*datcollate.*datctype.*current_database\(\)/s,
    'PG13: encoding, datcollate, datctype of current_database()';
  my $q15 = $deploy->_locale_catalog_sql(150000);
  like $q15, qr/datlocprovider/, 'PG15: datlocprovider';
  like $q15, qr/daticulocale/, 'PG15: daticulocale';
  unlike $q15, qr/daticurules|datlocale\b/, 'PG15: no daticurules, no datlocale';
  my $q16 = $deploy->_locale_catalog_sql(160000);
  like $q16, qr/daticurules/, 'PG16: daticurules';
  unlike $q16, qr/datlocale\b/, 'PG16: no datlocale';
  my $q17 = $deploy->_locale_catalog_sql(170000);
  like $q17, qr/datlocale\b/, 'PG17: datlocale';
  unlike $q17, qr/daticulocale/, 'PG17: no daticulocale (it was renamed)';
}

# --- _create_temp_db sends the statement the catalog row makes ---------------
{
  package T195::Dbh;
  sub new { bless { AutoCommit => 1, pg_server_version => $_[1], log => [] }, $_[0] }
  sub selectrow_hashref { my $s = shift; push @{ $s->{log} }, $_[0];
    return { encoding => 'LATIN1', collate => 'C', ctype => 'C' } }
  sub do { my $s = shift; push @{ $s->{log} }, $_[0]; 1 }
}
{
  my $dbh = T195::Dbh->new(140000);
  my $name = $deploy->_create_temp_db($dbh);
  like $dbh->{log}[0], qr/FROM pg_catalog\.pg_database/, 'the catalog is asked first';
  is $dbh->{log}[1],
    "CREATE DATABASE $name TEMPLATE template0 ENCODING 'LATIN1' LC_COLLATE 'C' LC_CTYPE 'C'",
    '_create_temp_db sends TEMPLATE template0 with the live database\'s encoding';
}

# --- the emptiness check -----------------------------------------------------
my $empty = {
  schemas    => { public => {} },
  extensions => { plpgsql => {} },
  types => {}, tables => {}, sequences => {}, functions => {},
};
is_deeply [ $deploy->_foreign_objects($empty) ], [], 'public and plpgsql only: nothing foreign';

for my $case (
  [ function  => { functions  => { 'public.backdoor()' => {} } }, 'function public.backdoor()' ],
  [ table     => { tables     => { 'public.t' => {} } },          'table public.t' ],
  [ schema    => { schemas    => { public => {}, evil => {} } },  'schema evil' ],
  [ extension => { extensions => { plpgsql => {}, hstore => {} } }, 'extension hstore' ],
  [ type      => { types      => { 'public.mood' => {} } },       'type public.mood' ],
  [ sequence  => { sequences  => { 'public.s' => {} } },          'sequence public.s' ],
) {
  my ($what, $part, $want) = @$case;
  my $model = { %$empty, %$part };
  is_deeply [ $deploy->_foreign_objects($model) ], [ $want ], "a foreign $what is found by name";
}

{
  my $model = { %$empty, tables => { 'public.t' => {} }, functions => { 'public.f()' => {} } };
  is_deeply [ $deploy->_foreign_objects($model) ], [ 'table public.t', 'function public.f()' ],
    'several objects: all are found';
}

# _check_database_empty throws a DBIO::Exception naming them
{
  package T195::Intro;
  sub new { my ($c, %a) = @_; bless { %a }, $c }
  sub model { $T195::model }
  package T195::Deploy;
  our @ISA = ('DBIO::PostgreSQL::Deploy');
  sub _introspect_class { 'T195::Intro' }
}
{
  my $d = T195::Deploy->new(schema => undef);
  local $T195::model = { %$empty, functions => { 'public.backdoor()' => {} }, tables => { 'public.t' => {} } };
  ok !eval { $d->_check_database_empty(undef); 1 }, 'a database with objects: dies';
  isa_ok $@, 'DBIO::Exception';
  like "$@", qr/function public\.backdoor\(\)/, 'the message names the function';
  like "$@", qr/table public\.t/, 'the message names the table';
  local $T195::model = $empty;
  ok eval { $d->_check_database_empty(undef); 1 }, 'an empty database: returns';
}

done_testing;
