use warnings;
use strict;
use Test::More;
use CGI::Wiki::Kwiki;
use CGI::Wiki::Setup::SQLite;

use lib "./t/lib"; # for test formatters

eval { require DBD::SQLite; };

if ( $@ ) {
    plan skip_all => "DBD::SQLite not installed - no database to test with";
} else {
    plan tests => 3;

    # We're testing the behaviour of a wiki that only has one formatter
    # defined.

    # Clear database, instantiate wiki.
    CGI::Wiki::Setup::SQLite::cleardb( "./t/wiki.db" );
    CGI::Wiki::Setup::SQLite::setup( "./t/wiki.db" );
    my $wiki = CGI::Wiki::Kwiki->new(
        db_type       => "SQLite",
        db_name       => "./t/wiki.db",
        formatters    => {
                           pony     => "Local::Test::Formatter::Pony",
                         },
        template_path => './templates',
    );

    # Add some data.
    $wiki->run(
                return_output => 1, # be quiet
                action        => "commit",
                node          => "New Node",
                content       => "foo",
                username      => "Kake",        # avoid uninit value warning
                comment       => "New page.",   # " "
                edit_type     => "Normal edit", # " "
              );

    # Check that a default value went in for the formatter.
    my %data = $wiki->{wiki}->retrieve_node( "New Node" );
    is( $data{metadata}{formatter}[0], "pony",
        "default value set for formatter in single-formatter wiki" );

    # Check that it displays right.
    my $output = $wiki->run(
                             return_output => 1,
                             node          => "New Node",
                           );
    $output =~ s/^Content-Type.*[\r\n]+//m; # strip header
    
    like( $output, qr/PONY/, "single-formatter wiki displays node right" );

    # Now test that the formatter type option isn't offered on the edit
    # page if there is only one available formatter.
    eval { require Test::HTML::Content; };
    SKIP: {
        skip "Test::HTML::Content not installed", 1 if $@;

        $wiki = CGI::Wiki::Kwiki->new(
            db_type       => "SQLite",
            db_name       => "./t/wiki.db",
            formatters    => {
                               default => "Local::Test::Formatter::Pony",
                             },
            template_path => './templates',
            search_map    => 't/search_map',
        );

        $output = $wiki->run(
                              return_output => 1,
                              action        => "edit",
                              node          => "New Node",
                            );

        $output =~ s/^Content-Type.*[\r\n]+//m; # strip header
        Test::HTML::Content::no_tag( $output, "select", { name => "formatter"},
            "no formatter select offered on edit page if only one formatter" );

    } # end of SKIP
}
