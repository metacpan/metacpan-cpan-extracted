use strict;
use Test::More;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use TestApp;
use Dancer::Test;

# replace with the actual test
ok 1;

my $res = dancer_response('GET' => '/');
# diag(Dumper(\$res)); use Data::Dumper;
is $res->content, 'blabla';

# ok(-e "$Bin/logs/fayland_test_$$.log"); # Dancer::Test do not generate any log file, FIXME

done_testing;
