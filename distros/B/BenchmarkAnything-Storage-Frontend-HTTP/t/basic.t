use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

# my $cfgfile   = "t/benchmarkanything-mysql.cfg";
# my $dsn       = 'DBI:mysql:database=benchmarkanythingtest';
my $cfgfile   = "t/benchmarkanything.cfg";
my $dsn       = 'dbi:SQLite:t/benchmarkanything.sqlite';

$ENV{BENCHMARKANYTHING_CONFIGFILE} = $cfgfile;

my $t = Test::Mojo->new('BenchmarkAnything::Storage::Frontend::HTTP');
$t->get_ok('/api/v1/listnames')->status_is(200);

done_testing();
