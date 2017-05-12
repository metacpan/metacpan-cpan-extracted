use strict;
use warnings;
use DBIx::Handler;
use Test::More;
use Test::Requires 'DBD::SQLite';

subtest 'on_(disconnect|connect)_do' => sub {
    my $handler = DBIx::Handler->new('dbi:SQLite:','','', undef, +{
        on_connect_do    => sub { my $dbh = shift; isa_ok $dbh, 'DBI::db'},
        on_disconnect_do => sub { my $dbh = shift; isa_ok $dbh, 'DBI::db'},
    });

    isa_ok $handler, 'DBIx::Handler';
    isa_ok $handler->dbh, 'DBI::db';
    $handler->disconnect;
};

subtest 'on_connect_do' => sub {
    my $handler = DBIx::Handler->new('dbi:SQLite:','','', undef, +{
        on_connect_do => sub { my $dbh = shift; isa_ok $dbh, 'DBI::db'},
    });

    isa_ok $handler, 'DBIx::Handler';
    isa_ok $handler->dbh, 'DBI::db';

    $handler->disconnect;
};

subtest 'on_disconnect_do' => sub {
    my $handler = DBIx::Handler->new('dbi:SQLite:','','', undef, +{
        on_disconnect_do => sub { my $dbh = shift; isa_ok $dbh, 'DBI::db'},
    });

    isa_ok $handler, 'DBIx::Handler';
    isa_ok $handler->dbh, 'DBI::db';

    $handler->disconnect;
};

done_testing;
