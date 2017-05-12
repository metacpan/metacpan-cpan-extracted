use Test::More tests => 4;

BEGIN {
use_ok( 'BioX::FedDB' );
use_ok( 'BioX::FedDB::Base' );
use_ok( 'BioX::FedDB::Client' );
use_ok( 'BioX::FedDB::Server' );
}

diag( "Testing BioX::FedDB $BioX::FedDB::VERSION" );
diag( "Testing BioX::FedDB::Base $BioX::FedDB::Base::VERSION" );
diag( "Testing BioX::FedDB::Client $BioX::FedDB::Client::VERSION" );
diag( "Testing BioX::FedDB::Server $BioX::FedDB::Server::VERSION" );
