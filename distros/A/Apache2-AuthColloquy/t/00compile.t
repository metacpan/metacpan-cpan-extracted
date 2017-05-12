# $Id: 00compile.t,v 1.1 2006/01/07 11:58:06 nicolaw Exp $

chdir('t') if -d 't';
use lib qw(./lib ../lib);
use Test::More tests => 2;

use_ok('Apache2::AuthColloquy');
require_ok('Apache2::AuthColloquy');

