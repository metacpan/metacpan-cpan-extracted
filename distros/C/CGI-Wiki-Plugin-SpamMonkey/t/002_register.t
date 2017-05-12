# -*- perl -*-

# t/002_register.t - register against a test wiki

use Test::More;

BEGIN {
    eval { require DBD::SQLite; };
    if ($@) {
        plan skip_all => 'SQLite database not available for running tests';
    }
    else {
        plan tests => 5;
    }

    #01
    use_ok( 'CGI::Wiki::Plugin::SpamMonkey' );
}

use CGI::Wiki;
use CGI::Wiki::Store::SQLite;
use CGI::Wiki::Setup::SQLite;

CGI::Wiki::Setup::SQLite::cleardb( "./t/wiki.db" );
CGI::Wiki::Setup::SQLite::setup( "./t/wiki.db" );

my $store = CGI::Wiki::Store::SQLite->new (dbname => "./t/wiki.db" );

#02
isa_ok( $store, "CGI::Wiki::Store::SQLite" );

my $wiki = CGI::Wiki->new( store => $store);

#03
isa_ok( $wiki, "CGI::Wiki" );

my $plugin = CGI::Wiki::Plugin::SpamMonkey->new;

#04
isa_ok ($plugin, 'CGI::Wiki::Plugin::SpamMonkey');

eval { $wiki->register_plugin( plugin => $plugin) };

#05
ok(!$@, "register_plugin didn't throw an exception");


