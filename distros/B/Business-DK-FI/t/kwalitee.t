#Courtesy of chromatic
#http://search.cpan.org/~chromatic/Test-Kwalitee/lib/Test/Kwalitee.pm

# $Id$

use strict;
use warnings;
use Env qw($TEST_AUTHOR);
use Test::More;

eval {
    require Test::Kwalitee;
};

if ($@ and $TEST_AUTHOR) {
    plan skip_all => 'Test::Kwalitee not installed; skipping';
} elsif (not $TEST_AUTHOR) {
    plan skip_all => 'set TEST_AUTHOR to enable this test';
} else {
    Test::Kwalitee->import();
}