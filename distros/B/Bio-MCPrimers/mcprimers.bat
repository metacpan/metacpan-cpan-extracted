@echo off
set PRIMER3_DIR=c:\windows\system32


@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!/usr/bin/perl -w
#line 15

$VERSION = '2.5'; 

# mcprimers.pl - Designs molecular cloning PCR primers.

# Author:    Stephen G. Lenk, 2005, 2006.
# Copyright: Stephen G. Lenk (C) 2005, 2006. 

# This program is free software; you can redistribute it and/or  
# modify it under the same terms as Perl itself.
# Licenced under the Perl Artistic Licence.

# Note: mcprimers.pl is intended to mimic an EMBOSS/EMBASSY program

#########################################################################
# This software comes with no guarantee of usefulness. 
# Use at your own risk. Check any solutions you obtain.
# Stephen G. Lenk assumes no responsibility for the use of this software.
#########################################################################

# Limitations: Does not account for redundancy codes in FASTA files
# Note:        These runs use intermediate files keyed to PID
#              See Bio::MCPrimers for POD
#              Use with V2.5 of BIO::MCPrimers.pm

use strict;
use warnings;

use Bio::MCPrimers;

my %flag;                     # hash for all flags
$flag{clamp}        = 'both'; # default
$flag{stdout}       = 0;      # default
$flag{filter}       = 0;      # default
$flag{searchpaststart} = 18;  # default
$flag{searchbeforestop} = 0;  # default
$flag{maxchanges} = 3;        # default

my $use_msg;                  # help use message
my $flag;                     # flag currently being checked
my $vector_name     = '';     # name of cloning vector
my $pr3_file        = '';     # Primer3 Boulder file
my $seq_file        = '';     # sequence file
my $out_file        = '';     # output file
my $seq_fh;                   # sequence
my $out_fh;                   # output
my $pr3_fh;                   # Primer3 Boulder
my $pr3_hr;                   # hash reference for Primer3 Boulder
my %pr3;                      # original values
my $line;                     # read lines into here ...
my $orf = '';                 # then load ONLY nucleotides into $orf
my @re;                       # restriction enzymes pattern
my %re_name;                  # names of restriction enzymes
my @ecut_loc;                 # cut location in enzyme
my @vcut_loc;                 # cut location in vector
my $answer_ar;                # array of solutions
my @excluded_sites = ();      # excluded recognition sites array

# executable steps
&define_use_message();
&parse_arguments();
&sanity_check_arguments();
&check_files();
&open_files();
&get_sequence();
&get_plasmid();
&convert_excluded_sites();
&remove_excluded_sites();
&invoke_solver();
&print_output();

exit(0);


####################################################################

# remove tag values from pr3_hr that mcprimers will overwrite
 
sub clean_up_primer3_tags {

my @remove = (                  # remove from pr3 hash
    "SEQUENCE",                 # these will be inserted later
    "PRIMER_PRODUCT_MAX_SIZE",
    "PRIMER_PRODUCT_SIZE_RANGE",
    "PRIMER_LEFT_INPUT",
    "PRIMER_RIGHT_INPUT",
    "EXCLUDED_REGION",
    "PRIMER_EXPLAIN_FLAG" );

    # identify and remove
    foreach my $key (keys %{$pr3_hr}) {     
        if (grep (/$key/, @remove)) { 
            delete ${$pr3_hr}{$key};  
        }
    }
}

####################################################################

