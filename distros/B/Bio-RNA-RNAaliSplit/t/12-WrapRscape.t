#-*-Perl-*-
#!perl -T
use 5.010;
use strict;
use warnings;
use File::Share ':all';
use FindBin qw($Bin);
use constant TEST_COUNT => 1;
use Data::Dumper;

use lib "$Bin/../lib", "$Bin/../blib/lib", "$Bin/../blib/arch";


BEGIN {
  # include Test.pm from 't' dir in case itis not installed
  eval { require Test::More; };
  if ($@) {
    use lib 't';
  }
  use Test::More tests => TEST_COUNT;
}

use Bio::RNA::RNAaliSplit::WrapRscape;

{
  my $aln1 = dist_file('Bio-RNA-RNAaliSplit','aln/all.SL.SPOVG.stk');
  my @arg1 = (ifile => $aln1, odir => ['t']);
  my $ro1 = new_ok('Bio::RNA::RNAaliSplit::WrapRscape' => \@arg1);
  diag(Dumper($ro1));
}

