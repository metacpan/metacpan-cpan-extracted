# make test
# perl Makefile.PL; make; perl -Iblib/lib t/19_serialize.t

use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 1;

ok_ref( [serialize({1=>2,2=>3})], ['(\'1\'=>\'2\',
\'2\'=>\'3\'
)'] );

#TODO: lots
