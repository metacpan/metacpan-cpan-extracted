# $Id: 01basic.t 31 2011-06-12 22:56:18Z stro $

use strict;
use warnings;
use Test::More;
BEGIN {plan tests => 4};
for (qw(CPAN::SQLite::Index CPAN::SQLite::Search
        CPAN::SQLite CPAN::SQLite::META)) {
  require_ok($_);
}
