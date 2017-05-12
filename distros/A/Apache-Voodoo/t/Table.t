use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 17;

use_ok('File::Temp');
use_ok('DBI');
use_ok('Apache::Voodoo::Exception');
use_ok('Apache::Voodoo::Table');
use_ok('Apache::Voodoo::Table::Probe');

################################################################################
# Tests related to checking the config syntax
################################################################################
my $table;
eval {
	$table = Apache::Voodoo::Table->new({ });
};
my $e = Exception::Class->caught();
isa_ok($e,"Apache::Voodoo::Exception::RunTime::BadConfig");

eval {
	$table = Apache::Voodoo::Table->new({
		table       => '_vtable',
		columns => {
			id => {	
				type => 'unsigned_int',
				bytes => 4
			}
		}
	});
};

my $avt_table_config = {
	table => 'avt_table',
	primary_key => 'id',
	columns => {
		id     => { type => 'unsigned_int', bytes => 4, required => 1 },
		avt_ref_table_id => { 
			type => 'unsigned_int', 
			bytes => 4, 
			required => 1,
			references => {
				table => 'avt_ref_table',
				primary_key => 'id',
				columns => ['name'],
				select_label => 'name'
			}
		},
		a_date     => { type => 'date' },
		a_time     => { type => 'time' },
		a_datetime => { type => 'datetime' },
		a_varchar  => { type => 'varchar', length => 128},
		a_text     => { type => 'text'}
	},
	'list_options' => {
		'default_sort' => 'varchar',
		'sort' => {
			'varchar' => 'a_varchar',
			'text' => 'a_text'
		}
	}
};

$e = Exception::Class->caught();
isa_ok($e,"Apache::Voodoo::Exception::RunTime::BadConfig");

my $dbh;

SKIP: {
	my $dbh;
	eval { require DBD::mysql; };
	skip "DBD::mysql not found, skipping these tests",6 if $@;

	eval {
		$dbh = DBI->connect("dbi:mysql:test:localhost",'root','',{RaiseError => 1});
	};
	skip "Can't connect to mysql test database on localhost, skipping these tests",6 if $@;

	setup_db(   'MySQL',$dbh);
	table_tests('MySQL',$dbh);
	probe_tests('MySQL',$dbh);
	my $res = $dbh->selectall_arrayref("SHOW TABLES LIKE 'avt_%'");
	foreach (@{$res}) {
		$dbh->do("DROP TABLE $_->[0]");
	}
	$dbh->disconnect;
}

SKIP: {
	eval { require DBD::SQLite; };
	skip "DBD::SQLite not found, skipping these tests",4 if $@;

	my ($fh,$filename) = File::Temp::tmpnam();
	$dbh = DBI->connect("dbi:SQLite:dbname=$filename","","",{RaiseError => 1}) || BAIL_OUT("Couldn't make a testing database: ".DBI->errstr);

	setup_db(   'SQLite',$dbh);
	table_tests('SQLite',$dbh);
	$dbh->disconnect;
	unlink($filename);
}

sub setup_db {
	my $type = shift;
	my $dbh  = shift;

	open(F,"t/test_data/test_db.sql") || BAIL_OUT("Can't open test db source file: $!");
	{
		local $/ = ';';
		while (<F>) {
			$_ =~ s/^\s*//;
			$_ =~ s/\s*$//;
			$_ =~ s/;$//;
			next unless length($_);
			$dbh->do($_);
		}
	}
	close(F);
}

sub table_tests {
	my $type = shift;
	my $dbh  = shift;


	my $table = Apache::Voodoo::Table->new($avt_table_config);
	is_deeply(
		$table->view({dbh => $dbh,'params' => {'id' => 1}}),
		{
          'a_text' => 'a much larger text string',
          'a_date' => '01/01/2009',
          'a_varchar' => 'a text string',
          'avt_ref_table_id' => 1,
          'a_datetime' => '2000-02-01 12:00:00',
          'a_time' => ' 1:00 PM',
		  'avt_ref_table.name' => 'First Value',
          'id' => 1
        },
		"($type) Simple view with valid id"
	);

	my $v;
	eval {
		$v = $table->view({dbh => $dbh,'params' => {'id' => 100}});
	};
	$e = Exception::Class->caught();
	isa_ok($e,"Apache::Voodoo::Exception::Application::DisplayError");

	is_deeply(
		$table->list({ dbh => $dbh }),
		{
			'PATTERN' => '',
			'SORT_PARAMS' => 'desc=1&amp;last_sort=varchar&amp;showall=0',
			'DATA' => [
				{
					'a_text' => 'a much larger text string',
					'a_date' => '01/01/2009',
					'a_varchar' => 'a text string',
					'avt_ref_table.name' => 'First Value',
					'a_datetime' => '2000-02-01 12:00:00',
					'avt_ref_table_id' => 1,
					'id' => 1,
					'a_time' => ' 1:00 PM'
				},
				{
					'a_text' => 'different much longer string',
					'a_date' => '01/01/2010',
					'a_varchar' => 'another text string',
					'avt_ref_table.name' => 'Second Value',
					'a_datetime' => '2010-02-01 14:00:00',
					'avt_ref_table_id' => 2,
					'id' => 2,
					'a_time' => ' 5:00 PM'
				},
				{
					'a_varchar' => 'loren ipsum solor sit amet',
					'a_text' => 'consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
					'a_date' => '03/15/2010',
					'avt_ref_table.name' => 'Fourth Value',
					'a_datetime' => '2010-01-01 12:00:00',
					'avt_ref_table_id' => 4,
					'id' => 3,
					'a_time' => ' 4:00 PM'
				}
			],
			'NUM_MATCHES' => 3,
			'LIMIT' => []
		},
		"($type) list results"
	);

	is_deeply(
		$table->list({ dbh => $dbh, params => { 'search_a_varchar' => 'a text' }}),
		{
			'PATTERN' => '',
			'SORT_PARAMS' => 'desc=1&amp;last_sort=varchar&amp;showall=0',
			'DATA' => [
				{
					'a_text' => 'a much larger text string',
					'a_date' => '01/01/2009',
					'a_varchar' => 'a text string',
					'avt_ref_table.name' => 'First Value',
					'a_datetime' => '2000-02-01 12:00:00',
					'avt_ref_table_id' => 1,
					'id' => 1,
					'a_time' => ' 1:00 PM'
				}
			],
			'NUM_MATCHES' => 1,
			'LIMIT' => []
		},
		"($type) list search results"
	);

}

sub probe_tests {
	my $type = shift;
	my $dbh  = shift;

	my $probe = Apache::Voodoo::Table::Probe->new($dbh);
	my $no_such;
	eval {
		$no_such = $probe->probe_table('no_such_table_as_this_in_the_db');
	};
	ok($@ =~ /doesn't exist/, "($type) no such table");

	my $config = $probe->probe_table('avt_all_types');
	my $table;
	eval {
		$table = Apache::Voodoo::Table->new($config);
	};
	my $e = Exception::Class->caught();
	ok(!$e,"($type) probe produces output that table accepts") || diag($e);
}
