package Bio::MCPrimers;

our $VERSION = '2.5';

use strict;
use warnings;

# Bio::MCPrimers.pm - 
#     generates molecular cloning PCR primers for a plasmid vector

##########################################################################
# This software comes with no guarantee of usefulness.
# Use at your own risk. Check any solutions you obtain.
# Stephen G. Lenk assumes no responsibility for the use of this software.
# Licenced under the Artistic Licence.
##########################################################################

#######################################################
###### See bottom for pod and other information    ####
#######################################################

my $primer3_name;           # set depending upon OS
my $primer3_dir;            # from $ENV or set to default
my $primer3_exe;            # full executable name
my $min_size_primer = 18;   # minimum size primer
my $max_size_primer = 24;   # maximum size primer  
my $MIN_PRODUCT_SIZE = 60;  # size in bases of minimum sized product
my $CODON_SIZE = 3;         # likely to stay a constant
my $MAX_DOTS_IN_A_ROW = 3;  # can't change three codons in a row
my %left_bad;               # for tracking bad primers during calculation
my %right_bad;              # and check right as well
my $fh_write;               # write to Primer3
my $fh_read;                # read from Primer3

my $p3_in  = "p3_in$$.txt";  # intermediate file for Primer3
my $p3_out = "p3_out$$.txt"; # intermediate file for Primer3

####################################################################

BEGIN {

    # check PRIMER3_DIR
    if (defined $ENV{PRIMER3_DIR}) {
        $primer3_dir = $ENV{PRIMER3_DIR};
    }
    else {
        $primer3_dir = '.'
    }   
    
    if ($^O =~ /^MSW/) { 
    
        # Microsoft
        $primer3_name = 'primer3.exe';
        $primer3_exe  = "$primer3_dir\\$primer3_name";
    } 
    else {         
    
        # non-Microsoft
        $primer3_name = 'primer3_core';
        $primer3_exe  = "$primer3_dir/$primer3_name";
    }

    # Is Primer3 executable available?
    if (not -e $primer3_exe) {    
        print STDERR "\n$primer3_exe not available\n\n";
        exit 1;
    }
}

####################################################################

END {

    # clean up intermediate files for Primer3    
    unlink $p3_in;      
    unlink $p3_out;
}

####################################################################

# forward declarations for subs
sub find_mc_primers;
sub _solver;
sub _get_re_patterns;
sub _get_re_matches;
sub _start_codon;
sub _stop_codon;
sub _primers_ok;
sub _primer_pairs;
sub _create_primers;
sub _create_left_primers;
sub _create_right_primers;
sub _handle_reply;
sub _sanity_check_gene;
sub _number_dots;
sub _generate_re_patterns;
sub _too_many_substitutions_in_a_row;
sub _check_3prime_gc;

####################################################################

#### front end sets up solver ####
sub find_mc_primers {

    my ($orf,            # ATGC string
        $flag_hr,        # anonymous hash reference to flags
        $pr3_hr,         # Primer3 Boulder hash
        $ecut_loc_ar,    # enzyme cut location array reference
        $vcut_loc_ar,    # vector cut location array reference
        @re              # array of restriction enzyme strings
       ) = @_;

    my $searchpaststart = 18;   # permit the search for left primer
                                # to shift to the right for > 0
    my $searchbeforestop = 0;   # permit the search for right primer
                                # to shift to the left for > 0
    my $clamp = 'both';         # GC clamp at both ends 
    my $max_changes = 3;        # maximum number of allowable changes
                                # using site-directed mutagenesis

    # put flags into local variables, apply defaults
    if (defined $flag_hr->{searchpaststart}) { 
        $searchpaststart = $flag_hr->{searchpaststart};
    } 
    if (defined $flag_hr->{searchbeforestop}) { 
        $searchbeforestop = $flag_hr->{searchbeforestop};
    } 
    if (defined $flag_hr->{maxchanges}) { 
        $max_changes = $flag_hr->{maxchanges};
    }   
    if (defined $flag_hr->{clamp}) {

        if ($flag_hr->{clamp} eq 'both' or 
            $flag_hr->{clamp} eq '3prime') {

            $clamp = $flag_hr->{clamp};
        }
    }
    
    # invoke solver inside an eval to catch 'die'
    my $answer;
    eval {
        $answer = _solver(
                         $orf, 
                         $max_changes,
                         $searchpaststart,
                         $searchbeforestop,
                         $clamp,
                         $pr3_hr,
                         $ecut_loc_ar,
                         $vcut_loc_ar,
                         @re);
    };

    # catch any problems coming out, clean up, rethrow error message
    if ($@) {   
        unlink $p3_in;      
        unlink $p3_out;
        die $@; 
    }
    
    return $answer;
}

