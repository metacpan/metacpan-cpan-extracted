# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'DBIx::File2do' ); }

my $dbh;
my $object = DBIx::File2do->new (\$dbh);
isa_ok ($object, 'DBIx::File2do');


