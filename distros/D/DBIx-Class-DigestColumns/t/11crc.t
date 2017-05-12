use strict;
use warnings;
use Test::More;

BEGIN {
	if ( !eval "require Digest" ) {
		plan skip_all => 'needs Digest for testing';
	
	} elsif ( !eval "require Digest::CRC" ) {
		plan skip_all => 'needs Digest::CRC for testing';
	} else {
		plan tests => 6;
	};
}

use lib qw(t/lib);

use DigestTest;
my $schema = DigestTest->init_schema;
my $row;


DigestTest::Schema::Test->digest_algorithm('CRC-16');
DigestTest::Schema::Test->digest_encoding('hex');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, 'f729', 'got hex CRC-16 from Digest';

DigestTest::Schema::Test->digest_algorithm('CRC-16');
DigestTest::Schema::Test->digest_encoding('base64');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, 'NjMyNz', 'got base64 CRC-16 from Digest';

DigestTest::Schema::Test->digest_algorithm('CRC-32');
DigestTest::Schema::Test->digest_encoding('hex');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, '452b02e0', 'got hex CRC-32 from Digest';

DigestTest::Schema::Test->digest_algorithm('CRC-32');
DigestTest::Schema::Test->digest_encoding('base64');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, 'MTE2MDQ0NjY4OA', 'got base64 CRC-32 from Digest';

DigestTest::Schema::Test->digest_algorithm('CRC-CCITT');
DigestTest::Schema::Test->digest_encoding('hex');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, '2f5e', 'got hex CRC-CCITT from Digest';

DigestTest::Schema::Test->digest_algorithm('CRC-CCITT');
DigestTest::Schema::Test->digest_encoding('base64');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, 'MTIxMj', 'got base64 CRC-CCITT from Digest';

1;