####################################################################

### solver function ####
sub _solver {

    my ($orf,               # ATGC string
        $max_changes,       # changes to gene for primer
        $searchpaststart,   # extra search into start of gene for left primer
        $searchbeforestop,  # extra search into end of gene for right primer
        $clamp,             # both or 3prime
        $pr3_hr,            # Primer3 Boulder hash
        $ecut_loc_ar,       # enzyme cut location array reference
        $vcut_loc_ar,       # vector cut location array reference
        @re                 # array of RE strings
       ) = @_;

    my $solution_ar  = [];  # solution array reference
    my @re_matches;         # array of anonymous arrays of RE matches
    
    for (my $i = 0; $i < @re; $i++) { 
        $re_matches[$i] = [];
    }

    my $orf_start = _start_codon($orf); 
    my $orf_stop  = _stop_codon($orf, $orf_start); 

    if (not defined $orf_stop) {
        return $solution_ar;
    }

    # generate RE matches
    for (my $i=0; $i < @re; $i += 1) {

        my @patterns = _get_re_patterns($re[$i], $max_changes);

        my @matches  = _get_re_matches($orf, 
                                       $ecut_loc_ar->[$i],
                                       $vcut_loc_ar->[$i],
                                       @patterns);

        foreach my $match (@matches) { 
            push @{$re_matches[$i]}, $match;
        }
    }
    
    # keep pulling out a potential left primer until exhausted or solved
    while (@re > 1) {

        my $re_l         = shift @re;
        my $re_pos_l_ref = shift @re_matches;

        # position match list for head enzyme
        foreach my $re_pos_l (@{$re_pos_l_ref}) {
                    
            # control where left primer is placed
            if ($re_pos_l > ($orf_start + $searchpaststart)) {            
                next; 
            }
         
            # left primers
            my $modified_gene = $orf;
            substr($modified_gene, $re_pos_l, length $re_l, $re_l);
            my @left = _create_left_primers($modified_gene, 
                                            $orf_start,
                                            $searchpaststart,
                                            $re_pos_l, 
                                            $re_l,
                                            $clamp);
                                            
            # loop across rest of sites
            my $num_sites_left = @re;
            my $site = 0;
            
            # rest of enzymes left after head has been shifted off
            while ($site < $num_sites_left) {
            
                my $re_r = $re[$site];
                my $re_pos_r_ref = $re_matches[$site]; 
                my $right_hr = {};
       
                # rest of restriction sites going right in vector
                RIGHT: foreach my $re_pos_r (@{$re_pos_r_ref}) {
    
                    if ($re_pos_r < 
                           ($orf_stop + $CODON_SIZE - $searchbeforestop)) {  
                        next RIGHT 
                    }
    
                    # right primers
                    my $more_modified_gene = $modified_gene;
                    substr($more_modified_gene, 
                           $re_pos_r, 
                           length $re_r, 
                           $re_r);     
             
                    my @right = _create_right_primers($more_modified_gene, 
                                                      $orf_stop,
                                                      $searchbeforestop,
                                                      $re_pos_r, 
                                                      $re_r,
                                                      $clamp);

                    # test new primers only, bypass primers already tested
                    foreach (@right) { 
                        if (defined $right_hr->{$_}) { next RIGHT } 
                    }

                    # generate primer pairs and have them checked
                    my $reply = _primer_pairs(\@left, 
                                              \@right, 
                                              $more_modified_gene, 
                                              $orf_start,
                                              $orf_stop,
                                              $searchpaststart,
                                              $searchbeforestop,
                                              $pr3_hr);

                    # solution obtained if $reply is defined
                    if (defined $reply) { 

                        # details of assembling solution
                        _handle_reply($reply,
                                      $more_modified_gene,
                                      $re_l,
                                      $re_r,
                                      $orf_start,
                                      $orf_stop,
                                      $solution_ar);
                    } 

                    # keep track of which right primers have been tested
                    foreach (@right) { $right_hr->{$_} = 1 }
                }
                
                # next RE site for possible insertion
                $site = $site + 1;  
            }
        } 
    }

    # all solutions
    return $solution_ar;
}

