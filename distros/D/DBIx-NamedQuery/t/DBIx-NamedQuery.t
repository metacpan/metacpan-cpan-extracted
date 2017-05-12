use Test::More tests => 3;
use File::Spec ();


# Test 1: Load the module
BEGIN { use_ok('DBIx::NamedQuery', 'EXTEND_DBI') };


# Test 2: Load embedded queries
my $queries_loaded = DBIx::NamedQuery::load_named_queries();
is($queries_loaded, 2, "Number of loaded queries");


# Test 2: Load queries from external source
my $test_filename = 'test_queries.sql';
my $test_dir = (File::Spec->splitpath($0))[1];
my $test_file = File::Spec->catfile($test_dir, $test_filename);
my $external_queries_loaded = DBIx::NamedQuery::load_named_queries_from_file($test_file);
is ($external_queries_loaded, 3, "Number of queries loaded from $test_file");


__DATA__

--[present guests]
SELECT room_number, guest_name, check_in
FROM guests g, rooms r
WHERE g.room_id = r.room_id
	AND check_out IS NULL
ORDER BY room_number, guest_name

--[number of visits]
SELECT guest_name, passport_no, COUNT(*) AS number_of_visits,
	MAX(check_in) AS last_check_in
FROM guests
GROUP BY guest_name, passport_no
ORDER BY guest_name, passport_no
