use warnings;
use strict;
use Test::More;
use CGI::Wiki::Kwiki;
use CGI::Wiki::Setup::SQLite;

eval { require DBD::SQLite; };

if ( $@ ) {
    plan skip_all => "DBD::SQLite not installed - no database to test with";
} else {
    plan tests => 1;

    # Clear database, instantiate wiki.
    CGI::Wiki::Setup::SQLite::cleardb( "./t/wiki.db" );
    CGI::Wiki::Setup::SQLite::setup( "./t/wiki.db" );
    my $wiki = CGI::Wiki::Kwiki->new(
        db_type       => "SQLite",
        db_name       => "./t/wiki.db",
        formatters    => {
                           default => "CGI::Wiki::Formatter::Default",
                         },
        template_path => './templates',
        home_node     => "The Home Node",
    );

    my %tt_vars = $wiki->run(
                              return_tt_vars => 1,
                              node           => "WantedPages",
                            );
    isnt( $tt_vars{node_name}, "The Home Node",
          "WantedPages doesn't redirect to home node." );
}

