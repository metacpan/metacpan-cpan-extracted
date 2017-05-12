use strict;
use warnings;
use Test::More;
use Amon2::DBI;
use Test::Requires 'DBD::SQLite';

my $call_connected;
my $call_prepare = 0;
my $call_execute = 0;

my $dbh = Amon2::DBI->connect('dbi:SQLite::memory:', '', '',{
    Callbacks => {
        connected => sub {
            shift->do(q{CREATE TABLE foo (e)});
            $call_connected = 1;
            return;
        },
        prepare => sub {
            $call_prepare++;
            return;
        },
        ChildCallbacks => {
            execute => sub {
                my $obj = shift;
                $call_execute++;
                return;
            },
        },
    }
});

ok($call_connected);
is($call_prepare,0);
is($call_execute,0);

$dbh->insert('foo', {e => 3});
is($call_prepare,1);
is($call_execute,1);

$dbh->do_i('INSERT INTO foo ', {e => 4});
is($call_prepare,2);
is($call_execute,2);

is join(',', map { @$_ } @{$dbh->selectall_arrayref('SELECT * FROM foo ORDER BY e')}), '3,4';
is($call_prepare,3);
is($call_execute,2);
#is($call_execute,4); execute is not called by selectall_arrayref 

done_testing;

