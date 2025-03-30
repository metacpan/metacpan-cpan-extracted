
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 13;
use File::Spec;
use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';
$mwclass = 'App::Codit';

$quitdelay = 1000;
$delay = 2000;
$delay = 5000 if $mswin;

BEGIN { use_ok('App::Codit::Plugins::SplitView') };

createapp(
	-plugins => ['SplitView'],
	-width => 800,
	-height => 600,
	-configfolder => File::Spec->rel2abs('t/settings'),
);

my $pext;
if (defined $app) {
	$pext = $app->extGet('Plugins');
	pause(1000);
}

push @tests, (
	[ sub { 
		return $pext->plugExists('SplitView') 
	}, 1, 'Plugin SplitView loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('SplitView');
		my $b = $pext->plugGet('SplitView');
		return defined $b 
	}, '', 'Plugin SplitView unloaded' ],
	[ sub {
		$pext->plugLoad('SplitView');
		return $pext->plugExists('SplitView') 
	}, 1, 'Plugin SplitView reloaded' ],
	[ sub {
		$app->cmdExecute('split_horizontal');
		return 1 
	}, 1, 'split horizontal' ],
	[ sub {
		$app->cmdExecute('split_vertical');
		return 1 
	}, 1, 'split vertical' ],
	[ sub {
		$app->cmdExecute('split_cancel');
		return 1 
	}, 1, 'split cancel' ],
	[ sub {
		$app->cmdExecute('split_horizontal');
		return 1 
	}, 1, 'split horizontal' ],
	[ sub {
		$app->cmdExecute('split_cancel');
		return 1 
	}, 1, 'split cancel' ],
	[ sub {
		$app->cmdExecute('split_vertical');
		return 1 
	}, 1, 'split vertical' ],
	[ sub {
		$app->cmdExecute('split_cancel');
		return 1 
	}, 1, 'split cancel' ],
);

starttesting;

