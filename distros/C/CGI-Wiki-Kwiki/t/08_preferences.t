use warnings;
use strict;
use Test::More tests => 1;
use CGI::Wiki::Kwiki;
use CGI::Wiki::Setup::SQLite;

eval { require DBD::SQLite; };
my $run_tests = $@ ? 0 : 1;

SKIP: {
    skip "DBD::SQLite not installed - no database to test with", 1
        unless $run_tests;

    CGI::Wiki::Setup::SQLite::setup( "./t/wiki.db" );
    my $wiki = CGI::Wiki::Kwiki->new(
        db_type       => "SQLite",
        db_name       => "./t/wiki.db",
        prefs_expire  => "DUMMY_VALUE",
    );
    my $cookie = $wiki->make_prefs_cookie;
    like( $cookie, qr/expires=DUMMY_VALUE/, "prefs_expire option used" );
}
