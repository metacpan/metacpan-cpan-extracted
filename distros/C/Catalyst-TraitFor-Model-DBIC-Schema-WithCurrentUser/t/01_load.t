use strict;
use warnings;
use Test::More tests => 5;
use lib 'lib';
use lib 't/lib';

use_ok("Catalyst::TraitFor::Model::DBIC::Schema::WithCurrentUser");
use_ok("TestApp");
use_ok("TestApp::Schema");
use_ok("TestApp::User");
use_ok("TestApp::Model::DB");
