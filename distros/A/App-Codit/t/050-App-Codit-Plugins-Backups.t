
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 5;
use File::Spec;
use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';
$mwclass = 'App::Codit';

$quitdelay = 1000 if $mswin;

BEGIN { use_ok('App::Codit::Plugins::Backups') };

createapp(
	-plugins => ['Backups'],
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
		return $pext->plugExists('Backups') 
	}, 1, 'Plugin Backups loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('Backups');
		my $b = $pext->plugGet('Backups');
		return defined $b 
#		return $pext->plugExists('Backups') 
	}, '', 'Plugin Backups unloaded' ],
);

starttesting;

