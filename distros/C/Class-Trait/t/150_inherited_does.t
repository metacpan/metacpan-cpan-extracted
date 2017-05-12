#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    unshift @INC => ( 't/test_lib', '/test_lib' );
}

{
    package P1;
    use Class::Trait qw(TBomb);
}
{
    package P2;
    use base qw(P1);
}

ok +P1->does('TBomb'), 'Traits should do what traits should do';
ok +P2->does('TBomb'), '... and so should their subclasses';
