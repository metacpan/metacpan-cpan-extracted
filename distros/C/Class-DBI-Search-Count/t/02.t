use strict;

use Test::More;

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 5);
}

package My::Foo;

use base 'Class::DBI::Test::SQLite';

__PACKAGE__->set_table('foo');
__PACKAGE__->columns(All => qw/id name year/);
__PACKAGE__->add_searcher(search_count => 'Class::DBI::Search::Count');

sub create_sql {
  return q{
    id     INTEGER PRIMARY KEY,
    name   CHAR(40),
    year   INT
  }
}


package main;

My::Foo->create({ name => "Fred", year => 2001 });
My::Foo->create({ name => "Will", year => 2001 });
My::Foo->create({ name => "John", year => 2002 });
My::Foo->create({ name => "Fred", year => 2002 });
My::Foo->create({ name => "Jack", year => 2002 });

is +My::Foo->search_count(year => 2001), 2, "2 x 2001";
is +My::Foo->search_count(year => 2002), 3, "3 x 2002";
is +My::Foo->search_count(year => 2003), 0, "0 x 2002";
is +My::Foo->search_count(name => "Fred"), 2, "2 x Fred";
is +My::Foo->search_count(name => "Fred", year => 2001), 1, "1 x Fred01";

