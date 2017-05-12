use Test::More;

use strict;
use warnings;
use utf8;

use Dancer::Session::DBI;
use Dancer qw(:syntax :tests);
use DBI;

unless ( $ENV{TRAVIS_TESTING} ) {
    plan( skip_all => "Travis CI specific tests not required for installation" );
}

set session => 'DBI';

for my $config (
    {dsn => "DBI:mysql:database=myapp_test;host=127.0.0.1", user => "root"},
    {dsn => "DBI:Pg:dbname=myapp_test;host=127.0.0.1", user => "postgres"},
    {dsn => "DBI:SQLite:dbname=:memory:", user => "" }
) {

    my $dbh = DBI->connect($config->{dsn}, $config->{user}, "");

    # There is no way to reference an in-memory database created elsewhere
    # So the SQLite setup goes here.
    if (!$config->{user}) {
        $dbh->do("CREATE TABLE session (id char(72), session_data varchar(2048), PRIMARY KEY (id))");
    }

    set 'session_options' => {
        table => 'session',
        dbh   => sub { $dbh },
    };

    my $current_session_id = session->id();

    ok(session(testing => "123"), "Can something in the session " . $config->{user});
    is(session('testing'), '123', "Can retrieve something from the session " . $config->{user});

    ok(session(utf8 => "☃"), "Can set UTF8 " . $config->{user});
    is(session('utf8'), '☃', "Can get UTF8 back " . $config->{user});

    is(Dancer::Session::DBI->retrieve('XXX'), undef, "Unknown session is not found " . $config->{user});

    ok(Dancer::Session::DBI->retrieve($current_session_id), "Directly retrieved session " . $config->{user});
    ok(session->destroy(), "Successfully destroyed session " . $config->{user});
    is(Dancer::Session::DBI->retrieve($current_session_id), undef, "Session was correctly destroyed " . $config->{user});

}

done_testing(24);
