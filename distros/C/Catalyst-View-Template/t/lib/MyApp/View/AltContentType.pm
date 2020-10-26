use strict; use warnings;

package MyApp::View::AltContentType;

use Catalyst::View::Template ();
BEGIN { our @ISA = 'Catalyst::View::Template' }

__PACKAGE__->config(
	template_ext => '.tt',
	content_type => 'text/plain',
);
