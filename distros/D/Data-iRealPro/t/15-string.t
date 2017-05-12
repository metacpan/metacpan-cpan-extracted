#!perl -T

use strict;
use Test::More tests => 8;

BEGIN {
    use_ok( 'Data::iRealPro::URI' );
}

my $u = Data::iRealPro::URI->new;
ok( $u, "Create URI object" );

my $data = <<'EOD';
<a href="irealb://You're%20Still%20The%20One%3DTwain%20Shania%3D%3DRock%20Ballad%3DC%3D%3D1r34LbKcu7L%23F/D4DLZD%7D%20AZLGZL%23F/DZLAD*%7B%0A%7D%20AZLGZL%23F/%0A%7CDLZ4Ti*%7BDZLAZLZSDLGZLDB*%7B%0A%5D%20AZLALZGZLDZLAZLAZLGZLZE-LAZLGZ%23F/DZALZN1%5D%20%3EadoC%20la%20.S.%3CD%20A2N%7CQyXQyX%7D%20G%0A%5BQDLZLGZLLZGLZfA%20Z%20%3D%3D155%3D0">You're Still The One</a>
EOD

$u->parse($data);
ok( $u->{playlist}, "Got playlist" );
my $pl = $u->{playlist};
is( scalar(@{$pl->{songs}}), 1, "Got one song" );
my $song = $pl->{songs}->[0];

my $exp = <<'EOD';
You're Still The One=Twain Shania==Rock Ballad=C==1r34LbKcu7L#F/D4DLZD} AZLGZL#F/DZLAD*{
} AZLGZL#F/
|DLZ4Ti*{DZLAZLZSDLGZLDB*{
] AZLALZGZLDZLAZLAZLGZLZE-LAZLGZ#F/DZALZN1] >adoC la .S.<D A2N|QyXQyX} G
[QDLZLGZLLZGLZfA Z ==155=0
EOD
chomp($exp);

is( $song->as_string, $exp, "Song as string" );
is( $pl->as_string, $exp, "Playlist as string" );

$exp = "irealb://" . $exp;

is( $u->as_string, $exp, "URI as string" );

$exp = <<'EOD';
irealb://You're%20Still%20The%20One%3DTwain%20Shania%3D%3DRock%20Ballad%3DC%3D%3D1r34LbKcu7L%23F/D4DLZD%7D%20AZLGZL%23F/DZLAD*%7B%0A%7D%20AZLGZL%23F/%0A%7CDLZ4Ti*%7BDZLAZLZSDLGZLDB*%7B%0A%5D%20AZLALZGZLDZLAZLAZLGZLZE-LAZLGZ%23F/DZALZN1%5D%20%3EadoC%20la%20.S.%3CD%20A2N%7CQyXQyX%7D%20G%0A%5BQDLZLGZLLZGLZfA%20Z%20%3D%3D155%3D0
EOD
chomp($exp);

is( $u->as_string(1), $exp, "URI as escaped string" );
