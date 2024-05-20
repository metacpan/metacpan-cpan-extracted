
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 1;
$mwclass = 'Tk::AppWindow';
require Tk::Font;

BEGIN { use_ok('App::Codit::Plugins::Git') };

# createapp(
# );
# 
# 
# starttesting;
# 
