
use Test::More tests => 2;

BEGIN {
	$Apache::GopherHandler::Config{doc_root} = '/';
	$Apache::GopherHandler::Config{server}   = 'localhost';
	$Apache::GopherHandler::Config{port}     = 70;
	$Apache::GopherHandler::Config{handler}  = 
		'Gopher::Server::RequestHandler::File';

	use_ok( 'Apache::GopherHandler::TiedSocket'    );
	use_ok( 'Apache::GopherHandler' );
}

