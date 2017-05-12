use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings;

BEGIN {
    delete $ENV{a};
    @ENV{qw<b c d>} = ('', q{2 '3' "4 5"}, "7");
    @ARGV = ('8');
}

use ARGV::ENV qw<a b c d>;

is_deeply(\@ARGV, ['2', '3', '4 5', '8'], "full test");

