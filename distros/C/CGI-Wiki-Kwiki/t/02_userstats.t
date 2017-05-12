use warnings;
use strict;
use Test::More tests => 6;
use CGI::Wiki::Kwiki;
use CGI::Wiki::Setup::SQLite;

eval { require DBD::SQLite; };
my $run_tests = $@ ? 0 : 1;

SKIP: {
    skip "DBD::SQLite not installed - no database to test with", 6
        unless $run_tests;

    # Clear database, instantiate wiki, add some data.
    CGI::Wiki::Setup::SQLite::cleardb( "./t/wiki.db" );
    CGI::Wiki::Setup::SQLite::setup( "./t/wiki.db" );
    my $wiki = CGI::Wiki::Kwiki->new(
        db_type       => "SQLite",
        db_name       => "./t/wiki.db",
        template_path => './templates',
    );
    $wiki->{wiki}->write_node( "Node 1", "This is Node 1", undef,
                               { username => "Kake", comment => "foobar" } );

    my $output1 = eval {
                         $wiki->run(
                                     return_output => 1,
                                     username      => "Kake",
                                     action        => "userstats",
                                   );
                       };

    is( $@, "", "userstats action is supported" );
    like( $output1, qr/Node 1/, "...and gets the node name" );
    like( $output1, qr/foobar/, "...and gets the comment" );
    like( $output1, qr/Last\s+node\s+edited\s+by/,
          "...number of nodes correct when 1 node found" );

    $wiki->{wiki}->write_node( "Node 2", "This is Node 2", undef,
                               { username => "Kake", comment => "foobar" } );

    my $output2 = $wiki->run(
                              return_output => 1,
                              username      => "Kake",
                              action        => "userstats",
                            );
    like( $output2, qr/Last\s+2\s+nodes\s+edited\s+by/,
          "...number of nodes correct when 2 nodes found" );

    my $output3 = $wiki->run(
                              return_output => 1,
                              username      => "Kake",
                              action        => "userstats",
                              n             => 1,
                            );
    like( $output3, qr/Last\s+node\s+edited\s+by/,
          "...only returns 1 node when we ask for only 1" );
}
