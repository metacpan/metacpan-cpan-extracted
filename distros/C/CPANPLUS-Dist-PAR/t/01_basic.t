use Test::More 'no_plan';
use strict;

BEGIN { chdir 't' if -d 't' };
BEGIN { use lib '../lib';   };

my $Class   = 'CPANPLUS::Dist::PAR';

use_ok( $Class );

### check if the format is available
{   ok( $Class->format_available,   "$Class Format available" );

}
