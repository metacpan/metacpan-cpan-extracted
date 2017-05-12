use Test::Most tests => 9;
use strict;
use warnings;

use lib 't/lib';
use App::Mimosa::Test;
use Test::DBIx::Class;

fixtures_ok 'basic_ss';

action_ok '/', 'a route handler is defined for /';
action_ok '/autocrud';
action_ok '/autocrud/bcs';
action_ok '/autocrud/bcs/organism';
action_ok '/autocrud/bcs/organism_dbxref';
action_ok '/autocrud/bcs/mimosa_sequence_set_organism';
action_ok '/autocrud/bcs/mimosa_sequence_set';
action_ok '/autocrud/bcs/organismprop';
