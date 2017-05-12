use strict;
use warnings;
use DBIx::Handler;
use Test::More;
use Test::SharedFork;
use Test::Requires 'DBD::SQLite';

my $handler = DBIx::Handler->new('dbi:SQLite:','','');
isa_ok $handler, 'DBIx::Handler';
isa_ok $handler->dbh, 'DBI::db';

subtest 'other db handler after disconnect' => sub {
    my $dbh = $handler->dbh;

    $handler->disconnect;

    isnt $dbh, $handler->dbh;
};

subtest 'fork' => sub {
    my $dbh = $handler->dbh;
    if (fork) {
        wait;
        is $dbh, $handler->dbh;
    } else {
        isnt $dbh, $handler->dbh;
        exit;
    }
};

subtest 'no active handle case' => sub {
    my $dbh = $handler->dbh;

    $dbh->{Active} = 0;

    isnt $dbh, $handler->dbh;
};

subtest 'can not ping case' => sub {
    no strict 'refs';
    no warnings 'redefine';

    my $dbh = $handler->dbh;

    my $ping = ref($handler->{_dbh}) . '::ping';
    local *$ping = sub { 0 };

    $handler->no_ping(1);
    is $dbh, $handler->dbh, 'no_ping: 1';
    $handler->no_ping(0);
    isnt $dbh, $handler->dbh, 'no_ping: 0';
};

subtest 'connect' => sub {
    my $h = DBIx::Handler->new('dbi:SQLite:','','');
    isa_ok $h, 'DBIx::Handler';
    isa_ok $h->dbh, 'DBI::db';
};

subtest 'disconnect' => sub {
    my $h = DBIx::Handler->new('dbi:SQLite:','','');
    isa_ok $h->dbh, 'DBI::db';
    $h->disconnect;
    ok !$h->{_dbh}, 'Removed DBH';
};

subtest 'attributes' => sub {
    subtest 'default' => sub {
        my $h = DBIx::Handler->new('dbi:SQLite:','','');
        ok $h->dbh->FETCH('RaiseError'), 'RaiseError is true';
        ok !$h->dbh->FETCH('PrintError'), 'PrintError is false';
        ok $h->dbh->FETCH('AutoInactiveDestroy'), 'AutoInactiveDestroy is true' if DBI->VERSION > 1.613;
    };

    subtest 'override:AutoInactiveDestroy' => sub {
        my $h = DBIx::Handler->new('dbi:SQLite:','','', { AutoInactiveDestroy => 0 });
        ok $h->dbh->FETCH('RaiseError'), 'RaiseError is true';
        ok !$h->dbh->FETCH('PrintError'), 'PrintError is false';
        ok !$h->dbh->FETCH('AutoInactiveDestroy'), 'AutoInactiveDestroy is false' if DBI->VERSION > 1.613;
    };

    subtest 'override:RaiseError' => sub {
        my $h = DBIx::Handler->new('dbi:SQLite:','','', { RaiseError => 0 });
        ok !$h->dbh->FETCH('RaiseError'), 'RaiseError is false';
        ok $h->dbh->FETCH('PrintError'), 'PrintError is true';
        ok $h->dbh->FETCH('AutoInactiveDestroy'), 'AutoInactiveDestroy is true' if DBI->VERSION > 1.613;
    };

    subtest 'override:PrintError' => sub {
        my $h = DBIx::Handler->new('dbi:SQLite:','','', { PrintError => 1 });
        ok $h->dbh->FETCH('RaiseError'), 'RaiseError is true';
        ok $h->dbh->FETCH('PrintError'), 'PrintError is true';
        ok $h->dbh->FETCH('AutoInactiveDestroy'), 'AutoInactiveDestroy is true' if DBI->VERSION > 1.613;
    };
};

done_testing;
