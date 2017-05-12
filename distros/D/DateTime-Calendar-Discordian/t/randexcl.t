#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use DateTime::Calendar::Discordian;

my @excl = (
    'Hail Eris!',
    'All Hail Discordia!',
    'Kallisti!',
    'Fnord.',
    'Or not.',
    'Wibble.',
    'Pzat!',
    q{P'tang!},
    'Frink!',
    'Slack!',
    'Praise "Bob"!',
    'Or kill me.',
    'Grudnuk demand sustenance!',
    'Keep the Lasagna flying!',
    'Umlaut Zebra über alles!',
    'You are what you see.',
    'Or is it?',
    'This statement is false.',
    'Hail Eris, Hack Perl!',
);

ok(scalar grep { DateTime::Calendar::Discordian->new(
	  season => 'Confusion', day => 1, year => 0)->_randexcl
         } @excl, 
	'randexcl'
);

done_testing();
