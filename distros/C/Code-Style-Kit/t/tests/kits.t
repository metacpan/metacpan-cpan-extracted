use Test2::V0;
use lib 't/lib';

my $pkgcounter=0;
sub compile {
    my ($options, $pkg_code) = @_;

    my $pkgname = "TestPkg$pkgcounter"; ++$pkgcounter;

    my $program = "package $pkgname; no strict; no warnings; use TestKit $options; $pkg_code; 1;";
    note $program;
    my $ok = eval $program;

    return ($ok, $@, $pkgname);
}

subtest 'defaults' => sub {
    my ($ok, $exception, $pkgname) = compile('','0+undef');
    ok(!$ok,'using "undef" should be fatal');

    ok(!$pkgname->can('thing'),'TestThing should not be loaded');
    ok(!$pkgname->can('args'),'"args" should not be imported');
    ok(!$pkgname->can('one'),'"one" should not be imported');
    ok(!$pkgname->can('two'),'"two" should not be imported');
};

# TestKit::Parts::Strictures would set 'strict', but TestKit makes it
# optional
subtest 'overidden defaults' => sub {
    my ($ok, $exception, $pkgname) = compile('','$x=1');
    ok($ok,'non-strict code should compile with default options')
        or diag $exception;

    ($ok, $exception, $pkgname) = compile('"strict"','$x=1');
    ok(!$ok,'non-strict code should die with explicit "strict"');
};

subtest 'arguments' => sub {
    my ($ok, $exception, $pkgname) = compile('strict=>[1]','');
    ok(!$ok,'passing arguments to the wrong feature should die');
    like($exception,qr{\Afeature strict does not take arguments\b},
         'and the exception should explain it');

    ($ok, $exception, $pkgname) = compile('args=>[1,2,3]','');
    ok($ok,'passing arguments to the right feature should compile')
        or diag $exception;
    is($pkgname->args,[1,2,3],
       'the arguments should be passed');
};

# explicit feature_*_export has been tested by the above cases
subtest 'list export' => sub {
    my ($ok, $exception, $pkgname) = compile('list','');
    ok($ok,'feature_*_export_list should compile')
        or diag $exception;
    ok($pkgname->can('thing'),'and import the correct module');
    is($pkgname->thing,'thing','and the method should work');
};

subtest 'introspection and conditionals' => sub {
    my ($ok, $exception, $pkgname) = compile('two','');
    ok($ok,'importing other features, and maybe-importing a non-existent one, should compile')
        or diag $exception;
    ok($pkgname->can('two'),'the requested feature should be imported');
    ok($pkgname->can('one'),'the cascaded feature should be imported');
    ok($pkgname->can('args'),'the optional cascaded feature should be imported');
    is($pkgname->two,2,'the requested feature should work');
    is($pkgname->one,1,'the cascaded feature should work');
    is($pkgname->args,[4,5,6],'the optional cascaded feature should get the arguments');

    ($ok, $exception, $pkgname) = compile('qw(two not_two)','');
    ok(!$ok,'importing confilcting features should die');
    like($exception,qr{\bnot two\b},'and the exception should bubble up');
};

done_testing;
