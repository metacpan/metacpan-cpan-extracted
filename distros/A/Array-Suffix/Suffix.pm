#########################################################################
# PACKAGE: Array::Suffix
#
# Copyright (C), 2004-2007
# Bridget Thomson McInnes,       bthomson@d.umn.edu
#
# University of Minnesota, Duluth
#
# USAGE:
#           use Array::Suffix
#
# DESCRIPTION:
#
#      The Array::Suffix module creates a suffix array data structure 
#      that has the ability to store and return variable length n-grams
#      and their frequency. See  perldoc Array::Suffix
#
#########################################################################
package Array::Suffix;

use 5.008;
use strict;
use bytes;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Array::Suffix ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '.5';

#########################
#  File Name Variables  #
#########################
my $CORPUS_FILE   = "";
my $VOCAB_FILE    = "";
my $SNT_FILE      = "";
my $SNTNGRAM_FILE = "";
my $NGRAM_FILE    = "";
my $STOPLIST      = "";
my $TOKEN_FILE    = "";
my $NONTOKEN_FILE = "";

########################################
#  User defined Suffix Array Variables #
########################################
my $max_ngram_size = 2;      #default is 2
my $min_ngram_size = 2;      #default is 2
my $frequency      = 0;      #default is 0

#########################
#  Stop List Variables  #
#########################
my $stop_mode      = "AND";  #AND/OR default is AND
my $stop_regex = "";         #regex to store stop list
   
  
############################
#  Token Option Variables  #
############################
my $tokenizerRegex    = "";
my $nontokenizerRegex = "";

####################
#  Flag Variables  #
####################
my $stop_flag      = 0;   #default is false
my $marginals      = 0;   #default is false
my $remove         = 0;   #default is false;
my $new_line       = 0;   #default is false

####################
#  Hash Variables  #
####################
my $cache = "";
my $unigrams = "";
my %remove_hash = ();

#####################
#  Array Variables  #
#####################
my @vocab_array = ();
my @window_array = ();

#################################
#  Main Suffix Array Variables  #
#################################
# VEC VARIABLES
my $corpus = "";   # corpus vec
my $suffix = "";   # the suffix vec

####################
#  MISC VARIABLES  #
####################
my $N = 0;           # the length of the corpus
my $bit = 32;        # the bit size for the vec array
my $ngram_count = 0; # the number of ngrams
my $win_bit = 1;     # the bit size for the windowing
my $timestamp = "";  # the time stamp for the files

###############
# new method  #
###############
my $location;
sub new
{
    # First argument is class
    my $class = shift;

    my $self = {};

    bless $self, $class;

    $self->{dir} = shift if (defined(@_ > 0));
    $self->{verbose} = @_ ? shift : 0;

    warn "Dir = ", $self->{dir}, "\n" if ($self->{verbose});
    warn "Verbose = ", $self->{verbose}, "\n" if ($self->{verbose});

    #  Initialize some variables at new
    $CORPUS_FILE    = "";    $VOCAB_FILE     = "";    $SNT_FILE      = "";    $SNTNGRAM_FILE = "";
    $NGRAM_FILE     = "";    $STOPLIST       = "";    $TOKEN_FILE    = "";    $NONTOKEN_FILE = "";
    $stop_flag      = 0;     $marginals      = 0;     $remove        = 0;     $new_line      = 0;   
    $max_ngram_size = 2;     $min_ngram_size = 2;     $frequency     = 0;     $remove        = 0;

    return $self;
}

