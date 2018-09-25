# -*-Perl-*- Test Harness script for Bioperl
# $Id$

use strict;

BEGIN {
   use lib '.';
   use Bio::Root::Test;

   test_begin(-tests => 4);
   use_ok('Bio::Index::Hmmer');
}

# test Hmmer
my $hmmer_ind = Bio::Index::Hmmer->new(-filename => 'Wibbl7',
                                       -write_flag => 1,
                                       -verbose    => 0);
isa_ok $hmmer_ind, 'Bio::Index::Hmmer';
$hmmer_ind->make_index(test_input_file('hmmpfam_multiresult.out'));
ok ( -e "Wibbl7" );
my $hmm_result = $hmmer_ind->fetch_report('lcl|gi|340783625|Plus1');
is ($hmm_result->query_description, 'megaplasmid, complete sequence [UNKNOWN]');

END {
   cleanup();
}

sub cleanup {
   for my $root ( qw(Wibbl7) ) {
      unlink $root if( -e $root );
      unlink "$root.pag" if( -e "$root.pag");
      unlink "$root.dir" if( -e "$root.dir");
   }
}
