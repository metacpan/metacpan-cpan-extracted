#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2026 D&D Corporation
#
# This program is distributed under the terms of the Artistic License 2.0
#
#########################################################################
use Test::More;
use Acrux::DBI;

plan skip_all => "Currently a developer-only test" unless -d ".git";
my $url = $ENV{DB_CONNECT_URL} or plan skip_all => "DB_CONNECT_URL required";
ok($url, 'DB_CONNECT_URL is correct') and note $url;

# Connect
my $dbi;
subtest 'Connecting' => sub {
    $dbi = Acrux::DBI->new($url, autoclean => 1);
    is($dbi->{autoclean}, 1, 'autoclean = 1');
    $dbi->connect;
    ok(!$dbi->error, 'Connect to ' . $dbi->dsn) or diag $dbi->error;
    ok $dbi->ping, 'Connected';

    #is($dbi->driver, 'postgres', 'Driver (scheme) is postgres');
    #is($dbi->host, 'localhost', 'Host is localhost');
    #is($dbi->port, '', 'Port is null');
    #is($dbi->userinfo, 'foo:pass', 'Userinfo is foo:pass');
    #is($dbi->password, 'pass', 'Password is pass');
    #is($dbi->database, 'mydb', 'Password is mydb');
    #is($dbi->dsn, 'DBI:Pg:dbname=mydb;host=localhost', 'DSN is DBI:Pg:dbname=mydb;host=localhost');
    #note explain {(DBI->installed_drivers)};

    #my $res = $dbi->query('select * from monm');
    #ok($res, 'select * from monm') or diag $dbi->error;
    #note explain $res;
    #note explain $res->array;
    #note explain $res->arrays;
    #note explain $res->collection_list;
    #note explain $res->columns;
    #note explain $res->hash;
    #note explain $res->hashes;
    #note explain $res->collection;
    #note $res->rows;
    #note $res->text;
    #note $res->errstr;
    #note $res->last_insert_id;
    #note explain $res->hashed_by('id');

    # Get table
    #my $rslt = $res->fetchall_arrayref;
    #   $rslt = [] unless $rslt && ref($rslt) eq 'ARRAY';
    #$res->finish;
    #note explain $rslt;

    #note explain $dbi->dbh->{Driver};
    #note $dbi->dbh->{Driver}{Name}

    #note explain $res->{'mysql_type'};
    #note explain $res->{'pg_type'};

};

subtest 'Create' => sub {
    my $res = $dbi->query('CREATE TABLE IF NOT EXISTS `names` (`id` INTEGER AUTO_INCREMENT PRIMARY KEY, `name` VARCHAR(255))');
    ok($res, 'Create table') or diag $dbi->error;
    if (ref $res) {
        # Insert a few rows
        ok($dbi->query('INSERT INTO `names` (name) VALUES (?)', 'Bob'), 'Add Bob') or diag $dbi->error;
        ok($dbi->query('INSERT INTO `names` (name) VALUES (?)', 'Alice'), 'Add Alice') or diag $dbi->error;
    }
};

subtest 'Read' => sub {
    my $res = $dbi->query('SELECT `name` FROM `names` WHERE `name` = ?', 'Bob');
    ok($res, 'Read Bob') or diag $dbi->error;
    if (ref $res) {
        is($res->hash->{name}, 'Bob', 'Bob user found');
        #note explain $res->hash;
    }
};

subtest 'Update' => sub {
    my $res = $dbi->query('UPDATE `names` SET `name` = ? WHERE `name` = ?', 'Fred', 'Bob');
    ok($res, 'Update Bob to Fred') or diag $dbi->error;
    if (ref $res) {
        my $r2 = $dbi->query('SELECT `name` FROM `names` WHERE `name` = ?', 'Fred');
        ok($r2 && $r2->rows, 'Fred user found');
    }
};

subtest 'Delete' => sub {
    my $res = $dbi->query('DELETE FROM `names` WHERE `name` = ?', 'Alice');
    ok($res, 'Delete Alice') or diag $dbi->error;
    if (ref $res) {
        my $r2 = $dbi->query('SELECT `name` FROM `names` WHERE `name` = ?', 'Alice');
        ok($r2 && !$r2->rows, 'Alice user not found');
    }
};

subtest 'Cleanup' => sub {
    my $res = $dbi->query('DROP TABLE IF EXISTS `names`');
    ok($res, 'Drop table') or diag $dbi->error;
};

done_testing;

1;

__END__

DB_CONNECT_URL='postgres://foo:pass@localhost/mydb?PrintError=1&foo=123' prove -lv t/03-connect.t
DB_CONNECT_URL='mysql://test:test@192.168.0.1/test?mysql_auto_reconnect=1&mysql_enable_utf8=1' prove -lv t/03-connect.t