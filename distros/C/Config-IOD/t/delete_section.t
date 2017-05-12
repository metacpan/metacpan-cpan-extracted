#!perl

use 5.010;
use strict;
use warnings;

use Test::Config::IOD qw(test_modify_doc);
use Test::More 0.98;

subtest "delete_section" => sub {
    test_modify_doc(sub { my $res = $_[0]->delete_section("s3"); is($res, 0, "return value") },
                    <<'EOF1', <<'EOF2', 'unknown section -> noop');
a=1
[s1]
b=2
c=3
[s2]
d=4
[s1]
EOF1
a=1
[s1]
b=2
c=3
[s2]
d=4
[s1]
EOF2

    test_modify_doc(sub { my $res = $_[0]->delete_section("s1"); is($res, 1, "return value") },
                    <<'EOF1', <<'EOF2', 'default');
a=1
[s1]
b=2
c=3
[s2]
d=4
[s1]
EOF1
a=1
[s2]
d=4
[s1]
EOF2

    test_modify_doc(sub { my $res = $_[0]->delete_section("s3"); is($res, 1, "return value") },
                    <<'EOF1', <<'EOF2', 'default (last section)');
a=1
[s1]
b=2
c=3
[s2]
d=4
[s3]
e=5
EOF1
a=1
[s1]
b=2
c=3
[s2]
d=4
EOF2

    test_modify_doc(sub { my $res = $_[0]->delete_section({all=>1}, "s1"); is($res, 2, "return value") },
                    <<'EOF1', <<'EOF2', 'opt:all=1');
a=1
[s1]
b=2
c=3
[s2]
d=4
[s1]
EOF1
a=1
[s2]
d=4
EOF2


    test_modify_doc(sub { my $res = $_[0]->delete_section({all=>1, cond=>sub{ my ($self, %args) = @_; return $args{linum_start} < $args{linum_end} ? 0:1} }, "s"); is($res, 1, "return value") },
                    <<'EOF1', <<'EOF2', 'opt:cond');
[s]
a=1
[s]
[s]
b=2

EOF1
[s]
a=1
[s]
b=2

EOF2

};

DONE_TESTING:
done_testing;
