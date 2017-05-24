#!perl -T

use strict;
use Test::More tests => 5;

BEGIN {
    use_ok( 'Data::iRealPro::Input' );
}

my $in = Data::iRealPro::Input->new;
ok( $in, "Create input handler" );

my $data = <<EOD;
Song: You're Still The One (Shania Twain)
Style: Rock Ballad; key: C; tempo: 155

{*i T44D _ |D/F# _ |G _ |A _ }
{*A D _ |D/F# _ |G _ |A _ }
|D _ |D/F# _ |G _ |A _ |SD _ |G _ |A _ |A _ |D _ |G _ |A _ |A _ ]
{*B D _ |G _ |E- _ |A _ |D _ |G _ |A _ |N1G _ }
______ |N2A _<D.S. al Coda>_ ]
[QD _ |D/F# _ |G _ |fA _ Z _

EOD

my $u = $in->parsedata($data);
ok( $u->{playlist}, "Got playlist" );
my $pl = $u->{playlist};
is( scalar(@{$pl->{songs}}), 1, "Got one song" );

my $res = $u->as_string(1);
my $exp = <<'EOD';
irealb://You're%20Still%20The%20One%3DTwain%20Shania%3D%3DRock%20Ballad%3DC%3D%3D1r34LbKcu7L%23F/D44DLZ%20AZLGZL%23F/DZLDA%2C*%7B%7D%20AZLGZL%23F/D%7D%7CDLZT%2Ci*%7BDZLAZLZSDLGZLD%2CB*%7B%5D%20AZLALZGZLDZLAZLAZLGZLZE-LAZLGZL%23F/DALZN1%5D%20%3EadoC%20la%20.S.%3CD%20A2N%7CQyXQyX%7D%20G%5BQDLZZLGZLZGLZfA%20Z%20%3D%3D155%3D0
EOD
chomp($exp);

is_deeply( $res, $exp, "Text input" );
