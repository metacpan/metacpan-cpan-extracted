use warnings;
use strict;
use Test::More;
use CGI::Wiki::Kwiki;
use CGI::Wiki::Setup::SQLite;

eval { require DBD::SQLite; require Test::HTML::Content; require CGI::Wiki::Formatter::UseMod};
if ( $@ ) {
    plan skip_all => "One of CGI::Wiki::Formatter::UseMod, DBD::SQLite, or Test::HTML::Content not installed";
} else {
    plan tests => 6;

    # Clear database, instantiate wiki.
    CGI::Wiki::Setup::SQLite::cleardb( "./t/wiki.db" );
    CGI::Wiki::Setup::SQLite::setup( "./t/wiki.db" );
    my $wiki = CGI::Wiki::Kwiki->new(
        db_type       => "SQLite",
        db_name       => "./t/wiki.db",
        template_path => './templates',
        cgi_path      => "http://wiki.example.com/",
        formatters    => { default => "CGI::Wiki::Formatter::UseMod" },
    );

    my $output = $wiki->run(
                             return_output => 1,
                             action        => "create",
                           );
    $output =~ s/^Content-Type.*[\r\n]+//m; # strip header

    Test::HTML::Content::tag_ok( $output, "form", {},
            "action=create with no arguments offers a form" );
    Test::HTML::Content::tag_ok( $output, "input",
            { type => "hidden", name => "action", value => "create" },
            "...with a hidden action=create" );

    $output = $wiki->run(
                          return_output => 1,
                          action        => "create",
                          node          => "New Page",
                        );
    like( $output, qr/^Status: 302/,
          "when sent a suitable name sends a redirect" );
    # work around old CGI.pm
    like( $output, qr|\n[Ll]ocation: http://wiki.example.com/.*action=edit|,
          "...to an edit page" );
    like( $output,
          qr|\n[Ll]ocation: http://wiki.example.com/.*node=New%20Page|,
          "...the right one" );

    $output = $wiki->run(
                          return_output => 1,
                          action        => "create",
                          node          => "new page",
                        );
    like( $output,
          qr|\n[Ll]ocation: http://wiki.example.com/.*node=New%20Page|,
          "Finds the right edit page even when sent non-canonical node name" );
}
