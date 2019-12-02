# -*-Perl-*- Test Harness script for Bioperl
# $Id$

use strict;

BEGIN {
    use Bio::Root::Test;

    test_begin(-tests => 7,
               -requires_modules => [qw(IO::String
                                        LWP::UserAgent
                                        HTTP::Request::Common)]);
    use_ok('Bio::DB::RefSeq');
}

my $verbose = test_debug() || -1;

my ($db,$seq,$seqio);
# get a single seq

$seq = $seqio = undef;

SKIP: {
    test_skip(-tests => 6, -requires_networking => 1);

    eval {
        ok defined($db = Bio::DB::RefSeq->new(-verbose=>$verbose));
        ok(defined($seq = $db->get_Seq_by_acc('NM_006732')));
        is( $seq->length, 3775);
        ok defined ($db->request_format('fasta'));
        ok(defined($seq = $db->get_Seq_by_acc('NM_006732')));
        is( $seq->length, 3775);
    };
    skip "Warning: Couldn't connect to RefSeq with Bio::DB::RefSeq.pm!", 6 if $@;
}
