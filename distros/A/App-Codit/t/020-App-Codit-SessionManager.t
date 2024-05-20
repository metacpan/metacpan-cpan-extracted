
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 1;
$mwclass = 'Tk::AppWindow';

BEGIN { use_ok('App::Codit::SessionManager') };

# createapp(
# );
# 
# my $text;
# if (defined $app) {
# 	$text = $app->CoditText->pack(-expand => 1, -fill => 'both');
# }
# 
# push @tests , [ sub { return defined $text }, 1, 'CoditText created'];
# 
# starttesting;