####################################################################

#### handle reply from solution checker ####
# see if primers are unique, if so then 
# append one solution to @{$solution_ar}
sub _handle_reply {

    my ($reply,                 # solution checker reply
        $more_modified_gene,    # ATGC modified for left and right RE
        $re_l,                  # left RE
        $re_r,                  # right RE
        $orf_start,             # location of START codon
        $orf_stop,              # location of STOP codon
        $solution_ar            # array reference to solution
       ) = @_;

    # check that RE sequences have only one match
    my $left_cnt  = 0;
    my $right_cnt = 0;
    while ($more_modified_gene =~ /$re_l/g) { 
        $left_cnt  += 1 
    }
    while ($more_modified_gene =~ /$re_r/g) { 
        $right_cnt += 1 
    }

    # one match for each?
    if ($left_cnt == 1 and $right_cnt == 1) { 

        # add anonymous hash to anonymous array
        push @{$solution_ar}, { primer3  => $reply,
                                left_re  => $re_l,
                                right_re => $re_r,
                                start    => $orf_start,
                                stop     => $orf_stop };
                                
        return 1; # solution added
    }
    
    return 0; # solution not added
}

####################################################################

#### check primers with Primer3 ####
sub _primers_ok {

    my ($left,             # left primer string
        $right,            # right primer string
        $orf,              # ATGC string modified to match primers
        $orf_start,        # location of start codon
        $orf_stop,         # location of stop codon
        $searchpaststart,  # move search zone into gene from left
        $searchbeforestop, # move search zone into gene from right
        $pr3_hr            # Primer3 Boulder tags
       ) = @_;
 
    my $ok = 1;
    
    if (defined $right_bad{$right}) { 
        $ok = 0 
    }
    if (defined $left_bad{$left})   { 
        $ok = 0 
    }
    
    # outta here if one of the primers has been identified as bad
    if ($ok == 0) { 
        return undef 
    }
  
    # create Boulder file text for Primer3
    my $range = length $orf; 
    my $excluded_region_start = $orf_start + $searchpaststart + $CODON_SIZE;
    my $excluded_length = 
         $orf_stop - $excluded_region_start - $searchbeforestop;

    # mcprimers calculates these
    my @boulder = 
       ( "SEQUENCE=$orf",
         "PRIMER_PRODUCT_MAX_SIZE=$range",
         "PRIMER_PRODUCT_SIZE_RANGE=$MIN_PRODUCT_SIZE-$range",
         "PRIMER_LEFT_INPUT=$left",
         "PRIMER_RIGHT_INPUT=$right",
         "EXCLUDED_REGION=$excluded_region_start,$excluded_length",
         "PRIMER_EXPLAIN_FLAG=1",
       );
   
    # add to hash function
    foreach (@boulder) {  
        $_ =~ /(.*)=(.*)/;
        $pr3_hr->{$1} = $2;
    }
  
    # write intermediate file for Primer3
    open  $fh_write, ">$p3_in" or die "\nError: Can\'t open $p3_in\n"; 
    foreach (keys %{$pr3_hr}) {
        print $fh_write "$_=$pr3_hr->{$_}\n";
    }
    print $fh_write "=\n";
    close $fh_write;
 
    # primer3 call done here
    my $status;
    $status = system("$primer3_exe -format_output < $p3_in > $p3_out");
    if ($status != 0) {
        die "\nError: Primer3 Error $status\n";
        return undef;
    }
        
    my $p3_reply;
    
    # go through Primer3 output
    open $fh_read, "<$p3_out" or die "\nError: Can\'t open $p3_out\n";   
    PRIMER3_READ: while (<$fh_read>) { 

        my $line = $_;       
        $p3_reply .= $line;

        if ($line =~ /NO PRIMERS FOUND/) { 
        
            # solution fails primer3
            $ok = 0; 
        }        
        if ($line =~ /^primer3 release/) {

            # done with primer3 for this primer pair
            last PRIMER3_READ;
        }   
        if ($line =~ /PRIMER_ERROR/) {
        
            # Primer3 found an error
            close $fh_read;
            die "\nPrimer3 Error: $line\n";
            return undef;
        }        
        if ($line =~ /PROBLEM/) {

            # Primer3 had a problem
            close $fh_read;
            die "\nPrimer3 Problem: $line\n";
            return undef;
        } 

        # check left and right
        if ($line =~ /^Left.*0$/)  { 
            $ok = 0; 
            $left_bad{$left} = 1 
        }
        if ($line =~ /^Right.*0$/) { 
            $ok = 0; 
            $right_bad{$right} = 1 
        }
    }
 
    close $fh_read;
    
    # whew! a solution
    if ($ok == 1) { 
        return $p3_reply; 
    }

    # no solution
    return undef;
}

