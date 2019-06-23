use Test::More;
use Test::Output;
use DB::SQL::Migrations;
use DBI;
use DBD::mysql;

# Skip these tests if we are not running under Travis
if ($ENV{'TRAVIS'} eq 'true') {
	plan tests => 4;
} else {
	plan skip_all => 'These tests require Travis CI';
}

my $hostname = $ENV{'DBHOST'};
my $database = $ENV{'DBNAME'};
my $username = $ENV{'DBUSER'};
my $password = $ENV{'DBPASS'};

my $dbh;
ok($dbh = DBI->connect("DBI:mysql:database=$database;host=$hostname", $username, $password,
	{
		# Required for updates to work properly
		mysql_client_found_rows => 0,
		# Required to print symbols
		mysql_enable_utf8mb4 => 1,
	}
), 'connect to DB');

	#) or die "Couldn't connect to database: " . DBI->errstr);

my $migrator;
ok($migrator = DB::SQL::Migrations->new(dbh=>$dbh, migrations_directory=>'migrations'), 'set up migration object');

# Creates migrations table if it doesn't exist
ok($migrator->create_migrations_table(), 'create migrations table');

# Run migrations
stdout_unlike(sub {$migrator->apply();}, qr/Failed to apply migration/, 'run migrations');
