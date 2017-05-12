use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
use Test::Exception;
use Catalyst::Helper::Model::DBIC::Schema;
use Storable 'dclone';
use Data::Dumper;
use Test::Requires qw(Catalyst::Helper DBIx::Class::Schema::Loader);

my $helper      = Catalyst::Helper->new;
$helper->{base} = $Bin;
my $static      = 'create=static';
my $dynamic     = 'create=dynamic';
my $sqlite      = 'dbi:SQLite:myapp.db';
my $pg          = 'dbi:Pg:dbname=foo';
my $on_connect_do = 'on_connect_do=["select 1", "select 2"]';
my $quote_char  = 'quote_char="';
my $name_sep    = 'name_sep=.';
my $i;

$i = instance(schema_class => 'ASchemaClass');
is $i->old_schema, 1, '->load_classes detected correctly';

throws_ok { $i = instance(args => [$static, 'DbI:SQLite:myapp.db']) }
    qr/case matters/i, "wrong case for 'dbi:' DSN part";

$i = instance(args => ['traits=Caching']);
is_deeply $i->traits, ['Caching'], 'one trait';
is $i->helper->{traits}, "['Caching']", 'one trait as string';

$i = instance(args => ['traits=Caching,Replicated']);
is_deeply $i->traits, ['Caching', 'Replicated'], 'two traits';
is $i->helper->{traits}, "['Caching','Replicated']", 'two traits as string';

$i = instance(args => [$static]);
is $i->create, 'static', 'create=static';

$i = instance(args => [$static,
    q{moniker_map={ authors => "AUTHORS", books => "BOOKS" }}]
);
is_deeply $i->loader_args->{moniker_map},
    { authors => 'AUTHORS', books => 'BOOKS' },
    'loader hash arg';
is $i->helper->{loader_args}{moniker_map},
    q{{authors => "AUTHORS",books => "BOOKS"}},
    'loader hash arg as string';

$i = instance(args => [$static, q{foo=["bar","baz"]}]);
is_deeply $i->loader_args->{foo}, ['bar', 'baz'], 'loader array arg';
is $i->helper->{loader_args}{foo},
    q{["bar","baz"]},
    'loader array arg as string';

$i = instance(args => [$static, q{components=TimeStamp}]);
is_deeply $i->components, ['InflateColumn::DateTime', 'TimeStamp'],
    'extra component';
is $i->helper->{loader_args}{components},
    q{["InflateColumn::DateTime","TimeStamp"]},
    'components as string';

$i = instance(
    schema_class => 'ASchemaClass',
    args => [$static, q{components=TimeStamp}]
);
is_deeply $i->components, ['TimeStamp'],
    'extra component with ->load_classes';

$i = instance(args => [$static, q{components=TimeStamp,Foo}]);
is_deeply $i->components, ['InflateColumn::DateTime', 'TimeStamp', 'Foo'],
    'two extra components';

# Different versions of perl and Data::Dumper serialise regexes differently
my ($flagstart, $flagend, $postflag) = Dumper(qr//) =~ m{qr/(.*?)(\)?)/([a-z]*)};
$i = instance(args => [$static, q{constraint=^(foo|bar)$}]);
is $i->loader_args->{constraint}, qr/^(foo|bar)$/,
    'constraint loader arg';
is $i->helper->{loader_args}{constraint},
    qq{qr/$flagstart^(foo|bar)\$$flagend/$postflag},
    'constraint loader arg as string';

$i = instance(args => [$static, q{exclude=^(foo|bar)$}]);
is $i->loader_args->{exclude}, qr/^(foo|bar)$/,
    'exclude loader arg';

$i = instance(args => [$static, q{db_schema=foo;bar::baz/quux}]);
is $i->loader_args->{db_schema}, q{foo;bar::baz/quux},
    'simple value loader arg';

$i = instance(args => [
    $static, 'components=TimeStamp', $sqlite, $on_connect_do,
    $quote_char, $name_sep
]);

is_deeply $i->components, ['InflateColumn::DateTime', 'TimeStamp'],
    'extra component';

is $i->connect_info->{dsn}, $sqlite, 'connect_info dsn';
is $i->connect_info->{user}, '', 'sqlite omitted user';
is $i->connect_info->{password}, '', 'sqlite omitted password';

is_deeply $i->connect_info->{on_connect_do},
    ['select 1', 'select 2'], 'connect_info data struct';

is $i->helper->{connect_info}{on_connect_do},
    q{["select 1", "select 2"]}, 'connect_info data struct as string';

is $i->connect_info->{quote_char}, '"', 'connect_info quote_char';

is $i->helper->{connect_info}{quote_char}, 'q{"}',
    'connect_info quote_char as string';

is $i->connect_info->{name_sep}, '.', 'connect_info name_sep';

is $i->helper->{connect_info}{name_sep}, 'q{.}',
    'connect_info name_sep as string';

$i = instance(args => [
    $static, $sqlite, 'on_connect_do=PRAGMA foreign_keys = ON'
]);

is $i->connect_info->{on_connect_do},
    'PRAGMA foreign_keys = ON', 'on_connect_do string';

is $i->helper->{connect_info}{on_connect_do},
    'q{PRAGMA foreign_keys = ON}', 'on_connect_do string as string';

$i = instance(args => [
    $static, 'components=TimeStamp', $sqlite, '', $on_connect_do,
    $quote_char, $name_sep
]);

is $i->connect_info->{dsn}, $sqlite, 'connect_info dsn';
is $i->connect_info->{user}, '', 'sqlite user';
is $i->connect_info->{password}, '', 'sqlite omitted password';

$i = instance(args => [
    $static, 'components=TimeStamp', $pg, 'user', 'pass', $on_connect_do,
    $quote_char, $name_sep
]);

is $i->connect_info->{dsn}, $pg, 'connect_info dsn';
is $i->connect_info->{user}, 'user', 'user';
is $i->connect_info->{password}, 'pass', 'password';

$i = instance(args => [
    $static, $pg, 'user', 'pass', 'quote_char=[]', $name_sep
]);

is_deeply $i->connect_info->{quote_char}, ['[', ']'],
    '2 character quote_char';
is $i->helper->{connect_info}{quote_char}, '["[","]"]',
    '2 character quote_char as string';

$i = instance(args => [
    $static, 'components=TimeStamp', $sqlite, $on_connect_do,
    $quote_char, $name_sep, '{ auto_savepoint => 1, AutoCommit => 0 }'
]);

is $i->connect_info->{auto_savepoint}, 1, 'connect_info arg from extra hash';
is $i->connect_info->{AutoCommit}, 0, 'connect_info arg from extra hash';
is $i->helper->{connect_info}{auto_savepoint}, 'q{1}',
    'connect_info arg from extra hash as string';
is $i->helper->{connect_info}{AutoCommit}, 'q{0}',
    'connect_info arg from extra hash as string';

$i = instance(args => [
    $static, 'components=TimeStamp', $sqlite, $on_connect_do,
    $quote_char, $name_sep, 'auto_savepoint=1', 'AutoCommit=0',
    'db_schema=myschema',
]);

is $i->loader_args->{db_schema}, 'myschema',
    'loader arg after connect_info';

ok ((not exists $i->helper->{connect_info}{db_schema}),
    'loader args removed from connect_info');

done_testing;

sub instance {
    Catalyst::Helper::Model::DBIC::Schema->new(
        schema_class => 'AnotherSchemaClass',
        helper => dclone($helper),
        args => ['create=static'],
        @_
    )
}
