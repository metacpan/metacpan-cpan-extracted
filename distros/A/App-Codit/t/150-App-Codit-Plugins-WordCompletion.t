
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 11;
use File::Spec;
use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';
$mwclass = 'App::Codit';

$delay = 2000;
$quitdelay = 1000;
$delay = 5000 if $mswin;

BEGIN { use_ok('App::Codit::Plugins::WordCompletion') };

createapp(
	-plugins => ['WordCompletion'],
	-width => 800,
	-height => 600,
	-configfolder => File::Spec->rel2abs('t/settings'),
);

my $pext;
my $wordcomp;
if (defined $app) {
	$pext = $app->extGet('Plugins');
	pause(1000);
	$wordcomp = $pext->plugGet('WordCompletion');
	
}

testaccessors($wordcomp, 'activeDelay', 'PopSize', 'ScanSize', 'TriggerWord', 'wordcompletion');

push @tests, (
	[ sub { 
		return $pext->plugExists('WordCompletion') 
	}, 1, 'Plugin WordCompletion loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('WordCompletion');
		my $b = $pext->plugGet('WordCompletion');
		return defined $b 
#		return $pext->plugExists('WordCompletion') 
	}, '', 'Plugin WordCompletion unloaded' ],
	[ sub {
		$pext->plugLoad('WordCompletion');
		return $pext->plugExists('WordCompletion') 
	}, 1, 'Plugin WordCompletion loaded' ],
);

starttesting;

