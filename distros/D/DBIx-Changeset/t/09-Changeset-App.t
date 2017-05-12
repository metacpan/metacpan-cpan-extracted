#!perl 

use Test::More qw(no_plan);
use Test::Exception;

use lib qw(./t/lib);

my $test_db = File::Spec->catfile('t', 'test.db');

unlink $test_db if -e $test_db;
	
my $test_dsn = "dbi:SQLite:dbname=$test_db";

my $test_db2 = File::Spec->catfile('t', 'test2.db');

unlink $test_db2 if -e $test_db2;

my $test_db3 = File::Spec->catfile('t', 'testenv.db');

unlink $test_db3 if -e $test_db3;

	
BEGIN {
	require_ok( 'DBIx::Changeset::App' );
}

diag( "Testing DBIx::Changeset::App $DBIx::Changeset::App::VERSION, Perl $], $^X" );

use Test::Output;

my $cmd = DBIx::Changeset::App->new;
isa_ok($cmd, 'DBIx::Changeset::App', 'correct type');
can_ok($cmd, qw(config));

### test config
## test with single file
$cmd->config(File::Spec->catfile('t', 'test1.yml'));
is($cmd->{'config'}->{'test'}, 1, 'Got expected config var for test from test1.yml');
is($cmd->{'config'}->{'test3'}, 1, 'Got expected config var for test3 from test1.yml');
## test with array
$cmd->config([File::Spec->catfile('t', 'test1.yml'), File::Spec->catfile('t', 'test2.yml')]);
is($cmd->{'config'}->{'test'}, 'overrided', 'Got overrided config var for test from array test');
is($cmd->{'config'}->{'test2'}, 'testing', 'Got correct test2 value from test2.yml during array test');
is($cmd->{'config'}->{'test3'}, 1, 'Got correct test3 value from test1.yml during array test');
## test with array
$cmd->config([File::Spec->catfile('t', 'test2.yml'), File::Spec->catfile('t', 'test1.yml')]);
is($cmd->{'config'}->{'test'}, 1, 'Got correct config var for test from reverse array test');
is($cmd->{'config'}->{'test2'}, 'testing', 'Got correct test2 value from test2.yml during reverse array test');
is($cmd->{'config'}->{'test3'}, 1, 'Got correct test3 value from test1.yml during array reverse test');


{
	local @ARGV = qw(commands);

	my ($output) = Test::Output::output_from(sub { $cmd->run });
	
	for my $name (qw(create update compare applied bootstrap commands help)) {
		like($output, qr/^\s+\Q$name\E/sm, "$name command in listing");
	}
}

### test create options
{
	local @ARGV = qw(help create);

	my ($output) = Test::Output::output_from(sub { $cmd->run });

	### do we have the default options
	for my $name (qw(help prompt)) {
		like($output, qr/^\s+\Q--$name\E/sm, "$name default option listed");
	}
	
	### do we have the 2 other added options
	for my $name (qw(edit editor location template)) {
		like($output, qr/^\s+\Q--$name\E/sm, "$name create option listed");
	}
}

### test create option validation
{
	local @ARGV = qw(create);

	eval { $cmd->run; };

	### check for complaint about changeset location
	like($@, qr/valid changeset location/, 'got complaint about changeset location from create');
}

### test create option validation
{
	local @ARGV = qw(create --location=./t/data);

	eval { $cmd->run; };

	### check for complaint about missing delta name
	like($@, qr/valid changeset name/, 'got complaint about delta name from create');
}

### test create
{
	local @ARGV = qw(create --location=./t/data --template=./t/add_template.txt moose);

	my $output;
	eval { ($output) = Test::Output::output_from(sub { $cmd->run }); };

	### check that we get the create filename message
	my $created;
	if ( $output =~ qr/created: (.*_moose.sql)$/ ) {
		$created = $1;
	}
	like($output, qr/created: (.*_moose.sql)$/, 'found filename in output');
	### does purported file exists
	ok(-e $created, 'reported file exists');
	unlink ( $created );
}

