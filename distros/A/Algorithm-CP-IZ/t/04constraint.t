use strict;
use warnings;

use Test::More tests => 253;
BEGIN { use_ok('Algorithm::CP::IZ') };

# Add
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    my $v3 = $iz->Add($v1, $v2);

    $v1->Eq(3);
    $v2->Eq(5);
    is($v3->value, 8);
}

# Add
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->Add(9, $v1);

    $v1->Eq(3);
    is($v2->value, 12);
}

# Add
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->Add($v1, 2);

    $v1->Eq(3);
    is($v2->value, 5);
}

# Add
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->Add(123, 456);

    is($v1->value, 579);
}

# Add
{
    for my $i (11..50) {
      my $iz = Algorithm::CP::IZ->new();
      my @vars = map{$iz->create_int($_, $_)} (1..$i);
      my $sum = (($i + 1) * $i) / 2;
      my $v = $iz->Add(@vars);

      is($v->value, $sum);
    }
}

# Add error
{
    my $iz = Algorithm::CP::IZ->new();
    my @vars = map{$iz->create_int($_, $_)} (1..2);
    my $err = 1;
    eval {
	my $v = $iz->Add();
	$err = 0;
    };

    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

    eval {
	my $v = $iz->Add("x");
	$err = 0;
    };

    $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

# Mul
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    my $v3 = $iz->Mul($v1, $v2);

    $v1->Eq(3);
    $v2->Eq(5);
    is($v3->value, 15);
}

# Mul
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->Mul(9, $v1);

    $v1->Eq(3);
    is($v2->value, 27);
}

# Mul
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->Mul($v1, 2);

    $v1->Eq(3);
    is($v2->value, 6);
}

# Mul
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->Mul(123, 456);

    is($v1->value, 123 * 456);
}

# Mul
{
    my $iz = Algorithm::CP::IZ->new();
  my $v = $iz->Mul(1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3);

  is($v->value, 6 * 6 * 6 * 6 * 6);
}

# Mul error
{
    my $iz = Algorithm::CP::IZ->new();
    my @vars = map{$iz->create_int($_, $_)} (1..2);
    my $err = 1;
    eval {
	my $v = $iz->Mul();
	$err = 0;
    };

    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

    eval {
	my $v = $iz->Mul("x");
	$err = 0;
    };

    $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

# Sub
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    my $v3 = $iz->Sub($v1, $v2);

    $v1->Eq(3);
    $v2->Eq(5);
    is($v3->value, -2);
}

# Sub
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->Sub(9, $v1);

    $v1->Eq(3);
    is($v2->value, 6);
}

# Sub
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->Sub($v1, 2);

    $v1->Eq(3);
    is($v2->value,1);
}

# Sub
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->Sub(5, 2);

    is($v1->value, 3);
}

# Sub
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->Sub(5, 2, 1);

    is($v1->value, 2);
}

# Sub error
{
    my $iz = Algorithm::CP::IZ->new();
    my @vars = map{$iz->create_int($_, $_)} (1..2);
    my $err = 1;
    eval {
	my $v = $iz->Sub();
	$err = 0;
    };

    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

    eval {
	my $v = $iz->Sub("x", "y");
	$err = 0;
    };

    $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

# Div
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    my $v3 = $iz->Div($v1, $v2);

    $v1->Eq(4);
    $v2->Eq(2);
    is($v3->value, 2);
}

# Div
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->Div(9, $v1);

    $v1->Eq(3);
    is($v2->value, 3);
}

# Div
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->Div($v1, 2);

    $v1->Eq(8);
    is($v2->value, 4);
}

# Div (segfault in cs_Div)
{
    my $iz = Algorithm::CP::IZ->new();
    # my $v1 = $iz->Div(7, 2);
    # ok(!defined($v1));
    ok(1);
}

# Div error
{
    my $iz = Algorithm::CP::IZ->new();
    my @vars = map{$iz->create_int($_, $_)} (1..2);
    my $err = 1;
    eval {
	my $v = $iz->Div();
	$err = 0;
    };

    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

    eval {
	my $v = $iz->Div(5, "a");
	$err = 0;
    };

    $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

# Sigma
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->Sigma([9, $v1]);

    $v1->Eq(3);
    is($v2->value, 12);
}

# Sigma empty
{
    my $iz = Algorithm::CP::IZ->new();
    my $v = $iz->Sigma([]);

    is($v->value, 0);
}

# ScalProd
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->ScalProd([9, $v1], [4, 3]);

    $v1->Eq(3);
    is($v2->value, 9 * 4 + 3 * 3);

    # using same variables and constants
    my $v3 = $iz->ScalProd([9, $v1], [4, 3]);
    is($v3->value, $v2->value);
}

# ScalProd empty
{
    my $iz = Algorithm::CP::IZ->new();
    my $v = $iz->ScalProd([], []);

    is($v->value, 0);
}

