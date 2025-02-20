use strict;
use warnings;

use Test::More tests => 122;
BEGIN { use_ok('Algorithm::CP::IZ') };

{
    my $iz = Algorithm::CP::IZ->new();
    my $v = $iz->create_int(0, 10);
    $iz->search([$v]);

    is($v->min, 0);
    is($v->max, 0);
    is($v->value, 0);
    is($v->nb_elements, 1);
}

# default search
{
    my $iz = Algorithm::CP::IZ->new();

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    $iz->AllNeq([$v1, $v2]);
    my $rc = $iz->search([$v1, $v2]);

    is($rc, 1);
    is($v1->value, 0);
    is($v2->value, 1);
}

# search error
{
    my $iz = Algorithm::CP::IZ->new();
    my $err = 1;
    eval {
	my $rc = $iz->search(["x"]);
	$err = 0;
    };

    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

    eval {
	my $rc = $iz->search([undef]);
	$err = 0;
    };

    $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

# default search (use Default)
{
    use Algorithm::CP::IZ::FindFreeVar;
    my $iz = Algorithm::CP::IZ->new();

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    $iz->AllNeq([$v1, $v2]);
    my $rc = $iz->search([$v1, $v2],
			 { FindFreeVar => Algorithm::CP::IZ::FindFreeVar::Default, }
			);

    is($rc, 1);
    is($v1->value, 0);
    is($v2->value, 1);
}

# default search (using NbElements)
{
    use Algorithm::CP::IZ::FindFreeVar;
    my $iz = Algorithm::CP::IZ->new();

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 5);
    $iz->AllNeq([$v1, $v2]);
    my $rc = $iz->search([$v1, $v2],
			 { FindFreeVar
			   => Algorithm::CP::IZ::FindFreeVar::NbElements, }
			);

    is($rc, 1);

    # v2 must be found first.
    is($v1->value, 1);
    is($v2->value, 0);
}

# search eror (FindFreeVar)
{
    use Algorithm::CP::IZ::FindFreeVar;
    my $iz = Algorithm::CP::IZ->new();

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 5);
    $iz->AllNeq([$v1, $v2]);

    my $err = 1;
    eval {
	my $rc = $iz->search([$v1, $v2],
			     { FindFreeVar
				   => "x", }
	    );
	$err = 0;
    };

    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

# search with FindFreeVar
{
    my $iz = Algorithm::CP::IZ->new();

    my $func_used = 0;

    my $func = sub {
	my $array = shift;
	my $n = scalar @$array;

	for my $i (0..$n-1) {
	    return $i if ($array->[$i]->is_free);
	}

	$func_used = 1;

	return -1;
    };

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    $iz->AllNeq([$v1, $v2]);
    my $rc = $iz->search([$v1, $v2],
			 { FindFreeVar => $func, }
			);

    is($func_used, 1);
    is($rc, 1);
    is($v1->value, 0);
    is($v2->value, 1);
}

# test MaxFail uinsg send more money
{
  my $iz = Algorithm::CP::IZ->new();
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

  $iz->save_context;
  my $rc1 = $iz->search([$s, $e, $n, $d, $m, $o, $r, $y],
			{ MaxFail => 1});


  # 1 or 2?
  ok($iz->get_nb_fails >= 1 && $iz->get_nb_fails < 3);

  is($rc1, 0);

  $iz->restore_context;

  my $rc = $iz->search([$s, $e, $n, $d, $m, $o, $r, $y],
		      { MaxFail => 10000});
  is($rc, 1);

  ok($iz->get_nb_fails < 10000);
  ok($iz->get_nb_choice_points > 0);
}

# search with Criteria
{
    my $iz = Algorithm::CP::IZ->new();

    my $func_used = 0;

    my $func = sub {
      my ($index, $val) = @_;
      $func_used = 1;
      if ($index == 0) {
	return $val ==4 ? 0 : 100;
      }
      if ($index == 1) {
	return $val ==5 ? 0 : 100;
      }
      return 0;
    };

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    $iz->AllNeq([$v1, $v2]);
    my $rc = $iz->search([$v1, $v2],
			 { Criteria => $func, }
			);

    is($rc, 1);
    is($func_used, 1);
    is($v1->value, 4);
    is($v2->value, 5);
}

