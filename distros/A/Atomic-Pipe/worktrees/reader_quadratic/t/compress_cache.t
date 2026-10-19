use Test2::V0;
use Atomic::Pipe;

skip_all "requires Compress::Zstd" unless eval { require Compress::Zstd; 1 };

my $calls = 0;
my $orig  = \&Atomic::Pipe::_compress;
no warnings 'redefine';
local *Atomic::Pipe::_compress = sub { $calls++; $orig->(@_) };

my ($r, $w) = Atomic::Pipe->pair(compression => 'zstd', mixed_data_mode => 1);

my $data = "compress me " x 20;
ok($w->fits_in_burst($data), "data fits in a burst");
ok($w->write_burst($data), "burst written");

is($calls, 1, "fits_in_burst + write_burst compressed the payload only once");

my ($type, $got) = $r->get_line_burst_or_data;
is($type, 'burst', "got the burst");
is($got, $data, "payload round-tripped intact");

# A different payload must not reuse the cached compression.
$calls = 0;
ok($w->write_burst("something else"), "second burst written");
is($calls, 1, "new payload was compressed");
($type, $got) = $r->get_line_burst_or_data;
is($got, "something else", "second payload intact");

done_testing;
