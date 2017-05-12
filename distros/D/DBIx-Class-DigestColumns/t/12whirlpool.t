use strict;
use warnings;
use Test::More;

BEGIN {
	if ( !eval "require Digest" ) {
		plan skip_all => 'needs Digest for testing';
	
	} elsif ( !eval "require Digest::Whirlpool" ) {
		plan skip_all => 'needs Digest::Whirlpool for testing';
	} else {
		plan tests => 2;
	};
}

use lib qw(t/lib);

use DigestTest;
my $schema = DigestTest->init_schema;
my $row;


DigestTest::Schema::Test->digest_algorithm('Whirlpool');
DigestTest::Schema::Test->digest_encoding('hex');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, '65512598af7508466a08744a6ed08a53e1ac9173d9cd8658e4caa245e00d36e92b5f58802e703f23e012381d62a1661bad0ee601c1ca9684f98b2369b259263e', 'got hex Whirlpool from Digest';

DigestTest::Schema::Test->digest_algorithm('Whirlpool');
DigestTest::Schema::Test->digest_encoding('base64');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, 'ZVElmK91CEZqCHRKbtCKU+GskXPZzYZY5MqiReANNukrX1iALnA/I+ASOB1ioWYbrQ7mAcHKloT5iyNpslkmPg==', 'got base64 Whirlpool from Digest';


1;