# search eror (Criteria)
{
    use Algorithm::CP::IZ::FindFreeVar;
    my $iz = Algorithm::CP::IZ->new();

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 5);
    $iz->AllNeq([$v1, $v2]);

    my $err = 1;
    eval {
	my $rc = $iz->search([$v1, $v2],
			     { Criteria
				   => "x", }
	    );
	$err = 0;
    };

    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

# search (ValueSelectors, basic)
SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 6
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 5);
    $iz->AllNeq([$v1, $v2]);

    my $vs = $iz->get_value_selector(&Algorithm::CP::IZ::CS_VALUE_SELECTOR_MIN_TO_MAX);

    my $label = $iz->save_context();
    my $rc = $iz->search([$v1, $v2],
			 { ValueSelectors
			       => [$vs, $vs], }
	);

    is($rc, 1);
    is($v1->value, 0);
    is($v2->value, 1);

    $iz->restore_context_until($label);
    $vs = $iz->get_value_selector(&Algorithm::CP::IZ::CS_VALUE_SELECTOR_MAX_TO_MIN);
    $rc = $iz->search([$v1, $v2],
		      { ValueSelectors => [$vs, $vs], }
	);

    is($rc, 1);
    is($v1->value, 10);
    is($v2->value, 5);
}

# test MaxFail uinsg send more money
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

    my $vs = $iz->get_value_selector(&Algorithm::CP::IZ::CS_VALUE_SELECTOR_MIN_TO_MAX);

    my $restart = 0;

    # cannot solve by MaxFail
    $iz->save_context;
    my $rc1 = $iz->search([$s, $e, $n, $d, $m, $o, $r, $y],
			  {
			      ValueSelectors =>
				  [map { $vs } 1..8],
				  MaxFail => 1,
				  MaxFailFunc => sub {
				      $func_called++;
				      return ++$restart;
			      },
			  });
    is($rc1, 0);
    $iz->restore_context;

    # cannot solve by MaxFailFunc
    $iz->save_context;
    my $rc2 = $iz->search([$s, $e, $n, $d, $m, $o, $r, $y],
			  {
			      ValueSelectors =>
				  [map { $vs } 1..8],
				  MaxFail => 100,
				  MaxFailFunc => sub {
				      $func_called++;
				      return 1; # always 1
			      }
			  });
    is($rc2, 0);
    $iz->restore_context;

    # solved
    $restart = 0;
    my $rc = $iz->search([$s, $e, $n, $d, $m, $o, $r, $y],
			 {
			     ValueSelectors =>
				 [map { $vs } 1..8],
				 MaxFailFunc => sub {
				     $func_called++;
				     return ++$restart;
			     }
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
}

# test NoGoodSet uinsg send more money
SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 8
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

    my $vs = $iz->get_value_selector(&Algorithm::CP::IZ::CS_VALUE_SELECTOR_MIN_TO_MAX);

    my $array = [$s, $e, $n, $d, $m, $o, $r, $y];
    my $ngs = $iz->create_no_good_set($array, undef, 100, undef);
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

    ok($ngs->nb_no_goods > 0);
}

# find_all
{
    my $iz = Algorithm::CP::IZ->new();

    my $v1 = $iz->create_int(1, 3);
    my $v2 = $iz->create_int(1, 3);
    $iz->AllNeq([$v1, $v2]);

    my @r;
    my $callback = sub {
      my $var_array = shift;
      push(@r, [map { $_->value } @$var_array]);
    };

    my $rc = $iz->find_all([$v1, $v2], $callback);

    is($rc, 1);
    is_deeply($r[0], [1, 2]);
    is_deeply($r[1], [1, 3]);
    is_deeply($r[2], [2, 1]);
    is_deeply($r[3], [2, 3]);
    is_deeply($r[4], [3, 1]);
    is_deeply($r[5], [3, 2]);
}