####################################################################

#### create the primers ####
sub _create_primers {

    my ($re,            # restriction enzyme sequence
        $seq_to_search, # ATGC sequence modified to match RE
        $primers_ref,   # reference to primers array
        $clamp          # both left right
       ) = @_;

    my @qs = ( ['', ''], ['?', ''], ['', '?'], ['?', '?'] );
    
    # padding around recognition site
    my $MIN_PAD = 3;
    my $MAX_PAD = 12;
    for my $pad ($MIN_PAD .. $MAX_PAD) {
    
        # ? marks for different types of matching
        foreach my $q (@qs) {
        
            # left and right '?' for regular expression matches
            my $l = $q->[0];
            my $r = $q->[1];
            
            # establish proper pattern
            my $pattern;

            if ($clamp eq 'both')  {            
                $pattern = "[GC](.{3,$pad}$l)$re(.{3,$pad}$r)[GC]" 
            }
            if ($clamp eq 'left')  { 
                $pattern = ".(.{3,$pad}$l)$re(.{3,$pad}$r)[GC]" 
            }
            if ($clamp eq 'right') { 
                $pattern = "[GC](.{3,$pad}$l)$re(.{3,$pad}$r)." 
            }

            # pattern matches
            while ($seq_to_search =~ /($pattern)/g) { 
    
                my $location = $-[0]; 
                my $primer   = $1;
                
                # limit primer sizes
                my $l = length $1;
                if ($l >= $min_size_primer and $l <= $max_size_primer) {               
                    $primers_ref->{$primer} = $location; 
                }
            }
        }
    }

    return undef;
}

####################################################################

#### sanity check gene ####
#### see if stop codon has been 'wacked' ####
sub _sanity_check_gene {

    my ($orf,               # ATGC as primers will make
        $orf_start,         # start codon
        $orf_stop,          # stop codon
        $searchbeforestop   # right side search shift
       ) = @_;

    if ($searchbeforestop != 0) {
        return 1;          
    }
    
    my $stop = _stop_codon($orf, $orf_start);
    
    if (not defined $stop) {     
        return 0 
    }
    
    if ($orf_stop == $stop) {
        return 1;
    } 
    else {
        return 0; 
    }
}

####################################################################

#### generate primer pairs, then process them one by one ####
sub _primer_pairs {

    my ($left_primers_ref,   # array reference
        $right_primers_ref,  # array reference
        $orf,                # ATGC
        $orf_start,          # start codon location
        $orf_stop,           # stop codon location
        $searchpaststart,    # shift search in from left
        $searchbeforestop,   # shift search in from right
        $pr3_hr              # Primer3 Boulder tags
       ) = @_;

    if (@{$left_primers_ref} == 0 or @{$right_primers_ref} == 0) {

        # need both left and right or go home
        return undef 
    }

    # lefties
    foreach my $left_pr (@{$left_primers_ref}) { 

        # righties
        foreach my $right_pr (@{$right_primers_ref}) { 

            # sequence to be made OK
            if (_sanity_check_gene(
                  $orf, $orf_start, $orf_stop, $searchbeforestop) == 1) { 
                
                # primers OK
                my $reply = _primers_ok($left_pr, 
                                        $right_pr, 
                                        $orf, 
                                        $orf_start, 
                                        $orf_stop, 
                                        $searchpaststart,
                                        $searchbeforestop,
                                        $pr3_hr);

                if (defined $reply) { 

                    # reply is OK here
                    return $reply 
                }
            }
        }
    }

    return undef;
}

