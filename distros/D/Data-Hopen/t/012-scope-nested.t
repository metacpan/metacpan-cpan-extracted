#!perl
# t/012-scope-nested.t: test nested Data::Hopen::Scope instances
use rlib 'lib';
use HopenTest;
use Set::Scalar;

use Data::Hopen::Scope::Hash;
use Data::Hopen::Scope::Environment;

sub makeset {
    my $set = Set::Scalar->new;
    $set->insert(@_);
    return $set;
}

# Make scopes

my $innermost = Data::Hopen::Scope::Hash->new();
isa_ok($innermost, 'Data::Hopen::Scope::Hash');
my $middle = Data::Hopen::Scope::Hash->new();
isa_ok($middle, 'Data::Hopen::Scope::Hash');
my $outermost_env = Data::Hopen::Scope::Environment->new();
isa_ok($outermost_env, 'Data::Hopen::Scope::Environment');

$middle->outer($outermost_env);
$innermost->outer($middle);

# Test find()

use constant CRAZY_NAME => "==|>  something wacky  \x{00a2} <|==";
    # equals signs and lowercase => not a valid Windows env var name
    # pipe/gt/lt => not a POSIX env var name you would create without
    #   serious effort
    # U+00A2: not in the POSIX Portable Character Set (references at
    #   https://stackoverflow.com/a/2821183/2877364)

$innermost->add(CRAZY_NAME, 42);
cmp_ok($innermost->find(CRAZY_NAME), '==', 42, 'Retrieving from hash works');

$middle->add(bar => 1337);
cmp_ok($middle->find('bar'), '==', 1337, 'Retrieving from hash works');
cmp_ok($innermost->find('bar'), '==', 1337, 'Retrieving from hash through outer works');
ok(!defined($middle->find(CRAZY_NAME)), "Inner doesn't leak into outer");

my $env_var_name;
foreach my $varname (qw(SHELL COMSPEC PATH)) {
    next unless exists $ENV{$varname};
    $env_var_name = $varname;

    is($innermost->find($varname), $ENV{$varname}, "Finds env var $varname through double chain");
    is($middle->find($varname), $ENV{$varname}, "Finds env var $varname through single chain");
    is($outermost_env->find($varname), $ENV{$varname}, "Finds env var $varname directly");
}

# Test names() with -levels
ok($innermost->names(-levels=>0)->is_equal(makeset(CRAZY_NAME)), 'names, levels=0');
ok($innermost->names(-levels=>1)->is_equal(makeset(CRAZY_NAME, 'bar')), 'names, levels=1');
ok($innermost->names(-levels=>2)->is_equal(makeset(CRAZY_NAME, 'bar', keys %ENV)), 'names, levels=2');
ok($innermost->names(-levels=>1337)->is_equal(makeset(CRAZY_NAME, 'bar', keys %ENV)), 'names, levels=1337');

# Test find() with -levels
cmp_ok($innermost->find(CRAZY_NAME, -levels=>0), '==', 42, 'find, levels=0');
ok(!defined $innermost->find('bar', -levels=>0), 'find, levels=0, does not go up');

cmp_ok($innermost->find(CRAZY_NAME, -levels=>1), '==', 42, 'find at 0, levels=1');
cmp_ok($innermost->find('bar', -levels=>1), '==', 1337, 'find at 1, levels=1');
ok(!defined $innermost->find($env_var_name, -levels=>1), 'find, levels=1, does not go up')
    if $env_var_name;

cmp_ok($innermost->find(CRAZY_NAME, -levels=>2), '==', 42, 'find at 0, levels=2');
cmp_ok($innermost->find('bar', -levels=>2), '==', 1337, 'find at 1, levels=2');

# Test names() with local
$innermost->local(true);
ok($innermost->names(-levels=>'local')->is_equal(makeset(CRAZY_NAME)), 'names, levels=local, innermost local');
$innermost->local(false);

$middle->local(true);
ok($innermost->names(-levels=>'local')->is_equal(makeset(CRAZY_NAME, 'bar')), 'names, levels=local, middle local');
$middle->local(false);

# Test find() with local
$innermost->local(true);
cmp_ok($innermost->find(CRAZY_NAME, -levels=>'local'), '==', 42, 'find at 0, levels=local, innermost local');
ok(!defined $innermost->find('bar', -levels=>'local'), 'find at 1 does not leak, levels=local, innermost local');
ok(!defined $innermost->find($env_var_name, -levels=>'local'), 'find at 2 does not leak, levels=local, innermost local') if $env_var_name;
$innermost->local(false);

$middle->local(true);
cmp_ok($innermost->find(CRAZY_NAME, -levels=>'local'), '==', 42, 'names, levels=local, middle local');
ok(!defined $innermost->find($env_var_name, -levels=>'local'), 'find at 2 does not leak, levels=local, middle local') if $env_var_name;
$middle->local(false);

done_testing();
# vi: set fenc=utf8:
