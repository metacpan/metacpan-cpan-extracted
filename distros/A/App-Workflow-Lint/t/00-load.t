use strict;
use warnings;
use Test::Most;

use_ok('App::Workflow::Lint');
use_ok('App::Workflow::Lint::Engine');
use_ok('App::Workflow::Lint::Rule');
use_ok('App::Workflow::Lint::Rule::MissingPermissions');

done_testing;
