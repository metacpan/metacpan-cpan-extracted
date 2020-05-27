use Data::AnyXfer::Test::Kit;

my $pkg = 'Data::AnyXfer::IteratorToElasticsearch';

use_ok($pkg);

meta_ok($pkg);
does_ok( $pkg, 'Data::AnyXfer::From::Iterator' );
does_ok( $pkg, 'Data::AnyXfer::To::Elasticsearch' );

done_testing;
