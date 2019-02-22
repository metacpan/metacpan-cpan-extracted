use 5.010000;
use warnings;
use strict;

use Test::More;
use Test::Prereq;
prereq_ok( undef, [
    'Term::Choose::Constants',
    'Term::Choose::LineFold',
    'Win32::Console',
    'Win32::Console::ANSI',
 ] );
