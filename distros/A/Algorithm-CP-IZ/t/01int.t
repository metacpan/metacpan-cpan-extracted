use strict;
use warnings;

use Test::More tests => 77;
BEGIN { use_ok('Algorithm::CP::IZ') };

# create(min, max)
my $iz = Algorithm::CP::IZ->new();
my $v = $iz->create_int(0, 10);

# nb_elements
is($v->nb_elements, 11);

# domain
{
  my $dom = $v->domain;
  is(@$dom, 11);
  for my $i (0..9) {
    is($dom->[$i], $i);
  }
}

my $vdom = $iz->create_int([2, 4, 6, 8, 10], "vdom");
is(join(",", @{$vdom->domain}), "2,4,6,8,10");

my $cvar1 = $iz->create_int(33);
is($cvar1->value, 33);
my $cvar2 = $iz->create_int(33);
is($cvar2->value, 33);
is("$cvar1", "33");
is("$vdom", "vdom: {2, 4, 6, 8, 10}");
is("$v", "{0..10}");
{
    $iz->save_context;
    $v->Neq(5);
    is("$v", "{0..4, 6..10}");
    $iz->restore_context;
}

{
  is($cvar1->key, $cvar1->key);
  is($v->key, $v->key);
  is($vdom->key, $vdom->key);
  ok($cvar1->key ne $v->key);
  ok($cvar1->key ne $vdom->key);
  ok($v->key ne $vdom->key);
}

is($vdom->get_next_value(4), 6);
is($vdom->get_previous_value(10), 8);

is($vdom->is_in(8), 1);
is($vdom->is_in(7), 0);

# Neq
{
  $iz->save_context;

  is($v->Neq(5), 1);
  is(join(",", @{$v->domain}), "0,1,2,3,4,6,7,8,9,10");
  $iz->restore_context;

  my $v2 = $iz->create_int(0, 0);

  $iz->save_context;

  is($v->Neq($v2), 1);
  is(join(",", @{$v->domain}), "1,2,3,4,5,6,7,8,9,10");
  $iz->restore_context;

  $iz->save_context;

  is ($v2->Neq(0), 0);
  $iz->restore_context;
}

# Le
{
  $iz->save_context;
  is($v->Le(5), 1);
  is(join(",", @{$v->domain}), "0,1,2,3,4,5");
  $iz->restore_context;

  my $v2 = $iz->create_int(8, 8);

  $iz->save_context;
  is($v->Le($v2), 1);
  is(join(",", @{$v->domain}), "0,1,2,3,4,5,6,7,8");
  $iz->restore_context;

  $iz->save_context;
  is($v->Le(-1), 0);
  $iz->restore_context;
}

# Lt
{
  $iz->save_context;
  is($v->Lt(5), 1);
  is(join(",", @{$v->domain}), "0,1,2,3,4");
  $iz->restore_context;

  my $v2 = $iz->create_int(8, 8);

  $iz->save_context;
  is($v->Lt($v2), 1);
  is(join(",", @{$v->domain}), "0,1,2,3,4,5,6,7");
  $iz->restore_context;

  $iz->save_context;
  is($v->Lt(0), 0);
  $iz->restore_context;
}

# Ge
{
  $iz->save_context;
  is($v->Ge(5), 1);
  is(join(",", @{$v->domain}), "5,6,7,8,9,10");
  $iz->restore_context;

  my $v2 = $iz->create_int(8, 8);

  $iz->save_context;
  is($v->Ge($v2), 1);
  is(join(",", @{$v->domain}), "8,9,10");
  $iz->restore_context;

  $iz->save_context;
  is($v->Ge(11), 0);
  $iz->restore_context;
}

# Gt
{
  $iz->save_context;
  is($v->Gt(5), 1);
  is(join(",", @{$v->domain}), "6,7,8,9,10");
  $iz->restore_context;

  my $v2 = $iz->create_int(8, 8);

  $iz->save_context;
  is($v->Gt($v2), 1);
  is(join(",", @{$v->domain}), "9,10");
  $iz->restore_context;

  $iz->save_context;
  is($v->Gt(10), 0);
  $iz->restore_context;
}

# InArray
{
  $iz->save_context;

  is($v->InArray([2, 3]), 1);
  is(join(",", @{$v->domain}), "2,3");

  is($v->InArray([100,200]), 0);

  $iz->restore_context;
}

# InArray
{
  $iz->save_context;

  is($v->NotInArray([2, 5]), 1);
  is(join(",", @{$v->domain}), "0,1,3,4,6,7,8,9,10");

  is($v->NotInArray([0..10]), 0);

  $iz->restore_context;
}

# InInterval
{
  $iz->save_context;

  is($v->InInterval(5, 8), 1);
  is(join(",", @{$v->domain}), "5,6,7,8");

  is($v->InInterval(100, 200), 0);

  $iz->restore_context;
}

# NotInInterval
{
  $iz->save_context;

  is($v->NotInInterval(5, 8), 1);
  is(join(",", @{$v->domain}), "0,1,2,3,4,9,10");

  is($v->NotInInterval(0, 200), 0);

  $iz->restore_context;
}

# error
{
    my $err = 1;
    eval {
	my $i = $iz->create_int("a");
	$err = 0;
    };
    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

# error
{
    my $err = 1;
    eval {
	my $i = $iz->create_int([]);
	$err = 0;
    };
    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

    # zero value is bad, but one value is good.
    my $i = $iz->create_int([3]);
    is("$i", "3");
}

SKIP: {
    skip "old iZ", 4
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    my $v = $iz->create_int(0, 10);
    ok($v->select_value(&Algorithm::CP::IZ::CS_VALUE_SELECTION_GE, 4));
    is($v->min, 4);
    is($v->max, 10);

    ok(!$v->select_value(&Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ, 1));
}

# memory leak
SKIP: {
    eval "use Test::LeakTrace";
    my $leak_test_enabled = !$@;
    skip "Test::LeakTrace is not installed", 1
        unless ($leak_test_enabled);

    my $v = $iz->create_int(0, 1);

    eval 'use Test::LeakTrace; no_leaks_ok { my $d = $v->domain;  };';
}
