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


              system 'perl -I../lib ../mcprimers.pl -excludedsites AvaI-XhoI,KpnI pet-32a.txt ppib.fa ppib_sans_avai_xhoi_kpni.pr3';
            

               system 'perl -I../lib ../mcprimers.pl -vectorfile pet-32a.txt -seqfile ppib.fa -outfile ppib.pr3';
           
  
               system 'perl -I../lib ../mcprimers.pl -vectorfile=pet-32a.txt -seqfile=ppib.fa ppib.pr3';
        

               system 'perl -I../lib ../mcprimers.pl -excludedsites AvaI-XhoI,KpnI pet-32a.txt ppib.fa ppib_sans_avai_xhoi_kpni.pr3';
              

               system 'perl -I../lib ../mcprimers.pl -filter -excludedsites=AvaI-XhoI,KpnI pet-32a.txt <ppib.fa >ppib_sans_avai_xhoi_kpni.pr3';
            

               system 'perl -I../lib ../mcprimers.pl -clamp 3prime -searchpaststart 42 -stdout pet-32a.txt HIcysS.fa > HIcysS.pr3';
         

               system 'perl -I../lib ../mcprimers.pl -clamp=3prime -searchpaststart=42 -excludedsites=KpnI pet-32a.txt HIcysS.fa no_solution.pr3';
         

               system 'perl -I../lib ../mcprimers.pl -primerfile=p3.txt -vectorfile=pet-32a.txt -seqfile=ppib.fa no_solution_p3.pr3';
     

               system 'perl -I../lib ../mcprimers.pl -vectorfile=pet-32a.txt -seqfile=nm_001045843_utr.fa nm_001045843_utr.pr3';
         

               system 'perl -I../lib ../mcprimers.pl -vectorfile=pet-32a.txt -searchpaststart=60 -searchbeforestop=42 -clamp=3prime -seqfile=nm_001045843_cds.fa nm_001045843_cds.pr3';
             

               system 'perl -I../lib ../mcprimers.pl -maxchanges=2 pet-32a.txt ppib.fa maxchanges_2.pr3';
         

               system 'perl -I../lib ../mcprimers.pl -maxchanges=1 pet-32a.txt ppib1.fa ppib1.pr3';
    

               system 'perl -I../lib ../mcprimers.pl -maxchanges=0 pet-32a.txt ppib0.fa ppib0.pr3 -searchpaststart=5 -searchbeforestop=6';
       

               system 'perl -I../lib ../mcprimers.pl -maxchanges=3 pet-32a.txt ppib3inarow.fa ppib3inarow.pr3';
             



