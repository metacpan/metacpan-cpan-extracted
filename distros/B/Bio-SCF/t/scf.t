#-*-Perl-*-
## Bioperl Test Harness Script for Modules

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use ExtUtils::MakeMaker;
use constant TEST_COUNT => 18;

BEGIN {
  # to handle systems with no installed Test module
  # we include the t dir (where a copy of Test.pm is located)
  # as a fallback
  eval { require Test; };
  if( $@ ) {
    use lib 't';
  }
  use Test;
  plan test => TEST_COUNT;
}

use Bio::SCF;

# object-oriented interface
my $scf = Bio::SCF->new('./test.scf');
ok($scf);
ok($scf->bases_length,1525);
ok($scf->samples_length,18610);
ok($scf->base(10),'C');
ok($scf->score(10),6);
ok($scf->index(10),151);
ok($scf->base_score('C',10),6);
ok($scf->sample('C',10)>$scf->sample('G',10));
ok($scf->write('./temp.scf'));
ok(-S './temp.scf',-S './test.scf');

# tied interface
my %h;
tie %h,'Bio::SCF','./test.scf';
ok(tied %h);
ok($h{bases_length},1525);
ok($h{bases_length},scalar @{$h{bases}});
ok($h{samples_length},18610);
ok($h{bases}[10],'C');
ok($h{C}[10],6);
ok($h{index}[10],151);
ok($h{samples}{C}[10]>$h{samples}{G}[10]);
