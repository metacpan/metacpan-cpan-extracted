# vim: set ft=perl :

use Test::More tests => 9;
BEGIN { use_ok('Class::DBI::DDL'); }

Folk->create_table(sub {
	Folk->create({first_name => 'Bob',       last_name => 'Tomato' });
	Folk->create({first_name => 'Larry',     last_name => 'Cucumber' });
	Folk->create({first_name => 'Archibald', last_name => 'Asparagus' });
});
Favorite->create_table(sub {
	Folk->retrieve(1)->add_to_favorites({color => 'Red'});
	Folk->retrieve(1)->add_to_favorites({color => 'Blue'});
	Folk->retrieve(2)->add_to_favorites({color => 'Green'});
});

ok(grep /^folks$/, MyDBI->_list_tables);
ok(grep /^favorites$/, MyDBI->_list_tables);

is(Folk->retrieve(1)->first_name, 'Bob');
is(Folk->retrieve(2)->first_name, 'Larry');
is(Folk->retrieve(3)->first_name, 'Archibald');

my @favorites = Folk->retrieve(2)->favorites;
is($favorites[0]->color, 'Green');

Favorite->drop_table;
Folk->drop_table;

ok(!grep /^folks$/, MyDBI->_list_tables);
ok(!grep /^favorites$/, MyDBI->_list_tables);

1
