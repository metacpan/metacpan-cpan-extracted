use Test2::V0;
use Atomic::Pipe;

# eof() must report false while the mixed-mode buffer still holds usable
# data, including the falsy-but-real string "0".

my ($r, $w) = Atomic::Pipe->pair(mixed_data_mode => 1);
$w->close;
$r->fill_buffer;    # observe the EOF

my $buffer = $r->{mixed_buffer} = {
    lines      => undef,
    burst      => '0',
    in_burst   => 0,
    in_message => 0,
    strip_term => 0,
};

ok(!$r->eof, "buffered burst data '0' means not EOF");

$buffer->{burst} = '';
$buffer->{lines} = '0';
ok(!$r->eof, "buffered line data '0' means not EOF");

$buffer->{lines} = '';
ok($r->eof, "empty buffers at EOF really is EOF");

done_testing;
