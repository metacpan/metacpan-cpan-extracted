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
irealb://You're%20Still%20The%20One%3DTwain%20Shania%3D%3DRock%20Ballad%3DC%3D%3D1r34LbKcu7GZL%23F4DLZD%7C%7D%20AZLGZL%23F/DZDLA*%7B%7D%20AZLGZL%23F/DLZD/4Ti*%7BGZLDZSDLZGEZLGZLDB*%7B%5D%20AZALZLGZLDZLAZLAZL-LZALZLAZLLGZL%23N1G%20%7DDQ%5B%5D%20%3EadoC%20la%20S..D%3C%20A2N%7CQyXQyXLZD/FZLAZLZfA%20Z%20%3D%3D155%3D0
EOD
chomp($exp);

is_deeply( $res, $exp, "Text input" );
