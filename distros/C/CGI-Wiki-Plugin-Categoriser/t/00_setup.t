use strict;

use CGI::Wiki::TestConfig::Utilities;
use CGI::Wiki;
use Test::More tests => 1;

# Reinitialise every configured storage backend.
CGI::Wiki::TestConfig::Utilities->reinitialise_stores;

pass( "Reinitialised stores" );
