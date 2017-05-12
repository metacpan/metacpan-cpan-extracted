use Test::More tests => 2;

BEGIN {
  use_ok( 'Data::YAML::Reader' );
  use_ok( 'Data::YAML::Writer' );
}

diag( "Testing Data::YAML $Data::YAML::Reader::VERSION" );
