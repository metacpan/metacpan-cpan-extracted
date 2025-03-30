
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 6;
use File::Spec;
use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';
$mwclass = 'App::Codit';

$quitdelay = 1000;
$quitdelay = 3000 if $mswin;
$delay = 3000;
$delay = 5000 if $mswin;

BEGIN { use_ok('App::Codit::Plugins::Icons') };

createapp(
	-plugins => ['Icons'],
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
		return $pext->plugExists('Icons') 
	}, 1, 'Plugin Icons loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('Icons');
		my $b = $pext->plugGet('Icons');
		return defined $b 
#		return $pext->plugExists('Icons') 
	}, '', 'Plugin Icons unloaded' ],
	[ sub {
		$pext->plugLoad('Icons');
		return $pext->plugExists('Icons') 
	}, 1, 'Plugin Icons reloaded' ],
);

starttesting;