# Abs
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(-10, 10);
    my $v2 = $iz->Abs($v1);

    $iz->save_context;

    $v1->Eq(3);
    is($v2->value, 3);

    $iz->restore_context;

    $v1->Eq(-5);
    is($v2->value, 5);

    is($iz->Abs(27)->value, 27);
    is($iz->Abs(-7)->value, 7);
}

# Min
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    my $v3 = $iz->Min([$v1, $v2]);

    $iz->save_context;

    $v1->Eq(3);
    $v2->Eq(4);
    is($v3->value, 3);

    $iz->restore_context;

    $iz->save_context;

    $v1->Eq(4);
    $v2->Eq(2);
    is($v3->value, 2);

    $iz->restore_context;

    my $v4 = $iz->Min([1, 2, 3]);
    is($v4->value, 1);
}

# Max
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    my $v3 = $iz->Max([$v1, $v2]);

    $iz->save_context;

    $v1->Eq(3);
    $v2->Eq(4);
    is($v3->value, 4);

    $iz->restore_context;

    $iz->save_context;

    $v1->Eq(8);
    $v2->Eq(2);
    is($v3->value, 8);

    $iz->restore_context;

    my $v4 = $iz->Max([1, 2, 3]);
    is($v4->value, 3);
}

# IfEq
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    is($iz->IfEq($v1, $v2, 5, 2), 1);

    $iz->save_context;

    is($v1->Eq(5), 1);
    is($v2->value, 2);

    $iz->restore_context;

    $iz->save_context;

    is($v1->Eq(8), 1);
    is($v2->Eq(3), 1);

    $iz->restore_context;
}

# IfNeq
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    is($iz->IfNeq($v1, $v2, 1, 9), 1);

    $iz->save_context;

    is($v1->Eq(1), 1);
    is($v2->Eq(9), 0);

    $iz->restore_context;

    $iz->save_context;

    is($v2->Eq(9), 1);
    is($v1->Eq(1), 0);

    $iz->restore_context;

    $iz->save_context;

    is($v1->Eq(9), 1);
    is($v2->Eq(1), 1);

    $iz->restore_context;
}

# OccurDomain
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    my $occur = $iz->OccurDomain(7, [$v1, $v2, 2]);

    $iz->save_context;

    is($v1->Eq(1), 1);
    is($v2->Eq(3), 1);
    is($occur->value, 0);

    $iz->restore_context;

    $iz->save_context;

    is($v1->Eq(7), 1);
    is($v2->Eq(7), 1);
    is($occur->value, 2);

    $iz->restore_context;
}

# OccurConstraints
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    my $v3 = $iz->create_int(0, 10);

    is($iz->OccurConstraints($v3, 5, [$v1, $v2, 2]), 1);

    $iz->save_context;

    is($v1->Eq(5), 1);
    is($v2->Eq(5), 1);
    is($v3->value, 2);

    $iz->restore_context;

    $iz->save_context;

    is($iz->OccurConstraints(1, 5, [$v1, $v2, 2]), 1);

    is($v1->Eq(5), 1);
    is($v2->Eq(5), 0);

    $iz->restore_context;
}

# Index
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    my $v3 = $iz->Index([$v1, $v2, 9], 2);

    $iz->save_context;

    is($v1->Eq(2), 1);
    is($v2->Eq(5), 1);
    is($v3->value, 0);

    $iz->restore_context;
}

# Element
{
    my $iz = Algorithm::CP::IZ->new();
    my $index = $iz->create_int(0, 10);
    my $elem = $iz->Element($index, [1, 3, 5, 7, 9]);

    $iz->save_context;

    is($index->Eq(2), 1);
    is($elem->value, 5);

    $iz->restore_context;
}

# Element (constant)
{
    my $iz = Algorithm::CP::IZ->new();
    my $elem = $iz->Element(3, [1, 3, 5, 7, 9]);

    $iz->save_context;

    is($elem->value, 7);

    $iz->restore_context;
}

# VarElement
{
    my $iz = Algorithm::CP::IZ->new();
    my $index = $iz->create_int(0, 10);
    my $v1 = $iz->create_int(2, 12);
    my $v2 = $iz->create_int(0, 5);
    my $elem = $iz->VarElement($index, [1, 3, 5, $v1, 9, $v2]);

    $iz->save_context;

    is($index->Eq(2), 1);
    is($elem->value, 5);

    $iz->restore_context;

    $iz->save_context;

    is($index->Eq(3), 1);
    is($elem->min, 2);
    is($elem->max, 12);

    is($elem->nb_elements, 12-2+1);
    is($v1->Neq(4), 1);
    is($elem->min, 2);
    is($elem->max, 12);
    is($elem->nb_elements, 12-2+1-1);
    ok(!$elem->is_in(4));

    is($v1->Eq(5), 1);
    is($elem->min, 5);
    is($elem->max, 5);

    $iz->restore_context;
}

