use strict;
use warnings;

use Test::More tests => 29;
BEGIN { use_ok('Algorithm::CP::IZ') };

{

    my $iz =  Algorithm::CP::IZ->new();
    my $err = 1;

    eval {
	my $v = $iz->create_int([]);
	$err = 0;
    };
    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

{
    my $iz =  Algorithm::CP::IZ->new();
    my $err = 1;

    eval {
	$iz->create_int(10, -10);
	$err = 0;
    };
    my $msg = $@;

    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

{
    my $iz =  Algorithm::CP::IZ->new();
    my $err = 1;
    my $v;

    eval {
        $err = 1;
	$v = $iz->create_int(-10, 10);
	$err = 0;
    };
    my $msg = $@;
    is($err, 0);
}

{
    my $iz =  Algorithm::CP::IZ->new();
    my $err = 1;

    eval {
	$iz->restore_context_until("x");
	$err = 0;
    };
    my $msg = $@;

    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

{
    my $iz =  Algorithm::CP::IZ->new();
    my $err = 1;

    eval {
	$iz->restore_context_until(1);
	$err = 0;
    };

    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

{
    my $iz =  Algorithm::CP::IZ->new();
    my $err = 1;

    my $label;
    eval {
	$label = $iz->save_context;
	$iz->restore_context_until($label);
	$err = 0;
    };
    is($err, 0);

    $err = 1;
    eval {
	$iz->restore_context_until(1);
	$err = 0;
    };

    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

#
# bad Min
#
{
    my $iz =  Algorithm::CP::IZ->new();
    my $err = 1;

    eval {
        $err = 1;
	my $v = $iz->Min("a");
	$err = 0;
    };
    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

    eval {
        $err = 1;
	my $v = $iz->Min(3);
	$err = 0;
    };
    $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

    eval {
        $err = 1;
	my $v = $iz->Min([]);
	$err = 0;
    };
    $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

    eval {
        $err = 1;
	my $v = $iz->Min([undef]);
	$err = 0;
    };
    $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

#
# bad Max
#
{
    my $iz =  Algorithm::CP::IZ->new();
    my $err = 1;

    eval {
    	$err = 1;
	my $v = $iz->Max("a");
	$err = 0;
    };
    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

    eval {
    	$err = 1;
	my $v = $iz->Max(3);
	$err = 0;
    };
    $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

    eval {
        $err = 1;
	my $v = $iz->Max([]);
	$err = 0;
    };
    $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

    eval {
        $err = 1;
	my $v = $iz->Max([undef]);
	$err = 0;
    };
    $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

