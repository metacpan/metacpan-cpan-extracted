#!perl

use 5.010;
use strict;
use warnings;

use Test::Config::IOD qw(test_modify_doc);
use Test::More 0.98;

subtest "delete_key" => sub {
    test_modify_doc(sub { my $res = $_[0]->delete_key("s3", "a"); is($res, 0, "return value") },
                    <<'EOF1', <<'EOF2', 'unknown section -> noop');
a=1
[s1]
b=2
c=3
c = 3b
[s2]
d=4
[s1]
EOF1
a=1
[s1]
b=2
c=3
c = 3b
[s2]
d=4
[s1]
EOF2

    test_modify_doc(sub { my $res = $_[0]->delete_key("s1", "x"); is($res, 0, "return value") },
                    <<'EOF1', <<'EOF2', 'unknown key -> noop');
a=1
[s1]
b=2
c=3
c = 3b
[s2]
d=4
[s1]
EOF1
a=1
[s1]
b=2
c=3
c = 3b
[s2]
d=4
[s1]
EOF2

    test_modify_doc(sub { my $res = $_[0]->delete_key("s1", "c"); is($res, 1, "return value") },
                    <<'EOF1', <<'EOF2', 'default');
a=1
[s1]
b=2
c=3
c = 3b
[s2]
d=4
[s1]
EOF1
a=1
[s1]
b=2
c = 3b
[s2]
d=4
[s1]
EOF2

    test_modify_doc(sub { my $res = $_[0]->delete_key({all=>1}, "s1", "c"); is($res, 2, "return value") },
                    <<'EOF1', <<'EOF2', 'opt:all=1');
a=1
[s1]
b=2
c=3
c = 3b
[s2]
d=4
[s1]
EOF1
a=1
[s1]
b=2
[s2]
d=4
[s1]
EOF2

    test_modify_doc(sub { my $res = $_[0]->delete_key({all=>1, cond=>sub { my ($self, %args) = @_; return $args{raw_value} % 2 == 0 ? 1:0 }}, "s", "a"); is($res, 2, "return value") },
                              <<'EOF1', <<'EOF2', 'opt:cond');
[s]
a=1
a=2
a=3
a=4
EOF1
[s]
a=1
a=3
EOF2

};

DONE_TESTING:
done_testing;
