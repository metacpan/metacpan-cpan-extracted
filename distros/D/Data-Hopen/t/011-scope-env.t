#!perl
# t/011-scope-env.t: test Data::Hopen::Scope::Environment
use rlib 'lib';
use HopenTest;
use Data::Hopen::Scope::Hash;

$Data::Hopen::VERBOSE=@ARGV;
    # say `perl -Ilib t/011-scope-env.t -- foo` to turn on verbose output

use Data::Hopen::Scope::Environment;

my $s = Data::Hopen::Scope::Environment->new();
isa_ok($s, 'Data::Hopen::Scope::Environment');
ok($s->DOES('Data::Hopen::Scope'), 'Scope::Environment DOES Scope');

$s->add(foo_hopen => 42);
cmp_ok($ENV{foo_hopen}, '==', 42, 'add() updates %ENV');
cmp_ok($s->find('foo_hopen'), '==', 42, 'Retrieving previously-set variable works');

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

my $inner = Data::Hopen::Scope::Hash->new()->add($varname_inner => 42);
my $outer = Data::Hopen::Scope::Hash->new()->add($varname_outer => 1337);

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

done_testing();
# vi: set fenc=utf8:
