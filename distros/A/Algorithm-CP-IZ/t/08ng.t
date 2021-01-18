use strict;
use warnings;

use Test::More tests => 24;
BEGIN { use_ok('Algorithm::CP::IZ') };
BEGIN { use_ok('Algorithm::CP::IZ::NoGoodSet') };

# test NoGoodSet using send more money
SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 9
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    my $s = $iz->create_int(1, 9);
    my $e = $iz->create_int(0, 9);
    my $n = $iz->create_int(0, 9);
    my $d = $iz->create_int(0, 9);
    my $m = $iz->create_int(1, 9);
    my $o = $iz->create_int(0, 9);
    my $r = $iz->create_int(0, 9);
    my $y = $iz->create_int(0, 9);

    $iz->AllNeq([$s, $e, $n, $d, $m, $o, $r, $y]);

    my $v1 = $iz->ScalProd([$s, $e, $n, $d], [1000, 100, 10, 1]);
    my $v2 = $iz->ScalProd([$m, $o, $r, $e], [1000, 100, 10, 1]);
    my $v3 = $iz->ScalProd([$m, $o, $n, $e, $y], [10000, 1000, 100, 10, 1]);
    my $v4 = $iz->Add($v1, $v2);
    $v3->Eq($v4);

    my $func_called = 0;  

    my $vs = $iz->get_value_selector(&Algorithm::CP::IZ::CS_VALUE_SELECTOR_LOWER_AND_UPPER);

    my $array = [$y, $s, $e, $n, $d, $m, $o, $r];
    my @ng_set;

    package TestNG;
    sub new {
	my $class = shift;
	bless {}, $class;
    }   

    sub prefilter {
	my $self = shift;
	my $ngs = shift;
	my $ng = shift;
	my $var_array = shift;
	my $nElem = scalar @$ng;

	push(@ng_set, $ng);

	# don't register this NoGood
	return 0;
    }
    package main;

    my $obj = TestNG->new;
    my $ngs = $iz->create_no_good_set($array,
				      sub { $obj->prefilter(@_); },
				      100, undef);
    my $restart = 0;
    my $rc = $iz->search($array,
			 {
			     ValueSelectors => [map { $vs } 1..8],
			     MaxFailFunc => sub {
				 $func_called++;
				 return ++$restart;
			     },
			     NoGoodSet => $ngs,
			 });

    ok($func_called > 0);
    is($rc, 1);

    ok($iz->get_nb_fails < 10000);
    ok($iz->get_nb_choice_points > 0);

    my $l1 = join(" ", map { $_->value } ($s, $e, $n, $d));
    my $l2 = join(" ", map { $_->value } ($m, $o, $r, $e));
    my $l3 = join(" ", map { $_->value } ($m, $o, $n, $e, $y));

    is($l1, "9 5 6 7");
    is($l2, "1 0 8 5");
    is($l3, "1 0 6 5 2");

    # NoGood is NOT registered
    ok($ngs->nb_no_goods == 0);

    # apply NoGood over current solution must fail
    my $nOk = 0;
    for my $ng (@ng_set) {
	my $label = $iz->save_context;
	my $is_fail;

	for my $nge (@$ng) {
            print "$nge\n";
	    my $v = $array->[$nge->index];
	    if (!$v->select_value($nge->method, $nge->value)) {
		$is_fail = 1;
		last;
	    }
	}
	$iz->restore_context_until($label);
	$nOk++ if ($is_fail);
    }
    is($nOk, scalar(@ng_set));
}

