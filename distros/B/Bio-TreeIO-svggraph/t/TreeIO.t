# -*-Perl-*- Test Harness script for Bioperl
# $Id$

use strict;

BEGIN {
    use Bio::Root::Test;
    test_begin(-tests => 2);
}

use Bio::TreeIO;

my $treeio = Bio::TreeIO->new(-format => 'newick', 
                              -fh => \*DATA);
my $tree = $treeio->next_tree;

my $FILE3 = test_output_file();
my $treeout3 = Bio::TreeIO->new(-format => 'svggraph',
                                -file => ">$FILE3");
ok($treeout3);
eval {$treeout3->write_tree($tree);};
ok (-s $FILE3);

__DATA__
(((A:1,B:1):1,(C:1,D:1):1):1,((E:1,F:1):1,(G:1,H:1):1):1);
