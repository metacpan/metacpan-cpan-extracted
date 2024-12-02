
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 6;
use File::Spec;
use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';
$mwclass = 'App::Codit';

$quitdelay = 9000;
$quitdelay = 3000 if $mswin;
$delay = 9000;
$delay = 5000 if $mswin;

BEGIN { use_ok('App::Codit::Plugins::FileBrowser') };

createapp(
	-plugins => ['FileBrowser'],
	-width => 800,
	-height => 600,
	-configfolder => File::Spec->rel2abs('t/settings'),
);

my $pext;
if (defined $app) {
	$app->geometry('800x600+0+0');
	$pext = $app->extGet('Plugins');
}
push @tests, (
	[ sub { 
		return $pext->plugExists('FileBrowser') 
	}, 1, 'Plugin FileBrowser loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('FileBrowser');
		my $b = $pext->plugGet('FileBrowser');
		return defined $b 
#		return $pext->plugExists('FileBrowser') 
	}, '', 'Plugin FileBrowser unloaded' ],
	[ sub {
		$pext->plugLoad('FileBrowser');
		return $pext->plugExists('FileBrowser') 
	}, 1, 'Plugin FileBrowser reloaded' ],
);

starttesting;

