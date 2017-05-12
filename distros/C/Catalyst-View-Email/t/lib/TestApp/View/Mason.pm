package # Hide me.
    TestApp::View::Mason;

use strict;
eval "use base 'Catalyst::View::Mason';";

eval "__PACKAGE__->config( data_dir => TestApp->path_to('cache')->stringify );";

1;
