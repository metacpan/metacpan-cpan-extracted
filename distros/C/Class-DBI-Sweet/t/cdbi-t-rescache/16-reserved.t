use strict;
use Test::More;
use Class::DBI::Sweet;
Class::DBI::Sweet->default_search_attributes({ use_resultset_cache => 1 });
Class::DBI::Sweet->cache(Cache::MemoryCache->new(
    { namespace => "SweetTest", default_expires_in => 60 } ) ); 

BEGIN {
	eval "use Cache::MemoryCache";
	plan skip_all => "needs Cache::Cache for testing" if $@;
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 5);
}

use lib 't/cdbi-t/testlib';
require Film;
require Order;

Film->has_many(orders => 'Order');
Order->has_a(film => 'Film');

Film->create_test_film;

my $film = Film->retrieve('Bad Taste');
isa_ok $film => 'Film';

$film->add_to_orders({ orders => 10 });

my $bto = Order->search(film => 'Bad Taste')->first;
isa_ok $bto => 'Order';
is $bto->orders, 10, "Correct number of orders";


my $infilm = $bto->film;
isa_ok $infilm, "Film";

is $infilm->id, $film->id, "Orders hasa Film";
