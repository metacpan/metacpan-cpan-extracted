package TestApp::View::Tenjin;

use Moose;
use namespace::autoclean;

extends 'Catalyst::View::Tenjin';

__PACKAGE__->config(
	#USE_STRICT => 1,
	INCLUDE_PATH => [ TestApp->path_to('root') ],
	TEMPLATE_EXTENSION => '.html',
	#ENCODING => 'UTF-8', # this is the default
);

__PACKAGE__->meta->make_immutable;
