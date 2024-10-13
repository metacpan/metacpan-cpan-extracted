
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 20;
use File::Spec;
$mwclass = 'App::Codit';
$delay = 1500;
$quitdelay = 2500;

BEGIN {
	use_ok('App::Codit');
	use_ok('App::Codit::Ext::CoditMDI');
	use_ok('App::Codit::Macro');
};

createapp(
	-width => 800,
	-height => 600,
	-configfolder => File::Spec->rel2abs('t/settings'),
);

my $mdi;
my $macro;
if (defined $app) {
	$mdi = $app->extGet('CoditMDI');
	$macro = App::Codit::Macro->new($mdi, 'dummy', '', [sub{}]);
}

testaccessors($macro, qw/countref interval last line remain/);

push @tests, (
	[ sub {
		return $app->extExists('Art')
	}, 1, 'Extension Art loaded' ],
	[ sub {
		return $app->extExists('CoditMDI')
	}, 1, 'Extension CoditMDI loaded' ],
	[ sub {
		return $app->extExists('ToolBar')
	}, 1, 'Extension ToolBar loaded' ],
	[ sub {
		return $app->extExists('StatusBar')
	}, 1, 'Extension StatusBar loaded' ],
	[ sub {
		return $app->extExists('MenuBar')
	}, 1, 'Extension MenuBar loaded' ],
	[ sub {
		return $app->extExists('Selector')
	}, 1, 'Extension Selector loaded' ],
	[ sub {
		return $app->extExists('Help')
	}, 1, 'Extension Help loaded' ],
	[ sub {
		return $app->extExists('Settings')
	}, 1, 'Extension Settings loaded' ],
	[ sub {
		return $app->extExists('Plugins')
	}, 1, 'Extension Plugins loaded' ],
	[ sub {
		$mdi->macroInit('Untitled', 'dummy', [sub {}]);
		return defined $mdi->macroGet('Untitled', 'dummy');
	}, 1, 'Macro dummy initialized' ],
);

starttesting;



