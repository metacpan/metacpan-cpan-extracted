use warnings;
use strict;
use Test::More;
use CGI::Wiki::Kwiki;
use CGI::Wiki::Setup::SQLite;

use lib "./t/lib"; # for test formatters

eval { require DBD::SQLite; require CGI::Wiki::Formatter::Multiple; };

if ( $@ ) {
    plan skip_all => "Either DBD::SQLite or CGI::Wiki::Formatter::Multiple not installed";
} else {
    plan tests => 3;

    # Clear database, instantiate wiki, add some data.
    CGI::Wiki::Setup::SQLite::cleardb( "./t/wiki.db" );
    CGI::Wiki::Setup::SQLite::setup( "./t/wiki.db" );
    my $wiki = CGI::Wiki::Kwiki->new(
        db_type       => "SQLite",
        db_name       => "./t/wiki.db",
        formatters    => {
                           pony     => "Local::Test::Formatter::Pony",
                           pie      => "Local::Test::Formatter::Pie",
                           _DEFAULT => "Local::Test::Formatter::Buffy",
                         },
        template_path => './templates',
    );
    $wiki->{wiki}->write_node( "Pony", "test", undef,
                               { formatter => "pony" } ) or die "Can't write";
    $wiki->{wiki}->write_node( "Pie", "test", undef,
                               { formatter => "pie" } )  or die "Can't write";
    $wiki->{wiki}->write_node( "No Formatter", "test" )  or die "Can't write";

    # Test that the correct formatter is being used.
    my $output = $wiki->run(
                             return_output => 1,
                             node          => "Pony"
                           );
    like( $output, qr/PONY/, "pony formatter used as expected" );

    $output = $wiki->run(
                          return_output => 1,
                          node          => "Pie"
                        );
    like( $output, qr/PIE/, "pie formatter used as expected" );

    $output = $wiki->run(
                          return_output => 1,
                          node          => "No Formatter"
                        );
    like( $output, qr/BUFFY/, "default formatter used" );
}
