#!/usr/bin/perl
# '$Id: 10choicepoint.t,v 1.2 2005/02/13 21:01:02 ovid Exp $';
use warnings;
use strict;
use Test::More tests => 11;

my $CLASS;
BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $CLASS = 'AI::Prolog::ChoicePoint';
    use_ok($CLASS) or die;
}

my $to_string_called = 0;
{
    package Goal;
    sub new       { bless {}=> shift }
    sub to_string { $to_string_called++; "some goal" }

    package Clause;
    sub new       { bless {}=> shift }
    sub to_string { $to_string_called++; "some clause" }
}

can_ok $CLASS, 'new';
ok my $cpoint = $CLASS->new(Goal->new, Clause->new), '... and calling it should succeed';
isa_ok $cpoint, $CLASS, '... and the object it returns';

can_ok $cpoint, 'goal';
isa_ok $cpoint->goal, 'Goal', '... and the object it returns';

can_ok $cpoint, 'clause';
isa_ok $cpoint->clause, 'Clause', '... and the object it returns';

can_ok $cpoint, 'to_string';
is $cpoint->to_string, '  ||some clause||   ',
    '... and it should return the right value';
ok $to_string_called, "... and call the goal's to_string method";
