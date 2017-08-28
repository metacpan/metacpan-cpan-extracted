use strict;
use warnings;

use Test::More tests => 55;
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

{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(1, 3);

    my $label = $iz->save_context;

    $iz->search([$v1]);
    is($v1->nb_elements, 1);

    $iz->restore_context_until($label);
    is($v1->nb_elements, 3);

}