####################################################################

#### how many '.' in pattern ####
sub _number_dots {

    my (@chars    # array of characters in pattern
       ) = @_;
       
    my $num = 0;

    foreach (@chars) { 
        if ($_ eq '.') { 
            $num += 1 
        } 
    }

    return $num;
}

####################################################################

#### see if there are too many substitutions in a row being requested ####
sub _too_many_substitutions_in_a_row {

    my (@chars        # array of characters to check
       ) = @_;

    my $n_in_a_row = 0;

    # count '.' in a row, reset where needed
    foreach my $c (@chars) {

        if ($c eq '.') { 
            $n_in_a_row += 1 
        } 
        else { 
            $n_in_a_row = 0 
        }

        if ($n_in_a_row == $MAX_DOTS_IN_A_ROW) {   
            return 1 
        }
    }

    return 0;
}

####################################################################

#### recursively generate patterns ####
sub _generate_re_patterns {

    my ($max_dots,     # maximum number of dots also limits recursion
        $pattern_hr,   # pattern hash reference
        @r             # incoming pattern to modify
       ) = @_;  

    my @s;   # next pattern

    # add to hash, keep track of only one instance
    if (_too_many_substitutions_in_a_row(@r) == 0) { 
        $pattern_hr->{ join '', @r } = 1;
    }
    else {       
        return undef 
    }   
    
    # limit to annealing capability of primer
    if (_number_dots(@r) >= $max_dots)  {   
        return undef 
    }

    # successively generate next group of patterns
    for my $i (1 .. @r) { 
    
        # already have a '.' here
        if ($r[$i-1] eq '.') {      
            next 
        }
        
        # empty @s, generate clean pattern array
        while (@s) {        
            pop @s 
        }
    
        # build next pattern
        for my $j (1 .. @r) {
        
            if ($i == $j) {             
                push @s, '.'                
            } 
            else {            
                push @s, $r[$j-1] 
            }
        }
            
        # keep going
        _generate_re_patterns( $max_dots, $pattern_hr, @s ); 
    }

    # all patterns stored in hash
    my @k=keys %{$pattern_hr};     
    
    return @k;
}

####################################################################

#### regular expression patterns with '.' generated ####
sub _get_re_patterns {

    my ($re,         # restriction enzyme
        $max_dots    # maximum number of '.'
       ) = @_;     
    
    my @re = split '', $re; # characters in RE
    my %l;                  # hash function with list of generated RE
    my @pats = ();          # patterns 
    
    # generate patterns for requested enzyme
    if ($max_dots == 0) {
        push @pats, $re;
        return @pats;
    }
    else {
        @pats = _generate_re_patterns($max_dots, \%l, @re);
    }

    # sort patterns here
    my @sorted;

    foreach my $n (0 .. $max_dots) {
        foreach my $p (@pats) { 
            if (_number_dots(split '', $p) == $n) { 
                push @sorted, $p 
            }
        }
    }

    return @sorted;
}

####################################################################

#### get matches for re pattern in gene ####
sub _get_re_matches {

    my ($orf,        # ATGC sequence
        $ecut_loc,   # enzyme cut location
        $vcut_loc,   # vector cut location
        @patterns    # array of RE patterns
       ) = @_;

    my @positions;
    my %used;

    # loop through patterns
    foreach my $p (@patterns) {

        # loop across gene
        while ($orf =~ /($p)/g) {
            
            # check for in-frame
            if ($vcut_loc == (($-[0] + $ecut_loc) % $CODON_SIZE)) {

                # only use a location once
                if (not defined $used{$-[0]}) {
                    push @positions, $-[0]; 
                }
                $used{$-[0]} = 1;
            }
        } 
    }   

    return @positions;
}

####################################################################

