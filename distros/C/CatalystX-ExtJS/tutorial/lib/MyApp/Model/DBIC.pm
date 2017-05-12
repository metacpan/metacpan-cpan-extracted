#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
	package MyApp::Model::DBIC;
	use Moose;
	extends 'Catalyst::Model::DBIC::Schema';

	__PACKAGE__->config({
		schema_class => 'MyApp::Schema',
		connect_info => ['dbi:SQLite:dbname=:memory:']
	});

	after BUILD => sub {
		my $self = shift;
		my $schema = $self->schema;
		$schema->deploy;
		$schema->resultset('User')->create({
		    email => 'onken@netcubed.de', 
		    first => 'Moritz', 
		    last => 'Onken'
		});
	};

	1;