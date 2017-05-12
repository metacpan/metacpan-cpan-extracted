#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 27;
use Test::Bot::BasicBot::Pluggable;

my $bot   = Test::Bot::BasicBot::Pluggable->new();
my $karma = $bot->load('Karma');

## We start testing without giving any reasons
$karma->set( "user_num_comments", 0 );

is(
    $bot->tell_indirect('karma alice'),
    'alice has karma of 0.',
    'inital karma of alice'
);
is(
    $bot->tell_indirect('explain karma alice'),
    'positive: 0; negative: 0; overall: 0.',
    'explain initial karma of alice'
);

$bot->tell_indirect('alice--');
is(
    $bot->tell_indirect('karma alice'),
    'alice has karma of -1.',
    'karma of alice after first --'
);

$bot->tell_indirect('alice++');
$bot->tell_indirect('alice++');
is(
    $bot->tell_indirect('karma alice'),
    'alice has karma of 1.',
    'karma of alice after first ++'
);

$bot->tell_indirect('alice++');
is(
    $bot->tell_indirect('karma alice'),
    'alice has karma of 2.',
    'karma of alice after second ++'
);

is(
    $bot->tell_indirect('explain karma alice'),
    'positive: 3; negative: 1; overall: 2.',
    'explain karma of Alice'
);

is( $bot->tell_indirect('test_bot++'),
    'Karma for test_bot is now 1 (thanks!)', 'thanking for karming up bot' );
is( $bot->tell_indirect( 'test_bot--', 'alice' ),
    'Karma for test_bot is now 0 (pffft)', 'complaining about karming down bot' );

$bot->tell_indirect('test_user++');
test_karma( 'test_user', 0, 'user is not allowed to use positiv selfkarma' );

$bot->tell_indirect('test_user--');
test_karma( 'test_user', 0, 'user is not allowed to use negative selfkarma' );

$karma->set( 'user_ignore_selfkarma', 0 );

$bot->tell_indirect('test_user++');
test_karma( 'test_user', 1, 'user is allowed to use positive selfkarma' );

$bot->tell_indirect('test_user--');
test_karma( 'test_user', 0, 'user is allowed to use negativ selfkarma' );

is(
    $karma->help(),
'Gives karma for or against a particular thing. Usage: <thing>++ # comment, <thing>-- # comment, karma <thing>, explain <thing>.',
    'help for karma'
);

is(
    $bot->tell_indirect('karma'),
    'test_user has karma of 0.',
    'asking for own karma without arguments'
);

is( $bot->tell_indirect( 'foobar', 'alice' ),
    '', 'ignoring karma unrelated issues' );

$bot->tell_indirect('(alice code)--');
is(
    $bot->tell_indirect('karma alice code'),
    'alice code has karma of -1.',
    'decrease karma of things with spaces '
);

$bot->tell_indirect('(alice code)++');
is(
    $bot->tell_indirect('karma alice code'),
    'alice code has karma of 0.',
    'increasing karma of things with spaces '
);

$bot->tell_indirect('alice: ++');
is(
    $bot->tell_indirect('karma alice'),
    'alice has karma of 2.',
    'positiv karma in sentance'
);

is( $bot->tell_indirect( 'explain', '' ),
    '', 'ignore explain without argument' );

is( $bot->tell_indirect('++'), '', 'ignoring ++ without thing or address' );
is( $bot->tell_indirect('--'), '', 'ignoring -- without thing or address' );

## Now we start testing reasons
$karma->set( "user_num_comments",      2 );
$karma->set( "user_show_givers",       0 );
$karma->set( "user_randomize_reasons", 0 );

$bot->tell_indirect('alice++ # good cipher');
is(
    $bot->tell_indirect('explain alice'),
    'positive: good cipher; negative: nothing; overall: 3.',
    'explaining karma of alice with one positive reason'
);

$bot->tell_indirect('alice-- # bad cipher');
is(
    $bot->tell_indirect('explain alice'),
    'positive: good cipher; negative: bad cipher; overall: 2.',
    'explaining karma of alice with one positive and negative reason'
);

$bot->tell_indirect('alice-- # Friend of Eve');
is(
    $bot->tell_indirect('explain alice'),
    'positive: good cipher; negative: Friend of Eve, bad cipher; overall: 1.',
    'explaining karma of alice with one positive and two negative reason'
);

$bot->tell_indirect('alice-- # Friend of Mallory');
is(
    $bot->tell_indirect('explain alice'),
'positive: good cipher; negative: Friend of Mallory, Friend of Eve; overall: 0.',
'explaining karma of alice with more than two reasons (user_num_commments=2)'
);

$karma->set( "user_show_givers", 1 );

is(
    $bot->tell_indirect('explain alice'),
'positive: good cipher (test_user); negative: Friend of Mallory (test_user), Friend of Eve (test_user); overall: 0.',
    'explaining karma of alice with reasons and givers'
);

$karma->set( "user_randomize_reasons", 1 );

{
    my %explanations;
    for ( 1 .. 100 ) {
        $explanations{ $bot->tell_indirect('explain alice') }++;
    }
    is( keys %explanations, 6, 'Testing randomness of reason list... (uh!)' )
}

sub test_karma {
    my ( $thing, $value, $message ) = @_;
    is( $karma->get_karma($thing), $value, $message );
}
