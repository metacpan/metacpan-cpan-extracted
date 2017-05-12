#!perl -T

use strict;
use warnings;

use Audit::DBI;
use Config::Tiny;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 8;

use lib 't/';
use LocalTest;


my $DATA_FILE = 'audit_test_data.tmp';

my $config;
lives_ok(
	sub
	{
		$config = Config::Tiny->read( $DATA_FILE );
	},
	'Load config file.',
) || diag( "Error: $Config::Tiny::errstr." );

my $test_event = $config->{'main'}->{'event'};
my $test_subject_type = $config->{'main'}->{'subject_type'};
my $test_subject_id = $config->{'main'}->{'subject_id'};
my $test_ip_address = $config->{'main'}->{'ip_address'};
my $random_string = $config->{'main'}->{'random_string'};

my $dbh = LocalTest::ok_database_handle();

ok(
	my $audit = Audit::DBI->new(
		database_handle => $dbh,
	),
	'Create a new Audit::DBI object.',
);

dies_ok(
	sub
	{
		$audit->record(
			subject_type => $test_subject_type,
			subject_id   => $test_subject_id,
		);
	},
	"The 'event' parameter is required.",
);

dies_ok(
	sub
	{
		$audit->record(
			event        => $test_event,
			subject_id   => $test_subject_id,
		);
	},
	"The 'subject_type' parameter is required.",
);

dies_ok(
	sub
	{
		$audit->record(
			event        => $test_event,
			subject_type => $test_subject_type,
		);
	},
	"The 'subject_id' parameter is required.",
);

ok(
	$ENV{'REMOTE_ADDR'} = $test_ip_address,
	"Change IP address to $test_ip_address.",
);

lives_ok(
	sub
	{
		$audit->record(
			event        => $test_event,
			subject_type => $test_subject_type,
			subject_id   => $test_subject_id,
			diff         =>
			[
				[ 'A', 'B' ],
				[ 'a', 'CDEFG' ],
				comparison_function => sub
				{
					my ( $variable_1, $variable_2 ) = @_;
					return lc( $variable_1 ) eq lc( $variable_2 );
				},
			],
			information  =>
			{
				test_id       => $test_subject_id,
				random_string => $random_string,
			},
			search_data  =>
			{
				test_id       => $test_subject_id,
				random_string => $random_string,
			},
		);
	},
	'Write audit event.',
);
