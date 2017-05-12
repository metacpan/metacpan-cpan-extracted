use strict;
use warnings;
use Test::More;

BEGIN {
    plan eval "require Digest"
        ? ( tests => 12 )
        : ( skip_all => 'needs Digest for testing' );
}

use lib qw(t/lib);

use DigestTest;
my $schema = DigestTest->init_schema;
my $row;

SKIP: {
	eval { 
		eval { require Digest::SHA1 } ||
		eval { require Digest::SHA } ||
		eval { require Digest::SHA2 }
	};

	skip 'needs Digest::SHA, Digest::SHA1 or Digest::SHA2 for testing', 4 if $@;

	DigestTest::Schema::Test->digest_algorithm('SHA-1');
	DigestTest::Schema::Test->digest_encoding('hex');
	Class::C3->reinitialize();
	$row = $schema->resultset('Test')->create({ password => 'testvalue' });
	is $row->password, 'fc3cfe2b4f554c2752444f1e6b7bad1e8d5cccf8', 'got hex SHA-1 from Digest';
	
	DigestTest::Schema::Test->digest_algorithm('SHA-1');
	DigestTest::Schema::Test->digest_encoding('base64');
	Class::C3->reinitialize();
	$row = $schema->resultset('Test')->create({ password => 'testvalue' });
	is $row->password, '/Dz+K09VTCdSRE8ea3utHo1czPg', 'got base64 SHA-1 from Digest';
	
	DigestTest::Schema::Test->digest_algorithm('SHA');
	DigestTest::Schema::Test->digest_encoding('hex');
	Class::C3->reinitialize();
	$row = $schema->resultset('Test')->create({ password => 'testvalue' });
	is $row->password, 'fc3cfe2b4f554c2752444f1e6b7bad1e8d5cccf8', 'got hex SHA-1 from Digest';
	
	DigestTest::Schema::Test->digest_algorithm('SHA');
	DigestTest::Schema::Test->digest_encoding('base64');
	Class::C3->reinitialize();
	$row = $schema->resultset('Test')->create({ password => 'testvalue' });
	is $row->password, '/Dz+K09VTCdSRE8ea3utHo1czPg', 'got base64 SHA-1 from Digest';
}
    
SKIP: {
	eval { require Digest::SHA };

	skip 'needs Digest::SHA for testing', 2 if $@;

	DigestTest::Schema::Test->digest_algorithm('SHA-224');
	DigestTest::Schema::Test->digest_encoding('hex');
	Class::C3->reinitialize();
	$row = $schema->resultset('Test')->create({ password => 'testvalue' });
	is $row->password, '659950ed3db1b9ba012ace73dc024d11cd6ae832c8c0d11b55c0be76',
		'got hex SHA-224 from Digest';
	
	DigestTest::Schema::Test->digest_algorithm('SHA-224');
	DigestTest::Schema::Test->digest_encoding('base64');
	Class::C3->reinitialize();
	$row = $schema->resultset('Test')->create({ password => 'testvalue' });
	is $row->password, 'ZZlQ7T2xuboBKs5z3AJNEc1q6DLIwNEbVcC+dg',
		'got base64 SHA-224 from Digest';	
}

SKIP: {
	eval { 
		eval { require Digest::SHA } ||
		eval { require Digest::SHA2 }
	};

	skip 'needs Digest::SHA, Digest::SHA2 for testing', 6 if $@;

	DigestTest::Schema::Test->digest_algorithm('SHA-256');
	DigestTest::Schema::Test->digest_encoding('hex');
	Class::C3->reinitialize();
	$row = $schema->resultset('Test')->create({ password => 'testvalue' });
	is $row->password, 'b52ccfce5067e90f4b4f8ec8567eb50f9e10850d6e114a2ea09cb45f753011b9', 'got hex SHA-256 from Digest';
	
	DigestTest::Schema::Test->digest_algorithm('SHA-256');
	DigestTest::Schema::Test->digest_encoding('base64');
	Class::C3->reinitialize();
	$row = $schema->resultset('Test')->create({ password => 'testvalue' });
	is $row->password, 'tSzPzlBn6Q9LT47IVn61D54QhQ1uEUouoJy0X3UwEbk', 'got base64 SHA-256 from Digest';
	
	DigestTest::Schema::Test->digest_algorithm('SHA-384');
	DigestTest::Schema::Test->digest_encoding('hex');
	Class::C3->reinitialize();
	$row = $schema->resultset('Test')->create({ password => 'testvalue' });
	is $row->password, '3abe10a9c224d3e097441aea3cd3afac3af98a3c6eb54f244daa8d1c40fb913d78ef3b2397ec9d67692532a4367aa8c9', 'got hex SHA-384 from Digest';
	
	DigestTest::Schema::Test->digest_algorithm('SHA-384');
	DigestTest::Schema::Test->digest_encoding('base64');
	Class::C3->reinitialize();
	$row = $schema->resultset('Test')->create({ password => 'testvalue' });
	is $row->password, 'Or4QqcIk0+CXRBrqPNOvrDr5ijxutU8kTaqNHED7kT147zsjl+ydZ2klMqQ2eqjJ', 'got base64 SHA-384 from Digest';
	
	DigestTest::Schema::Test->digest_algorithm('SHA-512');
	DigestTest::Schema::Test->digest_encoding('hex');
	Class::C3->reinitialize();
	$row = $schema->resultset('Test')->create({ password => 'testvalue' });
	is $row->password, '548032e3e11aef8d64b743608e7a9fe930050b7bc8d32b1cffff949a0075d7d7abc6e9e4dbdbb48f7a546628a74857e53f6c3e890eb95bdec328917cdd18cbdb', 'got hex SHA-512 from Digest';
	
	DigestTest::Schema::Test->digest_algorithm('SHA-512');
	DigestTest::Schema::Test->digest_encoding('base64');
	Class::C3->reinitialize();
	$row = $schema->resultset('Test')->create({ password => 'testvalue' });
	is $row->password, 'VIAy4+Ea741kt0Ngjnqf6TAFC3vI0ysc//+UmgB119erxunk29u0j3pUZiinSFflP2w+iQ65W97DKJF83RjL2w', 'got base64 SHA-512 from Digest';
}
1;