#### create left primers ####
sub _create_left_primers {
    
    my ($modified_gene,   # ATGC modified for left RE
        $orf_start,       # location of start codon
        $searchpaststart, # amount search is shifted in from left
        $re_pos_l,        # position of left RE
        $re_l,            # left RE
        $clamp            # type of GC clamp
       ) = @_;
    
    # only hand off the part of the gene needed for the left primers
    my $seq_to_search = 
        substr($modified_gene, 
               0, 
               $orf_start + $searchpaststart + $max_size_primer);
 
    my $left_primers  = {};
    
    if ($clamp eq 'both') {            
        _create_primers($re_l, $seq_to_search, $left_primers, 'both');                
    } 
    else {            
        _create_primers($re_l, $seq_to_search, $left_primers, 'left');
    }
       
    my @left;

    foreach my $l (keys %{$left_primers}) {    
  
        if (_check_3prime_gc($l) == 1) {
            push @left, $l
        }
    }
 
    return @left;
}

####################################################################

#### create right primers ####
sub _create_right_primers {
    
    my ($more_modified_gene,   # ATGC modified for left and right RE
        $orf_stop,             # location of stop codon
        $searchbeforestop,     # search into ORF
        $re_pos_r,             # position of right RE
        $re_r,                 # right RE
        $clamp                 # type of GC clamp
       ) = @_;

    # search location
    my $seq_to_search = substr($more_modified_gene, 
                               $orf_stop + $CODON_SIZE - $searchbeforestop);
    
    my $right_primers = {};
                   
    if ($clamp eq 'both') {                    
        _create_primers($re_r, $seq_to_search, $right_primers, 'both');
    } 
    else {                    
        _create_primers($re_r, $seq_to_search, $right_primers, 'right');
    }
                    
    my @right;
     
    foreach my $r (keys %{$right_primers}) {  
        push @right, $r 
    }           
    
    # reverse complement right primer
    my @rev_comp;
    foreach my $r (@right) {
        $r =~ tr/ATGC/TACG/; 
        $r = reverse $r;
        if (_check_3prime_gc($r) == 1) {
            push @rev_comp, $r;
        }
    }
    
    return @rev_comp;
}

####################################################################

#### check 3' end for undesirable [GC] run ####
sub _check_3prime_gc {

    my ($primer   # 5' to 3' order for left or right
       ) =@_;

    my $num_at_end = 5;
    my $end = substr($primer, (length $primer) - $num_at_end, $num_at_end);

    if ($end =~ /[GC][GC][GC]/) { 
            
        # undesirable GC run found at 3' end   
        return 0   
    } 
    else { 
        return 1 
    }
}

####################################################################

#### find in-frame start codon ####
sub _start_codon {

    my ($orf      # ATGC sequence
       ) = @_;

    my $orf_start = 0;
    
    if ($orf =~ /^((.{$CODON_SIZE})*?)((ATG)|(GTG))/) { 
        $orf_start = $-[3];
    }

    return $orf_start;
}

####################################################################

#### find in-frame stop codon location ####
sub _stop_codon {

    my ($orf,         # ATGC sequence
        $orf_start    # look for stop after start
       ) = @_;

    my $WAY_TOO_BIG = 100000000; # bigger than any anticipated pattern
    my $orf_stop = $WAY_TOO_BIG;

    # look for stop codon, keep track of first one in sequence after start codon
    foreach my $stop_codon (('TAA', 'TAG', 'TGA')) {

        if (substr($orf, $orf_start) =~ 
                /^((.{$CODON_SIZE})*?)($stop_codon)/) {

            if ($-[3] < $orf_stop) { 
                $orf_stop = $-[3] 
            }
        }
    }

    # sanity check if stop codon was found
    if ($orf_stop == $WAY_TOO_BIG) { 
        return undef 
    } else { 
        return $orf_stop + $orf_start
    }
}

####################################################################

1;

__END__

####################################################################

=head1 NAME

Bio::MCPrimers
 
=head1 DESCRIPTION

Creates molecular cloning PCR primer pairs for a given gene so that the 
gene can be directionally inserted into a vector. Solver is generic, 
restriction enzymes and their order in the vector are specified in the 
caller.
 
=head1 EXPORT SUBROUTINES