sub print_output {

    # Copyright notices
      my $local_time = localtime;
    my $copr = 
    qq/
|------------------------------------------------------------------|
| MCPrimers V2.5 Copyright (c) 2005,2006 Stephen G. Lenk           |
| CloningVector  Copyright (c) 2006 Tim Wiggin and Stephen G. Lenk |
| Primer3        Copyright (c) 1996,1997,1998,1999,2000,2001,2004  |
| Whitehead Institute for Biomedical Research. All rights reserved |
|------------------------------------------------------------------|

Date = $local_time

Sequence file  = $seq_file
Results file   = $out_file
Primer3 file   = $pr3_file
Cloning vector = $vector_name
Clamp flag     = $flag{clamp}

Maximum mutagenic changes = $flag{maxchanges} (per PCR primer)
Search past START codon   = $flag{searchpaststart}
Search before STOP codon  = $flag{searchbeforestop}
/;
    
    print $out_fh $copr, "Excluded sites            = ";
    foreach (@excluded_sites) {print $out_fh "$re_name{$_} "};
    print $out_fh "\n\n";
    
    # Primer3 Boulder tags
    if (keys %pr3) {
        print $out_fh "Primer3 Boulder tags used from $pr3_file:\n";
        foreach (keys %pr3) {
            if (defined $pr3{$_}) {
                print $out_fh "\t$_=$pr3{$_}\n";
            }   
        }
    }
    
    # Original gene sequence for reference
    print $out_fh "Original sequence:\n";
    while ($orf =~ /(.{1,60})/g) {
        print $out_fh "$1\n"; 
    }
    print $out_fh "\n\n";
    
    if (not defined $answer_ar or @{$answer_ar} == 0) { 
    
        # No solution found
        print $out_fh "Sorry: No solution found\n\n";
    
    } else {
    
        # Dump the solutions
        my $count = 0;
        foreach my $answer_hr (@{$answer_ar}) {
    
            # handle count
            $count += 1;
            my $count_text = 
            "=========\n=========  Solution # $count\n=========";
            
            # compose result text
            my $result = qq/
Start codon at  $answer_hr->{start}
Stop codon  at  $answer_hr->{stop}
Left RE site  = $re_name{$answer_hr->{left_re}} ($answer_hr->{left_re})
Right RE site = $re_name{$answer_hr->{right_re}} ($answer_hr->{right_re})

Primer3 analysis of PCR primers designed by MCPrimers:

$answer_hr->{primer3}/;
        
            print $out_fh "$count_text\n$result\n\n";
        }
    }
}

####################################################################

sub get_sequence {

    # toss > annotation
    $line = '>';
    while (defined $line and substr($line,0,1) eq '>') { 
        $line = <$seq_fh>;   
    }
    
    # get sequence data
    while (defined $line) {    
       chomp $line;
       $orf .= $line;
       $line = <$seq_fh>;
    }
    
    # check sequence
    if (not defined $orf or $orf eq '') {
        die "\n\nNo sequence data found\n\n";
    }
}

####################################################################

sub open_files {

    # sequence
    if ($flag{filter}) {
        $seq_fh = *STDIN;
    }
    else {
        open $seq_fh, "<$seq_file" or 
            die "\n\nError: Can\'t use \'$seq_file\' for input\n\n";
    }
    
    # output file
    if ($flag{stdout} or $flag{filter}) {
        $out_fh = *STDOUT;
    }
    else {
        open $out_fh, ">$out_file" or 
            die "\n\nError: Can\'t use \'$out_file\' for output\n\n";
    }
    
    # Primer3 boulder file
    if ($pr3_file ne '') { 
        open ($pr3_fh, "<$pr3_file") or 
            die "\n\nError: Can\'t use \'$pr3_file\' for input\n\n";
            
        $line = <$pr3_fh>;
        while (defined $line) {
            if ($line =~ /(.+)=(.+)/) {
                $pr3_hr->{$1} = $2;
            }
            $line = <$pr3_fh>;
        }
        &clean_up_primer3_tags();
        %pr3 = %{$pr3_hr};
    }
}

####################################################################

sub check_files {

    # vector file
    if (not defined $vector_name or $vector_name eq '') {
        print "Enter vector file name:   ";
        $vector_name = <>; 
        if (defined $vector_name and $vector_name ne '') {
            chomp $vector_name;
        }
        else {
            die "\n\nError - Need to define vector name\n\n";
        }
    }
    
    # sequence file
    if ($flag{filter} == 0) {
        if (not defined $seq_file or $seq_file eq '') {
            print "Enter sequence file name: ";
            $seq_file = <>; 
            if (defined $seq_file and $seq_file ne '') {
                chomp $seq_file;
            }
            else {
                die "\n\nError - Need to define sequence file\n\n";
            }
        }
    } 
    
    # output file
    if ($flag{filter} == 0 and $flag{stdout} == 0) {    
        if (not defined $out_file or $out_file eq '') {
            print "Enter output file name:   ";
            $out_file = <>; 
            if (defined $out_file and $out_file ne '') {
                chomp $out_file;
            }
            else {
                die "\n\nError - Need to define output file\n\n";
            }
        }
    }
}

####################################################################

