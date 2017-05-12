#!perl -T

use strict;
use warnings;
use Test::More tests => 5;

use Bot::BasicBot::Pluggable::Module::XKCD;

sub mk_args {
    my $text = shift;
    return (undef, {body => $text} );
}

sub told {
    Bot::BasicBot::Pluggable::Module::XKCD::told(mk_args(@_));
}

is(told('something'), '', "doesn't respond to other commands");
like(told('xkcd'), qr{.* - http://xkcd\.com/(\d+/)?}, "'xkcd' reply looks sane");
like(told('xkcd mark'), qr{.* - http://xkcd\.com/\d+/}, "'xkcd mark' reply looks sane");
is(told('xkcd aqswdefd'), "Couldn't get comic", "unmatching comic returns error");
is(told('xkcd 1'), 'Barrel - Part 1 - http://xkcd.com/1/', "'xkcd 1' is correct");
