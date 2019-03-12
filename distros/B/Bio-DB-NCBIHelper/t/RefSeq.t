# -*-Perl-*- Test Harness script for Bioperl
# $Id$

use strict;

BEGIN {
    use Test::Most tests => 5;
    use Test::RequiresInternet;
    use_ok('Bio::DB::GenBank');
}

my $verbose = $ENV{'BIOPERLDEBUG'} || -1;

my ($db,$seq);
# get a single seq

$seq = undef;

#test redirection from GenBank
ok $db = Bio::DB::GenBank->new('-verbose'=> $verbose);

throws_ok {$seq = $db->get_Seq_by_acc('NT_006732')} qr/NT_ contigs are whole chromosome files/;

SKIP: {
    ok($seq = $db->get_Seq_by_acc('NM_006732'));
    is($seq->length, 3775);
}
