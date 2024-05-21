
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 5;
use File::Spec;
$mwclass = 'App::Codit';
#$quitdelay = 2500;

BEGIN { use_ok('App::Codit::Plugins::Colors') };

createapp(
	-plugins => ['Colors'],
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
		return $pext->plugExists('Colors') 
	}, 1, 'Plugin Colors loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('Colors');
		my $b = $pext->plugGet('Colors');
		return defined $b 
#		return $pext->plugExists('Colors') 
	}, '', 'Plugin Colors unloaded' ],
);

starttesting;