### test bootstrap options
{
	local @ARGV = qw(help bootstrap);

	my ($output) = Test::Output::output_from(sub { $cmd->run });

	### do we have the other added options
	for my $name (qw(history_db_dsn history_db_user history_db_password)) {
		like($output, qr/^\s+\Q--$name\E/sm, "$name compare option listed");
	}
}

### test bootstrap option validation
{
	local @ARGV = qw(bootstrap);

	eval { $cmd->run; };

	### check for complaint about missing history_db_dsn
	like($@, qr/history_db_dsn/, 'got complaint about history_db_dsn from bootstrap');
}

### test valid bootstrap
{
	local @ARGV = ('bootstrap', "--history_db_dsn=".$test_dsn);
	
	my $output;
	eval { ($output) = Test::Output::output_from(sub { $cmd->run; }); };
	if ( $@ ) { diag($@); }
	
	like($output, qr/complete./, 'can do a valid bootstrap');
}

### test valid bootstrap with DBIX_UPDATE_CONFIG env var
{
	my $testenvcfg = File::Spec->catfile('t', 'testenv.yml');
	
	my $cmd = DBIx::Changeset::App->new;
	
	my $output;
	($output) = eval { qx#DBIX_CHANGESET_CONFIG=$testenvcfg bin/dbix_changeset.pl bootstrap#; };
	if ( $@ ) { diag($@); }

	like($output, qr/complete./, 'can do a valid bootstrap with DBIX_UPDATE_CONFIG');
}

### test compare options
{
	local @ARGV = qw(help compare);

	my ($output) = Test::Output::output_from(sub { $cmd->run });

	### do we have the other added options
	for my $name (qw(location type like history_db_dsn history_db_user history_db_password)) {
		like($output, qr/^\s+\Q--$name\E/sm, "$name compare option listed");
	}
}

### test compare option validation
{
	local @ARGV = qw(compare);

	eval { $cmd->run; };

	### check for complaint about changeset location
	like($@, qr/valid changeset location/, 'got complaint about changeset location from compare');

	@ARGV = qw(compare --location=./t/data2);
	
	eval { $cmd->run; };

	### check for complaint about missing history_db_dsn
	like($@, qr/history_db_dsn/, 'got complaint about history_db_dsn from compare');
}

### test update options
{
	local @ARGV = qw(help update);

	my ($output) = Test::Output::output_from(sub { $cmd->run });

	### do we have the other added options
	for my $name (qw(loader location type db_user db_password db_host db_name history_db_dsn history_db_user history_db_password)) {
		like($output, qr/^\s+\Q--$name\E/sm, "$name update option listed");
	}
}

### test compare option validation
{
	local @ARGV = qw(update);

	eval { $cmd->run; };

	### check for complaint about changeset location
	like($@, qr/valid changeset location/, 'got complaint about changeset location from update');

	@ARGV = qw(update --location=./t/data2);
	
	eval { $cmd->run; };

	### check for complaint about missing history_db_dsn
	like($@, qr/history_db_dsn/, 'got complaint about history_db_dsn from update');

	local @ARGV = ('update', '--location=./t/data', '--history_db_dsn='.$test_dsn);
	
	eval { $cmd->run; };
	
	### check for complaint about missing db_name
	like($@, qr/db_name/, 'got complaint about history_db_dsn from update');

}
### test that update works with valid options
=head1
{
	SKIP: {
		skip 'Set $ENV{MYSQL_TEST} to a true value to run all mysql tests. DBD_MYSQL_DBNAME, DBD_MYSQL_USER and DBD_MYSQL_PASSWD can be used to change the defult db of test', 1 unless defined $ENV{MYSQL_TEST};
		
		my $db   = $ENV{DBD_MYSQL_DBNAME} || 'test';
		my $user = $ENV{DBD_MYSQL_USER}   || '';
		my $pass = $ENV{DBD_MYSQL_PASSWD} || '';

		local @ARGV = ('update', '--location=./t/data', '--history_db_dsn='.$test_dsn, '--db_name='.$db, '--db_user='.$user, '--db_password='.$pass);

		my $output;
		diag(join(' ', @ARGV));
		eval { ($output) = Test::Output::output_from(sub { $cmd->run }); };
#		eval { $cmd->run };
#		diag($@);
#		diag($output);
	
	}

}
=cut
