#-*-Perl-*-
#!perl -T
use 5.010;
use strict;
use warnings;
use File::Share ':all';
use FindBin qw($Bin);
use constant TEST_COUNT => 2;
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
  my $stk1 = dist_file('Bio-RNA-RNAaliSplit','aln/all.SL.SPOVG.stk');
  my @arg1 = (ifile => $stk1, odir => ['t'], nofigures => 1);
  my @arg2 = (ifile => $stk1, odir => ['t'] );
  my $ro1 = new_ok('Bio::RNA::RNAaliSplit::WrapRscape' => \@arg1);
  my $ro2 = new_ok('Bio::RNA::RNAaliSplit::WrapRscape' => \@arg2);
  	
#diag(Dumper($ro1));

}

