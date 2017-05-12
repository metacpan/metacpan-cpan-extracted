#!perl -T

use strict;
use warnings;

use Config::Tiny;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 3;


my $DATA_FILE = 'audit_test_data.tmp';

ok(
	defined(
		my $subject_id = generate_random_string( 3 ) . time()
	),
	'Generate a test subject ID.',
);

ok(
	defined(
		my $random_string = generate_random_string( 10 )
	),
	'Generate a random test value.',
);


lives_ok(
	sub
	{
		my $config = Config::Tiny->new();
		$config->{'main'}->{'event'} = 'Test audit event';
		$config->{'main'}->{'subject_type'} = 'test';
		$config->{'main'}->{'ip_address'} = '10.0.0.7';
		$config->{'main'}->{'subject_id'} = $subject_id;
		$config->{'main'}->{'random_string'} = $random_string;
		$config->write( $DATA_FILE );
	},
	'Save config file with test data.',
) || diag( "Error: $Config::Tiny::errstr." );


sub generate_random_string
{
	my ( $length ) = @_;

	$length = 10
		unless defined( $length ) && $length > 0;

	my @char = ( 'a'..'z', 'A'..'Z', '0'..'9' );
	return join('', map { $char[ rand @char ] } ( 1 .. $length ) );
}