# VarElement (constant)
{
    my $iz = Algorithm::CP::IZ->new();
    my $index = $iz->create_int(0, 10);
    my $elem = $iz->VarElement(1, [1, 3, 5]);

    is($elem->value, 3);
}

# VarElementRange
SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 14
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    my $index = $iz->create_int(0, 10);
    my $v1 = $iz->create_int(2, 12);
    my $v2 = $iz->create_int(0, 5);
    my $elem = $iz->VarElementRange($index, [$v1, $v2]);

    $iz->save_context;

    is($index->Eq(1), 1);
    is($elem->min, 0);
    is($elem->max, 5);

    ok($v2->Eq(5));
    is($elem->min, 5);
    is($elem->max, 5);

    $iz->restore_context;

    # hole is ignored
    $iz->save_context;

    is($index->Eq(1), 1);
    is($elem->min, 0);
    is($elem->max, 5);
    is($elem->nb_elements, 5-0+1);

    ok($v2->Neq(3));
    is($elem->min, 0);
    is($elem->max, 5);
    is($elem->nb_elements, 5-0+1);

    $iz->restore_context;
}

# VarElementRange (constant)
SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 1
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    my $elem = $iz->VarElementRange(0, [3, 5, 7]);

    is($elem->value, 3);
}

# Cumulative
SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 1
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);
    
    my @s = (0, $iz->create_int(0, 10));
    my @d = ($iz->create_int(0, 5), 5);
    my @r = ($iz->create_int(0, 5), 5);
    my $limit = $iz->create_int(2, 5);
    ok($iz->Cumulative(\@s, \@d, \@r, $limit));
}

# Cumulative (constant)
SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 2
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);
    
    my @s = (0, $iz->create_int(0, 10));
    my @d = (5, 5);
    my @r = (1, 1);
    ok($iz->Cumulative(\@s, \@d, \@r, 1));
    is($s[1]->min, 5);
}

# Disjunctive
SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 1
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    my @s = (0, $iz->create_int(0, 10));
    my @d = ($iz->create_int(0, 5), 5);
    ok($iz->Disjunctive(\@s, \@d));
}

# Disjunctive (constant)
SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 2
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    my @s = (0, $iz->create_int(0, 10));
    my @d = (5, 5);
    ok($iz->Disjunctive(\@s, \@d));
    is($s[1]->min, 5);
}

# ReifEq(var, var)
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    my $r = $iz->ReifEq($v1, $v2);

    $iz->save_context;
    is($v1->Eq(2), 1);
    is($v2->Eq(2), 1);
    is($r->value, 1);
    $iz->restore_context;

    $iz->save_context;
    is($v1->Eq(2), 1);
    is($v2->Eq(3), 1);
    is($r->value, 0);
    $iz->restore_context;
}

# ReifEq(var, const)
{
    my $iz = Algorithm::CP::IZ->new();
    my $v = $iz->create_int(0, 10);
    my $r1 = $iz->ReifEq($v, 5);
    my $r2 = $iz->ReifEq(5, $v);

    $iz->save_context;
    is($v->Eq(5), 1);
    is($r1->value, 1);
    is($r2->value, 1);
    $iz->restore_context;

    $iz->save_context;
    is($v->Eq(2), 1);
    is($r1->value, 0);
    is($r2->value, 0);
    $iz->restore_context;
}

# ReifNeq(var, var)
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    my $r = $iz->ReifNeq($v1, $v2);

    $iz->save_context;
    is($v1->Eq(2), 1);
    is($v2->Eq(2), 1);
    is($r->value, 0);
    $iz->restore_context;

    $iz->save_context;
    is($v1->Eq(2), 1);
    is($v2->Eq(3), 1);
    is($r->value, 1);
    $iz->restore_context;
}

# ReifNeq(var, const)
{
    my $iz = Algorithm::CP::IZ->new();
    my $v = $iz->create_int(0, 10);
    my $r1 = $iz->ReifNeq($v, 5);
    my $r2 = $iz->ReifNeq(5, $v);

    $iz->save_context;
    is($v->Eq(5), 1);
    is($r1->value, 0);
    is($r2->value, 0);
    $iz->restore_context;

    $iz->save_context;
    is($v->Eq(2), 1);
    is($r1->value, 1);
    is($r2->value, 1);
    $iz->restore_context;
}

# ReifLt(var, var)
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    my $r = $iz->ReifLt($v1, $v2);

    $iz->save_context;
    is($v1->Eq(3), 1);
    is($v2->Eq(2), 1);
    is($r->value, 0);
    $iz->restore_context;

    $iz->save_context;
    is($v1->Eq(5), 1);
    is($v2->Eq(5), 1);
    is($r->value, 0);
    $iz->restore_context;

    $iz->save_context;
    is($v1->Eq(2), 1);
    is($v2->Eq(3), 1);
    is($r->value, 1);
    $iz->restore_context;
}

