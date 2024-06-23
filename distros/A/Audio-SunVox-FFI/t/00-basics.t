use strict;
use warnings;
use Test2::V0;

use Audio::SunVox::FFI ':all';
use Time::HiRes qw/ usleep /;

sub call_ok { ok $_[0] >= 0, $_[1]; $_[0] }

call_ok sv_init, "Initialised SunVox in offline mode";

my $slot = 0;
call_ok sv_open_slot( $slot ), "Opened a SunVox instance";

call_ok sv_lock_slot( $slot ), "Can lock slot";
my $generator = call_ok sv_new_module( $slot, "Generator", "foo" ),
    "Created generator";
my $module = call_ok sv_find_module( $slot, "foo" ), "Can find generator";
ok $module == $generator, "Correct module found";
call_ok sv_connect_module( $slot, $generator, 0 ), "Can connect to output";
call_ok sv_unlock_slot( $slot ), "Can unlock slot";

call_ok sv_set_event_t( $slot, 1, 0 ), "Process events ASAP enabled";
call_ok sv_set_module_ctl_value( $slot, $generator, 0, 0x8000, 1 ),
    "Can set module value";
usleep(100_000); # IPC, audio system latency (default buf is 4096, ~85ms)
my $val = call_ok sv_get_module_ctl_value( $slot, $generator, 0, 1 ),
    "Can get module value";
ok $val == 0x8000, "Expected value returned";

#call_ok sv_save($slot, 'test.sunvox');

call_ok sv_close_slot( $slot ), "Close SunVox instance";
call_ok sv_deinit, "De-initialise";

done_testing;
