#!perl
use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

use DBIx::Fast;
use Cwd 'abs_path';

sub Check{ return -e $_[0] ? 1 : 0  }

my $db = DBIx::Fast->new(
    db     => 't/db/test.db',
    driver => 'SQLite',
    Error  => 0,
    PrintError => 0,
    trace => 1,
    profile => '!Statement:!MethodName'
    );

my $log   = abs_path($db->db->dbh->{Profile}->{File});
my $trace = abs_path('dbix-fast-trace');

$db->db->disconnect();

ok( Check($log) == 1,'Log file');
ok( Check($trace) == 1,'Trace file');

unlink $log;
unlink $trace;

done_testing();
