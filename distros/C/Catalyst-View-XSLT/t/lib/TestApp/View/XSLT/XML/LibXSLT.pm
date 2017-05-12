package TestApp::View::XSLT::XML::LibXSLT;

use strict;
use base 'Catalyst::View::XSLT';

our $VERSION = '0.07';

__PACKAGE__->config(
	INCLUDE_PATH => [
		TestApp->path_to( 'root' ),
	],
#	DUMP_CONFIG => 1,
);

1;
