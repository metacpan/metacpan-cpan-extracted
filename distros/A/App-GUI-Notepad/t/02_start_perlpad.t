#!/usr/bin/perl -w

# Compile-testing for App::Gui::Notepad

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'lib'),
			catdir('blib', 'arch'),
			);
	}
}

use Test::NeedsDisplay;
use Test::More tests => 8;

use App::GUI::Notepad;

my $app = App::GUI::Notepad->new();
ok(defined $app, 'Åpplication object instantiation');
isa_ok($app, 'App::GUI::Notepad');
ok(defined $app->{frame}, 'Menubar instantiation');
isa_ok($app->{frame}, 'App::GUI::Notepad::Frame');
my $frame = $app->{frame};
ok(defined $frame->{menubar}, 'Frame has a menubar');
isa_ok($frame->{menubar}, 'App::GUI::Notepad::MenuBar');
ok(defined $frame->{textctrl}, 'Frame has a menubar');
isa_ok($frame->{textctrl}, 'Wx::TextCtrl');

exit(0);
