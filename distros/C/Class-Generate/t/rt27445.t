#!/usr/bin/perl

# Regression test for https://rt.cpan.org/Ticket/Display.html?id=27445 .
#
# Seems to be working fine now, but adding it here just in case.
#
# Thanks to roman.yepishev@gmail.com

use strict;
use warnings;

use Test::More tests => 1;

use Class::Generate qw(class subclass);

class MyTest => [ '&createNewClass' => <<'EOF'
    subclass MySubTest => [ '&ISA' => 'return @ISA;' ], -parent => 'MyTest';
EOF
    ],
    -use => ['Class::Generate qw(class subclass)']
    ;

my $d = MyTest->new();
$d->createNewClass();

# TEST
ok (1, "createNewClass worked fine for RT #27445");
