use strict; use warnings;

package MyApp::View::PkgConfig;

use Catalyst::View::Template ();
BEGIN { our @ISA = 'Catalyst::View::Template' }

__PACKAGE__->config(
	PRE_CHOMP    => 1,
	POST_CHOMP   => 1,
	template_ext => '.tt',
);

1;
