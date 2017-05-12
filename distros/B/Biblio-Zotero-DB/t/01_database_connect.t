use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok 'Biblio::Zotero::DB' }
use lib "t/lib";

use TestData;

my $schema;
my $sqlite_db = get_test_db_path();
ok( $schema = Biblio::Zotero::DB->new( db_file => $sqlite_db )->schema, 'created schema' );

done_testing;
