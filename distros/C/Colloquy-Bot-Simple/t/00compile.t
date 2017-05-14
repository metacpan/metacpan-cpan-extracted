# $Id: 00compile.t 516 2006-05-29 11:22:09Z nicolaw $

chdir('t') if -d 't';
use lib qw(./lib ../lib);
use Test::More tests => 2;

use_ok('Colloquy::Bot::Simple');
require_ok('Colloquy::Bot::Simple');

