use Data::AnyXfer::Test::Kit;

use File::Basename                                   ();
use Data::UUID                                       ();
use Data::AnyXfer::Elastic::IndexInfo        ();
use Data::AnyXfer::Elastic::Import::DataFile ();
use Data::AnyXfer::Elastic::Test::Import     ();

my $pkg = 'Data::AnyXfer::ElasticsearchToDataFile';

use_ok($pkg);
does_ok( $pkg, 'Data::AnyXfer::From::Elasticsearch' );
does_ok( $pkg, 'Data::AnyXfer::To::Elasticsearch::DataFile' );

done_testing;
