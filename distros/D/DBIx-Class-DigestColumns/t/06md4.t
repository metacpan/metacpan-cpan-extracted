use strict;
use warnings;
use Test::More;

BEGIN {
	if ( !eval "require Digest" ) {
		plan skip_all => 'needs Digest for testing';
	
	} elsif ( !eval "require Digest::MD4" ) {
		plan skip_all => 'needs Digest::MD4 for testing';
	} else {
		plan tests => 2;
	};
}

use lib qw(t/lib);

use DigestTest;
my $schema = DigestTest->init_schema;
my $row;


DigestTest::Schema::Test->digest_algorithm('MD4');
DigestTest::Schema::Test->digest_encoding('hex');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, '98d72aa322f4413a09a16157efafdaae', 'got hex MD4 from Digest';

DigestTest::Schema::Test->digest_algorithm('MD4');
DigestTest::Schema::Test->digest_encoding('base64');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, 'mNcqoyL0QToJoWFX76/arg', 'got base64 MD4 from Digest';


1;