#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
	package MyApp::View::TT;
	use Moose;
	extends 'Catalyst::View::TT::Alloy';

	__PACKAGE__->config( {
			CATALYST_VAR => 'c',
			INCLUDE_PATH => [ MyApp->path_to( 'root', 'src' ) ]
		} );

	1;