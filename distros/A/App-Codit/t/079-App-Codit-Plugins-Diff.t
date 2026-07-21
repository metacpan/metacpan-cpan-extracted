
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More;
use File::Spec;
use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';
$mwclass = 'App::Codit';

$quitdelay = 1000;
$delay = 6500;
$delay = 8500 if $mswin;

BEGIN { use_ok('App::Codit::Plugins::Diff') };

createapp(
	-plugins => ['Diff'],
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
		return $pext->plugExists('Diff') 
	}, 1, 'Plugin Diff loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('Diff');
		my $b = $pext->plugGet('Diff');
		return defined $b 
#		return $pext->plugExists('Colors') 
	}, '', 'Plugin Diff unloaded' ],
	[ sub {
		pause(400);
		$pext->plugLoad('Diff');
		pause(100);
		return $pext->plugExists('Diff') 
	}, 1, 'Plugin Diff reloaded' ],
) unless $mswin;

starttesting;

my $num_of_tests = @tests + 3;
done_testing( $num_of_tests );
