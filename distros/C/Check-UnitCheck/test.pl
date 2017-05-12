# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

# DIFFERENT PERL VERSIONS HEAD HURTY GAH 

#########################
# change 'tests => 1' to 'tests => last_test_to_print';

# in perls without UNITCHECK we'll run last
my $plan;
BEGIN {
    $plan = 4;
    if ($] < 5.009005) {
	eval 'sub UNITCHECK (&) {&{$_[0]}}';
	$plan = 1;
    }
}

use Test;
BEGIN { plan tests => $plan };
my @order;
sub add {
    push @order, $_[0];
}

UNITCHECK {add("UC1")};
CHECK {add("c1")}

use Check::UnitCheck sub {add("uc1")};
use Check::UnitCheck sub {add("uc2")};

UNITCHECK {add("UC2")};
CHECK {add("c2")}

if ($] < 5.009005) {
    ok(join(":", @order), "c2:uc2:uc1:c1:UC1:UC2", "pre UNITCHECK ok");
}
else {
    ok(join(":", @order), "UC2:uc2:uc1:UC1:c2:c1", "has UNITCHECK ok");

    my $foo;
    eval 'use Check::UnitCheck sub {$foo = "haddock"};';
    ok($foo, "haddock");
    my($b4, $af);
    eval 'sub bar {return "z"};BEGIN {$b4 = bar(); Check::UnitCheck::unitcheckify(sub {*bar = sub {return "brunt"}})}; $af = bar()';
    die $@ if $@;
    ok($b4, "z");
    ok($af, "brunt");
}

