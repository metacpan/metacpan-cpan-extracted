use Test::More tests => 6;
use Test::DatabaseRow;

use strict;
use Bot::BasicBot::Pluggable;

use_ok( "Bot::BasicBot::Pluggable::Module::SimpleBlog" );
use_ok( "Bot::BasicBot::Pluggable::Module::SimpleBlog::Store::SQLite" );

my $bot = Bot::BasicBot::Pluggable->new( channels => [ "#test" ],
					 server   => "irc.example.com",
					 port     => "6667",
					 nick     => "bot",
					 username => "bot",
					 name     => "bot",
				       );
$bot->load( "SimpleBlog" );

my $blog_handler = $bot->handler( "SimpleBlog" );

eval {
    local $SIG{__WARN__} = { }; # we expect DBI to warn
    $blog_handler->set_store(
        Bot::BasicBot::Pluggable::Module::SimpleBlog::Store::SQLite
            ->new( "thisdoesnotexist/brane.db" )
    );
};
ok( $@, "set_store croaks when database file can't be created" );

eval {
    $blog_handler->set_store(
        Bot::BasicBot::Pluggable::Module::SimpleBlog::Store::SQLite
            ->new( "t/brane.db" )
    );
};
is( $@, "", "...but is fine when it can" );

my $store = Bot::BasicBot::Pluggable::Module::SimpleBlog::Store::SQLite
            ->new( "t/brane.db" );
isa_ok( $store, "Bot::BasicBot::Pluggable::Module::SimpleBlog::Store::SQLite");

my $dbh = $store->dbh;
$Test::DatabaseRow::dbh = $dbh;

my %test_data = (timestamp => "2003-03-19 08:09:56",
		 name      => "Kake",
		 channel   => "#london.pm",
		 url       => "http://london.pm.org/",
		 comment   => "perlmongers" );

$store->store( %test_data );

row_ok( table => "blogged",
	where => [ 1 => 1 ],
        tests => [ %test_data ],
	label => "can store stuff" );
