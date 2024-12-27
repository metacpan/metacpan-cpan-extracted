
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 17;
use File::Spec;
use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';
$mwclass = 'App::Codit';

$quitdelay = 1000;
$delay = 3000;
$delay = 5000 if $mswin;

BEGIN { use_ok('App::Codit::Plugins::Exporter') };

createapp(
	-plugins => ['Exporter'],
	-width => 800,
	-height => 600,
	-configfolder => File::Spec->rel2abs('t/settings'),
);

my $pext;
my $exp;
if (defined $app) {
	pause(300);
	$pext = $app->extGet('Plugins');
	$exp = $pext->plugGet('Exporter');
}

testaccessors($exp, qw/background iheight image imargin iwidth linecolumn linenumbers maxwidth tabstring xpos ypos/);

push @tests, (
	[ sub { 
		return $pext->plugExists('Exporter') 
	}, 1, 'Plugin Exporter loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('Exporter');
		my $b = $pext->plugGet('Exporter');
		return defined $b 
#		return $pext->plugExists('Colors') 
	}, '', 'Plugin Exporter unloaded' ],
	[ sub {
		$pext->plugLoad('Exporter');
		return $pext->plugExists('Exporter') 
	}, 1, 'Plugin Exporter reloaded' ],
);

starttesting;

