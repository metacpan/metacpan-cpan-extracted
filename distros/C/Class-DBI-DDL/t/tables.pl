{
	package Folk;
	use base 'MyDBI';

	Folk->table('folks');
	Folk->columns(Primary => 'fid');
	Folk->columns(Essential => qw(first_name last_name));
	Folk->has_many(favorites => 'Favorite');

	Folk->column_definitions([
		[ fid        => 'int', 'not null', 'auto_increment' ],
		[ first_name => 'varchar(20)', 'not null' ],
		[ last_name  => 'varchar(20)', 'not null' ],
	]);
}

{
	package Favorite;
	use base 'MyDBI';

	Favorite->table('favorites');
	Favorite->columns(Primary => 'favid');
	Favorite->columns(Essential => qw(folk color));
	Favorite->has_a(folk => 'Folk');

	Favorite->column_definitions([
		[ favid => 'int', 'not null', 'auto_increment' ],
		[ folk  => 'numeric(10)', 'not null' ],
		[ color => 'varchar(15)', 'not null' ],
	]);

	Favorite->index_definitions([
		 [ Foreign => 'folk', 'Folk', 'fid' ],
	]);
}

1
