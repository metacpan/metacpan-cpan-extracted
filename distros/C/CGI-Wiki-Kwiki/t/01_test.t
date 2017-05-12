use warnings;
use strict;
use Test::More tests => 2;
use CGI::Wiki;

use_ok( "CGI::Wiki::Kwiki" );

eval { require DBD::SQLite; };
my $run_tests = $@ ? 0 : 1;

SKIP: {
    skip "DBD::SQLite not installed - no database to test with", 1
        unless $run_tests;

    my $wiki = CGI::Wiki::Kwiki->new(
        db_type       => "SQLite",
        db_name       => "./t/wiki.db",
        template_path => './templates',
    );
    isa_ok( $wiki, "CGI::Wiki::Kwiki" );

}
