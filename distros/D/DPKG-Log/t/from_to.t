use Test::More tests => 10;
use lib 'lib';
use DPKG::Log;
use Data::Dumper;

my $dpkg_log;
my $filename;
ok($dpkg_log = DPKG::Log->new('filename'=> 'test_data/from_to.log'), "initialize DPKG::Log object");
$dpkg_log->parse;
ok(@entries = 
    $dpkg_log->entries('from' => '2011-02-02 00:00:00', 'to' => '2011-02-03 00:00:00'),
    'entries(from => ... , to => ...)  returns array'
);
is(scalar(@entries), 78, 'Number of entries is correct');
ok($entries[int(rand(77))]->timestamp->epoch <= 1296691200,
    "Sample entry has timestamp below 1296691200");

ok($dpkg_log = DPKG::Log->new('filename' => 'test_data/from_to.log',
        'from' => '2011-02-02 00:00:00',
        'to' => '2011-02-03 00:00:00'),
        'Initialize DPKG::Log object with limited time range');
$dpkg_log->parse;
ok(@entries = $dpkg_log->entries(), "entries returns array");
is(scalar(@entries), 78, 'Number of entries is correct');

ok($dpkg_log = DPKG::Log->new('filename' => 'test_data/from_to.log',
        'from' => '2011-02-02',
        'to' => '2011-02-03',
        'timestamp_pattern' => '%F'),
        'Initialize DPKG::Log object with limited time range and custom pattern');
$dpkg_log->parse;
ok(@entries = $dpkg_log->entries(), "entries returns array");
is(scalar(@entries), 78, 'Number of entries is correct');

