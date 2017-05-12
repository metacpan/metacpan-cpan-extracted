#!/usr/bin/perl
use strict;
use warnings;

BEGIN { $ENV{AIEVOLVEBEFUNGE} = 't/insane.conf'; };

my $num_tests;
BEGIN { $num_tests = 0; };
use Test::More;
use Test::Output;
use Test::Exception;

use AI::Evolve::Befunge::Util;


# global_config
is(scalar global_config('basic_value', 'undefined'), 42, 'config(exists)');
is(scalar global_config('nonexistent', 'undefined'), 'undefined', 'config(!exists)');
is_deeply([global_config('nonexistent', 'undefined')], ['undefined'], 'wantarray config(!exists)');
is_deeply([global_config('nonexistent', undef)], [undef], 'wantarray config(!exists)');
is_deeply([global_config('nonexistent')], [], 'wantarray config(!exists)');
is_deeply([global_config('test_list')], [5,8,13], 'wantarray config(array exists)');
is_deeply([global_config('basic_value')], [42], 'wantarray returns value even if no default given');
BEGIN { $num_tests += 7 };


my $global = custom_config();
my $proper = custom_config(host => 'myhost', physics => 'foo', gen => 6);
my $wrong1 = custom_config(host => 'myhost', physics => 'bar', gen => 8);
my $wrong2 = custom_config(host => 'nohost', physics => 'bar', gen => 2);
is($global->config('basic_value'                ), 42, 'global value inherited');
is($proper->config('basic_value'                ), 42, 'global value inherited');
is($wrong1->config('basic_value'                ), 42, 'global value inherited');
is($wrong2->config('basic_value'                ), 42, 'global value inherited');
is($global->config('overrode'                   ), 0, '$global overrode');
is($proper->config('overrode'                   ), 5, '$proper overrode');
is($wrong1->config('overrode'                   ), 1, '$wrong1 overrode');
is($wrong2->config('overrode'                   ), 0, '$wrong2 overrode');
is($global->config('overrode_host'              ), 0, '$global overrode_host');
is($proper->config('overrode_host'              ), 1, '$proper overrode_host');
is($wrong1->config('overrode_host'              ), 1, '$wrong1 overrode_host');
is($wrong2->config('overrode_host'              ), 0, '$wrong2 overrode_host');
is($global->config('overrode_host_physics'      ), 0, '$global overrode_host_physics');
is($proper->config('overrode_host_physics'      ), 6, '$proper overrode_host_physics');
is($wrong1->config('overrode_host_physics'      ), 0, '$wrong1 overrode_host_physics');
is($wrong2->config('overrode_host_physics'      ), 0, '$wrong2 overrode_host_physics');
is($global->config('overrode_host_physics_foo'  ), 0, '$global overrode_host_physics_foo');
is($proper->config('overrode_host_physics_foo'  ), 1, '$proper overrode_host_physics_foo');
is($wrong1->config('overrode_host_physics_foo'  ), 0, '$wrong1 overrode_host_physics_foo');
is($wrong2->config('overrode_host_physics_foo'  ), 0, '$wrong2 overrode_host_physics_foo');
is($global->config('overrode_host_physics_baz'  ), 0, '$global overrode_host_physics_bar');
is($proper->config('overrode_host_physics_baz'  ), 0, '$proper overrode_host_physics_bar');
is($wrong1->config('overrode_host_physics_baz'  ), 0, '$wrong1 overrode_host_physics_bar');
is($wrong2->config('overrode_host_physics_baz'  ), 0, '$wrong2 overrode_host_physics_bar');
is($global->config('overrode_host_physics_gen'  ), 0, '$global overrode_host_physics_gen');
is($proper->config('overrode_host_physics_gen'  ), 1, '$proper overrode_host_physics_gen');
is($wrong1->config('overrode_host_physics_gen'  ), 0, '$wrong1 overrode_host_physics_gen');
is($wrong2->config('overrode_host_physics_gen'  ), 0, '$wrong2 overrode_host_physics_gen');
is($global->config('overrode_host_physics_gen_2'), 0, '$global overrode_host_physics_gen_2');
is($proper->config('overrode_host_physics_gen_2'), 1, '$proper overrode_host_physics_gen_2');
is($wrong1->config('overrode_host_physics_gen_2'), 0, '$wrong1 overrode_host_physics_gen_2');
is($wrong2->config('overrode_host_physics_gen_2'), 0, '$wrong2 overrode_host_physics_gen_2');
is($global->config('overrode_host_physics_gen_5'), 0, '$global overrode_host_physics_gen_5');
is($proper->config('overrode_host_physics_gen_5'), 1, '$proper overrode_host_physics_gen_5');
is($wrong1->config('overrode_host_physics_gen_5'), 0, '$wrong1 overrode_host_physics_gen_5');
is($wrong2->config('overrode_host_physics_gen_5'), 0, '$wrong2 overrode_host_physics_gen_5');
is($global->config('overrode_host_physics_gen_6'), 0, '$global overrode_host_physics_gen_6');
is($proper->config('overrode_host_physics_gen_6'), 1, '$proper overrode_host_physics_gen_6');
is($wrong1->config('overrode_host_physics_gen_6'), 0, '$wrong1 overrode_host_physics_gen_6');
is($wrong2->config('overrode_host_physics_gen_6'), 0, '$wrong2 overrode_host_physics_gen_6');
is($global->config('overrode_host_physics_gen_8'), 0, '$global overrode_host_physics_gen_8');
is($proper->config('overrode_host_physics_gen_8'), 0, '$proper overrode_host_physics_gen_8');
is($wrong1->config('overrode_host_physics_gen_8'), 0, '$wrong1 overrode_host_physics_gen_8');
is($wrong2->config('overrode_host_physics_gen_8'), 0, '$wrong2 overrode_host_physics_gen_8');
BEGIN { $num_tests += 44 };


BEGIN { plan tests => $num_tests };
