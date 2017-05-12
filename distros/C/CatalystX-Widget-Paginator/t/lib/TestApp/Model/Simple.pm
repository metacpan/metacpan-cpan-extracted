package TestApp::Model::Simple;

use Moose;

extends 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config({
	schema_class => 'TestApp::Schema',
	connect_info => {
		dsn => 'dbi:SQLite:dbname=' . TestApp->path_to('..','..','test.db')
	},
});


__PACKAGE__->meta->make_immutable;

1;