#######################################
#  Create the vocabulary and snt file #
#######################################
sub create_files
{
    my $self  = shift; my @files = @_; @vocab_array = ();

    #  Open the corpus, vocab and snt files
    open(VOCAB , ">$VOCAB_FILE") || die "Could not open the vocabfile: $!\n";
    open(SNT,    ">$SNT_FILE")   || die "Could not open the sntfile : $!\n";

    #  Create the token and nontoken regular expression
    if($NONTOKEN_FILE ne "") { set_nontoken_regex(); } set_token_regex();
    
    ################################################
    #  Index always starts at 2 because 1 is       #
    #  considered a new line parameter if defined  #
    ################################################
    
    my $index = 2; my %vocab_hash = ();
 
    foreach (@files) {
	open(CORPUS, $_) || die "Could not find the corpus file: $_ \n";
	while(<CORPUS>) {
	    chomp;
	    
	    s/$nontokenizerRegex//g;
	    
	    while( /$tokenizerRegex/g ) {
		my $token = $&;

		if (! exists $vocab_hash{$token} ) {
		    print SNT "$index ";
		    print VOCAB "$index\n";  print VOCAB "$token\n";
		    $vocab_hash{$token} = $index++; 
		}
		else {
		    print SNT "$vocab_hash{$token} ";
		}
	    }
	    print SNT "1" if $new_line;
	    print SNT "\n";
	}
    }
}

######################
#  Remove the files  #
######################
sub remove_files
{
    my $self = shift;

    system("rm -rf $VOCAB_FILE");
    system("rm -rf $SNT_FILE");
    system("rm -rf $SNTNGRAM_FILE");

}

###########################
#  Remove the ngram file  #
###########################
sub remove_ngram_file
{

    my $self = shift;

    system("rm -rf $NGRAM_FILE");

}

