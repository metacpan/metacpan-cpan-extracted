use strict;
use warnings;
use utf8;

use Test2::V0;
use Module::Spy;

use Acme::CoC::Dice;

my $target = 'Acme::CoC::Dice';

subtest '#role' => sub {
    subtest 'normal calling' => sub {
        my $spy_role_skill = spy_on($target, 'role_skill')->and_call_through;

        $spy_role_skill->calls_reset;
        my $result = $target->role('1d100');
        is @{ $result->{dices} }, 1;
        for my $item (@{ $result->{dices} }) {
            ok $item >= 1 && $item <= 100, "1 <= result <= 100: $item";
            ok !$spy_role_skill->called, 'role_skill was not called';
        }

        $spy_role_skill->calls_reset;
        $result = $target->role('10d10');
        is @{ $result->{dices} }, 10;
        for my $item (@{ $result->{dices} }) {
            ok $item >= 1 && $item <= 10, "1 <= result <= 10: $item";
            ok !$spy_role_skill->called, 'role_skill was not called';
        }

        $spy_role_skill->calls_reset;
        $result = $target->role('skill');
        is @{ $result->{dices} }, 1;
        for my $item (@{ $result->{dices} }) {
            ok $item >= 1 && $item <= 100, "1 <= result <= 100: $item";
            ok $spy_role_skill, 'role_skill was called';
        }
    };
};

done_testing;
