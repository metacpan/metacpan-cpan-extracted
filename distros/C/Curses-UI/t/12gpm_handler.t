# -*- perl -*-
use strict;
use Test::More tests => 5;
use FindBin;
use lib "$FindBin::RealBin/fakelib";

$ENV{LINES} = 25;
$ENV{COLUMNS} = 80;

BEGIN { 
    sub require {
	my $mod = shift;
	if ($mod ne "Curses::UI::Mousehandler::GPM") {
	    return CORE::require $mod;
	} else {
	    $@ = "Couldn't load module $mod (faked by test)";
	    $INC{$mod} = undef;
	    die $@;
	}
    }

    use_ok( "Curses::UI"); 

}

my $cui = new Curses::UI("-clear_on_exit" => 0);
isa_ok($cui, "Curses::UI");
$cui->{-read_timeout} = 0;
$cui->do_one_event(); #should not lead to errors
pass("Without forced GPM support");

undef $cui;
$Curses::UI::initialized = 0;

$Curses::UI::gpm_mouse = 1; #force mouse
$cui = new Curses::UI("-clear_on_exit" => 0);

isa_ok($cui, "Curses::UI");

$cui->{-read_timeout} = 1;

eval { $cui->do_one_event(); };
if ($@) {
    pass("Undefined routine is ok");
} else {
    fail("Should have failed");
}


