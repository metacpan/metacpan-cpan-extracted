#!perl

use lib qw(t/lib);

use MyDSLWithEval;

my $dsl = MyDSLWithEval->new();

my $code = <<'EOT';
use Test::More;
use Test::Deep;
# peek under the covers, get instance
my $dsl = break_encapsulation;
isa_ok( $dsl, 'MyDSL' );

# check the call_log and a simple invocation of main
cmp_deeply( $dsl->call_log, [], 'call log starts off empty' );
main;
cmp_deeply( $dsl->call_log, [qw(main)], 'logged call to main' );

# check that clearing call_log works.
clear_call_log;
cmp_deeply( $dsl->call_log, [], 'clear_call_log works' );

# test that curry_chain works
is( test_curry_chain, 'beep beep', 'curried chain says beep beep' );
is( test_curry_chain_with_arg, 'Andele!', 'curried chain with arg says andele' );

# a single before action
test_simple_before;
cmp_deeply( $dsl->call_log, [qw(before_1 main)], 'simple before works' );
clear_call_log;

# multiple before actions
test_multi_before;
cmp_deeply(
    $dsl->call_log,
    [qw(before_1 before_2 main)],
    'multi before works'
);
clear_call_log;

# a single after action
test_simple_after;
cmp_deeply( $dsl->call_log, [qw(main after_1)], 'simple after works' );
clear_call_log;

# multiple after actions
test_multi_after;
cmp_deeply( $dsl->call_log, [qw(main after_1 after_2)], 'multi after works' );
clear_call_log;

# something for everyone
test_complex;
cmp_deeply(
    $dsl->call_log,
    [qw(before_1 before_2 main after_1 after_2)],
    'multi after works'
);
clear_call_log;

## test context handling

# void context
my_context;
cmp_deeply( $dsl->call_log, [qw(void_context)], 'void context works' );
clear_call_log;

# scalar context
my $dummy = my_context;
cmp_deeply( $dsl->call_log, [qw(scalar_context)], 'scalar context works' );
clear_call_log;

# array context
my @dummy = my_context;
cmp_deeply( $dsl->call_log, [qw(array_context)], 'array context works' );
clear_call_log;

# push a bunch of stuff onto the call_log and use it to test
# context handling again, differently
test_complex;
my $count       = scalar call_log_as_array;
my @log_entries = call_log_as_array;
is( $count, 5, "fancier context test, scalar version" );
cmp_deeply(
    \@log_entries,
    [qw(before_1 before_2 main after_1 after_2)],
    'fancier context test, array version'
);
clear_call_log;

# test argument handling, single scalar
argulator("a scalar");
cmp_deeply( $dsl->call_log, ['a scalar'], 'scalar arg works' );
clear_call_log;

# test argument handling, list of args
argulator(qw(a list of things));
cmp_deeply( $dsl->call_log, ['a::list::of::things'], 'list arg works' );
clear_call_log;

# test alternate currier
test_alternate_currier;
cmp_deeply(
    $dsl->trace_log,
    ['tracing call to main()'],
    'tracing currier works'
);
clear_trace_log;

# test alternate currier with some args
test_alternate_currier(qw(fee fi fo));
cmp_deeply(
    $dsl->trace_log,
    ['tracing call to main(fee, fi, fo)'],
    'tracing currier works with args'
);
clear_trace_log;

is(naked, "buck", 'naked generator works');
is(bare, "buck", 'naked generator w/ rename works');

done_testing
EOT

$dsl->instance_eval($code);
