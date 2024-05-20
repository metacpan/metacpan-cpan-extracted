
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 4;
use File::Spec;
$mwclass = 'App::Codit';
#$quitdelay = 2500;

BEGIN { use_ok('App::Codit::Plugins::PerlSubs') };

createapp(
	-plugins => ['PerlSubs'],
	-width => 800,
	-height => 600,
	-configfolder => File::Spec->rel2abs('t/settings'),
);

push @tests, (
	[ sub { 
		return $app->extGet('Plugins')->plugExists('PerlSubs') 
	}, 1, 'Plugin PerlSubs loaded' ],
);

starttesting;

