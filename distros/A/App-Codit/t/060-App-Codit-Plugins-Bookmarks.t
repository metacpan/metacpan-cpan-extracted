
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 5;
use File::Spec;
$mwclass = 'App::Codit';
#$quitdelay = 2500;

BEGIN { use_ok('App::Codit::Plugins::Bookmarks') };

createapp(
	-plugins => ['Bookmarks'],
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
		return $pext->plugExists('Bookmarks') 
	}, 1, 'Plugin Bookmarks loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('Bookmarks');
		my $b = $pext->plugGet('Bookmarks');
		return defined $b 
#		return $pext->plugExists('Bookmarks') 
	}, '', 'Plugin Bookmarks unloaded' ],
);

starttesting;

