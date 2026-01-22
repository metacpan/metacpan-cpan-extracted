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
    $dbi = Acrux::DBI->new($url, autoclean => 1)->connect;
    ok(!$dbi->error, 'Connect to ' . $dbi->dsn) or diag $dbi->error;
    ok $dbi->ping, 'Connected' or return;
};

subtest 'Create table' => sub {
    my $res = $dbi->query('CREATE TABLE IF NOT EXISTS `names` (`id` INTEGER AUTO_INCREMENT PRIMARY KEY, `name` VARCHAR(255))');
    ok($res, 'Create table') or do { diag $dbi->error; return }
};

subtest 'Transactions1' => sub {
    $dbi->dbh->{AutoCommit} = 0;  # enable transactions, if possible
    eval {
        my $tx = $dbi->transaction;
        $dbi->query("INSERT INTO `names` (name) values ('foo')") or die $dbi->error;
        $dbi->query("INSERT INTO `names` (name_bad) values ('bar')") or die $dbi->error;
        $tx->commit;
    };
    ok($@, 'Transaction 1 completed with errors') and diag $@ // 'oops';
};

subtest 'Transactions2' => sub {
    $dbi->dbh->{AutoCommit} = 0;  # enable transactions, if possible
    eval {
        my $tx = $dbi->transaction;
        $dbi->query("INSERT INTO `names` (name) values ('baz')") or die $dbi->error;
        $dbi->query("INSERT INTO `names` (name) values ('qux')") or die $dbi->error;
        $tx->commit;
    };
    ok(!$@, 'Transaction 2 completed without errors') or diag $@ // 'oops';
};

subtest 'Cleanup' => sub {
    my $res = $dbi->query('DROP TABLE IF EXISTS `names`');
    ok($res, 'Drop table') or diag $dbi->error;
};

done_testing;

1;

__END__

DB_CONNECT_URL='mysql://test:test@192.168.0.1/test?mysql_auto_reconnect=1&mysql_enable_utf8=1' prove -lv t/04-transaction.t