BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = ("../lib", "lib/compress");
    }
}

use lib qw(t);
use strict;
use warnings;
use bytes;

use Test::More tests => 15;

BEGIN { use_ok('Compress::Raw::Lzma', 2); }

my $dict = "sphinx of black quartz judge my vow";
my $to_compress = "sphinx of black quartz judge my vow" x 100;

my $filter = Lzma::Filter::Lzma2(
  PresetDict => \$dict,
  DictSize   => 1024 * 1024 * 8,
  Lc         => 0,
  Lp         => 3,
  Pb         => LZMA_PB_MAX,
  Mode       => LZMA_MODE_NORMAL,
  Nice       => 128,
  Mf         => LZMA_MF_HC4,
  Depth      => 77);

my $filter_no_dict = Lzma::Filter::Lzma2(
  DictSize   => 1024 * 1024 * 8,
  Lc         => 0,
  Lp         => 3,
  Pb         => LZMA_PB_MAX,
  Mode       => LZMA_MODE_NORMAL,
  Nice       => 128,
  Mf         => LZMA_MF_HC4,
  Depth      => 77);

my ($x,$err,$status);
my $out_no_dict;
{
  (my $enc, $err) = Compress::Raw::Lzma::RawEncoder->new(Filter => [$filter_no_dict], AppendOutput => 1);
  ok $enc;
  cmp_ok $err, '==', LZMA_OK, "  status is LZMA_OK";

  my $tmp = $to_compress;
  $status = $enc->code($tmp, $out_no_dict);
  cmp_ok $status, '==', LZMA_OK, "  status is LZMA_OK";

  cmp_ok $enc->flush($out_no_dict), '==', LZMA_STREAM_END, "  flush returned LZMA_STREAM_END";
}

my $out_dict;
{
  my ($x,$err,$status);
  (my $enc, $err) = Compress::Raw::Lzma::RawEncoder->new(Filter => [$filter], AppendOutput => 1);
  ok $enc;
  cmp_ok $err, '==', LZMA_OK, "  status is LZMA_OK";

  my $tmp = $to_compress;
  $status = $enc->code($tmp, $out_dict);
  cmp_ok $status, '==', LZMA_OK, "  status is LZMA_OK";

  cmp_ok $enc->flush($out_dict), '==', LZMA_STREAM_END, "  flush returned LZMA_STREAM_END";

  cmp_ok length($out_dict), '<', length($out_no_dict), "  compressed w/ dictionary is shorter than without";
}

substr($dict,0,2) = 'xx'; # clobber the dictionary, just to make sure this doesn't break anything

my $out_decompressed;
{
  my ($x,$err,$status);
  (my $dec, $err) = Compress::Raw::Lzma::RawDecoder->new(Filter => [$filter], AppendOutput => 1);
  ok $dec;
  cmp_ok $err, '==', LZMA_OK, "  status is LZMA_OK";

  my $out;
  $status = $dec->code($out_dict, $out_decompressed);
  cmp_ok $status, '==', LZMA_STREAM_END "  status is LZMA_STREAM_END";

  is length($out_decompressed), length($to_compress);
  ok $out_decompressed eq $to_compress;
}
