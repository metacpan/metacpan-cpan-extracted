use strict;
use warnings;

use Test::More tests => 69;
BEGIN { use_ok('Algorithm::CP::IZ') };

# event_all_known
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);

    my $fire = '';

    my $handler = sub {
	my ($array, $ext) = @_;

	is($v1->value, 5);
	is($v2->value, 7);
	$fire = $ext;

	return 1;
    };

    $iz->event_all_known([$v1, $v2], $handler, "abc");

    $v1->Eq(5);
    is($fire, '');

    $v2->Eq(7);
    is($fire, 'abc');
}

# event_all_known error
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);

    my $handler = sub {
	return 1;
    };

    my $err = 1;
    eval {
        $iz->event_all_known([undef, $v2], $handler, "abc");
	$err = 0;
    };
    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

    eval {
        $iz->event_all_known([$v1, $v2], "x", "abc");
	$err = 0;
    };
    $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

# event_known
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);

    my $fire = '';
    my $handler_value = 99;
    my $handler_index = 99;
    my $var_value = 99;

    my $known_handler = sub {
	my ($val, $index, $array, $ext) = @_;

	$handler_value = $val;
	$handler_index = $index;
	$var_value = $array->[$index]->value;

	$fire = $ext;
	
	return 1;
    };

    $iz->event_known([$v1, $v2], $known_handler, "abc");

    $v1->Eq(5);
    is($fire, 'abc');
    is($handler_value, 5);
    is($handler_index, 0);
    is($var_value, 5);

    $v2->Eq(7);
    is($fire, 'abc');
    is($handler_value, 7);
    is($handler_index, 1);
    is($var_value, 7);
}

# event_known error
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);

    my $known_handler = sub {
	return 1;
    };

    my $err = 1;
    eval {
	$iz->event_known("1", $known_handler, "abc");
	$err = 0;
    };

    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

    eval {
	$iz->event_known([$v1, $v2], undef, "abc");
	$err = 0;
    };

    $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

}

# event_new_min
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10, "v1");
    my $v2 = $iz->create_int(0, 10, "v2");

    my $fire = '';
    my $handler_index = 99;
    my $handler_min = 99;
    my $var_min = 99;
    my $var_name = "?";

    my $new_min_handler= sub {
	my ($var, $index, $old_min, $array, $ext) = @_;

	$fire = $ext;
	$handler_index = $index;
	$handler_min = $old_min;
	$var_min = $var->min;
	$var_name = $var->name;
	
	# called later 2 times
	is($array->[$index]->name, $var->name);

	return 1;
    };

    $iz->event_new_min([$v1, $v2], $new_min_handler, "abc");

    $v1->Ge(5);
    is($fire, 'abc');
    is($handler_min, 0);
    is($handler_index, 0);
    is($var_min, 5);
    is($var_name, "v1");

    $v2->Ge(7);
    is($fire, 'abc');
    is($handler_min, 0);
    is($handler_index, 1);
    is($var_min, 7);
    is($var_name, "v2");

}

# event_new_min err
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10, "v1");
    my $v2 = $iz->create_int(0, 10, "v2");

    my $new_min_handler= sub {
	return 1;
    };

    my $err = 1;
    eval {
	$iz->event_new_min([$v1, "x"], $new_min_handler, "abc");
	$err = 0;
    };
    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

    eval {
	$iz->event_new_min([$v1, $v2], $v1, "abc");
	$err = 0;
    };
    $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

# event_new_max
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10, "v1");
    my $v2 = $iz->create_int(0, 10, "v2");

    my $fire = '';
    my $handler_index = 99;
    my $handler_max = 99;
    my $var_max = 99;
    my $var_name = "?";

    my $new_max_handler = sub {
	my ($var, $index, $old_max, $array, $ext) = @_;

	$fire = $ext;
	$handler_index = $index;
	$handler_max = $old_max;
	$var_max = $var->max;
	$var_name = $var->name;
	
	# called later 2 times
	is($array->[$index]->name, $var->name);

	return 1;
    };

    $iz->event_new_max([$v1, $v2], $new_max_handler, "abc");

    $v1->Le(4);
    is($fire, 'abc');
    is($handler_max, 10);
    is($handler_index, 0);
    is($var_max, 4);
    is($var_name, "v1");

    $v2->Le(3);
    is($fire, 'abc');
    is($handler_max, 10);
    is($handler_index, 1);
    is($var_max, 3);
    is($var_name, "v2");

}

# event_new_max error
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10, "v1");
    my $v2 = $iz->create_int(0, 10, "v2");

    my $new_max_handler = sub {
	return 1;
    };

    my $err = 1;
    eval {
	$iz->event_new_max($new_max_handler, $new_max_handler, "abc");
	$err = 0;
    };
    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

    eval {
	$iz->event_new_max([$v1, $v2], 1, "abc");
	$err = 0;
    };
    $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

# event_neq
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10, "v1");
    my $v2 = $iz->create_int(0, 10, "v2");

    my $fire = '';
    my $handler_index = 99;
    my $handler_neq = 99;
    my $var_domain = "?";
    my $var_name = "?";

    my $neq_handler = sub {
	my ($var, $index, $neq_val, $array, $ext) = @_;

	$fire = $ext;
	$handler_index = $index;
	$handler_neq = $neq_val;
	$var_domain = join(",", @{$var->domain});
	$var_name = $var->name;
	
	# called later 2 times
	is($array->[$index]->name, $var->name);

	return 1;
    };

    $iz->event_neq([$v1, $v2], $neq_handler, "abc");

    $v1->Neq(4);
    is($fire, 'abc');
    is($handler_neq, 4);
    is($handler_index, 0);
    is($var_domain, "0,1,2,3,5,6,7,8,9,10");
    is($var_name, "v1");

    $v2->Neq(3);
    is($fire, 'abc');
    is($handler_neq, 3);
    is($handler_index, 1);
    is($var_domain, "0,1,2,4,5,6,7,8,9,10");
    is($var_name, "v2");

}

# event_neq error
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10, "v1");
    my $v2 = $iz->create_int(0, 10, "v2");

    my $fire = '';
    my $handler_index = 99;
    my $handler_neq = 99;
    my $var_domain = "?";
    my $var_name = "?";

    my $neq_handler = sub {
	return 1;
    };

    my $err = 1;
    eval {
	$iz->event_neq($v1, $neq_handler, "abc");
	$err = 0;
    };
    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

    eval {
	$iz->event_neq([$v1, $v2], "abc", $neq_handler);
	$err = 0;
    };
    $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);

}
