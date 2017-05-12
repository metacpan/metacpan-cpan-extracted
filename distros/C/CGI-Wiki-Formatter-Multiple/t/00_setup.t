use strict;
use CGI::Wiki::Setup::SQLite;
use Test::More tests => 1;

# We can only run most of the tests if DBD::SQLite is available to let us
# make a temporary test database.
eval { require DBD::SQLite };
if ( $@ ) {
    print "DBD::SQLite not installed... will have to skip most tests.\n";
} else {
    print "Setting up test SQLite database... ";
    CGI::Wiki::Setup::SQLite::cleardb( "./t/wiki.db" );
    CGI::Wiki::Setup::SQLite::setup( "./t/wiki.db" );
}

pass( "setup complete" );

