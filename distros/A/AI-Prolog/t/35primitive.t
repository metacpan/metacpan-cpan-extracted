#!/usr/bin/perl
# '$Id: 35primitive.t,v 1.2 2005/06/20 07:36:48 ovid Exp $';
use warnings;
use strict;
#use Test::More 'no_plan';
use Test::More tests => 6;

my $CLASS;
BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $CLASS = 'AI::Prolog::TermList::Primitive';
    use_ok($CLASS) or die;
}

# XXX These are mostly stub tests.  I'm going to have to
# come back and flesh these out more

use aliased 'AI::Prolog::Parser';
use aliased 'AI::Prolog::Term';

can_ok $CLASS, 'new';
ok my $primitive = $CLASS->new(7),
    '... and creating a new primitive from a parser object should succeed';
isa_ok $primitive, $CLASS, '... and the object it creates';

can_ok $primitive, 'to_string';
is $primitive->to_string, ' <7> ',
    '... and its to_string representation should be correct';

