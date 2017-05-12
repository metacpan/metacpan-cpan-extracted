use strict;
use Test::More tests => 7;

BEGIN
{
    use_ok("Data::Visitor::Encode");
}

my $hankaku = "ｱｲｳｴｵ";
my $zenkaku = "アイウエオ";

my $dve = Data::Visitor::Encode->new;

my $converted = $dve->h2z('utf-8', $hankaku);
is($converted, $zenkaku);

$converted = $dve->z2h('utf-8', $zenkaku);
is($converted, $hankaku);

my $sjis_hankaku = Encode::encode('sjis', Encode::decode('utf-8', $hankaku));
my $sjis_zenkaku = Encode::encode('sjis', Encode::decode('utf-8', $zenkaku));

$converted = $dve->h2z('sjis', $sjis_hankaku);
is($converted, $sjis_zenkaku);

$converted = $dve->z2h('sjis', $sjis_zenkaku);
is($converted, $sjis_hankaku);

my $euc_hankaku = Encode::encode('euc-jp', Encode::decode('utf-8', $hankaku));
my $euc_zenkaku = Encode::encode('euc-jp', Encode::decode('utf-8', $zenkaku));

$converted = $dve->h2z('euc-jp', $euc_hankaku);
is($converted, $euc_zenkaku);

$converted = $dve->z2h('euc-jp', $euc_zenkaku);
is($converted, $euc_hankaku);

1;