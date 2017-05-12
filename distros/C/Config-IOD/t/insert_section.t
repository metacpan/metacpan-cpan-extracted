#!perl

use 5.010;
use strict;
use warnings;

use Test::Config::IOD qw(test_modify_doc);
use Test::More 0.98;

subtest "insert_section" => sub {
    test_modify_doc({dies=>1}, sub { $_[0]->insert_section("") },
                    '', undef, 'validate section (1)');
    test_modify_doc({dies=>1}, sub { $_[0]->insert_section("a\nb") },
                    '', undef, 'validate section (2)');
    test_modify_doc({dies=>1}, sub { $_[0]->insert_section("a]") },
                    '', undef, 'validate section (3)');

    test_modify_doc(sub { $_[0]->insert_section("s1") },
                    <<'EOF1', <<'EOF2', 'empty');
EOF1
[s1]
EOF2

    test_modify_doc(sub { $_[0]->insert_section("s1 ") },
                    <<'EOF1', <<'EOF2', 'clean section (1)');
EOF1
[s1]
EOF2

    test_modify_doc(sub { $_[0]->insert_section("s1") },
                    <<'EOF1', <<'EOF2', 'placed after other section');
[s0]
a=1
EOF1
[s0]
a=1
[s1]
EOF2

    test_modify_doc(sub { $_[0]->insert_section({top=>1}, "s1") },
                    <<'EOF1', <<'EOF2', 'opt:top=1 -> placed before other section');
[s0]
a=1
EOF1
[s1]
[s0]
a=1
EOF2

    test_modify_doc(sub { $_[0]->insert_section({top=>1}, "s1") },
                    <<'EOF1', <<'EOF2', 'opt:top=1 -> placed before other section (2)');
;comment
[s0]
a=1
EOF1
;comment
[s1]
[s0]
a=1
EOF2

    test_modify_doc({dies=>1}, sub { $_[0]->insert_section("s1") },
                    <<'EOF1', undef, 'existing section -> dies');
[s1]
EOF1

    test_modify_doc(sub { $_[0]->insert_section({ignore=>1}, "s1") },
                    <<'EOF1', <<'EOF2', 'opt:ignore=1 existing section -> noop');
[s1]
EOF1
[s1]
EOF2

    test_modify_doc(sub { $_[0]->insert_section({comment=>"foo"}, "s1") },
                    <<'EOF1', <<'EOF2', 'opt:comment');
EOF1
[s1] ;foo
EOF2

    test_modify_doc({dies=>1}, sub { $_[0]->insert_section({comment=>"a\nb"}, "s1") },
                    '', undef, 'validate comment (1)');

    test_modify_doc(sub { my $res = $_[0]->insert_section({linum=>2}, "s1"); is($res, 2, "return value") },
                    <<'EOF1', <<'EOF2', 'opt:linum');
a=1
b=2
c=3
EOF1
a=1
[s1]
b=2
c=3
EOF2

    test_modify_doc({dies=>1}, sub { $_[0]->insert_section({linum=>0}, "s1") },
                    '', undef, 'validate linum (1)');
    test_modify_doc({dies=>1}, sub { $_[0]->insert_section({linum=>2}, "s1") },
                    "a=1\n", undef, 'validate linum (2)');

};

DONE_TESTING:
done_testing;
