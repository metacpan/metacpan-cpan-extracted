use Test::More tests => 2;

BEGIN {
use_ok( 'CGI::Application::Plugin::AJAXUpload' );
use_ok( 'Data::FormValidator::Filters::ImgData' );
}

diag( "Testing CGI::Application::Plugin::AJAXUpload $CGI::Application::Plugin::AJAXUpload::VERSION" );
