use Test::More tests => 4;

use_ok('Catalyst::Plugin::Authentication::Store::DBIC');
use_ok('Catalyst::Plugin::Authentication::Store::DBIC::Backend');
use_ok('Catalyst::Plugin::Authentication::Store::DBIC::User');
use_ok('Catalyst::Plugin::Authentication::Store::DBIC::User::CDBI');
