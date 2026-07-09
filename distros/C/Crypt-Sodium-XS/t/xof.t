use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::xof;

plan skip_all => 'no xof available' unless Crypt::Sodium::XS::xof->available;

use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

my @test_strs = qw(foo bar baz);
my %test_out = (
  shake128 => '02cee818616be2012ed040818eb62b13d5fa77e6a778c4effcd0f12c5ffd1fba',
  shake256 => '8afe651984cf6edd5db286828d781816c74027c79becbebcf9b07870fda2c0a8',
  turboshake128 => '4a4e59a1d85d7c3ed033361627e4539df27e37687659bdd7fa6707b3af95dafa',
  turboshake256 => 'aced82a5418673c6fdbe0ce598885a07dd7880480573a1dcec8e5a6688455d8f',
);

for my $alg (Crypt::Sodium::XS::xof->primitives) {
  my $xof = Crypt::Sodium::XS->xof(primitive => $alg);

  for my $const (qw(BLOCKBYTES STATEBYTES)) {
    ok($xof->$const > 0, "$const > 0 ($alg)");
  }
  my $dom = $xof->DOMAIN_STANDARD;
  ok(length($dom) == 1, "1 byte domain ($alg)");
  ok(0 < ord($dom) && ord($dom) < 0x7f, "domain within range ($alg)");

  my $out = $xof->xof(join('', @test_strs), 32);
  is(unpack("H*", $out), $test_out{$alg}, "xof output matches expected ($alg)");

  my $multi = $xof->init;
  $multi->update(@test_strs);
  $out = $multi->squeeze(32);
  is(unpack("H*", $out), $test_out{$alg}, "multi output matches expected ($alg)");

  $multi = $xof->init;
  $multi->update($test_strs[0]);
  my $multi2 = $multi->clone;
  $multi->update(@test_strs[1 .. $#test_strs]);
  $multi2->update(@test_strs[1 .. $#test_strs]);
  $out = $multi->squeeze(32);
  is(unpack("H*", $out), $test_out{$alg}, "split multi output matches expected ($alg)");
  $out = $multi2->squeeze(32);
  is(unpack("H*", $out), $test_out{$alg}, "cloned split multi output matches expected ($alg)");
  undef $multi2;

  $multi = $xof->init;
  $multi->update(@test_strs);
  $out = $multi->squeeze(16);
  $out .= $multi->squeeze(16);
  is(unpack("H*", $out), $test_out{$alg}, "multi squeezes matches expected ($alg)");
}

done_testing();
