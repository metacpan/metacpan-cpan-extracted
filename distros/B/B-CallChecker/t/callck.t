use warnings;
use strict;

use Test::More tests => 61;

BEGIN {
	use_ok "B::CallChecker", qw(
		cv_get_call_checker cv_set_call_checker
		ck_entersub_args_list ck_entersub_args_proto
		ck_entersub_args_proto_or_list
	);
}

is prototype(\&ck_entersub_args_list), "\$";
is prototype(\&ck_entersub_args_proto), "\$\$\$";
is prototype(\&ck_entersub_args_proto_or_list), "\$\$\$";
ok \&ck_entersub_args_proto != \&ck_entersub_args_proto_or_list;

my @z = ();
my @a = qw(a);
my @b = qw(a b);
my @c = qw(a b c);
sub foo($$) { [@_] }
sub bar(@) { [@_] }
my($ckfun, $ckobj);

is_deeply scalar(eval(q{foo(@b, @c)})), [ 2, 3 ];
is scalar(@{[cv_get_call_checker(\&foo)]}), 2;
($ckfun, $ckobj) = cv_get_call_checker(\&foo);
ok $ckfun == \&ck_entersub_args_proto_or_list;
ok $ckobj == \&foo;

cv_set_call_checker(\&foo, \&ck_entersub_args_proto_or_list, \"\$\@");
ok 1;

is scalar(@{[cv_get_call_checker(\&foo)]}), 2;
($ckfun, $ckobj) = cv_get_call_checker(\&foo);
ok $ckfun == \&ck_entersub_args_proto_or_list;
is_deeply $ckobj, \"\$\@";
is_deeply scalar(eval(q{foo(@b, @c)})), [ 2, qw(a b c) ];

my($scalars_called, $scalars_namegv, $scalars_ckobj, $scalars_argcount);
sub ckfun_scalars($$$) {
	my($entersubop, $namegv, $ckobj) = @_;
	$scalars_called++;
	$scalars_namegv = $namegv;
	$scalars_ckobj = $ckobj;
	my $pushop = $entersubop->first;
	$pushop = $pushop->first if $pushop->sibling->isa("B::NULL");
	my $aop = $pushop->sibling;
	$scalars_argcount = 0;
	until($aop->sibling->isa("B::NULL")) {
		$scalars_argcount++;
		$aop = $aop->sibling;
	}
	return ck_entersub_args_proto($entersubop, $namegv,
		\("\$" x $scalars_argcount));
}

cv_set_call_checker(\&foo, \&ckfun_scalars, {a=>1});
ok 1;

is scalar(@{[cv_get_call_checker(\&foo)]}), 2;
($ckfun, $ckobj) = cv_get_call_checker(\&foo);
ok $ckfun == \&ckfun_scalars;
is_deeply $ckobj, {a=>1};
is $scalars_called, undef;
is_deeply scalar(eval(q{foo(@b, @c, @a)})), [ 2, 3, 1 ];
is $scalars_called, 1;
ok $scalars_namegv == \*foo;
is_deeply $scalars_ckobj, {a=>1};
is $scalars_argcount, 3;
is_deeply scalar(eval(q{foo(@b)})), [ 2 ];
is $scalars_called, 2;
ok $scalars_namegv == \*foo;
is_deeply $scalars_ckobj, {a=>1};
is $scalars_argcount, 1;

is_deeply scalar(eval(q{bar(@b, @c)})), [ qw(a b a b c) ];
is scalar(@{[cv_get_call_checker(\&bar)]}), 2;
($ckfun, $ckobj) = cv_get_call_checker(\&bar);
ok $ckfun == \&ck_entersub_args_proto_or_list;
ok $ckobj == \&bar;

eval { cv_set_call_checker("a", \&ckfun_scalars, {a=>1}) };
like $@, qr/(?:is n|N)ot a (?:code|CODE|subroutine) reference/;

eval { cv_set_call_checker(\"a", \&ckfun_scalars, {a=>1}) };
like $@, qr/(?:is n|N)ot a (?:code|CODE|subroutine) reference/;

eval { cv_set_call_checker(\&foo, \&ckfun_scalars, "a") };
like $@, qr/is not a reference/;

cv_set_call_checker(\&foo, \&ck_entersub_args_proto_or_list, \&bar);
ok 1;

is_deeply scalar(eval(q{foo(@b, @c)})), [ qw(a b a b c) ];
is scalar(@{[cv_get_call_checker(\&foo)]}), 2;
($ckfun, $ckobj) = cv_get_call_checker(\&foo);
ok $ckfun == \&ck_entersub_args_proto_or_list;
ok $ckobj == \&bar;

sub ckfun_lists($$$) {
	my($entersubop, $namegv, $ckobj) = @_;
	return ck_entersub_args_list($entersubop);
}

cv_set_call_checker(\&foo, \&ckfun_lists, \&foo);
ok 1;

is_deeply scalar(eval(q{foo(@b, @c)})), [ qw(a b a b c) ];
is scalar(@{[cv_get_call_checker(\&foo)]}), 2;
($ckfun, $ckobj) = cv_get_call_checker(\&foo);
ok $ckfun == \&ckfun_lists;
ok $ckobj == \&foo;

cv_set_call_checker(\&foo, \&ckfun_lists, \!1);
ok 1;

is_deeply scalar(eval(q{foo(@b, @c)})), [ qw(a b a b c) ];
is scalar(@{[cv_get_call_checker(\&foo)]}), 2;
($ckfun, $ckobj) = cv_get_call_checker(\&foo);
ok $ckfun == \&ckfun_lists;
ok $ckobj == \!1;

cv_set_call_checker(\&foo, \&ckfun_lists, \!0);
ok 1;

is_deeply scalar(eval(q{foo(@b, @c)})), [ qw(a b a b c) ];
is scalar(@{[cv_get_call_checker(\&foo)]}), 2;
($ckfun, $ckobj) = cv_get_call_checker(\&foo);
ok $ckfun == \&ckfun_lists;
ok $ckobj == \!0;

cv_set_call_checker(\&foo, \&ckfun_lists, \undef);
ok 1;

is_deeply scalar(eval(q{foo(@b, @c)})), [ qw(a b a b c) ];
is scalar(@{[cv_get_call_checker(\&foo)]}), 2;
($ckfun, $ckobj) = cv_get_call_checker(\&foo);
ok $ckfun == \&ckfun_lists;
ok $ckobj == \undef;

1;
