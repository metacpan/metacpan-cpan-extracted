
use strict;
use Test::More 'no_plan';
use Test::Fatal;
$| = 1;



# =begin testing SETUP
use Test::Requires {
    'NOT::A::VALID::MODULE'     => '0',
};
