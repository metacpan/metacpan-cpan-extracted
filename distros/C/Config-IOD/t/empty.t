#!perl

use 5.010;
use strict;
use warnings;

use Test::Config::IOD qw(test_modify_doc);
use Test::More 0.98;

subtest "empty" => sub {
    test_modify_doc(sub { $_[0]->empty },
                    <<'EOF1', <<'EOF2', 'default');
a=1
[s1]
b=2
c=3
[s2]
EOF1
EOF2

};

DONE_TESTING:
done_testing;
