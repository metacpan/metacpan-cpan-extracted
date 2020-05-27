use Data::AnyXfer::Test::Kit;

my $pkg = 'Data::AnyXfer::DbicToElasticsearch::DataFile';

use_ok($pkg);
does_ok( $pkg, 'Data::AnyXfer::From::DBIC' );
does_ok( $pkg, 'Data::AnyXfer::To::Elasticsearch::DataFile' );

done_testing;
