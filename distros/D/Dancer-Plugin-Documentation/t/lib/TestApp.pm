package TestApp;
use Dancer (':syntax');
use Dancer::Plugin::Documentation;

document_route 'overview',
get '/' => sub {
	return [documentation(%{params()})];
};

document_section 'bars',
	'where we drink';

document_section 'foos',
	'few and fool';

prefix '/v1';

document_route "create foo",
post '/foo' => sub {};

document_route "fetch foo",
get '/foo/:id' => sub {};

document_route "find foo",
get '/foo' => sub {};

document_section 'bazs',
	'who knew?';

document_route "dunno",
post '/baz' => sub {};

document_section '', "disabling sections...shouldn't show";

true;
