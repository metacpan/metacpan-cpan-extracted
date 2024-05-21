
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 5;
use File::Spec;
$mwclass = 'App::Codit';
#$quitdelay = 2500;

BEGIN { use_ok('App::Codit::Plugins::Snippets') };

createapp(
	-plugins => ['Snippets'],
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
		return $pext->plugExists('Snippets') 
	}, 1, 'Plugin Snippets loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('Snippets');
		my $b = $pext->plugGet('Snippets');
		return defined $b 
#		return $pext->plugExists('Snippets') 
	}, '', 'Plugin Snippets unloaded' ],
);

starttesting;

