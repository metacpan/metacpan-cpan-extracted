package main;

use 5.008;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

diag 'Modules required for development';

require_ok 'SOAP::Lite';

require_ok 'Time::HiRes';

require_ok 'XML::Parser';

# require_ok 'XML::Parser::Lite';

require_ok 'YAML';

done_testing;

1;

# ex: set textwidth=72 :
