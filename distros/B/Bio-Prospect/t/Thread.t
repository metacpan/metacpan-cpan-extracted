#-------------------------------------------------------------------------------
# NAME: Thread.t
# PURPOSE: test script for the Bio::Prospect::File and Bio::Prospect::Thread objects.
#          used in conjunction with Makefile.PL to test installation
#
# $Id: Thread.t,v 1.2 2003/11/18 19:45:46 rkh Exp $
#-------------------------------------------------------------------------------

use Bio::Prospect::File;
use Bio::Prospect::Thread;
use Bio::Prospect::ThreadSummary;
use Test::More;
use warnings;
use strict;

plan tests => 102;

my $fn = 't/SOMA_HUMAN.xml';
ok( -f $fn, "$fn valid" );

my @tnames = qw( 1alu 1bgc 1lki 1huw 1f6fa 1cnt3 1ax8 1evsa 1f45b );

my $pf = new Bio::Prospect::File;
ok( defined $pf && ref($pf) && $pf->isa('Bio::Prospect::File'), 'Bio::Prospect::File::new()' );
ok( $pf->open( "<$fn" ), "open $fn" );
my $cnt=0;
while( my $t = $pf->next_thread() ) {
	# test Thread
	ok( defined $t && ref($t) && $t->isa('Bio::Prospect::Thread'), 'Bio::Prospect::Thread::new' );
	ok( $t->qname eq 'SOMA_HUMAN.fa', 'Bio::Prospect::Thread::qname' );
	ok( $t->tname eq $tnames[$cnt], "Bio::Prospect::Thread::tname eq $tnames[$cnt]" );

	# get ThreadSummary from Thread
	my $ts = new Bio::Prospect::ThreadSummary( $t );
	ok( defined $ts && ref($ts) && $ts->isa('Bio::Prospect::ThreadSummary'), 'Bio::Prospect::ThreadSummary::new' );
	ok( $ts->qname eq 'SOMA_HUMAN.fa', 'Bio::Prospect::ThreadSummary::qname' );
	ok( $ts->tname eq $tnames[$cnt], "Bio::Prospect::ThreadSummary::tname eq $tnames[$cnt]" );

	# check some other values
	ok( $t->tname eq $ts->tname, 'Bio::Prospect::Thread::tname eq Bio::Prospect::ThreadSummary::tname' );
	ok( $t->target_start eq $ts->target_start, 'Bio::Prospect::Thread::target_start eq Bio::Prospect::ThreadSummary::target_start' );
	ok( $t->align_len eq $ts->align_len, 'Bio::Prospect::Thread::align_len eq Bio::Prospect::ThreadSummary::align_len' );
	ok( $t->svm_score eq $ts->svm_score, 'Bio::Prospect::Thread::svm_score eq Bio::Prospect::ThreadSummary::svm_score' );
	ok( $t->raw_score eq $ts->raw_score, 'Bio::Prospect::Thread::raw_score eq Bio::Prospect::ThreadSummary::raw_score' );

	$cnt++;
}
