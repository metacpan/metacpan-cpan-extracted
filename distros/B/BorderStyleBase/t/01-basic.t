#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use BorderStyle::Test::CustomChar;
use BorderStyle::Test::Labeled;

subtest new => sub {
    dies_ok  { BorderStyle::Test::CustomChar->new } "missing required arg";
    dies_ok  { BorderStyle::Test::CustomChar->new(character=>"x", foo=>1) } "unknown arg";
    lives_ok { BorderStyle::Test::CustomChar->new(character=>"x") };
};

subtest get_border_char => sub {
    my $bs = BorderStyle::Test::Labeled->new;
    is($bs->get_border_char(0, 0), "A");
    is($bs->get_border_char(0, 1, 3), "BBB");

    my $bs2 = BorderStyle::Test::CustomChar->new(character=>"x");
    is($bs2->get_border_char(0, 0, 3), "xxx");
};

subtest get_struct => sub {
    my $bs = BorderStyle::Test::Labeled->new;
    my $struct = $bs->get_struct;
    is(ref($struct), 'HASH');
    is(ref($struct->{chars}), 'ARRAY');
};

subtest get_args => sub {
    my $bs = BorderStyle::Test::CustomChar->new(character=>"x");
    is_deeply($bs->get_args, {character=>"x"});
};

done_testing;
