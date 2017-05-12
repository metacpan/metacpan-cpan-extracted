package TestApp::Model::TestApp;

use base qw/Catalyst::Model::DBIC::Schema/;
use strict;

my @deployment_statements = split /;/, q{
    CREATE TABLE user (
        id       INTEGER PRIMARY KEY,
        username TEXT,
        email    TEXT,
        password TEXT,
        status   TEXT,
        role_text TEXT,
        session_data TEXT
    );
    CREATE TABLE role (
        id   INTEGER PRIMARY KEY,
        role TEXT
    );
    CREATE TABLE user_role (
        id   INTEGER PRIMARY KEY,
        user INTEGER,
        roleid INTEGER
    );

    INSERT INTO user VALUES (1, 'joeuser', 'joeuser@nowhere.com', 'hackme', 'active', 'admin', NULL);
    INSERT INTO user VALUES (2, 'spammer', 'bob@spamhaus.com', 'broken', 'disabled', NULL, NULL);
    INSERT INTO user VALUES (3, 'jayk', 'j@cpants.org', 'letmein', 'active', NULL, NULL);
    INSERT INTO user VALUES (4, 'nuffin', 'nada@mucho.net', 'much', 'registered', 'user admin', NULL);
    INSERT INTO role VALUES (1, 'admin');
    INSERT INTO role VALUES (2, 'user');
    INSERT INTO user_role VALUES (1, 3, 1);
    INSERT INTO user_role VALUES (2, 3, 2);
    INSERT INTO user_role VALUES (3, 4, 2)
};

__PACKAGE__->config(
    schema_class => 'TestApp::Schema',
    connect_info => [
        "dbi:SQLite:dbname=:memory:",
        '',
        '',
        { AutoCommit => 1 },
        { on_connect_do => \@deployment_statements },
    ],
);

# Load all of the classes
#__PACKAGE__->load_classes(qw/Role User UserRole/);


1;