# test NoGoodSet using send more money
SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 10
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    my $s = $iz->create_int(1, 9);
    my $e = $iz->create_int(0, 9);
    my $n = $iz->create_int(0, 9);
    my $d = $iz->create_int(0, 9);
    my $m = $iz->create_int(1, 9);
    my $o = $iz->create_int(0, 9);
    my $r = $iz->create_int(0, 9);
    my $y = $iz->create_int(0, 9);

    $iz->AllNeq([$s, $e, $n, $d, $m, $o, $r, $y]);

    my $v1 = $iz->ScalProd([$s, $e, $n, $d], [1000, 100, 10, 1]);
    my $v2 = $iz->ScalProd([$m, $o, $r, $e], [1000, 100, 10, 1]);
    my $v3 = $iz->ScalProd([$m, $o, $n, $e, $y], [10000, 1000, 100, 10, 1]);
    my $v4 = $iz->Add($v1, $v2);
    $v3->Eq($v4);

    my $func_called = 0;  

    my $vs = $iz->get_value_selector(&Algorithm::CP::IZ::CS_VALUE_SELECTOR_LOWER_AND_UPPER);

    my $array = [$y, $s, $e, $n, $d, $m, $o, $r];
    my @ng_set;

    package TestNG2;
    sub new {
	my $class = shift;
	bless {}, $class;
    }   

    sub prefilter {
	my $self = shift;
	my $ngs = shift;
	my $ng = shift;
	my $var_array = shift;
	my $nElem = scalar @$ng;
	return 1;
    }
    package main;

    my $obj = TestNG2->new;
    my $ngs = $iz->create_no_good_set($array,
				      sub { $obj->prefilter(@_); },
				      100, undef);
    my $restart = 0;
    my $rc = $iz->search($array,
			 {
			     ValueSelectors => [map { $vs } 1..8],
			     MaxFailFunc => sub {
				 $func_called++;
				 return ++$restart;
			     },
			     NoGoodSet => $ngs,
			 });

    ok($func_called > 0);
    is($rc, 1);

    ok($iz->get_nb_fails < 10000);
    ok($iz->get_nb_choice_points > 0);

    my $l1 = join(" ", map { $_->value } ($s, $e, $n, $d));
    my $l2 = join(" ", map { $_->value } ($m, $o, $r, $e));
    my $l3 = join(" ", map { $_->value } ($m, $o, $n, $e, $y));

    is($l1, "9 5 6 7");
    is($l2, "1 0 8 5");
    is($l3, "1 0 6 5 2");

    # NoGood is registered
    ok($ngs->nb_no_goods > 0);
    my $nng = $ngs->nb_no_goods;

    use Data::Dumper;
    $ngs->filter_no_good(sub {
	return 1;
			 }); # use this NG
    is($ngs->nb_no_goods, $nng);

    $ngs->filter_no_good(sub {0}); # don't use this NG
    is($ngs->nb_no_goods, 0);
}

# direct call of NoGoodSet->new
SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 2
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);
     
    eval {
	my $ng = Algorithm::CP::IZ::NoGoodSet->new([]);
	$ng->nb_no_goods;
    };
    ok($@);

    eval {
	my $ng = Algorithm::CP::IZ::NoGoodSet->new([]);
	$ng->filter_no_good(sub {1});
    };
    ok($@);
}

sub ng_leak_test {
    my $iz = Algorithm::CP::IZ->new();

    my $N = 7;
    my @a;
    for (my $i = 0; $i < $N; $i++) {
        push(@a, $iz->create_int(0, $N - 2));
    }
    for (my $i = 0; $i < $N - 1; $i++) {
        for (my $j = $i + 1; $j < $N; $j++) {
            $a[$i]->Neq($a[$j]);
        }
    }

    my $ngs = $iz->create_no_good_set(\@a,
				      sub { 1 },
				      100, undef);
    my $rc = $iz->search(\@a,
			 {
			     MaxFailFunc => sub {
                                 return 1;
			     },
                             MaxFail => 3,
			     NoGoodSet => $ngs,
			 });
    
}

# memory leak
SKIP: {
    eval "use Test::LeakTrace";
    my $leak_test_enabled = !$@;
    skip "Test::LeakTrace is not installed", 1
        unless ($leak_test_enabled);

    eval 'use Test::LeakTrace; no_leaks_ok { ng_leak_test  };';
}
