use strict;
use FindBin;
use Test::More tests => 1;
use lib ( "$FindBin::Bin/../lib" );

BEGIN { use_ok('Catalyst::Log::Log4perl') }
