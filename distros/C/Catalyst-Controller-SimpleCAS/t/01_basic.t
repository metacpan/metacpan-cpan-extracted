# -*- perl -*-

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
use Test::Exception;

use_ok('Catalyst::Controller::SimpleCAS');
use_ok('Catalyst::Controller::SimpleCAS::Role::TextTranscode');
use_ok('Catalyst::Controller::SimpleCAS::Content');
use_ok('Catalyst::Controller::SimpleCAS::MimeUriResolver');
use_ok('Catalyst::Controller::SimpleCAS::Store');
use_ok('Catalyst::Controller::SimpleCAS::Store::DBIC');
use_ok('Catalyst::Controller::SimpleCAS::Store::File');

done_testing;
