use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common qw(GET DELETE);
use Dancer2;
use Dancer2::Plugin::DBIC;
use DBI;
use File::Temp qw(tempfile);
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

use TestApp;

eval { require DBD::SQLite; require DBIx::Class::Schema::Loader };
if ($@) {
    plan skip_all =>
        'DBD::SQLite and DBIx::Class::Schema::Loader required for these tests';
}

my (undef, $dbfile) = tempfile(SUFFIX => '.db');

t::lib::TestApp::set plugins => {
    DBIC => {
        foo => {
            dsn =>  "dbi:SQLite:dbname=$dbfile",
        }
    }
};

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile");

my @sql = (
    q/create table users (id INTEGER primary key, name VARCHAR(64))/,
    q/insert into users values (1, 'sukria')/,
    q/insert into users values (2, 'bigpresh')/,
);

$dbh->do($_) for @sql;

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

subtest 'root' => sub {
    my $res = $test->request( GET '/' );

    like(
        $res->header('Content-Type'),
        qr{text/html},
        'Content-Type set up correctly',
    );

    like(
        $res->content,
        qr/2/,
        'content looks good for /',
    );
};

subtest 'user1' => sub {
    my $res = $test->request( GET '/user/1' );

    is(
        $res->status_line,
        '200 OK',
        'GET /user/1 is found',
    );

    like(
        $res->content,
        qr/sukria/,
        'content looks good for /user/1',
    );
};

subtest 'user2' => sub {
    my $res = $test->request( GET '/user/2' );

    is(
        $res->status_line,
        '200 OK',
        'GET /user/2 is found',
    );

    like(
        $res->content,
        qr/bigpresh/,
        "content looks good for /user/2",
    );
};

subtest 'delete' => sub {
    my $res = $test->request( DELETE '/user/2' );

    is(
        $res->status_line,
        '200 OK',
        'DELETE /user/2 is ok',
    );
};

subtest 'root again' => sub {
    my $res = $test->request( GET '/' );

    like(
        $res->header('Content-Type'),
        qr{text/html},
        'Content-Type set up correctly',
    );

    like(
        $res->content,
        qr/1/,
        'content looks good for /',
    );
};

unlink $dbfile;

done_testing;
