package t::DBIx::Handler::Sunny;
use parent qw(Test::Class);
use Test::More;
use Test::Requires qw(Test::mysqld Test::TCP);
use Class::Accessor::Lite (
    ro => ['handler'],
);
use DBIx::Handler::Sunny;
use t::query;

sub _prepare_db : Test(startup => 3) {
    my $self = shift;

    my $port = Test::TCP::empty_port;
    my $mysqld = Test::mysqld->new(
        my_cnf => {
            port => $port,
            'bind-address' => '127.0.0.1',
            'character_set_server' => 'latin1',
        }
    );

    ok my $handler = DBIx::Handler::Sunny->new(
        $mysqld->dsn(dbname => 'test'), 'root', ''
    );
    isa_ok $handler, 'DBIx::Handler::Sunny';
    isa_ok $handler->dbh, 'DBI::db';

    $handler->dbh->do(q(
        CREATE TABLE query_test (
            id INT UNSIGNED NOT NULL AUTO_INCREMENT,
            name VARCHAR(10) NOT NULL,
            PRIMARY KEY (id)
        );
    ));

    $self->{mysqld} = $mysqld;
    $self->{handler} = $handler;
}

sub last_insert_id : Tests {
    my $db = shift->handler;
    $db->query(q(
        INSERT INTO query_test (id, name) VALUES (2, 'tarao')
    ));
    is $db->last_insert_id, 2;

    $db->query(q(
        INSERT INTO query_test (name) VALUES ('katsuo')
    ));
    is $db->last_insert_id, 3;
}

package t::DBIx::Handler::Sunny::Model;
use Class::Accessor::Lite (new => 1);

package t::DBIx::Handler::Sunny;

__PACKAGE__->runtests;
