use Test::More tests => 33;
use Test::LongString;
use File::Spec;
use strict;

use Audio::MPC;
ok(1); 

my $mpc = Audio::MPC->new(File::Spec->catfile('t', 'test.mpc'));
ok($mpc);

my @info = qw/length frequency channels header_pos version bps
              average_bps frames samples max_band is ms block_size
	      profile profile_name gain_title gain_album peak_title
	      peak_album is_gapless last_frame_samples encoder_version
	      encoder tag_offset total_length/;

my %expected;
@expected{@info} = (
    [ '1.655', sub { sprintf "%.3f", shift } ], 44100, 2, 0, 7, 0, 
    [ 160065, sub { int shift } ], 64, 73152, 28, 0, 1, 1,
    10, "'Standard'", 0, 0, 0,
    0, 1, 417, 115, 
    '--Alpha-- 1.15', 33189, 33189);

for (@info) {
    my $val = $mpc->$_;
    if (ref $expected{ $_ }) {
	is($expected{ $_ }->[1]->($val), $expected{ $_ }->[0]);
    } else {
	is($val, $expected{ $_ });
    }
}

my $wav = do {
    open my $f, File::Spec->catfile('t', 'test.wav');
    binmode $f;
    local $/;
    <$f>;
};

my ($head, $data) = (substr($wav, 0, 44), substr($wav, 44));

{
    my $data_from_mpc;
    my $total;
    while (my $len = $mpc->decode(my $buf, MPC_LITTLE_ENDIAN)) {
	last if $len == 0;
	$data_from_mpc .= $buf;
	$total += $len;
    }

    is_string($data_from_mpc, $data);
    is_string($mpc->wave_header($total, MPC_LITTLE_ENDIAN), $head);
}

# do the above two tests again: this time seek_sample
$mpc->seek_sample(0);
{
    my $data_from_mpc;
    my $total;
    while (my $len = $mpc->decode(my $buf, MPC_LITTLE_ENDIAN)) {
	last if $len == 0;
	$data_from_mpc .= $buf;
	$total += $len;
    }

    is_string($data_from_mpc, $data);
    is_string($mpc->wave_header($total, MPC_LITTLE_ENDIAN), $head);
}

# do the above two tests again: this time seek_seconds
$mpc->seek_seconds(0);
{
    my $data_from_mpc;
    my $total;
    while (my $len = $mpc->decode(my $buf, MPC_LITTLE_ENDIAN)) {
	last if $len == 0;
	$data_from_mpc .= $buf;
	$total += $len;
    }

    is_string($data_from_mpc, $data);
    is_string($mpc->wave_header($total, MPC_LITTLE_ENDIAN), $head);
}