# find_all using (using NbElements)
{
    my $iz = Algorithm::CP::IZ->new();

    my $v1 = $iz->create_int(1, 3);
    my $v2 = $iz->create_int(1, 2);
    $iz->AllNeq([$v1, $v2]);

    my @r;
    my $callback = sub {
      my $var_array = shift;
      push(@r, [map { $_->value } @$var_array]);
    };

    my $rc = $iz->find_all([$v1, $v2], $callback,
			   { FindFreeVar
			    => Algorithm::CP::IZ::FindFreeVar::NbElements, });

    is($rc, 1);
    is_deeply($r[0], [2, 1]);
    is_deeply($r[1], [3, 1]);
    is_deeply($r[2], [1, 2]);
    is_deeply($r[3], [3, 2]);
}

# find_all using (using NbElements)
{
    my $iz = Algorithm::CP::IZ->new();

    my $v1 = $iz->create_int(1, 3);
    my $v2 = $iz->create_int(1, 2);
    $iz->AllNeq([$v1, $v2]);

    my $func_used = 0;

    my $func = sub {
	my $array = shift;
	my $n = scalar @$array;

	for my $i (0..$n-1) {
	    return $i if ($array->[$i]->is_free);
	}

	$func_used = 1;

	return -1;
    };

    my @r;
    my $callback = sub {
      my $var_array = shift;
      push(@r, [map { $_->value } @$var_array]);
    };

    my $rc = $iz->find_all([$v1, $v2], $callback,
			   { FindFreeVar => $func });

    is($rc, 1);
    is($func_used, 1);
    is_deeply($r[0], [1, 2]);
    is_deeply($r[1], [2, 1]);
    is_deeply($r[2], [3, 1]);
    is_deeply($r[3], [3, 2]);
}

# find_all error (callback)
{
    my $iz = Algorithm::CP::IZ->new();

    my $v1 = $iz->create_int(1, 3);
    my $v2 = $iz->create_int(1, 2);
    my $err = 1;
    eval {
	my $rc = $iz->find_all([$v1, $v2], undef,
			       { FindFreeVar => undef });
    };

    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

# find_all error (FindFreeVar)
{
    my $iz = Algorithm::CP::IZ->new();

    my $v1 = $iz->create_int(1, 3);
    my $v2 = $iz->create_int(1, 2);
    my $err = 1;
    eval {
	my $rc = $iz->find_all([$v1, $v2], sub {},
			       { FindFreeVar => undef });
    };

    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

# backtrack
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(1, 3);
    my $v2 = $iz->create_int(1, 3);
    my $b1called = 0;
    my $b2called = 0;

    my $btvar = undef;
    my $btindex = -999;

    my $b1 = sub {
      my ($v, $i) = @_;
      $b1called = 1;
      $btvar = $v;
      $btindex = $i;
    };

    my $b2 = sub {
      my ($v, $i) = @_;
      $b2called = 1;
      $btvar = $v;
      $btindex = $i;
    };

    $iz->save_context;
    $iz->backtrack($v1, 123, $b1);

    $iz->save_context;
    $iz->backtrack($v2, 456, $b2);


    is($b1called, 0);
    is($b2called, 0);

    $iz->restore_context;
    is($b2called, 1);
    is($v2->key, $btvar->key);
    is($btindex, 456);

    $iz->restore_context;
    is($b1called, 1);
    is($v1->key, $btvar->key);
    is($btindex, 123);
}

# save context
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(1, 3);

    my $label = $iz->save_context;

    $iz->search([$v1]);
    is($v1->nb_elements, 1);

    $iz->restore_context_until($label);
    is($v1->nb_elements, 3);

}

# forget save context
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);

    $iz->save_context(); # restored here
    ok($v1->Ge(1));

    $iz->save_context(); # forgotton
    ok($v1->Ge(2));

    $iz->forget_save_context();
    is($v1->min, 2);

    $iz->restore_context;
    is($v1->min, 0);
}

# forget save context until
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);

    $iz->save_context();
    ok($v1->Ge(1));

    $iz->save_context(); # restore here
    ok($v1->Ge(2));

    my $label = $iz->save_context(); # forgotton
    ok($v1->Ge(3));

    $iz->save_context();
    ok($v1->Ge(4));

    $iz->forget_save_context_until($label);
    is($v1->min, 4);

    $iz->restore_context;
    is($v1->min, 1);
}

