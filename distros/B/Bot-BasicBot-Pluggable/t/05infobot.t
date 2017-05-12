#!perl
use warnings;
use strict;
use Test::More tests => 89;
use Test::Bot::BasicBot::Pluggable;

use FindBin qw( $Bin );
use lib $Bin;

my $bot = Test::Bot::BasicBot::Pluggable->new();

ok( my $ib = $bot->load("Infobot"), "Loaded infobot module" );

ok( my $uur = $ib->get("user_unknown_responses"),
    "got list of unknown responses" )
  or die;
my $no_regex = qr/($uur)/;

# ok, the intent here is to test / document the infobot grammar, because
# every time I mess with it I get annoying regressions. In general, B::B::P
# wasn't built with Test-Driven techniques, and this is hurting me recently,
# it's way too hard to write tests retroactively..

ok( $ib->help, "module has help text" );

# by default, the infobot doesn't learn things that it merely overhears
ok( !$bot->tell_indirect("foo is red"), "passive learning off by default" );
ok( !$bot->tell_indirect("foo?"),       "no answer to passive learn" );
like( $bot->tell_direct("foo?"), $no_regex, "no info on foo" );

# ..but it will learn things it's told $bot->tell_directly.
like( $bot->tell_direct("foo?"), $no_regex, "no info on foo" );
is( $bot->tell_direct("foo is red"), "Okay.", "active learning works" );
is( $bot->tell_direct("foo?"), "foo is red", "correct answer to active learn" );

like( $bot->tell_direct("quux?"), $no_regex, "no info on quux" );
is( $bot->tell_direct("quux are blue"), "Okay.", "active learning works" );
is(
    $bot->tell_direct("quux?"),
    "quux are blue",
    "correct answer to active learn"
);

# you can tell someone about foo
is(
    $bot->tell_direct("tell testbot about foo"),
    "Told testbot about foo.",
    "tell someone about foo"
);

ok( !$bot->tell_indirect("foo?"), "passive questioning off by default" );

# you can turn on the ability to ask questions without addressing the bot
ok( $ib->set( "user_passive_answer", 1 ), "activate passive ask" );
is( $bot->tell_indirect("foo?"), "foo is red", "passive questioning now on" );

# and the ability to add factoids without addressing the bot
ok( $ib->set( "user_passive_learn", 1 ), "activate passive learn" );
is( $bot->tell_direct("bar is green"), "Okay.", "passive learning now works" );
is( $bot->tell_indirect("bar?"), "bar is green", "passive questioning works" );

# you can search factoids, but not in public
is(
    $bot->tell_direct("search for foo"),
    "privmsg only, please",
    "not searched in public"
);
$ib->set( "user_allow_searching", 0 );
is(
    $bot->tell_private("search for foo"),
    "searching disabled",
    "searched for 'foo' disabled"
);
$ib->set( "user_allow_searching", 1 );
is(
    $bot->tell_private("search for foo"),
    "I know about: 'foo'.",
    "searched for 'foo'"
);
is(
    $bot->tell_private("search for foobar"),
    "I don't know anything about foobar.",
    "searched for 'foobar' (which we know nothing about)"
);
is(
    $bot->tell_private("search for foo bar"),
    "I know about: 'foo', 'bar'.",
    "searched for 'foo' and 'bar'"
);
$ib->set( 'user_num_results' => 1 );
is(
    $bot->tell_private("search for foo bar"),
    "I know about: 'foo'.",
    "searched for 'foo' and 'bar' with user_num_results set to 1"
);

# you can append strings to factoids
is( $bot->tell_direct("foo is also blue"), "Okay.", "can append to faactoids" );
is( $bot->tell_direct("foo?"), "foo is red or blue", "works" );
is( $bot->tell_direct("foo is also pink"), "Okay.", "can append to faactoids" );
is( $bot->tell_direct("foo?"), "foo is red or blue or pink", "works" );

# factoids can be forgotten
is( $bot->tell_direct("forget foo"), "I forgot about foo.", "forgotten foo" );
like( $bot->tell_direct("foo?"), $no_regex, "no info on foo" );
is(
    $bot->tell_direct("forget foo"),
    "I don't know anything about foo.",
    "can't forget something i don't know"
);

# factoids can be replaced
my $but_reply =
  '... but bar is green ...';    # ok, why does this get interpreted as '1'
is( $bot->tell_direct("bar is yellow"),
    $but_reply, "Can't just redefine factoids" );
is( $bot->tell_indirect("bar is yellow"), '', "Can't just redefine factoids" );
is( $bot->tell_indirect("bar?"), "bar is green", "not changed" );
is( $bot->tell_direct("no, bar is yellow"),
    "Okay.", "Can explicitly redefine factoids" );
is( $bot->tell_indirect("bar?"), "bar is yellow", "changed" );

