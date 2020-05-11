#!perl
# t/011-scope-env.t: test Data::Hopen::Scope::Environment
use rlib 'lib';
use HopenTest;
use Data::Hopen::Scope;
use Data::Hopen::Scope::Hash;
use Test::Fatal;

$Data::Hopen::VERBOSE=@ARGV;
    # say `perl -Ilib t/011-scope-env.t -- foo` to turn on verbose output

use Data::Hopen::Scope::Environment;

my $s = Data::Hopen::Scope::Environment->new();
isa_ok($s, 'Data::Hopen::Scope::Environment');
ok($s->DOES('Data::Hopen::Scope'), 'Scope::Environment DOES Scope');

$s->put(foo_hopen => 42);
cmp_ok($ENV{foo_hopen}, '==', 42, 'put() updates %ENV');
cmp_ok($s->find('foo_hopen'), '==', 42, 'Retrieving previously-set variable works');
cmp_ok($s->find('foo_hopen', -set => 0), '==', 42, 'Retrieving previously-set variable works (set 0)');
cmp_ok($s->find('foo_hopen', -set => FIRST_ONLY), '==', 42, 'Retrieving previously-set variable works (set FIRST_ONLY)');
is_deeply($s->find('foo_hopen', -set => '*'), {0=>42}, 'Retrieving previously-set variable works (set *)');

foreach my $varname (qw(SHELL COMSPEC PATH)) {
    is($s->find($varname), $ENV{$varname}, "Finds existing env var $varname")
        if exists $ENV{$varname};
}

# Some constants for variable names
our ($varname_inner, $varname_outer, $varname_env);
local *varname_inner = \'+;!@#$%^&*() Some crazy variable name that is not a valid env var name';
local *varname_outer = \'+;!@#$%^&*() Another crazy variable name that is not a valid env var name';
local *varname_env = \'__ENV_VAR_FOR_TESTING_HOPEN_';
    # On Win32, ENV variable names are all uppercase.

my $inner = Data::Hopen::Scope::Hash->new()->put($varname_inner => 42);
my $outer = Data::Hopen::Scope::Hash->new()->put($varname_outer => 1337);

$inner->outer($s);
$s->outer($outer);

cmp_ok($inner->find($varname_outer), '==', 1337, 'find() through intervening Scope::Environment works');
cmp_ok($s->find($varname_outer), '==', 1337, 'find() from Scope::Environment to outer works');

$ENV{$varname_env} = 'C=128';
#diag "New environment var $varname_env is $ENV{$varname_env} (should be 'C=128')";

ok(!$outer->names->has($varname_env),'$ENV{}-set var is not in scope in outer');

ok($s->names->has($varname_env), '$ENV{}-set var is in scope');
ok($inner->names->has($varname_env), '$ENV{}-set var is in scope starting from inner');
is($inner->find($varname_env), 'C=128', 'find() from inner up to Scope::Environment works');

# Misc.
ok(!defined exception { $s->put; }, 'empty put() allowed');
like(exception { $s->put('oops'); }, qr/odd number/, 'put() rejects odd number of params');

done_testing();
# vi: set fenc=utf8:
