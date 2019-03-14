use warnings FATAL => 'all';
use strict;
use Test::More;

sub do_test($$$) {
    my $expected = shift;
    my $result = shift;
    my $test_name = shift;
    if ($result =~ $expected) {
        pass $test_name;
    }
    else {
        fail $test_name;
        print STDERR "Got:\n$result";
    }
}

sub do_pass($$) {
    do_test(qr/Result: PASS/s, shift, shift);
}
sub do_fail($$) {
    do_test(qr/Result: FAIL/s, shift, shift);
}

my $basic_command = 'prove -PPassEnv -Q testData/target.t';

$ENV{PROVE_PASS_PASSED_VAR} = 'testVar';
do_pass(`$basic_command`, 'Pass env variable');
delete $ENV{PROVE_PASS_PASSED_VAR};

$ENV{PROVE_PASS_PASSED_VAR} = 'testVar1';
do_fail(`$basic_command`, 'Pass wrong env variable value');
delete $ENV{PROVE_PASS_PASSED_VAR};

$ENV{PASSED_VAR} = 'testVar';
do_pass(`$basic_command`, 'Pass with env variable directly');
delete $ENV{PASSED_VAR};

SKIP:{
    skip "Skipping on Windows system", 3 if $^O eq 'MsWin32';
    do_pass(`env PROVE_PASS_PASSED_VAR=testVar $basic_command`, 'Pass env variable with env');
    do_pass(`env PASSED_VAR=testVar $basic_command`, 'Pass env variable directly with env');
    do_fail(`env PROVE_PASS_PASSED_VAR=wrongVal $basic_command`, 'Pass wrong env variable with env');
}


done_testing;