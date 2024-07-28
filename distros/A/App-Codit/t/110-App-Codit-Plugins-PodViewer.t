
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 6;
use File::Spec;
use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';
$mwclass = 'App::Codit';

$delay = 3000;
$delay = 5000 if $mswin;
$quitdelay = 1000;

BEGIN { use_ok('App::Codit::Plugins::PodViewer') };

createapp(
	-plugins => [],
	-width => 800,
	-height => 600,
	-configfolder => File::Spec->rel2abs('t/settings'),
);

my $pext;
if (defined $app) {
	$pext = $app->extGet('Plugins');
}
push @tests, (
	[ sub {
		$pext->plugLoad('PodViewer');
		pause(400);
		my $b = $pext->plugGet('PodViewer');
		return defined $b 
#		return $pext->plugExists('PodViewer') 
	}, 1, 'Plugin PodViewer loaded' ],
	[ sub {
		$pext->plugUnload('PodViewer');
		pause(400);
		my $b = $pext->plugGet('PodViewer');
		return defined $b 
#		return $pext->plugExists('PodViewer') 
	}, '', 'Plugin PodViewer unloaded' ],
	[ sub {
		$pext->plugLoad('PodViewer');
		return $pext->plugExists('PodViewer') 
	}, 1, 'Plugin PodViewer reloaded' ],
);

starttesting;

