
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 9;
use File::Spec;
use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';
$mwclass = 'App::Codit';

$quitdelay = 1000;
$delay = 2000;
$delay = 5000 if $mswin;

BEGIN { use_ok('App::Codit::Plugins::SearchReplace') };

createapp(
	-plugins => ['SearchReplace'],
	-width => 800,
	-height => 600,
	-configfolder => File::Spec->rel2abs('t/settings'),
);

my $pext;
my $sr;
if (defined $app) {
	$pext = $app->extGet('Plugins');
	pause(1000);
	$sr = $pext->plugGet('SearchReplace');
}

testaccessors($sr, 'Current', 'repl', 'skipped');

push @tests, (
	[ sub { 
		return $pext->plugExists('SearchReplace') 
	}, 1, 'Plugin SearchReplace loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('SearchReplace');
		my $b = $pext->plugGet('SearchReplace');
		return defined $b 
#		return $pext->plugExists('SearchReplace') 
	}, '', 'Plugin SearchReplace unloaded' ],
	[ sub {
		$pext->plugLoad('SearchReplace');
		return $pext->plugExists('SearchReplace') 
	}, 1, 'Plugin SearchReplace reloaded' ],
);

starttesting;

