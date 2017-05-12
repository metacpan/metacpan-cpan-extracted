use strict;
use CGI::Wiki::TestLib;
use Test::More;

if ( scalar @CGI::Wiki::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 6 * scalar @CGI::Wiki::TestLib::wiki_info );
}

my $iterator = CGI::Wiki::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    # Put some test data in.
    $wiki->write_node( "Hammersmith Station", "a station", undef,
                       { tube_data =>
                         { line => "Piccadilly",
                           direction => "Eastbound",
                           next_station => "Baron's Court Station"
                         }
                       }
                    );

    my %node_data = $wiki->retrieve_node( "Hammersmith Station" );
    my %metadata  = %{ $node_data{metadata} || {} };
    ok( !defined $metadata{tube_data},
        "hashref metadata not stored directly" );
    ok( defined $metadata{__tube_data__checksum},
        "checksum stored instead" );

    ok( $wiki->write_node( "Hammersmith Station", "a station",
                           $node_data{checksum},
                           { tube_data => [
                             { line => "Piccadilly",
                               direction => "Eastbound",
                               next_station => "Baron's Court Station"
                             },
                             { line => "Piccadilly",
                               direction => "Westbound",
                               next_station => "Acton Town Station"
                             }
                                        ]
                          }
                        ),
        "writing node with metadata succeeds when node checksum fresh" );

    ok( !$wiki->write_node( "Hammersmith Station", "a station",
                           $node_data{checksum},
                           { tube_data => [
                             { line => "Piccadilly",
                               direction => "Eastbound",
                               next_station => "Baron's Court Station"
                             },
                             { line => "Piccadilly",
                               direction => "Westbound",
                               next_station => "Acton Town Station"
                             }
                                           ]
                             }
                           ),
       "...but fails when node checksum old and hashref metadata changed");

    # Make sure that order doesn't matter in the arrayrefs.
    %node_data = $wiki->retrieve_node( "Hammersmith Station" );
    $wiki->write_node( "Hammersmith Station", "a station",
                       $node_data{checksum},
                       { tube_data => [
                         { line => "Piccadilly",
                           direction => "Westbound",
                           next_station => "Acton Town Station"
                         },
                         { line => "Piccadilly",
                           direction => "Eastbound",
                           next_station => "Baron's Court Station"
                         },
                                       ]
                        }
                      ) or die "Couldn't write node";
    ok( $wiki->verify_checksum("Hammersmith Station",$node_data{checksum}),
        "order within arrayrefs doesn't affect checksum" );

    my %node_data_check = $wiki->retrieve_node( "Hammersmith Station" );
    my %metadata_check  = %{ $node_data_check{metadata} || {} };
    is( scalar @{ $metadata_check{__tube_data__checksum} }, 1,
        "metadata checksum only written once even if multiple entries" );
}

