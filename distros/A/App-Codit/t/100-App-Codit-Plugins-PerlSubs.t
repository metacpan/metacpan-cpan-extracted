
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

BEGIN { use_ok('App::Codit::Plugins::PerlSubs') };

createapp(
	-plugins => ['PerlSubs'],
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
		return $pext->plugExists('PerlSubs') 
	}, 1, 'Plugin PerlSubs loaded' ],
	[ sub {
		pause(500);
		$pext->plugUnload('PerlSubs');
		my $b = $pext->plugGet('PerlSubs');
		return defined $b 
#		return $pext->plugExists('PerlSubs') 
	}, '', 'Plugin PerlSubs unloaded' ],
);

starttesting;