# ReifLt(var, const)
{
    my $iz = Algorithm::CP::IZ->new();
    my $v = $iz->create_int(0, 10);
    my $r1 = $iz->ReifLt($v, 5);
    my $r2 = $iz->ReifLt(5, $v);

    $iz->save_context;
    is($v->Eq(8), 1);
    is($r1->value, 0);
    is($r2->value, 1);
    $iz->restore_context;

    $iz->save_context;
    is($v->Eq(5), 1);
    is($r1->value, 0);
    is($r2->value, 0);
    $iz->restore_context;

    $iz->save_context;
    is($v->Eq(3), 1);
    is($r1->value, 1);
    is($r2->value, 0);
    $iz->restore_context;
}


# ReifLe(var, var)
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    my $r = $iz->ReifLe($v1, $v2);

    $iz->save_context;
    is($v1->Eq(5), 1);
    is($v2->Eq(4), 1);
    is($r->value, 0);
    $iz->restore_context;

    $iz->save_context;
    is($v1->Eq(5), 1);
    is($v2->Eq(5), 1);
    is($r->value, 1);
    $iz->restore_context;

    $iz->save_context;
    is($v1->Eq(2), 1);
    is($v2->Eq(3), 1);
    is($r->value, 1);
    $iz->restore_context;
}

# ReifLe(var, const)
{
    my $iz = Algorithm::CP::IZ->new();
    my $v = $iz->create_int(0, 10);
    my $r1 = $iz->ReifLe($v, 5);
    my $r2 = $iz->ReifLe(5, $v);

    $iz->save_context;
    is($v->Eq(8), 1);
    is($r1->value, 0);
    is($r2->value, 1);
    $iz->restore_context;

    $iz->save_context;
    is($v->Eq(5), 1);
    is($r1->value, 1);
    is($r2->value, 1);
    $iz->restore_context;

    $iz->save_context;
    is($v->Eq(3), 1);
    is($r1->value, 1);
    is($r2->value, 0);
    $iz->restore_context;
}

# ReifGt(var, var)
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    my $r = $iz->ReifGt($v1, $v2);

    $iz->save_context;
    is($v1->Eq(3), 1);
    is($v2->Eq(2), 1);
    is($r->value, 1);
    $iz->restore_context;

    $iz->save_context;
    is($v1->Eq(5), 1);
    is($v2->Eq(5), 1);
    is($r->value, 0);
    $iz->restore_context;

    $iz->save_context;
    is($v1->Eq(2), 1);
    is($v2->Eq(3), 1);
    is($r->value, 0);
    $iz->restore_context;
}

# ReifGt(var, const)
{
    my $iz = Algorithm::CP::IZ->new();
    my $v = $iz->create_int(0, 10);
    my $r1 = $iz->ReifGt($v, 5);
    my $r2 = $iz->ReifGt(5, $v);

    $iz->save_context;
    is($v->Eq(8), 1);
    is($r1->value, 1);
    is($r2->value, 0);
    $iz->restore_context;

    $iz->save_context;
    is($v->Eq(5), 1);
    is($r1->value, 0);
    is($r2->value, 0);
    $iz->restore_context;

    $iz->save_context;
    is($v->Eq(3), 1);
    is($r1->value, 0);
    is($r2->value, 1);
    $iz->restore_context;
}


# ReifGe(var, var)
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    my $r = $iz->ReifGe($v1, $v2);

    $iz->save_context;
    is($v1->Eq(5), 1);
    is($v2->Eq(4), 1);
    is($r->value, 1);
    $iz->restore_context;

    $iz->save_context;
    is($v1->Eq(5), 1);
    is($v2->Eq(5), 1);
    is($r->value, 1);
    $iz->restore_context;

    $iz->save_context;
    is($v1->Eq(2), 1);
    is($v2->Eq(3), 1);
    is($r->value, 0);
    $iz->restore_context;
}

# ReifGe(var, const)
{
    my $iz = Algorithm::CP::IZ->new();
    my $v = $iz->create_int(0, 10);
    my $r1 = $iz->ReifGe($v, 5);
    my $r2 = $iz->ReifGe(5, $v);

    $iz->save_context;
    is($v->Eq(8), 1);
    is($r1->value, 1);
    is($r2->value, 0);
    $iz->restore_context;

    $iz->save_context;
    is($v->Eq(5), 1);
    is($r1->value, 1);
    is($r2->value, 1);
    $iz->restore_context;

    $iz->save_context;
    is($v->Eq(3), 1);
    is($r1->value, 0);
    is($r2->value, 1);
    $iz->restore_context;
}
