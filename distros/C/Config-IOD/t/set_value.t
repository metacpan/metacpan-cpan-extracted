#!perl

use 5.010;
use strict;
use warnings;

use Test::Config::IOD qw(test_modify_doc);
use Test::More 0.98;

subtest "set_value" => sub {
    test_modify_doc(sub { $_[0]->set_value("s1", "key", 2) },
                    <<'EOF1', <<'EOF2', 'found');
[s1]
key=1
EOF1
[s1]
key=2
EOF2

    test_modify_doc({dies=>1}, sub { $_[0]->set_value("s1", "key", "\n2") },
                    <<'EOF1', undef, 'validation');
[s1]
key=1
EOF1

    test_modify_doc(sub { $_[0]->set_value("s1", "key", 2) },
                    <<'EOF1', <<'EOF2', 'key not found');
[s1]
key2=1
EOF1
[s1]
key2=1
EOF2

    test_modify_doc(sub { $_[0]->set_value("s1", "key", 2) },
                    <<'EOF1', <<'EOF2', 'section not found');
[s2]
key=1
EOF1
[s2]
key=1
EOF2

};

DONE_TESTING:
done_testing;
