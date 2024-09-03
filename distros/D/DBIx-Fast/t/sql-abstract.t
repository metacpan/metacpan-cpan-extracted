#!perl -T
use lib '/Users/real/Mios/code/DBIx-Fast/lib/';
use strict;
use warnings FATAL => 'all';

use Test::More;

use DBIx::Fast;

eval "use SQL::Abstract 2.00";
plan skip_all => "SQL::Abstract 2.00" if $@;

eval "use DBD::SQLite 1.50";
plan skip_all => "DBD::SQLite 1.50" if $@;

plan tests => 15;

my $db = DBIx::Fast->new(
    db     => 't/db/test.db',
    driver => 'SQLite',
    Error  => 1,
    PrintError => 1 );

is ref $db->Q,'SQL::Abstract','Q() - SQL::Abstract ISA';

for my $Method ( qw(select insert update delete) ) {
    can_ok($db->Q,$Method);
}

my $Abs = $db->Q;
my ($stmt,@bind);

my (%data,%where,%field);

%data = ( user => 'tester', domain => 'domain.com', passwd => 'aaa', status => 0, admin => 0, time_mod => '0000-00-00' );

($stmt,@bind) = $Abs->insert('acceso', \%data);

is scalar(@bind),scalar(keys %data),'SQL::Abstract insert() bind='.scalar(keys %data);
is $stmt,'INSERT INTO acceso (admin, domain, passwd, status, time_mod, user) VALUES (?, ?, ?, ?, ?, ?)',
    'SQL::Abstract insert() stmt';

%where = (
    requestor => 'inna',
    worker => ['nwiger', 'rcwe', 'sfz'],
    status => { '!=', 'completed' }
    );

($stmt, @bind) = $Abs->select('tickets', '*', \%where);

is scalar(@bind),5,'SQL::Abstract select() bind=5';
is $stmt,'SELECT * FROM tickets WHERE ( requestor = ? AND status != ? AND ( worker = ? OR worker = ? OR worker = ? ) )',
    'SQL::Abstract select() stmt';

%where = ( id => 1 , user => 'tester' );
%field = ( message => 'DBIx::Fast Test' , email => 'email@domain.com' );

($stmt, @bind) = $Abs->update('tickets', \%field, \%where);

is scalar(@bind),4,'SQL::Abstract update() bind=4';
is $stmt,'UPDATE tickets SET email = ?, message = ? WHERE ( id = ? AND user = ? )',
    'SQL::Abstract update() stmt';

%where = ( id => 1 , status => 9 );
($stmt,@bind) = $Abs->delete('tickets', \%where);

is scalar(@bind),2,'SQL::Abstract delete() bind=2';
is $stmt,'DELETE FROM tickets WHERE ( id = ? AND status = ? )','SQL::Abstract delete() stmt';

%where = ( -and => [
		-bool => 'one',
		-not_bool => { two=> { -rlike => 'bar' } },
		-not_bool => { three => [ { '=', 2 }, { '>', 5 } ] },
	   ], id => 1 , status => 8 );

($stmt,@bind) = $Abs->select('tickets', \%where);

is scalar(@bind),0,'SQL::Abstract select() complex bind=0';
is $stmt,'SELECT ( ( one AND (NOT two RLIKE bar) AND (NOT ( three = 2 OR three > 5 )) ) AND id = 1 AND status = 8 ) FROM tickets',
    'SQL::Abstract select() complex stmt';

done_testing();
