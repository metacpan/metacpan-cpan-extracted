
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
$delay = 3000;
$delay = 5000 if $mswin;

BEGIN { use_ok('App::Codit::Plugins::Critic') };

createapp(
	-plugins => ['Critic'],
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
		return $pext->plugExists('Critic') 
	}, 1, 'Plugin Critic loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('Critic');
		my $b = $pext->plugGet('Critic');
		return defined $b 
#		return $pext->plugExists('Colors') 
	}, '', 'Plugin Critic unloaded' ],
	[ sub {
		$pext->plugLoad('Critic');
		pause(100);
		return $pext->plugExists('Critic') 
	}, 1, 'Plugin Critic reloaded' ],
) unless $mswin;

starttesting;

my $num_of_tests = @tests + 3;
done_testing( $num_of_tests );
