use lib 'lib';
use Apache::SWIT::Test::Apache;
use File::Slurp;
use File::Basename qw(dirname);
use File::Path qw(mkpath rmtree);
use Apache::SWIT::Maker::Skeleton::Startup;
use Test::TempDatabase;
use Apache::SWIT::DB::Connection;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);

my $test_db;
unlink("/tmp/swit_startup_test");
my $d = abs_path(dirname($0));
my $td;
unless ($<) {
	$td = tempdir("/tmp/swit_root_test_XXXXXX");
	print STDERR "# Running as root in $td\n";
	system("cp -a $d/../ $td/") and die;
	chdir $td;
	system("chmod a+rwx `find . -type d`") and die;
	system("chmod a+rw `find . -type f`") and die;
	$d = "$td/t";
	my $pid = fork();
	if ($pid) {
		waitpid $pid, 0;
		chdir '/';
		rmtree $td;
		exit;
	}
	Test::TempDatabase->become_postgres_user;
}

Apache::SWIT::Test::Apache->swit_run(sub {
	mkpath("$d/../blib/conf");
	symlink("$d/templates", "$d/../blib/templates");
	write_file("$d/../blib/conf/seal.key", "boo boo boo");
	write_file("$d/../blib/conf/startup.pl"
		, Apache::SWIT::Maker::Skeleton::Startup->new->get_output);
	symlink("$d/conf/do_swit_startups.pl"
		, "$d/../blib/conf/do_swit_startups.pl");
	$test_db = Test::TempDatabase->create(dbname => 'swit_test_db'
			, dbi_args => Apache::SWIT::DB::Connection->DBIArgs);
	Apache::SWIT::DB::Connection->instance($test_db->handle);
	$ENV{APACHE_SWIT_DB_NAME} = 'swit_test_db';

	my $dbh = Apache::SWIT::DB::Connection->instance->db_handle;
	$dbh->do("set client_min_messages to fatal");
	$dbh->do("create table dbp (id serial primary key, val text not null)");
	$dbh->do("create table upt (id serial primary key
			, loid oid unique not null)");
	$dbh->do(<<ENDS);
create table safet (id serial primary key, name text unique not null
	, email text unique not null, k1 smallint, k2 smallint, k3 smallint
	, constraint mugcons unique (k3, k2)
	, constraint strange_uq unique (k1, k2));

create table another_t (id serial primary key, name text unique not null);
ENDS
});
unlink("/tmp/swit_startup_test");
END { $test_db->destroy if $test_db; }
