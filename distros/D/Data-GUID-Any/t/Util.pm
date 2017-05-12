package t::Util;
use strict;
use warnings;
use Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/looks_like_uc_guid looks_like_lc_guid/;

my $uchex = "A-Z0-9";
my $lchex = "a-z0-9";

sub looks_like_uc_guid {
  my $guid = shift;
  return $guid =~ /[$uchex]{8}-[$uchex]{4}-[$uchex]{4}-[$uchex]{4}-[$uchex]{12}/;
}

sub looks_like_lc_guid {
  my $guid = shift;
  return $guid =~ /[$lchex]{8}-[$lchex]{4}-[$lchex]{4}-[$lchex]{4}-[$lchex]{12}/;
}

1;