sub parse_arguments {

    while (@ARGV) { 
    
        $flag = shift @ARGV;
        my $found = 0;
       
       if ($flag eq '-help') {
        
           print STDERR $use_msg;
           exit(1);
       }
       elsif ($flag =~ /^\-vectorfile/) {
            
            # select cloning vector
            if ($flag =~ /^\-vectorfile=(.*)/) {
                $vector_name = $1;
            }
            elsif (@ARGV) {
                $vector_name = shift @ARGV;
            } 
                        
            if (defined $vector_name and $vector_name ne '') {
                $found = 1;
            }
            else {
                die "\nError: -vector needs an argument\n"
            }
        }   
        elsif ($flag =~ /^\-searchpaststart/) {
        
            # search shift into start
            if ($flag =~ /^\-searchpaststart=(.*)/) {
                $flag{searchpaststart} = $1;
            }
            elsif (@ARGV) {
                $flag{searchpaststart} = shift @ARGV;
            }
            
            if (not defined $flag{searchpaststart}) {
                die "\nError: -searchpaststart needs an argument\n\n";
            }
            
            if ($flag{searchpaststart} =~ /^(\d)+$/) {
                $found = 1;
            } 
            else {
                 die "\nError: -searchpaststart $flag{searchpaststart} not an integer\n\n";
            }
        }
        elsif ($flag =~ /^\-searchbeforestop/) {
        
            # search shift into stop
            if ($flag =~ /^\-searchbeforestop=(.*)/) {
                $flag{searchbeforestop} = $1;
            }
            elsif (@ARGV) {
                $flag{searchbeforestop} = shift @ARGV;
            }
            
            if (not defined $flag{searchbeforestop}) {
                die "\nError: -searchbeforestop needs an argument\n\n";
            }
            
            if ($flag{searchbeforestop} =~ /^(\d)+$/) {
                $found = 1;
            } 
            else {
                 die "\nError: -searchbeforestop $flag{searchbeforestop} not an integer\n\n";
            }
        }
        elsif ($flag =~ /^\-clamp/) {
    
            # GC clamping
            if ($flag =~ /^\-clamp=(.*)/) {
                $flag{clamp} = $1;
            }
            elsif (@ARGV) {
                $flag{clamp} = shift @ARGV;
            }
            
            if (not defined $flag{clamp}) {
                die "\nError: -clamp needs an argument\n\n";
            }
            
            if ($flag{clamp} eq 'both' or $flag{clamp} eq '3prime') {
                $found = 1;
            } 
            else {
                 die "\nError: -clamp uses both or 3prime only\n\n";
            }     
        }       
        elsif ($flag =~ /^\-maxchanges/) {
    
            # Maximum mutagenic changes
            if ($flag =~ /^\-maxchanges=(.*)/) {
                $flag{maxchanges} = $1;
            }
            elsif (@ARGV) {
                $flag{maxchanges} = shift @ARGV;
            }
            
            if (not defined $flag{maxchanges}) {
                die "\nError: -maxchanges needs an argument\n\n";
            }
            
            if ($flag{maxchanges} =~ /^(\d)+$/) {
                $found = 1;
            } 
            else {
                 die "\nError: -maxchanges must be an integer\n\n";
            }     
        }               
        elsif ($flag =~ /^\-excludedsites/) {
            
            # excluded recognition sites
            my $x='';
            if ($flag =~ /^\-excludedsites=(.*)/) {
                $x = $1;
            }
            elsif (@ARGV) {
                $x = shift @ARGV;
            } 
            
            if ($x eq '') {
                die "\nError: specify list with -excludedsites\n\n";
            }
            
            @excluded_sites = split ',', $x; 
            $flag{excluded_sites_ar} = \@excluded_sites;
        }
        elsif ($flag =~ /^-primerfile/) {
            
            # Primer3 Boulder file
            if ($flag =~ /^\-primerfile=(.*)/) {
                $pr3_file = $1;
            }
            elsif (@ARGV) {
                $pr3_file = shift @ARGV;
            } 
                        
            if (defined $pr3_file and $pr3_file ne '') {
                $found = 1;
            }
            else {
                die "\nError: -primer3_file needs an argument\n"
            } 
        } 
         elsif ($flag =~ /^\-seqfile/) {
            
            # sequence file in FASTA format
            if ($flag =~ /^\-seqfile=(.*)/) {
                $seq_file = $1;
            }
            elsif (@ARGV) {
                $seq_file = shift @ARGV;
            } 
                        
            if (defined $seq_file and $seq_file ne '') {
                $found = 1;
            }
            else {
                die "\nError: -seqfile needs an argument\n"
            }
        }     
        elsif ($flag =~ /^\-outfile/) {
            
            # output file
            if ($flag =~ /^\-outfile=(.*)/) {
                $out_file = $1;
            }
            elsif (@ARGV) {
                $out_file = shift @ARGV;
            } 
                        
            if (defined $out_file and $out_file ne '') {
                $found = 1;
            }
            else {
                die "\nError: -outfile needs an argument\n"
            }
        }
        elsif ($flag =~ /^\-stdout/) {
            $flag{stdout} = 1;   
        }    
        elsif ($flag =~ /^\-filter/) {
            $flag{filter} = 1;
        }    
        else {
        
            # check if flag
            if (substr($flag, 0, 1) eq '-') { 
                    
                # Bad flag
                die "\nError: Option $flag not recognised\n\n"; 
            }
            else {
                     
                # Filenames
                
                if ($vector_name eq '') {
                
                    # vector
                    $vector_name = $flag;
                    if (not defined $pr3_file) { 
                        print STDERR $use_msg;
                        exit(0);
                    }
                }
                elsif ($seq_file eq '') {
                
                    # sequence
                    $seq_file = $flag;
                    if (not defined $seq_file) { 
                        print STDERR $use_msg;
                        exit(0);
                    }
                }
                elsif ($out_file eq '') {
                
                    # output
                    $out_file = $flag;
                    if (not defined $out_file) { 
                        print STDERR $use_msg;
                        exit(0);
                    }
                }
            }
        }
    }
}

