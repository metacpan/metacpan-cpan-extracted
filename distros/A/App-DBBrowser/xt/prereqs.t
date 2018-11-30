use 5.010000;
use warnings;
use strict;

use Test::More;
use Test::Prereq;
prereq_ok( undef, [
    'Win32::Console',
    'Win32::Console::ANSI',
 ] );
