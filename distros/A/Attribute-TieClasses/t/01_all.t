use warnings;
use strict;
use lib 't/testlib';
use Attribute::TieClasses;
use Test::More tests => 1;
my $st : __TEST;
my @st : __TEST;
my %st : __TEST;
pass('still alive (well, it compiled)');