############################################
#  Creates the token file                  #
#  CODE obtained from NSP version 6.7      #
#  http://www.d.umn.edu/~tpederse/nsp.html #
############################################
sub set_token_regex
{
    my $self = shift; my @tokenRegex = (); $tokenizerRegex = "";
    
    if(-e $TOKEN_FILE) {
	open (TOKEN, $TOKEN_FILE) || die "Couldnt open $TOKEN_FILE\n";
	
	while(<TOKEN>)        {
	    chomp; s/^\s*//; s/\s*$//;
	    if (length($_) <= 0) { next; }
	    if (!(/^\//) || !(/\/$/))
	    {
		print STDERR "Ignoring regex with no delimiters: $_\n"; next;
	    }
	    s/^\///; s/\/$//;
	    push @tokenRegex, $_;
	}
	close TOKEN;
    }
    else  {
	push @tokenRegex, "\\w+"; push @tokenRegex, "[\.,;:\?!]";
    }
    
    # create the complete token regex
    
    foreach my $token (@tokenRegex)
    {
	if ( length($tokenizerRegex) > 0 ) 
	{
	    $tokenizerRegex .= "|";
	}
	$tokenizerRegex .= "(";
	$tokenizerRegex .= $token;
	$tokenizerRegex .= ")";
    }
    
    # if you dont have any tokens to work with, abort
    if ( $#tokenRegex < 0 ) 
    {
	print STDERR "No token definitions to work with.\n";
	#askHelp();
	exit;
    }
}

############################################
#  Set the non token regular expression    #
#  CODE obtained from NSP version 6.7      #
#  http://www.d.umn.edu/~tpederse/nsp.html #
############################################
sub set_nontoken_regex
{
    $nontokenizerRegex = "";

    #check if the file exists
    if($NONTOKEN_FILE)
    {
	#open the non token file
	open(NOTOK, $NONTOKEN_FILE) || die "Couldn't open Nontoken file $NONTOKEN_FILE.\n";

	while(<NOTOK>) {
	    chomp;
	    s/^\s+//; s/\s+$//;
	    
	    #handling a blank lines
	    if(/^\s*$/) { next; }

	    if(!(/^\//)) {
		print STDERR "Nontoken regular expression $_ should start with '/'\n"; exit;
	    }
	    
	    if(!(/\/$/)) {
		print STDERR "Nontoken regular expression $_ should end with '/'\n"; exit;
	    }
	    
	    #removing the / s from the beginning and the end
	    s/^\///;
	    s/\/$//;
	    
	    #form a single regex
	    $nontokenizerRegex .="(".$_.")|";
	}
	
	# if no valid regexs are found in Nontoken file
	if(length($nontokenizerRegex)<=0) {
	    print STDERR "No valid Perl Regular Experssion found in Nontoken file $NONTOKEN_FILE.\n";
	    exit;
    	}
	
	chop $nontokenizerRegex;
    }  
    else {
	print STDERR "Nontoken file $NONTOKEN_FILE doesn't exist.\n";
	exit;
    }
} 

##############################
#  Create the stoplist hash  #
#   CODE obtained from NSP   #
##############################
sub create_stop_list
{
    my $self = shift;
    my $file = shift;
    
    $stop_regex = "";

    open(FILE, $file) || die "Could not open the Stoplist : $!\n";
    
    while(<FILE>) {
	chomp;	# accepting Perl Regexs from Stopfile
	s/^\s+//;
	s/\s+$//;
	
	#handling a blank lines
	if(/^\s*$/) { next; }
	
	#check if a valid Perl Regex
	if(!(/^\//)) {
	    print STDERR "Stop token regular expression <$_> should start with '/'\n";
	    exit;
	}
	if(!(/\/$/)) {
	    print STDERR "Stop token regular expression <$_> should end with '/'\n";
	    exit;
	}
	
	#remove the / s from beginning and end
	s/^\///;
	s/\/$//;
	
	#form a single big regex
	$stop_regex.="(".$_.")|";
    }
    
    if(length($stop_regex)<=0) {
	print STDERR "No valid Perl Regular Experssion found in Stop file.";
	exit;
    }
    
    chop $stop_regex;
    
    #  Reset the stop flag to true
    $stop_flag = 1;
    
    close FILE;
}

###############################
#  Load the vocabulary array  #
###############################
sub load_vocab_array
{
    open(VOCAB, $VOCAB_FILE) || die "Could not open the vocab file: $!\n";

    @vocab_array = ();
    while(<VOCAB>) {
	chomp;
	my $token = <VOCAB>; chomp $token;
	$vocab_array[$_] = $token;
    }
}

##############################
#  Set the remove parameter  #
##############################
sub set_remove
{
        my $self = shift;
	$remove = shift;
}

################################
#  Set the marginal parameter  #
################################
sub set_marginals
{
        my $self = shift; 
	$marginals = shift;

}

################################
#  Set the new_line parameter  #
################################
sub set_newline
{
        my $self = shift;
	$new_line = 1;

}

#######################
#  Set the frequency  #
#######################
sub set_frequency
{
        my $self = shift;
        $frequency = shift;
}

############################
#  Set minimum ngram size  #
############################
sub set_min_ngram_size
{
        my $self = shift;
       	$min_ngram_size = shift;

}

############################
#  Set maximum ngram size  #
############################
sub set_max_ngram_size
{
        my $self = shift;
        my $max_ngram_size = shift;
}

####################################
#  Set the min and max ngram size  #
####################################
sub set_ngram_size
{
    my $self = shift;
    my $size = shift;

    $max_ngram_size = $size;
    $min_ngram_size = $size;
}

#######################
#  Set the stop mode  #
#######################
sub set_stop_mode
{

    my $self = shift;
    $stop_mode = shift;
}

########################
#  Set the token file  #
########################
sub set_token_file
{
    my $self = shift;
    $TOKEN_FILE = shift;
}

###########################
#  Set the nontoken file  #
###########################
sub set_nontoken_file
{
    my $self = shift;
    my $NONTOKEN_FILE = shift;
}

#############################
#  Set the ngram file name  #
#############################
sub set_destination_file
{
    my $self = shift;
    my $file = shift;

    $timestamp = time();  

    #  Set the file names of the internal files
    #  that will be used by the perl module.
    $VOCAB_FILE    = $file . ".vocab."    . $timestamp;
    $SNT_FILE      = $file . ".snt."      . $timestamp;
    $SNTNGRAM_FILE = $file . ".sntngram." . $timestamp;

    #  Set the ngram file
    $NGRAM_FILE    = $file;
}

#################################
#  Return the number of ngrams  #
#################################
sub get_ngram_count
{
    return $ngram_count;
}

###########################
#  Return the ngram file  #
###########################
sub get_ngram_file
{
    return $NGRAM_FILE;
}
    
#######################################################################
#  METHOD THAT CALLS THE SUFFIX ARRAY FUNCTIONS TO OBTAIN THE NGRAMS  #
#######################################################################
sub get_ngrams
{

    #  Set the ngram count to zero
    $ngram_count = 0;

    #  Create the corpus array
    corpus_array();

    #  Create the suffix array
    suffix_array();

    #  Print the numerical ngrams to the snt ngram file
    print_sntngrams();
    
    # Print the ngrams
    print_ngrams();

    return 1;
}

##########################################
#  Find the frequency of a given string  #
##########################################
sub find_frequency
{
    my @ngram = split/\s+/, shift;
  
    #  Initialize the indexing variables
    my $bottom = shift; my $top = $bottom+1;
    
    while(1) {
	for (0..$#ngram) {	
	    if(vec($corpus,vec($suffix, $top, $bit)+$_,$bit)!=$ngram[$_]) { return($top-$bottom); }
	} $top++;
       
    }
}

###########################################
#  Print the ngrams and their frequencies #
###########################################
sub print_sntngrams
{
    #  Open the SNTGRAM File #
    open(SNTNGRAM, ">$SNTNGRAM_FILE") || die "Could not open the SNTNGRAM file : $!\n";

    #  Load the vocabulary array if not loaded
    if(!@vocab_array) { load_vocab_array(); }

    my $i = 0; %remove_hash = ();
    #  Continue for all the tokens in the vec
    while($i <= $N) {
	
	#  Initialize variables
	my @ngram =(); my @marginalFreqs = (); my $line = 0; my $doStop = 0; my @token_ngram = ();
	
	my $l = vec($suffix, $i, $bit);	
	#  Determine the ngram in its integer and token form
	if($l+$min_ngram_size-1 <= $N) {
	    for(0..$min_ngram_size-1) {
		push @ngram, vec($corpus, $l, $bit); 
		push @token_ngram, $vocab_array[vec($corpus, $l, $bit)];
		$l++;
	    }
	    
	    #  Determine the frequency of the ngram and increment the ngram count.
	    my $freq = find_frequency( (join " ", @ngram), $i); 

	    #  If new line determine if the new line exists in the  ngram
	    if($new_line) { map { if($_ == 1) { $line++; } } @ngram; }
	    
	    #  If the stop list exists determine if tokens are in the stop list
	    if($stop_flag) { 
		#  Set the doStop flag
		if($stop_mode=~/OR|or/) { $doStop = 0; } else { $doStop = 1; }
		
		for $i(0..$#token_ngram) {
		    # if mode is OR, remove the current ngram if any word is a stop word
		    if($stop_mode=~/OR|or/) { if($token_ngram[$i]=~/$stop_regex/) { $doStop=1; last; } }
	
		    # if mode is AND, accept the current ngram if any word is not a stop word 
		    else { if(!($token_ngram[$i]=~/$stop_regex/)) { $doStop=0; last; } }
		}
		if($doStop && $marginals) {
		    for (0..$#ngram) {
			if(exists $remove_hash{$_ . ":" . $ngram[$_]}) {
			    $remove_hash{$_ . ":" . $ngram[$_]} += $freq;
			}
			else { $remove_hash{$_ . ":" . $ngram[$_]} = $freq; }
		    }
		}
	    }
	    
	    #  If the ngram frequency is greater or equal to a specified frequency, a new 
	    #  line flag is false and the ngram is not elimanted by the stop list then print 
	    #  the ngram in its integer form  with its frequency to the snt ngram file
	    if($line == 0 && $doStop == 0) {
		if($remove <= $freq) {
		    $ngram_count+=$freq; 
		    if($frequency <= $freq) {  print SNTNGRAM "@ngram $freq\n"; }
		}
		else {
		    for (0..$#ngram) {
			if(exists $remove_hash{$_ . ":" . $ngram[$_]}) {
			    $remove_hash{$_ . ":" . $ngram[$_]} += $freq;
			}
			else { $remove_hash{$_ . ":" . $ngram[$_]} = $freq; }
		    }
		}
	    } $i += $freq;
       	} else { $i++; }
    }
 
}
	
######################################################
#  Print the ngrams with their marginal frequencies  #
######################################################
sub print_ngrams
{
    #open the SNTNGRAM file
    open(SNTNGRAM, $SNTNGRAM_FILE) || die "Could not open the sntngram file: $!\n";
    
    #open the ngram file
    open(NGRAM, ">$NGRAM_FILE") || die "Could not open the ngram file: $! \n";

    #  Load the vocabulary array if not loaded
    if(!@vocab_array) { load_vocab_array(); }
    
    my $count = get_ngram_count();
    print NGRAM "$count\n";

    while(<SNTNGRAM>) {
	
	chomp; my @ngram = split/\s+/;  my @marginalFreqs = ();
	
	#  Get the ngram size
	my $freq = pop @ngram;
	
	#  Get the marginal counts for all ngrams
	if($marginals) { @marginalFreqs = Marginals(@ngram); }

	#################################################################################
	#  Get the marginal counts for trigrams -> not set right now but it does work!! #
	#  This is an expensive operation!!!!!                                          #  
	#if($marginals && $#ngram == 2) { @marginalFreqs = trigramMarginals(@ngram); }  #
	#################################################################################

        # get the ngram in its token form and calculate the marginal frequencies
	for (0..$#ngram) {  print NGRAM "$vocab_array[$ngram[$_]]<>"; }
	
	# print the frequencies
	print NGRAM "$freq @marginalFreqs \n";
    }
}

#  Gets the marginal counts for each individual word in the ngram
sub Marginals
{
    my @marginalFreqs = ();
    
    for my $i(0..$#_) {
	push @marginalFreqs, vec($unigrams, $_[$i], $bit); 
	
	
	if($i == 0) {
	    if($_[$i] == vec($corpus, $N, $bit)) { $marginalFreqs[$#marginalFreqs] -= 1; }
	}
	if($i == $#_) {
	    if($_[$i] == vec($corpus,  0, $bit)) { $marginalFreqs[$#marginalFreqs] -= 1; }
	}

	if($stop_flag || $remove > 0) {
	    if(exists $remove_hash{$i . ":" . $_[$i]}) {
		$marginalFreqs[$#marginalFreqs] -= $remove_hash{$i . ":" . $_[$i]};
	    }
	}
    }
    return @marginalFreqs;
}


#  Find the marginals for trigrams
sub trigramMarginals 
{
    my @marginalFreqs = bigramMarginals(@_);
    
    for my $i(0..$#_-1) {
	for my $j($i+1..$#_) {
	    my @ngram = $_[$i]; $ngram[1] =  $_[$j]; my $split = $j - $i;
	    push @marginalFreqs, find_marginal($split, @ngram);	    
	    
	    if($split == 1) {
		if($ngram[0] == vec($corpus, 0, $bit)) {  $marginalFreqs[$#marginalFreqs] -= 1; }
		elsif($ngram[$#ngram] == vec($corpus, $N, $bit)) {  $marginalFreqs[$#marginalFreqs] -= 1; } 
	    }
	}
    }
    return @marginalFreqs;
}

##########################################
#  Find the frequency of a given string  #
##########################################
sub find_marginal
{
    my $split = shift; my $bottom = vec($cache, $_[0], $bit);

    while( vec($corpus, vec($suffix, $bottom, $bit)+$split,$bit) != $_[1]) { $bottom++; }
    
    my $top = $bottom+1;
    while(1) {
	if(vec($corpus,vec($suffix, $top, $bit)+$split,$bit)!=$_[1]) { return($top-$bottom); }
	 $top++;
    }
}

#############################
#  Create the corpus array  #
#############################
sub corpus_array
{
    #open SNTFILE
    open(SNT, $SNT_FILE) || die "Could not open the sntfile: $!\n";

    #  Initialize the variables
    my $offset = 0; $corpus = ""; $N = 0;

    while(<SNT>){
	chomp;
	my @t = split/\s+/;
	foreach (@t) { vec($corpus, $offset++, $bit)  = $_; $N++; }
    }

    #decrement N by one to obtain the actual size of the corpus
    $N--;
}

#############################
#  Create the suffix array  #
#############################
sub suffix_array
{
    my %w = ();
    for(0..$N) { push @{$w{vec($corpus, $_, $bit)}}, $_; }
   
    my $count = 0;
    foreach (sort keys %w) {
	my $first = $count; my $temp;
	#  store each possible ngram in sorted order
	foreach my $elem (sort bysuffix @{$w{$_}}) { 
	    vec($suffix, $count++, $bit) = $elem; $temp = $elem;
	}
	#  if marginals cache the unigram counts as well as the 
	#  first and last location of each word
	if($marginals == 1) { 
	    vec($unigrams, $_, $bit) = $count - $first; 
	    vec($cache, $_, $bit) = $first;
	}
    }
}

############################
#  Sort function bysuffix  #
############################
sub bysuffix
{
    
    my $z = $a; my $x = $b; my $counter = 0;
    while(vec($corpus, ++$z, $bit) == vec($corpus, ++$x, $bit) && ++$counter < $max_ngram_size) { ; } 
   
    return ( vec($corpus, $z, $bit) == vec($corpus, $x, $bit) ? 0 :
	     (vec($corpus, $z, $bit) <  vec($corpus, $x, $bit) ? -1 : 1) );
}

1;

__END__

###################
#  DOCUMENTATION  #
###################  

=head1 NAME

Array::Suffix 

=head1 SYNOPSIS

This document provides a general introduction to the Array::Suffix module.
  
=head1 DESCRIPTION

=head2 1. Introduction

The Array::Suffix module is a module that allows for the retrieval of variable
length ngrams. An ngram is defined as a sequence of 'n' tokens that occur within
a window of at leaste 'n' tokens in the text. What constitutes as a 'token' can
be defined by the user.

=head2 2. Ngrams

An ngram is a sequence of n tokens. The tokens in the ngrams are delimited
by the diamond symbol, "<>". Therefore "to<>be<>" is a bigram whose tokens 
consist of "to" and "be". Similarly, "or<>not<>to<>" is a trigram whose tokens
consist of "or", "not", and "to".

Given a piece of text, Ngrams are usually formed of contiguous tokens. For example, 
if we take the phrase:

    to     be     or     not     to     be

The bigrams for this phrase would be:

    to<>be<>     be<>or<>     or<>not<>

The trigrams for this phrase would be:

    to<>be<>or<>     be<>or<>not<>     
    or<>not<>to<>    not<>to<>be<>

=head2 3. Tokens  


We define a token as a contiguous sequence of characters that match one of a
set of regular expressions. These regular expressions may be user-provided,
or, if not provided, are assumed to be the following two regular expressions: 

 \w+        -> this matches a contiguous sequence of alpha-numeric characters

 [\.,;:\?!] -> this matches a single punctuation mark

For example, assume the following is a line of text:

"to be or not to be, that is the question!"

Then, using the above regular expressions, we get the following tokens:

    to           be           or          not       
    to           be           ,           that      
    is           the          question    !


If we assume that the user provides the following regular expression:

 [a-zA-Z]+  -> this matches a contiguous sequence of alphabetic characters

Then, we get the following tokens:

    to           be           or          not       
    to           be           that        is      
    the          question 
    

=head2 4. Usage

    use Array::Suffix;

=head3 Array::Suffix Requirements

   use Array::Suffix;

   #  create an instance of Array::Suffix
   my $sarray = Array::Suffix->new();

   #  create the files needed and specify which
   #  file you would like to get the ngrams from
   $sarray->create_files("my_file.txt");

   #  get the ngrams
   $sarray->get_ngrams();

=head3 Array::Suffix Functions

=item 1.  create_files(@FILE)

    Takes an array of files in which the ngrams are
    to be obtained from. This function will creates the 
    files that are required for the suffix array to be 
    created. These files are defined as the name of the
    first file entered in the FILE array and timestamped.

    1. vocabulary file : converts tokens to integers prefix: 
    2. snt file        : integer representation of corpus
    3. sntngram file   : integer representation of the ngrams
                         and their frequency counts
    4. ngram file      : ngrams and their frequencies


=item 2.  get_ngrams()

    Obtains ngrams of size two and their frequencies
    storing them in the given ngram file.

=item 3. create_stop_list(FILE)

    Removes n-grams containing at least one (in OR mode) 
    stop word or all stop words (in AND mode). The default 
    is OR mode. Each stop word should be a regular expression 
    in this FILE and should be on a line of its own. These 
    should be valid Perl regular expressions, which means that 
    any occurrence of the forward slash '/' within the regular 
    expression must be 'escaped'. 

=item 4. set_stop_mode(MODE)
    
    OR mode removes n-grams containing at least 
    one stop word and AND mode removes n-grams 
    that consists of entirely of stop words. 
    Default:  AND

=item 5.  set_token_file(FILE)

    Each regular expression in this FILE should be on a line
    of its own, and should be delimited by the forward slash 
    '/'. These should be valid Perl regular expressions, which 
    means that any occurrence of the forward slash '/' within 
    the regular expression must be 'escaped'. 
    
    NOTE: This function should be called before the 
    function that creates the main files ie before 
    create_files(FILE).
        
=item 6.  set_nontoken_file(FILE)
    
    The set_nontoken_file function can be used when there 
    are predictable sequences of characters that you know 
    should not be included as tokens.

    NOTE: This function should be called before the 
    function that creates the main files ie before 
    create_files(FILE).

=item 7.  set_remove()

    Ignores Ignores n-grams that occur less than N times. 
    Ignored n-grams are not counted and so do not affect 
    counts and frequencies.

    NOTE:  Should be set before you retrieve the ngrams, 
    ie before you call the get_ngrams() function.
           
=item 8.  set_marginals()

    The marginal frequencies consist of the frequencies of 
    the individual tokens in their respective positions in
    the n-gram.

    NOTE:  Should be set before you retrieve the ngrams, 
    ie before you call the get_ngrams() function.

=item 9.  set_newline()

    Prevents n-grams from spanning across the new-line
    character
        
=item 10. set_frequency(N)

    Does not display n-grams that occur less than N times

    NOTE:  Should be set before you retrieve the ngrams, 
    ie before you call the get_ngrams() function.

=item 11. set_min_ngram_size(N)
    
    Finds n-grams greater than or equal to size N.
    Default: 2

    NOTE:  Should be set before you retrieve the ngrams, 
    ie before you call the get_ngrams() function.

=item 12. set_max_ngram_size(N)

    Finds n-grams less than or equal to size N
    Default: 2

    NOTE:  Should be set before you retrieve the ngrams, 
    ie before you call the get_ngrams() function.

=item 13. set_ngram_size(N)
    
    Finds ngrams equal to size N
    Default : 2

    NOTE:  Should be set before you retrieve the ngrams, 
    ie before you call the get_ngrams() function.

=item 14. set_destination_file(FILE)
    
    Prints the ngrams to FILE. 

    The hidden files that get erased when program is 
    completed are named: <FILE>.<ext>.

    If this is not set the files will be named
    default.<ext>
    
=item 15. get_ngram_count()
    
    Returns the number of n-grams.

=item 16. remove_files()

    Removes the snt, sntngram and the vocab file.
    
=head1 AUTHOR

Bridget Thomson McInnes, bthomson@d.umn.edu

=head1 BUGS

Limitations of this package are:

=item 1.  Only a partial set of marginal counts are found in
this pachage. The frequency of the individual tokens in the 
n-gram are recorded. For example, given the trigram, w1 w2 w3,
the marginal counts that would be returned are: the number of 
times w1 occurs in position one of the ngram, the number of 
times that w2 occurs in the second position of an ngram, and
the number of times that w3 occurs in the third position of 
the ngram.

=item 2. The size of the corpus that this package can retrieve
ngrams fromm is limited to approximatly 75 million tokens. Please
note that this number may vary dependng on what options are
used.

=head1 SEE ALSO

=head1 COPYRIGHT

Copyright (C) 2004-2007, Bridget Thomson McInnes

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  
02111-1307, USA.

Note: a copy of the GNU Free Documentation License is available 
on the web at L<http://www.gnu.org/copyleft/fdl.html> and is 
included in this distribution as FDL.txt. 

perl(1)
