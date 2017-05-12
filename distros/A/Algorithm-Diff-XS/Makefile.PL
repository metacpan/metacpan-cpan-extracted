use strict;
use lib '.';
use inc::Module::Install;

name            'Algorithm-Diff-XS';
license         'perl';
all_from        'lib/Algorithm/Diff/XS.pm';

can_cc or die "This module requires a C compiler";

requires        'Algorithm::Diff' => '1.19';
sign; WriteAll;
