
use Test::More tests => 2;

BEGIN { use_ok( 'DBIx::CopyRecord' ); }

my $dbh;
my $object = DBIx::CopyRecord->new ( \$dbh);
isa_ok ($object, 'DBIx::CopyRecord');


