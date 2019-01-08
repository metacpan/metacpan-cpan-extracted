# $Id: 01basic.t 70 2019-01-04 19:39:59Z stro $

use strict;
use warnings;
use Test::More;

plan tests => 4;

require_ok('CPAN::SQLite::Index');
require_ok('CPAN::SQLite::Search');
require_ok('CPAN::SQLite');
require_ok('CPAN::SQLite::META');
