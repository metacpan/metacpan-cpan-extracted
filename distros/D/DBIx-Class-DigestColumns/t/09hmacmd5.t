use strict;
use warnings;
use Test::More;

BEGIN {
	if ( !eval "require Digest" ) {
		plan skip_all => 'needs Digest for testing';
	
	} elsif ( !eval "require Digest::HMAC_MD5" ) {
		plan skip_all => 'needs Digest::HMAC_MD5 for testing';
	} else {
		plan tests => 2;
	};
}

use lib qw(t/lib);

use DigestTest;
my $schema = DigestTest->init_schema;
my $row;


DigestTest::Schema::Test->digest_algorithm('HMAC-MD5');
DigestTest::Schema::Test->digest_encoding('hex');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, '2884cf2d25d2568852f655ab8e536e98', 'got hex HMAC-MD5 from Digest';

DigestTest::Schema::Test->digest_algorithm('HMAC-MD5');
DigestTest::Schema::Test->digest_encoding('base64');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, 'KITPLSXSVohS9lWrjlNumA', 'got base64 HMAC-MD5 from Digest';


1;