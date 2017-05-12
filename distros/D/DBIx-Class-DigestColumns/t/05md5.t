use strict;
use warnings;
use Test::More;

BEGIN {
	if ( !eval "require Digest" ) {
		plan skip_all => 'needs Digest for testing';
	
	} elsif ( !eval "require Digest::MD5" ) {
		plan skip_all => 'needs Digest::MD5 for testing';
	} else {
		plan tests => 2;
	};
}

use lib qw(t/lib);

use DigestTest;
my $schema = DigestTest->init_schema;
my $row;


DigestTest::Schema::Test->digest_algorithm('MD5');
DigestTest::Schema::Test->digest_encoding('hex');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, 'e9de89b0a5e9ad6efd5e5ab543ec617c', 'got hex MD5 from Digest';

DigestTest::Schema::Test->digest_algorithm('MD5');
DigestTest::Schema::Test->digest_encoding('base64');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, '6d6JsKXprW79Xlq1Q+xhfA', 'got base64 MD5 from Digest';


1;