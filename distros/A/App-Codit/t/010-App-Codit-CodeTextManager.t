
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 1;
$mwclass = 'Tk::AppWindow';

BEGIN { use_ok('App::Codit::CodeTextManager') };

# createapp(
# );
# 
# my $manager;
# if (defined $app) {
# 	$manager = $app->CodeTextManager(
# 		-extension => $app,
# 	)->pack(-expand => 1, -fill => 'both');
# }
# 
# push @tests , [ sub { return defined $manager }, 1, 'CodeTextManager created'];
# 
# starttesting;

