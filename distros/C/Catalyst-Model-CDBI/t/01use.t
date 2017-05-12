use strict;
use Test::More tests => 3;

BEGIN { use_ok('Catalyst::Model::CDBI') }
BEGIN { use_ok('Catalyst::Helper::Model::CDBI') }

use MRO::Compat;
ok(eval { mro::get_linear_isa('Catalyst::Model::CDBI'); 1 }, 'Linearise ok');
