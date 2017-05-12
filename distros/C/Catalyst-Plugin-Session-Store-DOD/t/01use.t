use Test::More tests => 3;
use FindBin;

use_ok('Catalyst::Plugin::Session::Store::DOD');

use lib "$FindBin::Bin/lib";
use_ok('TestApp');
use_ok('TestApp::M::Session');
