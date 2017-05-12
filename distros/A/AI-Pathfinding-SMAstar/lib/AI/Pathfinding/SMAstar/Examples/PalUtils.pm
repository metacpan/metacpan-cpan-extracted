
################################ subroutines ################################





use Tree::AVL;
use AI::Pathfinding::SMAstar::Examples::WordObj;
package AI::Pathfinding::SMAstar::Examples::PalUtils;


my $max_nodes_in_mem = 0;

sub length_no_spaces
{
    my ($w) = @_;    
    $w =~ s/\ //g;
    return length($w);
}



sub get_word_number_of_letters_that_have_repeats
{
    my ($word) = @_;    
    my @letters = split('', $word);
    my %letters_hash = ();

    foreach my $element (@letters) { $letters_hash{$element}++ }

    my $repeated_letters = 0;
    foreach my $element (keys %letters_hash){
	if($letters_hash{$element} > 1){
	    $repeated_letters++;
	}
    }
    
    return $repeated_letters;
}


#
# finds the number of times each letter appears within
# an entire list of words.   returns a hash of the letters
#
sub find_letter_frequencies
{
    my (@words) = @_;
    my %letters_freq;

    foreach my $w (@words)
    {
	@letters = split('', $w); 
	
	foreach my $l (@letters)
	{
	    $letters_freq{$l}++;
	}
    }

    return %letters_freq;
}


sub collisions_per_length
{
    my ($w, $phrase) = @_;

    if(!$w){ $w = "" }
    if(!$phrase){ $phrase = "" }


    my $length = length($w);
    $phrase =~ s/ //g;
    my @letters = split('', $w); 
    my @letters_seen = split('', $phrase); 
    my $collisions = 0;
    foreach my $l (@letters){	
	foreach my $ls (@letters_seen){
	    if($l eq $ls){
		$collisions++;
	    }
	}
    }
    my $val = $collisions/$length;

    return $val;
}




sub get_word_sparsity
{
    my ($word) = @_; 

    my $length = length($word);
    my $num_letters = num_chars_in_word_memo($word);

    my $sparseness = $length - $num_letters;

    return $sparseness;
}


{ my %memo_cache;
sub get_word_sparsity_memo
{
    my ($word) = @_; 

    if($memo_cache{$word}){
	return $memo_cache{$word};
    }
    else{
	my $length = length($word);
	my $num_letters = num_chars_in_word_memo($word);
	
	my $sparseness = $length - $num_letters;
	
	$memo_cache{$word} = $sparseness;
	return $sparseness;
    }
}
}


# get the highest number of times a letter 
# is repeated within a word.
sub get_word_highest_frequency
{
    my ($word) = @_;    
    my @letters = split('', $word);
    my %letters_hash = ();

    foreach my $element (@letters) { $letters_hash{$element}++ }

    my $most_frequent_letter_freq = 0;
    foreach my $element (keys %letters_hash){
	if($letters_hash{$element} > $most_frequent_letter_freq){
	    $most_frequent_letter_freq = $letters_hash{$element};
	}
    }    
    return $most_frequent_letter_freq;
}




sub get_letters
{
    my ($word) = @_;
    my @letter_set = ();
    my %letters_hash = ();
    my @letters = split('', $word);

    foreach my $element (@letters) { $letters_hash{$element}++ }

    foreach my $element (keys %letters_hash)
    {
	push(@letter_set, $element);
    }
    return @letter_set;
}



{ my %memo_cache;
sub word_collision_memo
{
    my ($word,
	$sorted_letters_seen) = @_;

    my $sorted_letters_seen_str = join('', @$sorted_letters_seen);
    my $memo_key = $word . $sorted_letters_seen_str;
    
    #print "sorted_letters_seen_str:  $sorted_letters_seen_str\n";
    
    if($memo_cache{$memo_key}){
	return @{$memo_cache{$memo_key}};	
    }
    else{
    my @letters = split('', $word);
  
    my @difference = ();
    my %letters_hash = ();
    my %letters_seen_hash = ();
    
    my $intersect_num = 0;
    my @intersection;

    foreach my $element (@$sorted_letters_seen) { $letters_seen_hash{$element}++ }

    foreach my $element (@letters) { $letters_hash{$element}++ }
    
    foreach my $element (keys %letters_hash) {       	
	if($letters_seen_hash{$element}){
	    push(@intersection, $element);
	    $intersect_num++;	    
	}
	else{
	    push(@difference, $element);
	}	
    }
   
    my @answer = ($intersect_num, @difference);

    $memo_cache{$memo_key} = \@answer;
    return ($intersect_num, @difference);
    }
}
}




