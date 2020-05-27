use Data::AnyXfer::Test::Kit;

my $pkg = 'Data::AnyXfer::IteratorToElasticsearch::DataFile';

use_ok($pkg);
does_ok( $pkg, 'Data::AnyXfer::From::Iterator' );
does_ok( $pkg, 'Data::AnyXfer::To::Elasticsearch::DataFile' );

done_testing;
