use 5.022;
use warnings;
use strict;

use Test::More;
use Test::Prereq;
prereq_ok( undef, [
    'DBD::mysql',
    'Term::Choose::Constants',
    'Term::Choose::LineFold',
    'Term::Choose::Screen',
    'Win32::Console::ANSI',
 ] );
