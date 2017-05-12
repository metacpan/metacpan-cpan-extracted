use strict;
use Test::More tests => 10;
use Bot::MetaSyntactic;

# check that the following functions are available
ok( exists &Bot::MetaSyntactic::init   ); #01
ok( exists &Bot::MetaSyntactic::said   ); #02
ok( exists &Bot::MetaSyntactic::help   ); #03

# create an object
my $bot = undef;
eval { $bot = new Bot::MetaSyntactic };
is( $@, ''                             ); #04
ok( defined $bot                       ); #05
ok( $bot->isa('Bot::MetaSyntactic')    ); #06
is( ref $bot, 'Bot::MetaSyntactic'     ); #07
 
# check that the following object methods are available
ok( ref $bot->can('init')          ); #08
ok( ref $bot->can('said')          ); #09
ok( ref $bot->can('help')          ); #10

