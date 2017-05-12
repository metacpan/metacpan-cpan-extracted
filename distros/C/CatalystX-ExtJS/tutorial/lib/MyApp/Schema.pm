#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
	package MyApp::Schema;
	use Moose;
	extends 'DBIx::Class::Schema';

	__PACKAGE__->load_namespaces;

	1;