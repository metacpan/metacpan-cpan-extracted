#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use lib qw(t/lib);
use BitStreamTest;

my @implementations = impl_list;
my @encodings       = encoding_list;

plan tests => scalar @encodings;

foreach my $encoding (@encodings) {
  subtest "$encoding" => sub { test_encoding($encoding); };
}
done_testing();


sub test_encoding {
  my $tencoding = shift;

  plan tests => 2 * scalar @implementations;

  foreach my $type (@implementations) {
    my $encoding = $tencoding;
    my $tmp_stream = new_stream($type);
    my $stream_maxbits = $tmp_stream->maxbits;

    my $nfibs = (!is_universal($encoding))  ?  22
                                            :  ($stream_maxbits < 64)  ?  47
                                                                       :  80;
    # Perl 5.6.x 64-bit support is problematic.
    $nfibs = 73 if ($] < 5.008) && ($nfibs > 73);

    # Just in case the stream maxbits is different
    $encoding =~ s/BinWord\(\d+\)/BinWord($stream_maxbits)/i;

    my @fibs = (0,1,1);
    my ($v2, $v1) = ( $fibs[-2], $fibs[-1] );
    for (scalar @fibs .. $nfibs) {
      ($v2, $v1) = ($v1, $v2+$v1);
      push(@fibs, $v1);
    }

    {
      my @data = @fibs;
      my $stream = stream_encode_array($type, $encoding, @data);
      BAIL_OUT("No stream of type $type") unless defined $stream;
      my @v = stream_decode_array($encoding, $stream);
      is_deeply( \@v, \@data, "$encoding store F(0) - F($nfibs) using $type");
    }

    {
      my @data = reverse @fibs;
      my $stream = stream_encode_array($type, $encoding, @data);
      BAIL_OUT("No stream of type $type") unless defined $stream;
      my @v = stream_decode_array($encoding, $stream);
      is_deeply( \@v, \@data, "$encoding store F($nfibs) - F(0) using $type");
    }
  }
}
