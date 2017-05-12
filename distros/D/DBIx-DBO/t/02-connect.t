use strict;
use warnings;

my $dbo;
use DBIx::DBO AutoReconnect => 1;
use Test::DBO Sponge => 'Sponge', connect_ok => [\$dbo], tests => 9;

is $dbo, $dbo->dbo, 'Method DBIx::DBO->dbo';

# Hack to fix Sponge ping()
$dbo->dbh->STORE(Active => 1);

is $dbo->rdbh, $dbo->dbh, 'rdbh falls back to the read-write handle';

ok $dbo->connect_readonly('DBI:Sponge:'), 'Connect read-only handle';

$dbo->dbh->STORE(Active => 0);
$dbo->disconnect;

ok $dbo->connect, 'AutoReconnect read-write handle';
ok $dbo->connect_readonly, 'AutoReconnect read-only handle';

$dbo->disconnect;
DBIx::DBO->config(AutoReconnect => 0);

ok $dbo->connect('DBI:Sponge:'), 'Reconnect read-write handle';
ok $dbo->connect_readonly('DBI:Sponge:'), 'Reconnect read-only handle';

