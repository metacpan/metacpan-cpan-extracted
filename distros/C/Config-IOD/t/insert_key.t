#!perl

use 5.010;
use strict;
use warnings;

use Test::Config::IOD qw(test_modify_doc);
use Test::More 0.98;

subtest "insert_key" => sub {
    test_modify_doc({dies=>1}, sub { $_[0]->insert_key("s1", " ", "value") },
                    "[s1]\n", undef, 'validate key (1)');
    test_modify_doc({dies=>1}, sub { $_[0]->insert_key("s1", "a\nb", "value") },
                    "[s1]\n", undef, 'validate key (2)');
    test_modify_doc({dies=>1}, sub { $_[0]->insert_key("s1", "a=", "value") },
                    "[s1]\n", undef, 'validate key (3)');
    test_modify_doc({dies=>1}, sub { $_[0]->insert_key("s1", "[a]", "value") },
                    "[s1]\n", undef, 'validate key (4)');
    test_modify_doc({dies=>1}, sub { $_[0]->insert_key("s1", ";key", "value") },
                    "[s1]\n", undef, 'validate key (5)');
    test_modify_doc({dies=>1}, sub { $_[0]->insert_key("s1", "# key", "value") },
                    "[s1]\n", undef, 'validate key (5)');

    test_modify_doc({dies=>1}, sub { $_[0]->insert_key("s1", "key", "a\nb") },
                    "[s1]\n", undef, 'validate value (1)');

    test_modify_doc({dies=>1}, sub { $_[0]->insert_key("s1", "key", "value") },
                    "[s0]\n", undef, 'unknown section -> dies');

    test_modify_doc(sub { $_[0]->insert_key({create_section=>1}, "s1", "key", "value") },
                    <<'EOF1', <<'EOF2', 'opt:create_section=1 unknown section');
[s0]
EOF1
[s0]
[s1]
key=value
EOF2

    test_modify_doc({dies=>1}, sub { $_[0]->insert_key("s1", "a", "value") },
                    "[s1]\na=1\n", undef, 'already exists -> dies');

    test_modify_doc(sub { $_[0]->insert_key({ignore=>1}, "s1", "a", "value") },
                    <<'EOF1', <<'EOF2', 'opt:ignore=1 already exists -> noop');
[s1]
a=1
EOF1
[s1]
a=1
EOF2

    test_modify_doc(sub { $_[0]->insert_key({add=>1}, "s1", "a", "value") },
                    <<'EOF1', <<'EOF2', 'opt:add=1 already exists -> add');
[s1]
a=1
EOF1
[s1]
a=1
a=value
EOF2

    test_modify_doc(sub { $_[0]->insert_key({replace=>1}, "s1", "a", "value") },
                    <<'EOF1', <<'EOF2', 'opt:replace=1 already exists -> replace');
[s1]
a=1
EOF1
[s1]
a=value
EOF2

    test_modify_doc(sub { $_[0]->insert_key("s1", "key", "value") },
                    <<'EOF1', <<'EOF2', 'placement at the bottom (1)');
[s1]
EOF1
[s1]
key=value
EOF2

    test_modify_doc(sub { $_[0]->insert_key("s1", "key", "value") },
                    <<'EOF1', <<'EOF2', 'placement at the bottom (1)');
[s1]
a=1
b=2

[s2]
EOF1
[s1]
a=1
b=2

key=value
[s2]
EOF2

    test_modify_doc(sub { $_[0]->insert_key("s1", "key", "value") },
                    <<'EOF1', <<'EOF2', 'placement at the bottom (3)');
[s1]
a=1
b=2
EOF1
[s1]
a=1
b=2
key=value
EOF2

    test_modify_doc(sub { $_[0]->insert_key({top=>1}, "s1", "key", "value") },
                    <<'EOF1', <<'EOF2', 'opt:top=1 (1)');
[s1]
a=1
b=2
EOF1
[s1]
key=value
a=1
b=2
EOF2

    test_modify_doc({dies=>1}, sub { $_[0]->insert_key({linum=>1}, "s1", "key", "value") },
                    <<'EOF1', undef, 'validate linum (1)');
a=1
[s1]
EOF1

    test_modify_doc(sub { my $res = $_[0]->insert_key({linum=>5}, "s1", "key", "value"); is($res, 5, "return value") },
                    <<'EOF1', <<'EOF2', 'opt:linum');
a=1
[s1]
b=2
c=3
d=4
e=5
EOF1
a=1
[s1]
b=2
c=3
key=value
d=4
e=5
EOF2

};

DONE_TESTING:
done_testing;