sub find_mc_primers

    $orf,            # ATGC string (I use 21 NT upstream, 200 NT downsteam)
    $flag_hr,        # anonymous hash reference to flags from mcprimers.pl
    $pr3_hr,         # hash reference to Primer3 Boulder file tags
    $ecut_loc_ar,    # enzyme cut location array reference from caller
    $vcut_loc_ar,    # vector cut location array reference from caller
    @re              # array of restriction enzyme strings from caller
    
Not explicitily exported. Use Bio::MCPrimers::find_mc_primers

See mcprimers.pl for an example of use and front-end.
 
=head1 INSTALLATION

    MCPrimers.pm     - Place into lib/Bio/MCPrimers.pm
    CloningVector.pm - Place into lib/Bio/Data/Plasmid/CloningVector.pm
    Vector files     - Make vector file directory accessable
    mcprimers.pl     - Place in a directory where it can be accessed 
    mcprimers_gui.pl - Place in a directory where it can be accessed 
    mcprimers.acd    - Put in acd directory for EMBOSS 
                       Only checked with acdvalidate 
    
    MCPrimers_manual.doc    - User documentation
    
    MCPRIMER_DIR     - Set this environment variable to point to the 
                       directory containing mcprimers.pl  
    PRIMER3_DIR      - Set environment variable to point to Primer3 
                       executable directory.
    
    MSWindows - use primer3.exe
    Other     - use primer3_core
 
=head1 DEPENDENCIES

Primer3 used as primer3.exe on MSWindows and as primer3_core otherwise.

Used by mcprimers.pl, which is used by mcprimers_gui.pl:

    Bio::MCPrimers,
    Bio::Data::Plasmid::CloningVector.pm

Used by mcprimers_gui.pl:

    Tk
    IPC::Open3
    Tk::FileSelect
    Tk::ROText

=head1 SYNOPSIS

mcprimers.pl -help
mcprimers.pl -vectorfile pet-32a.txt cyss.fa cyss.pr3
mcprimers_gui.pl

Note: Use perl -Ilib if modules are still in local lib directory.

See mcprimers.pl for an example of the use of Bio::MCPrimers itself
See MCPrimers_manual.doc for user documentation

Note: mcprimers.pl is a command line program
      mcprimers_gui.pl is a GUI on top of mcprimers.pl
      
=head1 LIMITATIONS and TROUBLESHOOTING

See MCPrimers_manual.doc

Note: Runs use intermediate files keyed to PID.

=head1 BUGS

Probably. Use at your own risk.

This software comes with no guarantee of usefulness. 
Use at your own risk. Check any solutions you obtain. 
Stephen G. Lenk assumes no responsibility for the use of this software.
 
=head1 COPYRIGHT

Stephen G. Lenk (C) 2005, 2006. All rights reserved. 

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

Primer3 is Copyright (c) 1996,1997,1998,1999,2000,2001,2004
Whitehead Institute for Biomedical Research. All rights reserved.

CloningVector (C) Tim Wiggin and Steve lenk 2006

=head1 AUTHOR

Stephen G. Lenk, November 2005, 2006. 

slenk@emich.edu

=head1 ACKNOWLEDGEMENTS

Primer3 is called by this code to verify that the PCR primers are OK.

Thanks to Tim Wiggin for good ideas at the start. 
Tim rewrote CloningVector.pm in 2006
    
Thanks to Dan Clemans for showing me molecular cloning in the first place. 
I am using Dr. Clemans's ideas about good MC primers in this code. 
Any errors in interpretation or implementation are mine.

Patricia Sinawe found that earlier versions of MCPrimers did not
detect out-of-frame solutions and suggested that extra binding sites
could be included.

Ken Youens-Clark has provided guidance in the proper naming of this 
software so that it functions cooperatively with other Perl modules.

Anar Khan and Alastair Kerr for their advice at BOSC 2006 regarding
EMBOSS compatability, Primer3 parameters, and selective use of sites.
They also insisted that I enhance MCPrimers to do eukaryotic organisms.

Other references:

(1) http://www.premierbiosoft.com/tech_notes/PCR_Primer_Design.html

(2) http://www.mcb.uct.ac.za/pcroptim.htm


=cut