
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 5;
use File::Spec;
$mwclass = 'App::Codit';
#$quitdelay = 2500;

BEGIN { use_ok('App::Codit::Plugins::FileBrowser') };

createapp(
	-plugins => ['FileBrowser'],
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
		return $pext->plugExists('FileBrowser') 
	}, 1, 'Plugin FileBrowser loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('FileBrowser');
		my $b = $pext->plugGet('FileBrowser');
		return defined $b 
#		return $pext->plugExists('FileBrowser') 
	}, '', 'Plugin FileBrowser unloaded' ],
);

starttesting;

