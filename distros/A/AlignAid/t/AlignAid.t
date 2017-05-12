# AlignAid.t - a test suite for the AlignAid module
# Dave Messina
# dave-pause@davemessina.net
# $Id: /svk-mirror/AlignAid/trunk/t/AlignAid.t 678 2006-12-13T22:23:32.495008Z dmessina  $

use strict;
use warnings;
use Carp;
use Test::More tests => 10;
use File::Spec;

BEGIN {
    # 1
    use_ok('AlignAid');
}

# make an AlignAid object

my $fa1     = 'test1.fa';  # file with one fasta seq in it
my $fa3     = 'test.fa';   # file with three fasta seqs in it
my $tmpdir  = "AlignAid_test$$";
my $testdir = 't';

my $fasta3 = File::Spec->catfile($testdir, $fa3);
my $fasta1 = File::Spec->catfile($testdir, $fa1);
my $dir    = File::Spec->catdir($testdir, $tmpdir);
mkdir($dir, 0777) or croak "could not make directory $dir";

# 2: create an AlignAid Blast object
ok( my $job = AlignAid->new( db => $fasta1, dir => $dir, fasta => $fasta1,
    prog_args => '-warnings -errors -notes' ),
	"class constructor for AlignAid object, singleton blast job") or exit;
# 3: submit a Blast singleton job
my $out1 = File::Spec->catfile($dir, $fa1 . '.blast.out');
ok( my $ret_val = $job->submit(outfile => $out1), "submit a singleton blast job") or exit;

# 4: create an AlignAid cross_match object
ok ( my $job3 = AlignAid->new( program => 'cross_match', db => $fasta1, 
    dir => $dir, fasta   => $fasta1 ),
     "create an AlignAid object for a singleton cross_match job") or exit;

# 5: submit cross_match singleton job
my $out3 = File::Spec->catfile($dir, $fa1 . '.cm.out');
ok( my $ret_val4 = $job3->submit(outfile => $out3), "submit singleton cross_match job") or exit;

SKIP:
{
    eval 'use PP';
    
    skip( '- PP is not installed', 5 ) if $@;
    
    # 6: make an AlignAid Blast object
    ok( my $job2 = AlignAid->new( db => $fasta3, dir => $dir,
        fasta => $fasta3, queue => 'LSF', ),
        "class constructor for AlignAid object, LSF blast jobs" ) or exit;

     # 7: submit Blast jobs
     my $out2 = File::Spec->catfile($dir, $fa3 . '.blast.out');
     ok( my $ret_val2 = $job2->submit(outfile => $out2),
        "submit some blasts to the LSF queue" ) or exit;

     # 8: create an AlignAid object for LSF cross_match jobs
     ok ( my $job4 = AlignAid->new( program => 'cross_match',
        db => $fasta3, dir => $dir,
        fasta   => $fasta3, queue => 'LSF', ),
        "create an AlignAid object for LSF cross_match jobs") or exit;

     # 9: submit cross_matches to the LSF queue
     my $out4 = File::Spec->catfile($dir, $fa3 . '.cm.out');
     ok( my $ret_val5 = $job4->submit(outfile => $out4),
        "submit cross_matches to the LSF queue" ) or exit;

     # 10: kill some jobs
     ok( my $ret_val3 = $job4->kill_all, "kill running jobs" ) or exit;

     # cleanup
     map { unlink $_ } ($out2, $out4);
}

END {
    map { unlink $_ } ($out1, $out3);
    rmdir $dir;
}
1;
