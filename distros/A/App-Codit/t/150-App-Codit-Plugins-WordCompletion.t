
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 5;
use File::Spec;
use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';
$mwclass = 'App::Codit';

$delay = 1500;
$quitdelay = 1000 if $mswin;

BEGIN { use_ok('App::Codit::Plugins::WordCompletion') };

createapp(
	-plugins => ['WordCompletion'],
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
		return $pext->plugExists('WordCompletion') 
	}, 1, 'Plugin WordCompletion loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('WordCompletion');
		my $b = $pext->plugGet('WordCompletion');
		return defined $b 
#		return $pext->plugExists('WordCompletion') 
	}, '', 'Plugin WordCompletion unloaded' ],
);

starttesting;

