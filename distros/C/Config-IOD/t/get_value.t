#!perl

use 5.010;
use strict;
use warnings;

use Config::IOD;
use Test::More 0.98;

my $doc = Config::IOD->new->read_string(<<'EOF');
a=1
c=3

[s1]
!merge GLOBAL
a=0
b=[2]

[s2]
!merge
b=20
c=!json "foo"

EOF

is_deeply($doc->get_value("GLOBAL", "a"), 1);
is_deeply($doc->get_value("s1", "a"), 0);
is_deeply($doc->get_value("s1", "b"), [2]);
is_deeply($doc->get_value("s1", "c"), 3);
is_deeply($doc->get_value("s2", "b"), 20);
is_deeply($doc->get_value("s2", "c"), "foo");
is_deeply($doc->get_value("s2", "d"), undef);
is_deeply($doc->get_value("s3", "a"), undef);

done_testing;
