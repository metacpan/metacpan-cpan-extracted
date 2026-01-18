use strict;
use warnings;
use Test::More 0.98;

use App::Greple::tee::Autoload qw(resolve);

# Test resolve with built-in function
my $code = resolve('CORE::length');
is ref($code), 'CODE', 'resolve returns CODE ref for CORE::length';

# Test resolve with a function in main
sub test_func { return 42 }
$code = resolve('main::test_func');
is ref($code), 'CODE', 'resolve returns CODE ref for main::test_func';
is $code->(), 42, 'resolved function works correctly';

# Test resolve dies on undefined function
eval { resolve('No::Such::Module::no_such_func') };
like $@, qr/Undefined function|Can't locate/, 'resolve dies on undefined function';

# Test alias resolution (without actually loading modules)
# Just verify the aliases are defined by checking they don't die immediately
# when the module loading fails (they should try to load the module)
for my $alias (qw(ansicolumn ansifold cat-v)) {
    eval { resolve($alias) };
    # Should either succeed or fail with module load error, not "Undefined function"
    unlike $@, qr/^Undefined function: \Q$alias\E/,
        "alias '$alias' is recognized (may fail on module load)";
}

# Test actual function resolution if modules are installed
SKIP: {
    eval { require App::ansifold };
    skip "App::ansifold not installed", 2 if $@;

    my $code = resolve('ansifold');
    is ref($code), 'CODE', 'resolve ansifold returns CODE ref';
    is $code, \&App::ansifold::ansifold, 'ansifold resolves to correct function';
}

SKIP: {
    eval { require App::ansicolumn };
    skip "App::ansicolumn not installed", 2 if $@;

    my $code = resolve('ansicolumn');
    is ref($code), 'CODE', 'resolve ansicolumn returns CODE ref';
    is $code, \&App::ansicolumn::ansicolumn, 'ansicolumn resolves to correct function';
}

SKIP: {
    eval { require App::cat::v };
    skip "App::cat::v not installed", 1 if $@;

    my $code = resolve('cat-v');
    is ref($code), 'CODE', 'resolve cat-v returns CODE ref';
}

# Test function execution via Command::Run (as tee does)
SKIP: {
    eval { require Command::Run };
    skip "Command::Run not installed", 3 if $@;
    eval { require App::ansifold };
    skip "App::ansifold not installed", 3 if $@;

    my $code = resolve('ansifold');
    my $input = "foo bar\n";
    my $run = Command::Run->new;
    my $out = $run->command($code, '-w', '4')->with(stdin => $input)->update->data;
    like $out, qr/foo/, 'ansifold via Command::Run produces output';
    like $out, qr/bar/, 'ansifold output contains wrapped text';
    like $out, qr/\n.*\n/, 'ansifold wrapped to multiple lines';
}

done_testing;
