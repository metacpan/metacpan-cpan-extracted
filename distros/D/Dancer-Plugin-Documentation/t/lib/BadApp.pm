package TestApp;
use Dancer (':syntax');
use Dancer::Plugin::Documentation;

document_route 'overview',
get '/' => sub {
	return [documentation];
};

document_route "invalid",
any ['get', 'post'] => '/foo' => sub {};

true;
