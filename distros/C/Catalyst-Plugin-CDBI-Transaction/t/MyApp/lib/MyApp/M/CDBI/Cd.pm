package MyApp::M::CDBI::Cd;

__PACKAGE__->might_have( liner_notes =>
                         MyApp::M::CDBI::LinerNotes => qw/notes/ );

use strict;

1;

