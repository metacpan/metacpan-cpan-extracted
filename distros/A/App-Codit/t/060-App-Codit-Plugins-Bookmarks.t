
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
	[ sub {
		$pext->plugLoad('Bookmarks');
		return $pext->plugExists('Bookmarks') 
	}, 1, 'Plugin Bookmarks reloaded' ],
);

starttesting;