sub word_collision{
    my ($word,
	$letters_seen) = @_;
    
    my @letters = split('', $word);
  
    my @difference = ();
    my %letters_hash = ();
    my %letters_seen_hash = ();
    
    my $intersect_num = 0;
    my @intersection;

    foreach my $element (@$letters_seen) { $letters_seen_hash{$element}++ }
    
    foreach my $element (@letters) { $letters_hash{$element}++ }
    
    foreach my $element (keys %letters_hash) {       	
	if($letters_seen_hash{$element}){
	    push(@intersection, $element);
	    $intersect_num++;	    
	}
	else{
	    push(@difference, $element);
	}
    }
    
    return ($intersect_num, @difference);   
}



sub get_cands_from_left
{   

    my ($word,
	$dictionary,
	$dictionary_rev) = @_;

    my @cands = get_cands_memo($word, $dictionary_rev);    
    
    foreach my $c (@cands){
	$c = reverse($c);
    }
    my @sorted_cands = sort(@cands);
    return @sorted_cands;    
}

sub get_cands_from_right
{
    my ($word,
	$dictionary,
	$dictionary_rev) = @_;
   
    my $rev_word = reverse($word);

    my @cands = get_cands_memo($rev_word, $dictionary);    
    my @sorted_cands = sort(@cands);
    return @sorted_cands;
}


{my $memo_hash_ref  = {}; 
 sub get_cands_memo
 {
     my ($word, $dictionary_rev) = @_;    
     
     my $cand = AI::Pathfinding::SMAstar::Examples::WordObj->new(
	 _word => $word
	 );

     my $cache_key = $word . $dictionary_rev;
     my $cached_vals = $memo_hash_ref->{$cache_key};
     if($cached_vals){
	 #print $spaces . "DING DING DING. cache hit!\n";
	 return @$cached_vals;
	     
     }
     else{
	 
	 my @substr_cands = get_substrs_memo($word, $dictionary_rev);
	 my @superstr_cands = $dictionary_rev->acc_lookup_memo($cand, 
							       \&AI::Pathfinding::SMAstar::Examples::WordObj::compare_up_to, 
							       \&AI::Pathfinding::SMAstar::Examples::WordObj::compare);        
	 my @cands = (@substr_cands, @superstr_cands); 
	 # these are all the words in the dictionary that could end this pal.
	 $memo_hash_ref->{$cache_key} = \@cands;
	 return @cands;
     }
 }
}

sub get_cands
{
    my ($word, $dictionary_rev) = @_;    
    
    my $cand = AI::Pathfinding::SMAstar::Examples::WordObj->new(
	_word => $word
	);

    my @substr_cands = get_substrs_memo($word, $dictionary_rev);
    my @superstr_cands = $dictionary_rev->acc_lookup($cand, 
						     \&AI::Pathfinding::SMAstar::Examples::WordObj::compare_up_to, 
						     \&AI::Pathfinding::SMAstar::Examples::WordObj::compare);        
    my @cands = (@substr_cands, @superstr_cands); 
    # these are all the words in the dictionary that could end this pal.
    return @cands;
}


sub match_remainder
{
    my ($word1, $word2) = @_;
   
    $word1 =~ s/\ //g;
    $word2 =~ s/\ //g;

    my $len1 = length($word1);
    my $len2 = length($word2);

    if(index($word1, $word2) != 0)
    {
	return;
    }
    my $remainder_word = substr($word1, $len2);
    return $remainder_word;
}



#
# memoized version of get_substrs-  for speed
#
{my $memo_hash_ref = {};
sub get_substrs_memo
{
    my ($word, $dictionary) = @_;
   
    my @words;
    my @matches;
    
   
    my $cache_key = $word . $dictionary;
    my $cached_vals = $memo_hash_ref->{$cache_key};
    if($cached_vals1){
	#print $spaces . "DING DING DING. cache hit!\n";
	return @$cached_vals;
	
    }
    else{	
	for(my $i = 1; $i < length($word); $i++){
	    push(@words, substr($word, 0, $i));
	}
	
	foreach my $substring (@words){
	    #print "looking for matches on: \"$substring\"\n";
	    
	    my $cand = AI::Pathfinding::SMAstar::Examples::WordObj->new(
		_word => $substring
		);
	    my $match_word = $dictionary->lookup($cand, \&AI::Pathfinding::SMAstar::Examples::WordObj::compare);
	    if($match_word){
		# print "FOUND A MATCH: $match_word\n";
		push(@matches, $match_word);
	    }
	    
	}
	#print "no hashed value yet, creating one.\n";
	$memo_hash_ref->{$cache_key} = \@matches;
	return @matches;
    }
}
}


