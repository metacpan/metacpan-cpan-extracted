use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires qw/DBD::SQLite Amon2/;

{
    package MyApp;
    use parent qw/Amon2/;
    __PACKAGE__->load_plugin(qw/DBI/);
    use File::Temp qw/tmpnam/;
    my $filename = tmpnam();
    sub config { +{ DBI => ["dbi:SQLite:dbname=$filename", '', '', {}] } }

    package MyApp::Web;
    use Amon2::Web;
    our @ISA = qw/MyApp Amon2::Web/;
    sub dispatch {
        my $c = shift;
        $c->create_response(200, [], [$c->dbh->ping ? 'OK' : 'NG']);
    }
}

subtest 'global context' => sub {
    my $app = MyApp->new();
    isa_ok $app->dbh(), 'Amon2::DBI::db';
    ok $app->dbh->ping();
    is $app->dbh(), $app->dbh(), 'cached';
};

subtest 'web context' => sub {
    my $app = MyApp::Web->to_app();
    my $res = $app->(+{});
    is $res->[0], 200;
    is $res->[2]->[0], 'OK';
};

done_testing;

