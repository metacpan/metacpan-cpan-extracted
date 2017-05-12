package t::DBIx::Handler::Sunny;
use parent qw(Test::Class);
use Test::More;
use Test::Requires 'DBD::SQLite';
use Class::Accessor::Lite (
    ro => ['handler'],
);
use DBIx::Handler::Sunny;
use t::query;

my $db_file = './query_test.db';

sub _prepare_db : Test(startup => 3) {
    my $self = shift;

    unlink $db_file;
    ok my $handler = DBIx::Handler::Sunny->new("dbi:SQLite:$db_file", '', '');
    isa_ok $handler, 'DBIx::Handler::Sunny';
    isa_ok $handler->dbh, 'DBI::db';

    $handler->dbh->do(q(
        CREATE TABLE query_test (
            name VARCHAR(10) NOT NULL,
            PRIMARY KEY (name)
        );
    ));

    $self->{handler} = $handler;
}

sub _cleanup_db : Test(shutdown) {
    unlink $db_file;
}

sub last_insert_id : Tests {
    my $db = shift->handler;
    $db->query(q(
        INSERT INTO query_test (name) VALUES ('tarao')
    ));
    is $db->last_insert_id, 1;

    $db->query(q(
        INSERT INTO query_test (name) VALUES ('katsuo')
    ));
    is $db->last_insert_id, 2;
}

package t::DBIx::Handler::Sunny::Model;
use Class::Accessor::Lite (new => 1);

package t::DBIx::Handler::Sunny;

__PACKAGE__->runtests;