sub get_substrs
{
    my ($word, $dictionary) = @_;
   
    my @words;
    my @matches;

    for(my $i = 1; $i < length($word); $i++){
	push(@words, substr($word, 0, $i));
    }

    foreach my $substring (@words){
	#print "looking for matches on: \"$substring\"\n";

	my $cand = AI::Pathfinding::SMAstar::Examples::WordObj->new(
	    _word => $substring
	    );
	my $match_word = $dictionary->lookup($cand, \&AI::Pathfinding::SMAstar::Examples::WordObj::compare);
	if($match_word){
	   # print "FOUND A MATCH: $match_word\n";
	    push(@matches, $match_word);
	}
	
    }
    return @matches;
}



# randomize an array.  Accepts a reference to an array.
sub fisher_yates_shuffle {
    my ($array) = @_;
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    }
}

sub process_words
{
    my ($words) = @_;	
    my @word_objs;
    
    for(my $i = 0; $i < @$words; $i++) 
    {       
	my $word = $words->[$i];
	chomp($word);

	$word_objs[$i] = AI::Pathfinding::SMAstar::Examples::WordObj->new(
	    _word => $word,
	   
	    );		
    }
    return @word_objs;
}

sub process_words_by_density
{
    my ($words, 
	$max_score # 0:  no repeats, 1: 1 repeat, etc.
	) = @_;
    
    my @word_objs;
    
    my $i = 0;
    foreach my $word (@$words)
    {       	
	chomp($word);		
	my $sparsity = get_word_sparsity($word);	

	if($sparsity <= $max_score){	  
	    $word_objs[$i] = AI::Pathfinding::SMAstar::Examples::WordObj->new(
		_word => $word,		
		);	
	    $i++;
	}	
    }
    return @word_objs;
}




sub process_rev_words
{
    my ($words) = @_;
    my @word_objs;
    
    for(my $i = 0; $i < @$words; $i++) 
    {       
	my $word = $words->[$i];
	chomp($word);

	my $rev_word = reverse($word);

	$word_objs[$i] = AI::Pathfinding::SMAstar::Examples::WordObj->new(
	    _word => $rev_word,	    
	    );		
    }
    return @word_objs;
}

sub process_rev_words_by_density
{
    my ($words, 
	$max_score # 0:  no repeats, 1: 1 repeat, etc.
	) = @_;
    
    my @word_objs;
    
    my $i = 0;
    foreach my $word (@$words)
    {       	
	chomp($word);

	my $rev_word = reverse($word);
	my $sparsity = get_word_sparsity($word);	

	if($sparsity <= $max_score){
	    $word_objs[$i] = AI::Pathfinding::SMAstar::Examples::WordObj->new(
		_word => $rev_word,		
		);	
	    $i++;
	}	
    }
    return @word_objs;
}


sub is_palindrome
{
    my ($candidate) = @_;
    if(!$candidate){
	return 0;
    }
    $candidate =~ s/\ //g;
    return($candidate eq reverse($candidate));
}

sub join_strings
{
    my ($strings) = @_;
    my $candidate = join(' ', @$strings);
    
    return $candidate;    
}

sub make_one_word
{
    my ($phrase) = @_;    
    $phrase =~ s/\s//g;  
    return $phrase;
}


sub num_chars_in_word
{
    my ($word) = @_;
    my %hash;
    
    if(!$word) { return 0; }
    
    @hash{ split '', $word} = 1;
    my $num_keys = keys(%hash);
    
    return $num_keys;
}


{my %memo_cache;
sub num_chars_in_word_memo
{
    my ($word) = @_;

    if($memo_cache{$word}){	
	return $memo_cache{$word};		
    }
    else{
	my %hash;
	@hash{ split '', $word} = 1;
	my $num_keys = keys(%hash);
	
	$memo_cache{$word} = $num_keys;
	return $num_keys;
    }
}
}


{my %memo_cache;
sub num_chars_in_pal
{
    my ($pal) = @_;    
    my $num_keys;

    $pal =~ s/\ //g;
    my $length = length($pal);
    my $first_half = substr($pal, 0, $length/2 + 1);


    if($memo_cache{$first_half}){	
	return $memo_cache{$first_half};		
    }
    else{

	my %hash;
	@hash{ split '', $first_half } = 1;
	$num_keys = keys(%hash);
	
	$memo_cache{$pal} = $num_keys;
	return $num_keys;
    }
}
}

sub read_dictionary
{
    my ($in_file) = @_;
    
    unless(open(READF, "+<$in_file")){	
	return;
    }
	
    my @lines = <READF>;
       
    close(READF);
    
    return @lines;
}

