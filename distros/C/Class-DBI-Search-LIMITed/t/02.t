use strict;

use Test::More;

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 2);
}

package My::Foo;

use base 'Class::DBI::Test::SQLite';

__PACKAGE__->set_table('foo');
__PACKAGE__->columns(All => qw/id name year/);
__PACKAGE__->add_searcher(limsearch => 'Class::DBI::Search::LIMITed');

sub create_sql {
  return q{
    id     INTEGER PRIMARY KEY,
    name   CHAR(40),
    year   INT
  }
}


package main;

My::Foo->create({ id => 1, name => "Fred", year => 2001 });
My::Foo->create({ id => 2, name => "Will", year => 2001 });
My::Foo->create({ id => 3, name => "John", year => 2002 });
My::Foo->create({ id => 4, name => "Fred", year => 2002 });
My::Foo->create({ id => 5, name => "Jack", year => 2002 });

{
	my @ids = map $_->id, My::Foo->search(
		year => 2002, { order_by => 'id', limit => 2 });
	is_deeply \@ids, [3, 4, 5], "Not Limited";
}

{
	my @ids = map $_->id, My::Foo->limsearch(
		year => 2002, { order_by => 'id', limit => 2 });
	is_deeply \@ids, [3, 4], "Limited";
}

