#!perl
# t/009-scope.t: test Data::Hopen::Scope functions not tested elsewhere.
use rlib 'lib';
use HopenTest 'Data::Hopen::Scope::Hash';
use Data::Hopen::Scope ':all';

# --- is_first_only --------------------------------------------------

ok(is_first_only(FIRST_ONLY), 'is_first_only(FIRST_ONLY)');
ok(!is_first_only({}), '!is_first_only({})');
ok(!is_first_only([]), '!is_first_only([])');
ok(!is_first_only(0), '!is_first_only(0)');
ok(!is_first_only(1), '!is_first_only(1)');

# --- _set0 ----------------------------------------------------------

{
    local *dut = \&Data::Hopen::Scope::_set0;
    my $val;

    ok(dut($val), 'set0: undef ok');
    ok(defined($val) && $val == 0, 'set0: undef defaults to 0');

    $val = 0;
    ok(dut($val), 'set0: 0 ok');
    ok(defined($val) && $val == 0, 'set0: 0 defaults to 0');

    $val = Data::Hopen::Scope::FIRST_ONLY;
    ok(dut($val), 'set0: first_only ok');
    ok(defined($val) && $val == 0, 'set0: first_only defaults to 0');

    $val = 'oops';
    ok(!dut($val), 'set0: "oops" not ok');
    ok(defined($val) && $val eq 'oops', 'set0: "oops" unchanged');

    $val = 1;
    ok(!dut($val), 'set0: 1 not ok');
    ok(defined($val) && $val == 1, 'set0: 1 unchanged');

}

done_testing;