sub read_dictionary_filter_by_density
{
    my ($in_file, $max_score) = @_;
    
    unless(open(READF, "+<$in_file")){	
	return;
    }
	
    my @lines = <READF>;
    my $num_lines = @lines;
       
    close(READF);

    my @filtered_words;
    
    my $i = 0;
    foreach my $word (@lines)
    {       	
	chomp($word);	
	my $sparsity = get_word_sparsity($word);

	if($sparsity <= $max_score){	  
	    $filtered_words[$i] = $word;			
	    $i++;
	}	
    }

    return ($num_lines, @filtered_words);
}

sub read_dictionary_filter_by_density_rev
{
    my ($in_file, $max_score) = @_;
    
    unless(open(READF, "+<$in_file")){	
	return;
    }
	
    my @lines = <READF>;
    my $num_lines = @lines;
       
    close(READF);

    my @filtered_words;
    
    my $i = 0;
    foreach my $word (@lines)
    {       	
	chomp($word);	
	my $sparsity = get_word_sparsity($word);

	if($sparsity <= $max_score){
	    my $rev_word = reverse($word);
	    $filtered_words[$i] = $rev_word;			
	    $i++;
	}	
    }

    return ($num_lines, @filtered_words);
}



sub flush {
   my $h = select($_[0]); my $a=$|; $|=1; $|=$a; select($h);
}

{my $spinny_thing = "-";
 my $call_num = 0;
 my $state;
sub show_progress {
    $call_num++;
    $state = $call_num % 4;
    if($state == 0){
	$spinny_thing = "-";
    }
    elsif($state == 1){
	$spinny_thing = "\\";
    }
    elsif($state == 2){
	$spinny_thing = "|";
    }
    elsif($state == 3){
	$spinny_thing = "/";
    }

    my ($progress) = @_;
    my $stars   = '*' x int($progress*10);
    my $percent = sprintf("%.2f", $progress*100);
    $percent = $percent >= 100 ? '100.00%' : $percent.'%';
    
    print("\r$stars $spinny_thing $percent.");
    flush(STDOUT);
}
}



sub show_search_depth_and_percentage {
    my ($depth, $so_far, $total) = @_;
    my $stars   = '*' x int($depth);   

    my $amount_completed = $so_far/$total;
    
    my $percentage = sprintf("%0.2f", $amount_completed*100);

    print("\r$stars depth: $depth. completed:  $percentage %");
    flush(STDOUT);
}


sub show_search_depth_and_num_states {
    my ($depth, $states) = @_;
    my $stars   = '*' x int($depth);   
    my $num_states = @$states;

    print("\rdepth: $depth. num_states:  $num_states");
    flush(STDOUT);
}





{my $LINES=`tput lines`; # number of rows in current terminal window
 my $COLUMNS=`tput cols`; # number of columns in current terminal window

sub show_progress_so_far {
    my ($iteration, $num_states, $str, $opt_datum, $opt_datum2) = @_;
    my $stars   = '*' x int($iteration);   
    

#     print  "\e[H";              # Put the cursor on the first line
#     print  "\e[J";              # Clear from cursor to end of screen
#     print  "\e[H\e[J";          # Clear entire screen (just a combination of the above)
#     print  "\e[K";              # Clear to end of current line (as stated previously)
#     print  "\e[m";              # Turn off character attributes (eg. colors)
#     printf "\e[%dm", $N;        # Set color to $N (for values of 30-37, or 100-107)
#     printf "\e[%d;%dH", $R, $C; # Put cursor at row $R, column $C (good for "drawing")

   
    
    
    #print "\e[H\e[J"; #clears the entire screen
    printf "\e[%d;%dH", $LINES-1, 1; # Put cursor at row $R, column $C (good for "drawing")
    
    print "\e[J";  #clears to end of screen

    if($num_states > $max_nodes_in_mem){
	$max_nodes_in_mem = $num_states;
    }


    print "\riteration: $iteration, num_states_in_memory: $num_states, max_states_in_mem: $max_nodes_in_mem\n"; 
    

    printf "\e[%d;%dH", $LINES, 1; # Put cursor at row $R, column $C (good for "drawing")

    print "\e[J";  #clears to end of screen

    print "string: $str\e[J";


    flush(STDOUT);
}
}


sub show_search_depth_and_num_states_debug {
   
}


{my $LINES=`tput lines`; # number of rows in current terminal window
 my $COLUMNS=`tput cols`; # number of columns in current terminal window

sub show_progress_so_far_debug {
    my ($depth, $prog, $num_states, $str, $num_successors) = @_;
    my $stars   = '*' x int($depth);   
    
  
    print "depth: $depth, string: $str, num_successors:  $num_successors\n";

    flush(STDOUT);
}
}














1;
