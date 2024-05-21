
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 5;
use File::Spec;
$mwclass = 'App::Codit';
#$quitdelay = 2500;

BEGIN { use_ok('App::Codit::Plugins::PodViewer') };

createapp(
	-plugins => ['PodViewer'],
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
		return $pext->plugExists('PodViewer') 
	}, 1, 'Plugin PodViewer loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('PodViewer');
		my $b = $pext->plugGet('PodViewer');
		return defined $b 
#		return $pext->plugExists('PodViewer') 
	}, '', 'Plugin PodViewer unloaded' ],
);

starttesting;

