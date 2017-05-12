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
    );

    # Add some data.
    $wiki->run(
                return_output => 1, # be quiet
                action        => "commit",
                node          => "New Node",
                content       => "foo",
                comment       => "<h1>hello mum</h1>",
                username      => "Kake",        # avoid uninit value warning
                edit_type     => "Normal edit", # " "
              );

    my $output = $wiki->run(
                             return_output => 1,
                             action        => "list_all_versions",
                             node          => "New Node",
                           );
    unlike( $output, qr'<h1>hello mum</h1>',
            "comments are HTML-escaped in list_all_versions" );
}

