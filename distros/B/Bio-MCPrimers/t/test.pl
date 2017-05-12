#!/usr/bin/perl -w

# test.pl - test Bio::MCPrimers package

$VERSION='2.3';

# Author: Steve Lenk - 2006

# Copyright (C) Stephen G. Lenk 2006.
# Perl Artistic License applied.

# Use:    test.pl
# Output: OK or Not OK
# Return: 0 = OK, 1 = Not OK (shell script like output value)

use strict;
use warnings;

# OK so far
my $status = 1;

######################################################################

# define tests
my @tests;
push @tests, ['not',
              'perl -I../lib ../mcprimers.pl -help 2>generated_file.pr3',
              'help.txt'];
push @tests, ['not',
              'perl -I../lib ../mcprimers.pl -vectorfile Xpet-32a.txt -seqfile ppib.fa -stdout 2>generated_file.pr3',
              'bad_vectorfile.txt'];
push @tests, ['not',
              'perl -I../lib ../mcprimers.pl -vectorfile pet-32a.txt -seqfile Xppib.fa -stdout 2>generated_file.pr3',
              'bad_seqfile.txt'];
push @tests, ['not',
              'perl -I../lib ../mcprimers.pl -clamp dork 2>generated_file.pr3',
              'bad_clamp.txt'];
push @tests, ['not',
              'perl -I../lib ../mcprimers.pl -searchpaststart dork 2>generated_file.pr3',
              'bad_searchpaststart.txt'];
push @tests, ['not',
              'perl -I../lib ../mcprimers.pl -excludedsites 2>generated_file.pr3',
              'bad_excludedsites.txt'];
push @tests, ['not',
              'perl -I../lib ../mcprimers.pl pet-32a.txt bad_nt.fa dummy.txt 2>generated_file.pr3',
              'bad_nt.txt'];              
push @tests, ['',
              'perl -I../lib ../mcprimers.pl -excludedsites AvaI-XhoI,KpnI pet-32a.txt ppib.fa generated_file.pr3',
              'ppib_sans_avai_xhoi_kpni.pr3'];
push @tests, ['',
              'perl -I../lib ../mcprimers.pl -vectorfile pet-32a.txt -seqfile ppib.fa -outfile generated_file.pr3',
              'ppib.pr3'];
push @tests, ['',
              'perl -I../lib ../mcprimers.pl -vectorfile=pet-32a.txt -seqfile=ppib.fa -outfile=generated_file.pr3',
              'ppib.pr3'];
push @tests, ['',
              'perl -I../lib ../mcprimers.pl -excludedsites AvaI-XhoI,KpnI pet-32a.txt ppib.fa generated_file.pr3',
              'ppib_sans_avai_xhoi_kpni.pr3'];
push @tests, ['',
              'perl -I../lib ../mcprimers.pl -filter -excludedsites=AvaI-XhoI,KpnI pet-32a.txt <ppib.fa >generated_file.pr3',
              'ppib_sans_avai_xhoi_kpni.pr3'];
push @tests, ['',
              'perl -I../lib ../mcprimers.pl -clamp 3prime -searchpaststart 42 -stdout pet-32a.txt HIcysS.fa > generated_file.pr3',
              'HIcysS.pr3'];
push @tests, ['',
              'perl -I../lib ../mcprimers.pl -clamp=3prime -searchpaststart=42 -excludedsites=KpnI pet-32a.txt HIcysS.fa generated_file.pr3',
              'no_solution.pr3'];
push @tests, ['',
              'perl -I../lib ../mcprimers.pl -primerfile=p3.txt -vectorfile=pet-32a.txt -seqfile=ppib.fa -outfile=generated_file.pr3',
              'no_solution_p3.pr3'];
push @tests, ['',
              'perl -I../lib ../mcprimers.pl -vectorfile=pet-32a.txt -seqfile=nm_001045843_utr.fa -outfile=generated_file.pr3',
              'nm_001045843_utr.pr3'];
push @tests, ['',
              'perl -I../lib ../mcprimers.pl -vectorfile=pet-32a.txt -searchpaststart=60 -searchbeforestop=42 -clamp=3prime -seqfile=nm_001045843_cds.fa generated_file.pr3',
              'nm_001045843_cds.pr3'];
push @tests, ['',
              'perl -I../lib ../mcprimers.pl -maxchanges=2 pet-32a.txt ppib.fa generated_file.pr3',
              'maxchanges_2.pr3'];
push @tests, ['',
              'perl -I../lib ../mcprimers.pl -maxchanges=1 pet-32a.txt ppib1.fa generated_file.pr3',
              'ppib1.pr3'];
push @tests, ['',
              'perl -I../lib ../mcprimers.pl -maxchanges=0 pet-32a.txt  -searchpaststart=5 -searchbeforestop=6 ppib0.fa generated_file.pr3',
              'ppib0.pr3'];
push @tests, ['',
              'perl -I../lib ../mcprimers.pl -maxchanges=3 pet-32a.txt ppib3inarow.fa generated_file.pr3',
              'ppib3inarow.pr3'];
    
my $test = 1;

TEST_LOOP: foreach my $t (@tests) {
        
    print "Test $test - ";
    
    if (system($t->[1]) and $t->[0] eq '') {
        print "Not OK\n";
        $status = 0;
        last TEST_LOOP;
    }       
    elsif (&check_results($t->[2], "generated_file.pr3")) {
        print "OK\n";
    }
    else {
        print "Not OK\n";
        $status = 0;
        last TEST_LOOP;
    }
    
    $test++;
}

######################################################################

# simple presentation of results
if ($status == 1) {
    print "\nMCPrimers is OK\n";
    unlink("generated_file.pr3");
    exit 0;
}
else {
    print "\nMCPrimers is NOT OK\n";
    exit 1;
}

######################################################################

sub check_results {

    my ($n1, $n2) = @_;
    
    my ($f1, $f2);
    
    open $f1, $n1 or die "\nCan\'t open $n1";
    open $f2, $n2 or die "\nCan\'t open $n2";
    
    my $l1 = '';
    my $l2 = '';
    
    my $ok = 1;
    
    CHECK: while (1) {
    
        $l1 = <$f1>; 
        $l2 = <$f2>;
        
        # both files done
        if (not defined $l1 and not defined $l2) {
            last CHECK; 
        }
        
        # one file longer than the other
        if (not defined $l1 or not defined $l2)  { 
            $ok = 0; 
            last CHECK; 
        }
        
        # compare lines, ignore 'Date' line
        if ((not $l1 eq $l2)              and 
		    (not $l2 =~ /Copyright/)      and 
            (substr($l1, 0, 4) ne 'Date') and 
            (substr($l1, 0, 4) ne 'Resu') and
            (substr($l1, 0, 4) ne 'Sequ'))  {
                
            # lines differ - not ok
            print "$l1 $l2";
            $ok = 0;
            last CHECK;
        }
    }
    
    close $f1;
    close $f2;
    
    return $ok;
}

######################################################################


