use strict;
use warnings;
use Test::More;

BEGIN {
    plan eval "require Digest"
        ? ( tests => 5 )
        : ( skip_all => 'needs Digest for testing' );
}

use lib qw(t/lib);

use DigestTest;
my $schema = DigestTest->init_schema;
my $row;

$row = $schema->resultset('Test2')->create({ password => 'testvalue', password2 => 'testvalue' });
is $row->password, 'e9de89b0a5e9ad6efd5e5ab543ec617c',  'got hex MD5 from Digest (default) on insert';
is $row->password2, 'e9de89b0a5e9ad6efd5e5ab543ec617c', 'got hex MD5 from Digest (default) on insert';

$row->password('testvalue2');
$row->update;
is $row->password,  '91c04cd25d9cc5fc44b7e4086e022d4d', 'got hex MD5 from Digest (default) on update';
is $row->password2, 'e9de89b0a5e9ad6efd5e5ab543ec617c', 'clean column was not re digested';

$row->update({password => 'testvalue'});
is $row->password, 'e9de89b0a5e9ad6efd5e5ab543ec617c',  'got hex MD5 from Digest (default) on update';
1;