# cancel (call only)
SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 1
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    $iz->cancel_search;
    ok(1);
}

# FindFreeVar error
{
    my $iz = Algorithm::CP::IZ->new();

    my $rc = -1234;
    my $v = $iz->create_int(0, 9);
    my $vs = $iz->get_value_selector(&Algorithm::CP::IZ::CS_VALUE_SELECTOR_MIN_TO_MAX);

    my $label = $iz->save_context;

    # nothing returned
    eval {
	$rc = $iz->search([$v],
		      {
			  FindFreeVar => sub {
			      return;
			  },
		      });
    };
    # error
    ok($@);
    is($rc, -1234);

    $iz->restore_context_until($label);
    $label = $iz->save_context;
    
    # bad value
    eval {
	$rc = $iz->search([$v],
		      {
			  FindFreeVar => sub {
			      return "x";
			  },
		      });
    };
    # error
    ok($@);
    is($rc, -1234);

    $iz->restore_context_until($label);
    $label = $iz->save_context;
    
    # out of range
    eval {
	$rc = $iz->search([$v],
		      {
			  FindFreeVar => sub {
			      return 1; # must be 0;
			  },
		      });
    };
    ok($@);
    is($rc, -1234);
}

# Criteria error
{
    my $iz = Algorithm::CP::IZ->new();

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    $iz->AllNeq([$v1, $v2]);

    my $label = $iz->save_context;

    # nothing returned
    my $rc = -1234;

    eval {
	$rc = $iz->search([$v1, $v2],
			  {
			      Criteria => sub {
				  return;
			      },
			  });
    };
    ok($@);
    is($rc, -1234);

    $iz->restore_context_until($label);
    $label = $iz->save_context;

    eval {
	$rc = $iz->search([$v1, $v2],
			  {
			      Criteria => sub {
				  return "x";
			      },
			  });
    };
    ok($@);
    is($rc, -1234);
}

# MaxFailFunc error
SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 1
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    my $rc = -1234;
    my $v = $iz->create_int(0, 9);
    my $vs = $iz->get_value_selector(&Algorithm::CP::IZ::CS_VALUE_SELECTOR_MIN_TO_MAX);

    my $label = $iz->save_context;

    # nothing returned
    eval {
	$rc = $iz->search([$v],
		      {
			  ValueSelectors => [$vs],
			  MaxFailFunc => sub {
			      return;
			  }
		      });
    };
    # error
    ok($@);
    is($rc, -1234);

    $iz->restore_context_until($label);
    $label = $iz->save_context;

    # not a integer
    eval {
	$rc = $iz->search([$v],
		      {
			  ValueSelectors => [$vs],
			  MaxFailFunc => sub {
			      return "x";
			  }
		      });
    };
    # error
    ok($@);
    is($rc, -1234);
}

# MaxFailFunc only
SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 1
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    my $v = $iz->create_int(0, 9);
    my $vs = $iz->get_value_selector(&Algorithm::CP::IZ::CS_VALUE_SELECTOR_MIN_TO_MAX);

    my $rc = $iz->search([$v],
			 {
			     MaxFailFunc => sub {
				 return 1;
			     }
			 });
    is($rc, 1);
    is($v->value, 0);
}

# search with CriteriaEmulation
{
    my $iz = Algorithm::CP::IZ->new();

    my $criteria_used = 0;
    my $max_fail_used = 0;

    my $func = sub {
      my ($index, $val) = @_;
      $criteria_used = 1;
      if ($index == 0) {
	return $val ==4 ? 0 : 100;
      }
      if ($index == 1) {
	return $val ==5 ? 0 : 100;
      }
      return 0;
    };

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    $iz->AllNeq([$v1, $v2]);
    my $rc = $iz->search([$v1, $v2],
			 { Criteria => $func,
			   MaxFailFunc => sub {
			       $max_fail_used = 1;
			       return 1;
			   }
			 }
			);

    is($rc, 1);
    is($criteria_used, 1);
    is($max_fail_used, 1);
    is($v1->value, 4);
    is($v2->value, 5);
}
