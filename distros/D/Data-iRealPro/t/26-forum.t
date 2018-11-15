#!perl -T

use strict;
use Test::More tests => 11;

BEGIN {
    use_ok( 'Data::iRealPro' );
    use_ok( 'Data::iRealPro::Input' );
    use_ok( 'Data::iRealPro::Output::Forum' );
}

my $i = Data::iRealPro::Input->new;
ok( $i, "Create Input object" );

my $be = Data::iRealPro::Output::Forum->new;
ok( $be, "Create Forum backend" );

my $data = <<EOD;
Song 1: Ik Zie Jou (Trudie van den Bos)
Style: Medium Swing (Pop-Slow Rock); key: C; tempo: 180; repeat: 3
Playlist: September

{T34A- ___ | _ x __ |B- ___ | _ x _ <4x>}
{A-|x|F|x<3x> _ }
|G ___ | _ x __ | _ x __ | _ x __ ]
_
EOD

my $u = $i->parsedata($data);
ok( $u->{playlist}, "Got playlist" );
my $pl = $u->{playlist};
is( scalar(@{$pl->{songs}}), 1, "Got one song" );

my $res;
$be->process( $u, { output => \$res } );
my $exp = <<'EOD';
[URL="irealb://Ik%20Zie%20Jou%3DTrudie%20van%20den%20Bos%3D%3DMedium%20Swing%3DC%3D%3D1r34LbKcu7KQyXG-XyQK3%3Cx%7CF%7Cx%7C-A%7B%7D%3Ex%3C4%20lcKQyX-BZL%20lcx%3E%20%7D%7CA43T%7Bcl%20LZ%20x%20LZ%20x%20%20%5D%20%3DPop-Slow%20Rock%3D180%3D3%3D%3D%3DSeptember"]All songs[/URL] - September
[LIST=1]
[*][URL="irealb://Ik%20Zie%20Jou%3DTrudie%20van%20den%20Bos%3D%3DMedium%20Swing%3DC%3D%3D1r34LbKcu7KQyXG-XyQK3%3Cx%7CF%7Cx%7C-A%7B%7D%3Ex%3C4%20lcKQyX-BZL%20lcx%3E%20%7D%7CA43T%7Bcl%20LZ%20x%20LZ%20x%20%20%5D%20%3DPop-Slow%20Rock%3D180%3D3"]Ik Zie Jou[/URL] - Trudie van den Bos
[/LIST]
EOD

is_deeply( $res, $exp, "Forum (playlist)" );

$u = $i->parsedata($data);
ok( $u->{playlist}, "Got playlist" );
$pl = $u->{playlist};
is( scalar(@{$pl->{songs}}), 1, "Got one song" );

undef($res);
$be->process( $u, { output => \$res, split => 1 } );
$exp = <<'EOD';
[URL="irealb://Ik%20Zie%20Jou%3DTrudie%20van%20den%20Bos%3D%3DMedium%20Swing%3DC%3D%3D1r34LbKcu7KQyXG-XyQK3%3Cx%7CF%7Cx%7C-A%7B%7D%3Ex%3C4%20lcKQyX-BZL%20lcx%3E%20%7D%7CA43T%7Bcl%20LZ%20x%20LZ%20x%20%20%5D%20%3DPop-Slow%20Rock%3D180%3D3"]Ik Zie Jou[/URL] - Trudie van den Bos
EOD

is_deeply( $res, $exp, "Forum (song)" );
