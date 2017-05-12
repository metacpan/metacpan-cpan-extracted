use strict;
use warnings;
use Test::More;

BEGIN {
	if ( !eval "require Digest" ) {
		plan skip_all => 'needs Digest for testing';
	
	} elsif ( !eval "require Digest::Adler32" ) {
		plan skip_all => 'needs Digest::Adler32 for testing';
	} else {
		plan tests => 2;
	};
}

use lib qw(t/lib);

use DigestTest;
my $schema = DigestTest->init_schema;
my $row;


DigestTest::Schema::Test->digest_algorithm('Adler32');
DigestTest::Schema::Test->digest_encoding('hex');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, '138703de', 'got hex Adler32 from Digest';

DigestTest::Schema::Test->digest_algorithm('Adler32');
DigestTest::Schema::Test->digest_encoding('base64');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, 'E4cD3g', 'got base64 Adler32 from Digest';


1;