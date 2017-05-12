use strict;
use warnings;

use Test::More tests => 49;
BEGIN { use_ok('Algorithm::CP::IZ') };

# event_all_known
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);

    my $fire = '';

    sub handler1 {
	my ($array, $ext) = @_;

	is($v1->value, 5);
	is($v2->value, 7);
	$fire = $ext;

	return 1;
    }

    $iz->event_all_known([$v1, $v2], \&handler1, "abc");

    $v1->Eq(5);
    is($fire, '');

    $v2->Eq(7);
    is($fire, 'abc');
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

    sub known_handler {
	my ($val, $index, $array, $ext) = @_;

	$handler_value = $val;
	$handler_index = $index;
	$var_value = $array->[$index]->value;

	$fire = $ext;
	
	return 1;
    }

    $iz->event_known([$v1, $v2], \&known_handler, "abc");

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

    sub new_min_handler {
	my ($var, $index, $old_min, $array, $ext) = @_;

	$fire = $ext;
	$handler_index = $index;
	$handler_min = $old_min;
	$var_min = $var->min;
	$var_name = $var->name;
	
	# called later 2 times
	is($array->[$index]->name, $var->name);

	return 1;
    }

    $iz->event_new_min([$v1, $v2], \&new_min_handler, "abc");

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

    sub new_max_handler {
	my ($var, $index, $old_max, $array, $ext) = @_;

	$fire = $ext;
	$handler_index = $index;
	$handler_max = $old_max;
	$var_max = $var->max;
	$var_name = $var->name;
	
	# called later 2 times
	is($array->[$index]->name, $var->name);

	return 1;
    }

    $iz->event_new_max([$v1, $v2], \&new_max_handler, "abc");

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

    sub neq_handler {
	my ($var, $index, $neq_val, $array, $ext) = @_;

	$fire = $ext;
	$handler_index = $index;
	$handler_neq = $neq_val;
	$var_domain = join(",", @{$var->domain});
	$var_name = $var->name;
	
	# called later 2 times
	is($array->[$index]->name, $var->name);

	return 1;
    }

    $iz->event_neq([$v1, $v2], \&neq_handler, "abc");

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
