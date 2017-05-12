use strict;
use warnings;
use Test::More;

BEGIN {
	if ( !eval "require Digest" ) {
		plan skip_all => 'needs Digest for testing';
	
	} elsif ( !eval "require Digest::HMAC_SHA1" ) {
		plan skip_all => 'needs Digest::HMAC_SHA1 for testing';
	} else {
		plan tests => 2;
	};
}

use lib qw(t/lib);

use DigestTest;
my $schema = DigestTest->init_schema;
my $row;


DigestTest::Schema::Test->digest_algorithm('HMAC-SHA-1');
DigestTest::Schema::Test->digest_encoding('hex');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, '09c7f3c5459d406c78ab656028a39588eafc8865', 'got hex HMAC-SHA-1 from Digest';

DigestTest::Schema::Test->digest_algorithm('HMAC-SHA-1');
DigestTest::Schema::Test->digest_encoding('base64');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, 'CcfzxUWdQGx4q2VgKKOViOr8iGU', 'got base64 HMAC-SHA-1 from Digest';


1;