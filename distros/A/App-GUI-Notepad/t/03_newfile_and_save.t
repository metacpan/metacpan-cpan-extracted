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
use Test::More tests => 5;



use App::GUI::Notepad;

my $app = App::GUI::Notepad->new();
my $frame = $app->{frame};
my $textctrl = $frame->{textctrl};
can_ok($frame, '_menu_new');
ok($frame->_menu_new(), 'File..New');
ok($textctrl->GetValue eq '', 'File..New successful');
$frame->{filename} = 'test.txt';
can_ok($frame, '_menu_save');
ok($frame->_menu_save(), 'File..Save');
exit(0);
