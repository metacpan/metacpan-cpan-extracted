#!perl -T
#
# $Id: /svn/DateTime-Event-Klingon/tags/VERSION_1_0_1/t/01-load.t 323 2008-04-01T06:37:25.246199Z jaldhar  $
#
use warnings;
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok('DateTime::Event::Klingon');
}

diag(
    "Testing DateTime::Event::Klingon $DateTime::Event::Klingon::VERSION, Perl $], $^X"
);
