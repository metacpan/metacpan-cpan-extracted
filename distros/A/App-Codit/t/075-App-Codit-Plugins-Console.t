
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
$delay = 4000;
$delay = 5000 if $mswin;

BEGIN { use_ok('App::Codit::Plugins::Console') };

createapp(
	-plugins => ['Console'],
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
		return $pext->plugExists('Console') 
	}, 1, 'Plugin Console loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('Console');
		my $b = $pext->plugGet('Console');
		return defined $b 
#		return $pext->plugExists('Colors') 
	}, '', 'Plugin Console unloaded' ],
	[ sub {
		$pext->plugLoad('Console');
		pause(100);
		return $pext->plugExists('Console') 
	}, 1, 'Plugin Console reloaded' ],
) unless $mswin;

starttesting;

my $num_of_tests = @tests + 3;
done_testing( $num_of_tests );
