package MyAppCreateDB;
	
	use MyApp::Schema;
	my $schema = MyApp::Schema->connect('dbi:SQLite:t/var/myapp.db', '', '',{});
	$schema->deploy({add_drop_table => 1});
	$schema->populate( 'Book', [
			[qw/id title rating/],
			[1, "Title_One", 3],
			[2, "Title_Two", 2],
			[3, "Title_Three is longer", 1],
			[4, "Title_Four", 1],
			[5, "Last Title", 5],
		]
	);
	$schema->populate( 'Author', [
			[qw/id first_name last_name/],
			[1, "Mr", "Spock"],
			[2, "Lord",  "Test"],
			[3, "Third", "Author"],
		]
	);
	$schema->populate( 'BookAuthor', [
			[qw/book_id author_id/],
			[1, 1],
			[1, 2],
			[1, 3],
			[2, 2],
			[2, 1],
			[3, 1],
			[4, 2],
			[5, 2],
			[5, 3],
		]
	);
1;
