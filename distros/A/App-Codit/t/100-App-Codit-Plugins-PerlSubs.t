
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
my $ddelay = 3000;
$ddelay = 5000 if $mswin;

BEGIN { use_ok('App::Codit::Plugins::PerlSubs') };

createapp(
	-plugins => ['PerlSubs'],
	-width => 800,
	-height => 600,
	-configfolder => File::Spec->rel2abs('t/settings'),
);

my $pext;
my $subs;
if (defined $app) {
	pause($ddelay);
	$pext = $app->extGet('Plugins');
	$subs = $pext->plugGet('PerlSubs');
}

testaccessors($subs, 'Current', 'SortOn', 'SortOrder');

push @tests, (
	[ sub { 
		return $pext->plugExists('PerlSubs') 
	}, 1, 'Plugin PerlSubs loaded' ],
	[ sub {
		pause(500);
		$pext->plugUnload('PerlSubs');
		my $b = $pext->plugGet('PerlSubs');
		return defined $b 
#		return $pext->plugExists('PerlSubs') 
	}, '', 'Plugin PerlSubs unloaded' ],
	[ sub {
		$pext->plugLoad('PerlSubs');
		return $pext->plugExists('PerlSubs') 
	}, 1, 'Plugin PerlSubs reloaded' ],
);

starttesting;

