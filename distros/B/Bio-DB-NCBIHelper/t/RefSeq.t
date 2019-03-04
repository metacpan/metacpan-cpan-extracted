# -*-Perl-*- Test Harness script for Bioperl
# $Id$

use strict;

BEGIN {
    use Bio::Root::Test;

    test_begin(-tests => 5,
               -requires_modules => [qw(IO::String
                                        LWP::UserAgent
                                        HTTP::Request::Common)]);
    use_ok('Bio::DB::GenBank');
}

my $verbose = test_debug() || -1;

my ($db,$seq);
# get a single seq

$seq = undef;

#test redirection from GenBank
ok $db = Bio::DB::GenBank->new('-verbose'=> $verbose);

throws_ok {$seq = $db->get_Seq_by_acc('NT_006732')} qr/NT_ contigs are whole chromosome files/;

SKIP: {
    test_skip(-tests => 2, -requires_networking => 1);

    ok($seq = $db->get_Seq_by_acc('NM_006732'));
    is($seq->length, 3775);

    # Note:  Bio::DB::RefSeq-specific tests removed and placed under Bio::DB::RefSeq
}
