use v5.10;
use strict;
use warnings;

use Test::More;

use_ok('App::HL7::Compare');
isa_ok App::HL7::Compare->new(files => ['a', 'b']), 'App::HL7::Compare';

done_testing;

