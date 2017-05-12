use Test::More tests => 16;
use lib 'lib';
use DPKG::Log;

my $dpkg_log;
my $filename;
can_ok('DPKG::Log', 'entries');
can_ok('DPKG::Log', 'next_entry');
can_ok('DPKG::Log', 'filter_by_time');
can_ok('DPKG::Log', 'get_datetime_info');
ok($dpkg_log = DPKG::Log->new(filename => 'test_data/dpkg.log'), "initialize DPKG::Log object");
ok($filename = $dpkg_log->filename, "filename() returns filename");
ok($dpkg_log->filename("test.log"), "filename('test.log')");
is($dpkg_log->filename, "test.log", "filename() returns 'test.log'");
$dpkg_log->filename('test_data/dpkg.log');
ok($dpkg_log->parse > 0, "parse() returns a value greater 0" );
is(scalar(@{$dpkg_log->{invalid_lines}}), 0, "0 invalid lines" );
ok($entry = $dpkg_log->next_entry, "next entry returns an entry" );
isa_ok($entry, "DPKG::Log::Entry", "entry");
ok( my ($from, $to) = $dpkg_log->get_datetime_info(), "get_datetime_info returns report period info");
ok( $dpkg_log = DPKG::Log->new(filename => 'test_data/dpkg.log', parse => 1),
    'initialize DPKG::Log object with parse = 1');
ok ( eval { $dpkg_log->entries >= 0 } , "object stores entries");
ok ($dpkg_log = $dpkg_log->new(filename => 'test_data/dpkg.log'), 'initialize object from existing ref');
