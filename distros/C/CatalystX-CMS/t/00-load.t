use Test::More tests => 2;

BEGIN {
  use_ok('CatalystX::CMS');
  use_ok('Catalyst');
}

diag( "Testing CatalystX::CMS $CatalystX::CMS::VERSION" );
diag( "Testing using Catalyst $Catalyst::VERSION" );
