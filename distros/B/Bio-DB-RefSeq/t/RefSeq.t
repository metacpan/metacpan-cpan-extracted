#!/usr/bin/env perl
use utf8;

use strict;
use warnings;

use Test::More;
use Test::Needs qw(LWP::UserAgent HTTP::Request::Common Data::Stag);
use Test::RequiresInternet;

use Bio::DB::RefSeq;

my $verbose = $ENV{'BIOPERLDEBUG'} || -1;

my ($db,$seq,$seqio);
# get a single seq

$seq = $seqio = undef;

ok defined($db = Bio::DB::RefSeq->new(-verbose=>$verbose));
ok(defined($seq = $db->get_Seq_by_acc('NM_006732')));
is( $seq->length, 3775);
ok defined ($db->request_format('fasta'));
ok(defined($seq = $db->get_Seq_by_acc('NM_006732')));
is( $seq->length, 3775);

done_testing();
