use Test::More tests => 2;

BEGIN {
  use_ok('CatalystX::CRUD::YUI');
  use_ok('Catalyst');
}

diag( "Testing CatalystX::CRUD::YUI $CatalystX::CRUD::YUI::VERSION" );
diag( "Testing Catalyst::Runtime $Catalyst::VERSION" );

