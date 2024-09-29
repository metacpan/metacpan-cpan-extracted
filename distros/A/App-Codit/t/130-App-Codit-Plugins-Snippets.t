
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 7;
use File::Spec;
use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';
$mwclass = 'App::Codit';

$quitdelay = 1000;
$delay = 2000;
$delay = 5000 if $mswin;

BEGIN { use_ok('App::Codit::Plugins::Snippets') };

createapp(
	-plugins => ['Snippets'],
	-width => 800,
	-height => 600,
	-configfolder => File::Spec->rel2abs('t/settings'),
);

my $pext;
my $snp;
if (defined $app) {
	$pext = $app->extGet('Plugins');
	pause(1000);
	$snp = $pext->plugGet('Snippets');
}

testaccessors($snp, 'current');

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
	[ sub {
		$pext->plugLoad('Snippets');
		return $pext->plugExists('Snippets') 
	}, 1, 'Plugin Snippets reloaded' ],
);

starttesting;