####################################################################

sub get_plasmid {
    
    # details of the plasmid used as a vector
    use Bio::Data::Plasmid::CloningVector;  
    my $status = Bio::Data::Plasmid::CloningVector::cloning_vector_data
        ($vector_name, \@re, \%re_name, \@ecut_loc, \@vcut_loc);
    
    if ($status == 0) {
        die "\n\nError: Data not found for cloning vector $vector_name\n\n";
    }
}

####################################################################

sub invoke_solver {
    
    # invoke solver
    $answer_ar = Bio::MCPrimers::find_mc_primers
        ($orf, \%flag, $pr3_hr, \@ecut_loc, \@vcut_loc, @re);
}

####################################################################

sub define_use_message {
    
$use_msg = qq/
MCPrimers generates molecular cloning PCR primers

Use: mcprimers.pl [options] vector.txt sequence.fasta result.pr3

Options:  -help
          -stdout
          -filter
          -searchpaststart integer (default = 18)
          -searchbeforestop integer (default = 0)
          -clamp (both | 3prime)
          -maxchanges integer
          -excludedsites comma_seperated_list_with_no_blanks
          -primerfile primer3_file_name
          -vectorfile vector_file_name
          -seqfile FASTA_sequence.fasta
          -outfile result.pr3

Vector file is specified in Bio::Data::Plasmid::CloningVector
Sequence file must be DNA nucleotides in FASTA format
Results file has Primer3 output and extra data
'=' can be used in specifying parameter values on command line

Use at your risk. Check any solutions you obtain

/;

}

####################################################################

sub sanity_check_arguments {

    (my $dev,my $ino,my $mode,my $nlink,my $uid,my $gid,my $rdev,my $size,
       my $atime,my $mtime,my $ctime,my $blksize,my $blocks)
           = stat(*STDIN);
           
    if ($flag{filter} == 0 and $size > 0) {
        die "\nError - Input is redirected and -filter flag not set\n\n";
    }
}

####################################################################

# convert array from name to site
sub convert_excluded_sites {

    my $i = @excluded_sites;
    my $name;
    my $site;
    
    while ($i > 0) {
        $name = shift @excluded_sites; 
        $site = &get_site($name);
        if (defined $site) { push @excluded_sites, $site; }
        $i -= 1;
    } 
}

####################################################################

# individual name to site
sub get_site {

    my ($name) = @_;    # name of restriction enzyme

    # find name - get corresponding site
    foreach (keys %re_name) {
        if ($re_name{$_} eq $name) {
        
            # site value that matches $name
            return $_;
        }
    }
}

####################################################################

# don't even pass the excluded sites to the solver
# cut them out here
sub remove_excluded_sites {

    my @r_tmp = ();
    my @e_tmp = ();
    my @v_tmp = ();
    
    # check all molecular cloning sites
    foreach my $r (@re) {
    
        my $e = shift @ecut_loc; 
        my $v = shift @vcut_loc;
       
        # check if site is in excluded list
        if (not (grep($_ eq $r, @excluded_sites))) {
            
            # site not in excluded list
            push @r_tmp, $r;
            push @e_tmp, $e;
            push @v_tmp, $v;
        }
    }
    
    # load 'em up
    @re       = @r_tmp;
    @ecut_loc = @e_tmp;
    @vcut_loc = @v_tmp;
}

####################################################################


__END__
:endofperl
