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

    # Clear database, instantiate wiki, add some data.
    CGI::Wiki::Setup::SQLite::cleardb( "./t/wiki.db" );
    CGI::Wiki::Setup::SQLite::setup( "./t/wiki.db" );
    my $wiki = CGI::Wiki::Kwiki->new(
        db_type       => "SQLite",
        db_name       => "./t/wiki.db",
        template_path => './templates',
    );
    $wiki->{wiki}->write_node( "Node 1", "This is Node 1" );
    my %node_data = $wiki->{wiki}->retrieve_node( "Node 1" );
    $wiki->{wiki}->write_node( "Node 1",
                               "This is still Node 1",
                               $node_data{checksum} );

    my $output = $wiki->run(
                             return_output => 1,
                             node          => "Node 1",
                             version       => 1,
                             diffversion   => 2,
                           );
    like( $output, qr/differences between version 1 and version 2 of node 1/i,
          "diffs page header includes version numbers and node name" );
}
