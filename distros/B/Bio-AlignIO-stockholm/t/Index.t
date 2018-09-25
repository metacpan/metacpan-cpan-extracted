# -*-Perl-*- Test Harness script for Bioperl
# $Id$

use strict;

BEGIN {
   use lib '.';
   use Bio::Root::Test;

   test_begin(-tests => 4);
   use_ok('Bio::Index::Stockholm');
}

my $st_ind = Bio::Index::Stockholm->new(-filename => 'Wibbl6',
                                        -write_flag => 1,
                                        -verbose    => 0);
isa_ok $st_ind, 'Bio::Index::Stockholm';
$st_ind->make_index(test_input_file('testaln.stockholm'));
ok ( -e "Wibbl6" );
my $aln = $st_ind->fetch_aln('PF00244');
isa_ok($aln,'Bio::SimpleAlign');

END {
   cleanup();
}

sub cleanup {
   for my $root ( qw(Wibbl6) ) {
      unlink $root if( -e $root );
      unlink "$root.pag" if( -e "$root.pag");
      unlink "$root.dir" if( -e "$root.dir");
   }
}
