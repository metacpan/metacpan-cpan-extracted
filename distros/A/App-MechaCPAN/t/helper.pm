package App::MechaCPAN::t::Helper;

use App::MechaCPAN;

$App::MechaCPAN::QUIET  = 1;
$App::MechaCPAN::LOG_ON = 0;
$App::MechaCPAN::TIMEOUT = 0;

# Delete PERL_USE_UNSAFE_INC, it will interfere with our tests.
# This shouldn't be a problem for us since this helper has already benn
# included, this is so we can test the rest of our functionality
delete $ENV{PERL_USE_UNSAFE_INC};

1;
