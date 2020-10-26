use strict; use warnings;

package MyApp::View::TemplateClass;

use MyApp::Template::Any ();

use Catalyst::View::Template ();
BEGIN { our @ISA = 'Catalyst::View::Template' }

__PACKAGE__->config( class_name => 'MyApp::Template::Any' );

1;
