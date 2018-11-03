#!perl -T

use strict;
use Test::More tests => 8;

BEGIN {
    use_ok( 'Data::iRealPro' );
    use_ok( 'Data::iRealPro::URI' );
    use_ok( 'Data::iRealPro::Output::Text' );
}

my $u = Data::iRealPro::URI->new;
ok( $u, "Create URI object" );

my $be = Data::iRealPro::Output::Text->new;
ok( $be, "Create Text backend" );

my $data = <<EOD;
<a href="irealb://You're%20Still%20The%20One%3DTwain%20Shania%3D%3DRock%20Ballad%3DC%3D%3D1r34LbKcu7L%23F/D4DLZD%7D%20AZLGZL%23F/DZLAD*%7B%0A%7D%20AZLGZL%23F/%0A%7CDLZ4Ti*%7BDZLAZLZSDLGZLDB*%7B%0A%5D%20AZLALZGZLDZLAZLAZLGZLZE-LAZLGZ%23F/DZALZN1%5D%20%3EadoC%20la%20.S.%3CD%20A2N%7CQyXQyX%7D%20G%0A%5BQDLZLGZLLZGLZfA%20Z%20%3D%3D155%3D0">You're Still The One</a>
EOD

$u->parse($data);
ok( $u->{playlist}, "Got playlist" );
my $pl = $u->{playlist};
is( scalar(@{$pl->{songs}}), 1, "Got one song" );

my $res;
$be->process( $u, { output => \$res } );
my $exp = <<'EOD';
Song: You're Still The One (Shania Twain)
Style: Rock Ballad; key: C; actual key: C; tempo: 155

{*i T44D _ |D/F# _ |G _ |A _ }
{*A D _ |D/F# _ |G _ |A _ }
|D _ |D/F# _ |G _ |A _ |SD _ |G _ |A _ |A _ |D _ |G _ |A _ |A _ ]
{*B D _ |G _ |E- _ |A _ |D _ |G _ |A _ |N1G _ }
______ |N2A _<D.S. al Coda>_ ]
[QD _ |D/F# _ |G _ |fA _ Z _

EOD

is_deeply( $res, $exp, "Text (song)" );