# factoids can contain RSS
SKIP: {
    eval "use XML::Feed";
    skip 'XML::Feed not installed', 4 if $@;

    is( $bot->tell_direct("rsstest is <rss=\"file:///$Bin/test.rss\">"),
        "Okay.", "set RSS" );
    is( $bot->tell_indirect("rsstest?"), "title", "can read rss" );
    $bot->tell_direct("rsstest2 is <rss=\"file:///$Bin/05infobot.t\">");
    like(
        $bot->tell_indirect("rsstest2?"),
qr{rsstest2 is << Error parsing RSS from file:///.*/05infobot.t: Cannot detect feed type >>},
        "can't read rss"
    );
    is(
        $bot->tell_direct("literal rsstest?"),
        "rsstest =is= <rss=\"file:///$Bin/test.rss\">",
        "literal of rsstest"
    );
}

my $old_stopwords = $ib->get("user_stopwords");

# certain things can't be factoid keys.
ok( $ib->set( "user_stopwords", "and" ), "set stopword 'and'" );
ok( !$bot->tell_direct("and is mumu"), "can't set 'and' as factoid" );
ok( !$bot->tell_direct("dkjsdlfkdsjfglkdsfjglfkdjgldksfjglkdfjglds is mumu"),
    "can't set very long factoid" );

$ib->set( "user_stopwords", $old_stopwords );

# literal syntax
ok( $bot->tell_direct("bar is also fum"), "bar also fum" );
is( $bot->tell_direct("literal bar?"), "bar =is= yellow =or= fum", "bar" );

# alternate factoids ('|')
is( $bot->tell_direct("foo is one"),         "Okay.", "foo is one" );
is( $bot->tell_direct("foo is also two"),    "Okay.", "foo is also two" );
is( $bot->tell_direct("foo is also |maybe"), "Okay.", "foo is also maybe" );

ok( my $reply = $bot->tell_direct("foo?"), "got one of the foos" );
ok( ( $reply eq 'foo is maybe' or $reply eq 'foo is one or two' ),
    "it's one of the two" );

# blech's torture test, all three in one
# notes on dipsy differences:
# * 'ok' is 'okay.' in a true infobot
# * literal doesn't highlight =or= like it does =is=
# * infobots attempt to parse english
# * there's a difference between 'is' and 'are'
# * doesn't respond to a passive attempt to reset an item

is( $bot->tell_direct("forget foo"), "I forgot about foo.", "forgotten foo" );

is( $bot->tell_direct("foo is foo"),   "Okay.",      "simple set" );
is( $bot->tell_direct("foo?"),         "foo is foo", "simple get" );
is( $bot->tell_direct("what is foo?"), "foo is foo", "English-language get" )
  ;    # fails
is( $bot->tell_direct("where is foo?"), "foo is foo", "Another English get" );
is( $bot->tell_direct("who is foo?"), "foo is foo", "Yet another English get" );

is( $bot->tell_direct("hoogas are things"), "Okay.", "simple 'are' set" )
  ;    # fails
is(
    $bot->tell_direct("what are hoogas?"),
    "hoogas are things",
    "English-language 'are' get"
);

is(
    $bot->tell_direct("foo is a silly thing"),
    "... but foo is foo ...",
    "warning about overwriting"
);
is( $bot->tell_indirect("foo is a silly thing"), "", "shouldn't get a reply" );

is( $bot->tell_direct("foo is also bar"), "Okay.", "simple append" );
is( $bot->tell_direct("foo?"), "foo is foo or bar", "appended ok" );
is( $bot->tell_direct("foo is also baz or quux"), "Okay.", "complex append" );
is( $bot->tell_direct("foo?"), "foo is foo or bar or baz or quux", "also ok" );
is( $bot->tell_direct("foo is also | a silly thing"),
    "Okay.", "alternate appended" );

is(
    $bot->tell_direct("literal foo?"),
    "foo =is= foo =or= bar =or= baz =or= quux =or= |a silly thing",
    "entire factoid looks right"
);
is( $bot->tell_direct("foo is also |<reply>this is a very silly thing"),
    "Okay.", "and a reply" );
is(
    $bot->tell_direct("literal foo?"),
"foo =is= foo =or= bar =or= baz =or= quux =or= |a silly thing =or= |<reply>this is a very silly thing",
    "entire entry looks fine to me"
);

# run through a few times, and see what we get out
foreach my $i ( 0 .. 9 ) {
    ok( $reply = $bot->tell_direct("foo?"), "got one of the foos" );
    ok(
        (
                 $reply eq 'foo is foo or bar or baz or quux'
              or $reply eq 'foo is a silly thing'
              or $reply eq 'this is a very silly thing'
        ),
        "it's '$reply'"
    );
}
