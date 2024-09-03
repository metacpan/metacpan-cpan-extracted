#!perl
use strict;
use warnings FATAL => 'all';

use Test::More;
use DBIx::Fast;

use Cwd 'abs_path';

sub Check{ return -e $_[0] ? 1 : 0  }

plan( skip_all => 'Skip tests on Windows' ) if $^O eq 'MSWin32';

plan tests => 2;

my $db = DBIx::Fast->new(
    db     => 't/db/test.db',
    driver => 'SQLite',
    RaiseError => 0,
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
