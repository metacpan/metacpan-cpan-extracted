#!perl -w
use Test;
use strict;
BEGIN { plan tests => 77 };
use Compress::Zlib::Perl;
ok(1); # If we made it this far, we're ok.

undef $/;
#########################

my %files = (
	     "ArtisticZ" => 820605117,
	     "CopyingZ" => 1302860641,
	    );

chdir 't' if -d 't';

my ($filename, $csum);
while (($filename, $csum) = each %files) {
  my $origname = $filename;
  $origname =~ s/Z$// or die "Unexpected filename '$filename'";
  open FH, $filename or die "Cannot open '$filename': $!";
  binmode FH;
  my $input = <FH>;
  open FH, $origname or die "Cannot open '$origname': $!";
  binmode FH;
  my $orig = <FH>;

  my $bufsize;
  for $bufsize (length ($input), 4096, 16, 1) {
    my $prefix = "$origname, $bufsize, ";
    my ($inflater, $status)
      = Compress::Zlib::Perl::inflateInit(-WindowBits => - MAX_WBITS);
    ok ($status, Z_OK, "$prefix inflate status");
    ok (defined $inflater, 1, "$prefix defined");
    ok ($inflater->isa('Compress::Zlib::Perl'), 1, "$prefix isa");

    my $output;
    my $ongoing_crc;
    my $input_copy = $input . "N";
    while (length $input_copy) {
      my $bit = substr ($input_copy, 0, $bufsize, "");
      my $outbit;
      ($outbit, $status) = $inflater->inflate($bit);
      die "$prefix inflate status '$status'"
	unless $status == Z_OK || $status == Z_STREAM_END;
      die "$prefix inflate undefined" unless defined $outbit;
      $ongoing_crc = crc32 ($outbit, $ongoing_crc);
      $output .= $outbit;
      if ($status == Z_OK) {
	die "$prefix inflate not all input consumed" if length $bit;
      } elsif ($status == Z_STREAM_END) {
	if ($input_copy eq 'N') {
	  ok ($bit, "", "$prefix inflate trailing input bodge");
	} else {
	  ok ($bit, "N", "$prefix inflate trailing input remains");
	  ok ($input_copy, "", "$prefix inflate all input consume");
	}
	last;
      }
    }
    ok ($status, Z_STREAM_END, "$prefix did finish");
    ok (length ($output), length ($orig), "$prefix output has correct size");
    ok ($output eq $orig);
    ok ($ongoing_crc, $csum, "$prefix ongoing crc");
    my $crc = crc32 $output;
    ok ($crc, $csum, "$prefix final crc");
  }
}
