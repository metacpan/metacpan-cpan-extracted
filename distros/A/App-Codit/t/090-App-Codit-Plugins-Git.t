
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More;
use File::Spec;
use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';
$mwclass = 'App::Codit';

#test for git support
my $gitsupport = 0;
my $git = `git -v`;
$gitsupport = $git =~ /^git\sversion/;
print "No git support\n" unless $gitsupport;

$quitdelay = 1000;
$delay = 3000;
$delay = 5000 if $mswin;

BEGIN { use_ok('App::Codit::Plugins::Git') };

createapp(
	-plugins => ['Git'],
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
		return $pext->plugExists('Git') 
	}, 1, 'Plugin Git loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('Git');
		my $b = $pext->plugGet('Git');
		return defined $b 
#		return $pext->plugExists('Git') 
	}, '', 'Plugin Git unloaded' ],
	[ sub {
		$pext->plugLoad('Git');
		return $pext->plugExists('Git') 
	}, 1, 'Plugin Git reloaded' ],
) if $gitsupport;

starttesting;

done_testing(@tests + 3);
