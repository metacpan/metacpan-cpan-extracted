#
#
# Author:  matthias beebe
# Date :  June 2008
#
#

package AI::Pathfinding::SMAstar::Examples::Phrase;
use Tree::AVL;
use AI::Pathfinding::SMAstar::Examples::PalUtils;
use strict;

BEGIN {
    use Exporter ();
    @AI::Pathfinding::SMAstar::Examples::Phrase::ISA         = qw(Exporter);
    @AI::Pathfinding::SMAstar::Examples::Phrase::EXPORT      = qw();
    @AI::Pathfinding::SMAstar::Examples::Phrase::EXPORT_OK   = qw($d);

  }

use vars qw($d $max_forgotten_nodes);  # used to debug destroy method for accounting purposes
$d = 0;
$max_forgotten_nodes = 0;


##################################################
## the Phrase constructor 
##################################################
sub new {
    my $invocant = shift;
    my $class   = ref($invocant) || $invocant;
    my $self = {
	_word_list               => undef,
	_words_w_cands_list      => undef,
	_dictionary              => undef,
	_dictionary_rev          => undef,
	_start_word              => undef,  # remainder on cand for antecedent of this obj
	_word                    => undef,
	_cand                    => undef,  # cand found for the antecedent of this obj
	_predecessor             => undef,
	_dir                     => 0,
	_repeated_pal_hash_ref   => {},
        _match_remainder_left    => undef,  
	_match_remainder_right   => undef,
	_letters_seen            => undef,  # letters seen, up to/including antecedent
	_cost                    => undef,  # cost used for heuristic search
	_cost_so_far             => undef,
	_num_chars_so_far        => undef,  # cummulative cost used for heuristic
	_num_new_chars           => undef,
	_no_match_remainder      => undef,  # flag specifying whether there was a remainder
	_phrase                  => undef,
	_depth                   => 0,
	_f_cost                  => undef,
	@_,    # Override previous attributes
    };

    return bless $self, $class;
 
}

##############################################
## methods to access per-object data        
##                                    
## With args, they set the value.  Without  
## any, they only retrieve it/them.         
##############################################

sub start_word {
    my $self = shift;
    if (@_) { $self->{_start_word} = shift }
    return $self->{_start_word};
}

sub word {
    my $self = shift;
    if (@_) { $self->{_word} = shift }
    return $self->{_word};
}

sub cand {
    my $self = shift;
    if (@_) { $self->{_cand} = shift }
    return $self->{_cand};
}

sub antecedent{
    my $self = shift;
    if (@_) { $self->{_predecessor} = shift }
    return $self->{_predecessor};
}



sub dir{
    my $self = shift;
    if (@_) { $self->{_dir} = shift }
    return  $self->{_dir};
}

sub match_remainder_left{
    my $self = shift;
    if (@_) { $self->{_match_remainder_left} = shift }
    return  $self->{_match_remainder_left};
}

sub match_remainder_right {
    my $self = shift;
    if (@_) { $self->{_match_remainder_right} = shift }
    return  $self->{_match_remainder_right};
}

sub intersect_threshold {
    my $self = shift;
    if (@_) { $self->{_intersect_threshold} = shift }
    return  $self->{_intersect_threshold};
}

sub max_collisions{
    my $self = shift;
    if (@_) { $self->{_max_collisions} = shift }
    return  $self->{_max_collisions};
}

sub letters_seen{
    my $self = shift;
    if (@_) { $self->{_letters_seen} = shift }
    return  $self->{_letters_seen};
}

sub f_cost{
    my $self = shift;
    if (@_) { $self->{_f_cost} = shift }
    return  $self->{_f_cost};
}

sub depth{
    my $self = shift;
    if (@_) { $self->{_depth} = shift }
    return  $self->{_depth};
}

sub is_completed{
    my $self = shift;
    if (@_) { $self->{_is_completed} = shift }
    return  $self->{_is_completed};
}

sub is_on_queue{
    my $self = shift;
    if (@_) { $self->{_is_on_queue} = shift }
    return  $self->{_is_on_queue};
}

sub descendants_deleted{
    my $self = shift;
    if (@_) { $self->{_descendants_deleted} = shift }
    return  $self->{_descendants_deleted};
}

sub need_fval_change{
    my $self = shift;
    if (@_) { $self->{_need_fcost_change} = shift }
    return  $self->{_need_fcost_change};
}



	

sub compare
{
    my ($min_letters) = @_;

    return sub{
	my ($self, $arg_obj) = @_;

	my $self_eval_func = evaluate($min_letters);
	my $argobj_eval_func = evaluate($min_letters);
	my $self_eval = $self->$self_eval_func;
	my $arg_obj_eval = $arg_obj->$argobj_eval_func;
	
	return $self_eval - $arg_obj_eval;
    }
}



sub compare_by_depth
{
    my ($self, $arg_obj) = @_;
    
    my $self_depth = $self->{_depth};
    my $argobj_depth = $arg_obj->{_depth};
    
    my $result = $self_depth - $argobj_depth;
    
    return $result;    
}



# compare_phrase_word_strings
#
# usage:  $phrase_obj->compare_phrase_word_strings($other_word_obj)
#
# Accepts another Phrase object as an argument.
# Returns 1 if greater than argument, 0 if equal, and -1 if 
# less than argument
sub compare_phrase_word_strings
{
    my ($self, $arg_obj) = @_;
   
    my $arg_phrase_plus_word = $arg_obj->{_phrase} . $arg_obj->{_word};          
    my $phrase_plus_word = $self->{_phrase} . $self->{_word};
    
    if($arg_phrase_plus_word gt $phrase_plus_word){
	return -1;
    }
    elsif($arg_phrase_plus_word eq $phrase_plus_word){
	return 0;
    }
    return 1;   
}



#----------------------------------------------------------------------------
# evaluation function f(n) = g(n) + h(n) where 
#
# g(n) = cost of path through this node
# h(n) = distance from this node to goal (optimistic)
#
# used for A* search.
#
sub evaluate
{    
    my ($min_num_letters) = @_;
    return sub{
		
	my ($self) = @_;

	# if fcost has already been calculated (or reassigned during a backup)
	# then return it.   otherwise calculate it
	my $fcost = $self->{_f_cost};
	if(defined($fcost)){	    
	    return $fcost;
	}

	my $word = $self->{_start_word};
	my $cost = $self->{_cost};
	my $cost_so_far = $self->{_cost_so_far};
	my $num_new_chars = $self->{_num_new_chars};
	my $num_chars_so_far = $self->{_num_chars_so_far};

	my $phrase = defined($self->{_phrase}) ? $self->{_phrase} : "";
	my $len_phrase = length($phrase);
	my $phrase_num_chars = AI::Pathfinding::SMAstar::Examples::PalUtils::num_chars_in_word($phrase);
	
	my $ratio = 0;
	if($phrase_num_chars){	    
	    $ratio = $len_phrase/$phrase_num_chars;	
	}


	#my $total_cost = $cost_so_far + $cost;
	my $total_cost = $cost_so_far + $cost + $ratio;
	#my $total_cost = 0;  # greedy search (best-first search)	
	#my $distance_from_goal = 0; # branch and bound search.  optimistic/admissible.
        
        my $distance_from_goal = $min_num_letters - ($num_chars_so_far + $num_new_chars);  #1 optimistic/admissible

	my $evaluation = $total_cost + $distance_from_goal;	
	$self->{_f_cost} = $evaluation;

	return $evaluation;
    }
}

#-----------------------------------------------------------------------------
sub phrase_is_palindrome_min_num_chars
{
    my ($min_num_chars) = @_;
    
    return sub{
	my ($self) = @_;
	
	my $phrase = $self->{_phrase};
	
	if(AI::Pathfinding::SMAstar::Examples::PalUtils::is_palindrome($phrase) && 
	   (AI::Pathfinding::SMAstar::Examples::PalUtils::num_chars_in_pal($phrase) >= $min_num_chars)){
	    return 1;
	}
	else{ 
	    return 0; 
	}
    }
}

    
    
#----------------------------------------------------------------------------
sub letters_seen_so_far
{
    my ($self) = @_;      
    my $num_letters_seen = $self->{_num_chars_so_far};    
  
    return $num_letters_seen;
}



























#-----------------------------------------------------------------------------
# Get descendants iterator function.
# Generate the next descendant of a phrase object. Each descendant adds
# another word to the phrase that could possibly lead to a palindrome
#
#-----------------------------------------------------------------------------
sub get_descendants_iterator
{
    my ($phrase_obj) = @_;
    if(!$phrase_obj){
	return;
    }
	
    my $words = $phrase_obj->{_word_list};
    my $words_w_cands = $phrase_obj->{_words_w_cands_list};
    my $dictionary = $phrase_obj->{_dictionary};
    my $dictionary_rev = $phrase_obj->{_dictionary_rev};
    my $repeated_pal_hash_ref = $phrase_obj->{_repeated_pal_hash_ref};
    my $letters_seen = $phrase_obj->{_letters_seen};
    my $cost = $phrase_obj->{_cost};
    my $cost_so_far = $phrase_obj->{_cost_so_far};
    my $num_chars_so_far = $phrase_obj->{_num_chars_so_far};
    my $no_match_remainder = $phrase_obj->{_no_match_remainder};
    my $depth = $phrase_obj->{_depth};    
    my $direction = $phrase_obj->{_dir};
    my $word = $phrase_obj->{_start_word};
    my $whole_word = $phrase_obj->{_cand};
    my $len_whole_word = defined($whole_word) ? length($whole_word) : 0;
    my $rev_word = reverse($word);
    my $len_word = length($word);
    my @cands;
    my @descendants;

   
    if($direction == 0){
	@cands = AI::Pathfinding::SMAstar::Examples::PalUtils::get_cands_from_left($word, $dictionary, $dictionary_rev);
    }
    elsif($direction == 1){
	@cands = AI::Pathfinding::SMAstar::Examples::PalUtils::get_cands_from_right($word, $dictionary, $dictionary_rev);
    }
    
  
    
    #----------------Letters Seen-----------------------------------------------
    my @sorted_letters_seen = sort(@$letters_seen);
    # how much does this word collide with the letters seen so far, and what are the new letters?
    my ($word_intersect, @differences) = AI::Pathfinding::SMAstar::Examples::PalUtils::word_collision($word, \@sorted_letters_seen);
    # store the difference in new letters_seen value.
    push(@sorted_letters_seen, @differences);
         
    my $new_num_chars_so_far = @sorted_letters_seen;  
    #-----------------------------------------------------------
    

 

    my @words_to_make_phrases;
    my $stored_c;

    return sub{
		
      LABEL1:
	# this is a continuation of the second case below, where there were no 
	# match-remainders for the phrase-so-far, i.e. the palindrome has a space
	# in the middle with mirrored phrases on each side. 'cat tac' for example.
	my $next_word = shift(@words_to_make_phrases);
	if($next_word){
	    
	    my $w = $next_word;

	    my $repeated_word_p = 0;
	    my $antecedent = $phrase_obj->{_predecessor};
	    my $antecedent_dir = $antecedent->{_dir};
	    while($antecedent){

		if(defined($antecedent->{_word}) && $w eq $antecedent->{_word} && $antecedent_dir == 0){
		    $repeated_word_p = 1;
		    last;
		}
		$antecedent = $antecedent->{_predecessor};	
		if($antecedent){
		    $antecedent_dir = $antecedent->{_dir};
		}
	    }

	    if($repeated_word_p || $w eq $word){
		goto LABEL1;
		#next;  #skip this word, we are already looking at it
	    }

	    #----------------Compute the Cost-------------------------------------------
	    my $len_w = length($w);
	    my $collisions_per_length = AI::Pathfinding::SMAstar::Examples::PalUtils::collisions_per_length($w, $phrase_obj->{_phrase});
	    my $sparsity = AI::Pathfinding::SMAstar::Examples::PalUtils::get_word_sparsity_memo($w);
	    my $num_chars = AI::Pathfinding::SMAstar::Examples::PalUtils::num_chars_in_word_memo($w);
	    my ($word_intersect, @differences) = AI::Pathfinding::SMAstar::Examples::PalUtils::word_collision($w, 
									  \@sorted_letters_seen);
	    my $num_new_chars = $num_chars - $word_intersect;	
	    #my $newcost = $collisions_per_length + $sparsity;	
	    my $newcost = $collisions_per_length + $len_w;
	    my $new_cost_so_far = $cost + $cost_so_far;

	    #---------------------------------------------------------------------------
	    my $new_phrase = AI::Pathfinding::SMAstar::Examples::Phrase->new(		
		_word_list => $words,
		#_words_w_cands_list  => \@words_to_make_phrases,
		_words_w_cands_list  => $words_w_cands,
		_dictionary => $dictionary,
		_dictionary_rev => $dictionary_rev,		   
		_start_word => $w,
		_cand => $stored_c,	
		_word => $w,
		_predecessor => $phrase_obj,	
		_dir => 0,
		_repeated_pal_hash_ref => $repeated_pal_hash_ref,
		_letters_seen => \@sorted_letters_seen,
		_cost => $newcost,
		_cost_so_far => $new_cost_so_far,
		_num_chars_so_far => $new_num_chars_so_far,
		_num_new_chars => $num_new_chars,
		_no_match_remainder => 1,
		_depth => $depth+1,
		);	
	    
	    #print "returning new phrase from first cond.\n";
	    $new_phrase->{_phrase} = $new_phrase->roll_up_phrase();
	    return $new_phrase;	  
			    	   
	}
	else{	

	    my $c  = shift(@cands);	
	    if(!$c){
		return;
	    }
	    
	    # ------------- filter for repeated palcands for a particular word------
	    # ----------------------------------------------------------------------
	    # This will avoid many repeated patterns among palindromes to trim down the
	    # number redundant palindromes generated.
	    # 		
	    my $letters_seen_str = join("", @{$phrase_obj->{_letters_seen}});
	    if($letters_seen_str){
		my $repeated_pal_hash_key;
		$repeated_pal_hash_key = $word . "^" . $c . "^" . $letters_seen_str;	
		
		#print "\n\nrepeated_pal_hash_key: $repeated_pal_hash_key\n";
		if(my $hash_val = $repeated_pal_hash_ref->{$repeated_pal_hash_key}){
		    # skip because '$word' <--> '$p' pattern has already appeared in a previous palindrome.
		    if($hash_val != $depth){
			goto LABEL1;
			# next; # skip  
		    }
		}
		else{
		    #flag this candidate as already having been tested (below).
		    $repeated_pal_hash_ref->{$repeated_pal_hash_key} = $depth;
		}	
	    }
	    #--------------------------------------------------------------------------
	    #--------------------------------------------------------------------------
	    
	    my $len_c = length($c);
	    my $rev_c = reverse($c);	
	    my $word_remainder;
	    
	    if($len_c < $len_word){
		$word_remainder = $c;
	    }
	    elsif($len_c > $len_word){	
		$word_remainder = $word;
	    }
	    my $rev_word_remainder = reverse($word);
	    
	    my $num_cands = @cands;
	    
	    my $match_remainder;
	    my $len_match_remainder;
	    my $newcost;
	    my $new_cost_so_far;
	    my $num_new_chars;
	    my $new_direction;
	    
	    if($direction == 0){	 	   
		if($len_c < $len_word){		
		    $match_remainder = AI::Pathfinding::SMAstar::Examples::PalUtils::match_remainder($word, $rev_c);		
		    $new_direction = 0;
		}
		elsif($len_c > $len_word){	
		    $match_remainder = AI::Pathfinding::SMAstar::Examples::PalUtils::match_remainder($rev_c, $word);
		    $match_remainder = reverse($match_remainder);		
		    $new_direction = 1;
		}
	    }
	    elsif($direction == 1){
		if($len_c < $len_word){
		    $match_remainder = AI::Pathfinding::SMAstar::Examples::PalUtils::match_remainder($rev_word, $c);
		    $match_remainder = reverse($match_remainder);		
		    $new_direction = 1;	
		}
		elsif($len_c > $len_word){
		    $match_remainder = AI::Pathfinding::SMAstar::Examples::PalUtils::match_remainder($c, $rev_word);		
		    $new_direction = 0;
		}
	    }
	    
	    $len_match_remainder = defined($match_remainder) ? length($match_remainder) : 0;
	    
	    #----------------Compute the Cost-------------------------------------------
	    if($len_c < $len_word){	   		
		$num_new_chars = 0;
		$newcost = 0;  # new candidate is a (reversed) substring of word
		$new_cost_so_far = $cost + $cost_so_far;			    
	    }
	    elsif($len_c > $len_word){
		
		#if($len_c != $len_word){
		my $collisions_per_length = AI::Pathfinding::SMAstar::Examples::PalUtils::collisions_per_length($match_remainder, $phrase_obj->{_phrase});
		my $num_chars = AI::Pathfinding::SMAstar::Examples::PalUtils::num_chars_in_word_memo($match_remainder);
		my $sparsity = AI::Pathfinding::SMAstar::Examples::PalUtils::get_word_sparsity_memo($match_remainder);
		my ($word_intersect, @differences) = AI::Pathfinding::SMAstar::Examples::PalUtils::word_collision_memo($match_remainder, 
										       \@sorted_letters_seen);	    
		$num_new_chars = $num_chars - $word_intersect;		
		#$newcost = $sparsity + $collisions_per_length;
		$newcost = $collisions_per_length + $len_match_remainder;
		$new_cost_so_far = $cost + $cost_so_far;			    
	    }
	    #---------------------------------------------------------------------------
	    
	    if($match_remainder){  # there is a length difference between the candidate and this word.
		my $new_phrase = AI::Pathfinding::SMAstar::Examples::Phrase->new(
		    _word_list => $words,
		    _words_w_cands_list  => $words_w_cands,
		    _dictionary => $dictionary,
		    _dictionary_rev => $dictionary_rev,
		    _start_word => $match_remainder,
		    _cand => $c,
		    _word => $whole_word,
		    _predecessor => $phrase_obj,	
		    _dir => $new_direction,
		    _repeated_pal_hash_ref => $repeated_pal_hash_ref,
		    _letters_seen => \@sorted_letters_seen,
		    _cost => $newcost,
		    _cost_so_far => $new_cost_so_far,
		    _num_chars_so_far => $new_num_chars_so_far,		
		    _num_new_chars => $num_new_chars,
		    _depth => $depth+1,
		    );
		#print "returning new phrase from second cond.\n";
		$new_phrase->{_phrase} = $new_phrase->roll_up_phrase();
		return $new_phrase;
	    }
	    else{
		#
		# There is no match_remainder, so this candidate is the reverse
		# of $word, or the phrase built so far is an "even" palindrome,
		# i.e. it has a word boundary (space) in the middle.
		#
		#
		# This is a special case since there is no match remainder.
		# Because there is no remainder to create new phrase obj from, this 
		# section goes through the whole word list and creates phrase objects
		# for each new word.   The number of new characters offered by each
		# word is recorded to help with guided search.
		#
		# Update:  this case now only goes through the word list for which there
		# are cands.
		
		@words_to_make_phrases = @$words_w_cands;
		#@words_to_make_phrases = @$words;
		
		
		$stored_c = $c;
		my $next_word = shift(@words_to_make_phrases);
		my $w = $next_word;
		
		my $repeated_word_p = 0;
		my $antecedent = $phrase_obj->{_predecessor};
		my $antecedent_dir = $antecedent->{_dir};
		while($antecedent){
		    
		    if(defined($antecedent->{_word}) && $w eq $antecedent->{_word} && $antecedent_dir == 0){
			$repeated_word_p = 1;
			last;
		    }
		    $antecedent = $antecedent->{_predecessor};	
		    if($antecedent){
			$antecedent_dir = $antecedent->{_dir};
		    }
		}
		
		if($repeated_word_p || $w eq $word){	
		    goto LABEL1;
		    #next;  #skip this word, we are already looking at it
		}
		
		#----------------Compute the Cost-------------------------------------------
		my $len_w = length($w);
		my $collisions_per_length = AI::Pathfinding::SMAstar::Examples::PalUtils::collisions_per_length($w, $phrase_obj->{_phrase});
		my $sparsity = AI::Pathfinding::SMAstar::Examples::PalUtils::get_word_sparsity_memo($w);
		my $num_chars = AI::Pathfinding::SMAstar::Examples::PalUtils::num_chars_in_word_memo($w);
		my ($word_intersect, @differences) = AI::Pathfinding::SMAstar::Examples::PalUtils::word_collision_memo($w, 
										   \@sorted_letters_seen);
		my $num_new_chars = $num_chars - $word_intersect;	
		#my $newcost = $collisions_per_length + $sparsity;
		my $newcost = $collisions_per_length + $len_w;
		my $new_cost_so_far = $cost + $cost_so_far;
		
		#---------------------------------------------------------------------------
		my $new_phrase = AI::Pathfinding::SMAstar::Examples::Phrase->new(
		    _word_list => $words,
		    _words_w_cands_list  => $words_w_cands,
		    _dictionary => $dictionary,
		    _dictionary_rev => $dictionary_rev,		   
		    _start_word => $w,
		    _cand => $c,	
		    _word => $w,
		    _predecessor => $phrase_obj,
	
		    _dir => 0,
		    _repeated_pal_hash_ref => $repeated_pal_hash_ref,
		    _letters_seen => \@sorted_letters_seen,
		    _cost => $newcost,
		    _cost_so_far => $new_cost_so_far,
		    _num_chars_so_far => $new_num_chars_so_far,
		    _num_new_chars => $num_new_chars,
		    _no_match_remainder => 1,
		    _depth => $depth+1,
		    );	
		
		#print "returning new phrase from third cond.\n";
		$new_phrase->{_phrase} = $new_phrase->roll_up_phrase();
		return $new_phrase;	  
		
	    }		
	}	
    }
}




#-----------------------------------------------------------------------------
# Return the number of successors of this phrase
#-----------------------------------------------------------------------------
sub get_num_successors
{
    my ($self) = @_;
    
    my $num_successors = 0;
    my $iterator = $self->get_descendants_num_iterator();

    while(my $next_descendant = $iterator->()){
	$num_successors++;
    }

    return $num_successors
}





#-----------------------------------------------------------------------------
# Get descendants number function.
#
# 
#
#-----------------------------------------------------------------------------
sub get_descendants_number
{
    my ($phrase_obj) = @_;
    if(!$phrase_obj){
	return;
    }
	
    my $words = $phrase_obj->{_word_list};
    my $words_w_cands = $phrase_obj->{_words_w_cands_list};
    my $dictionary = $phrase_obj->{_dictionary};
    my $dictionary_rev = $phrase_obj->{_dictionary_rev};
    my $repeated_pal_hash_ref = $phrase_obj->{_repeated_pal_hash_ref};
    my $letters_seen = $phrase_obj->{_letters_seen};
    my $cost = $phrase_obj->{_cost};
    my $cost_so_far = $phrase_obj->{_cost_so_far};
    my $num_chars_so_far = $phrase_obj->{_num_chars_so_far};
    my $no_match_remainder = $phrase_obj->{_no_match_remainder};
    my $depth = $phrase_obj->{_depth};
    
    my $direction = $phrase_obj->{_dir};
    my $word = $phrase_obj->{_start_word};
    my $whole_word = $phrase_obj->{_cand};    
    my $len_word = length($word);
    my @cands;
    my @descendants;

   
    if($direction == 0){
	@cands = AI::Pathfinding::SMAstar::Examples::PalUtils::get_cands_from_left($word, $dictionary, $dictionary_rev);
    }
    elsif($direction == 1){
	@cands = AI::Pathfinding::SMAstar::Examples::PalUtils::get_cands_from_right($word, $dictionary, $dictionary_rev);
    }
        
  
    my @words_to_make_phrases;
    my $stored_c;

    my $num_successors = 0;

    while(1){
	# this is a continuation of the second case below, where there were no 
	# match-remainders for the phrase-so-far, i.e. the palindrome has a space
	# in the middle with mirrored phrases on each side. 'cat tac' for example.
	my $next_word = shift(@words_to_make_phrases);
	if($next_word){
	    
	    my $w = $next_word;

	    my $repeated_word_p = 0;
	    my $antecedent = $phrase_obj->{_predecessor};
	    my $antecedent_dir = $antecedent->{_dir};
	    while($antecedent){

		if(defined($antecedent->{_word}) && $w eq $antecedent->{_word} && $antecedent_dir == 0){
		    $repeated_word_p = 1;
		    last;
		}
		$antecedent = $antecedent->{_predecessor};	
		if($antecedent){
		    $antecedent_dir = $antecedent->{_dir};
		}
	    }

	    if($repeated_word_p || $w eq $word){		
		next;  #skip this word, we are already looking at it
	    }
	    $num_successors++;	  
			    	   
	}
	else{	
	    my $c  = shift(@cands);	
	    if(!$c){
		return $num_successors;
	    }
	    
	    # ------------- filter for repeated palcands for a particular word------
	    # ----------------------------------------------------------------------
	    # This will avoid many repeated patterns among palindromes to trim down the
	    # number redundant palindromes generated.
	    # 		
	    my $letters_seen_str = join("", @{$phrase_obj->{_letters_seen}});
	    if($letters_seen_str){
		my $repeated_pal_hash_key;
		$repeated_pal_hash_key = $word . "^" . $c . "^" . $letters_seen_str;	
		
		#print "\n\nrepeated_pal_hash_key: $repeated_pal_hash_key\n";
		if(my $hash_val = $repeated_pal_hash_ref->{$repeated_pal_hash_key}){
		    # skip because '$word' <--> '$p' pattern has already appeared in a previous palindrome.
		    if($hash_val != $depth){
			next;  #skip
		    }
		}
		else{
		    #flag this candidate as already having been tested (below).
		    $repeated_pal_hash_ref->{$repeated_pal_hash_key} = $depth;
		}	
	    }
	    #--------------------------------------------------------------------------
	    #--------------------------------------------------------------------------
	    
	    my $len_c = length($c);
	    my $rev_c = reverse($c);	
	    my $word_remainder;
	    
	    if($len_c < $len_word){
		$word_remainder = $c;
	    }
	    elsif($len_c > $len_word){	
		$word_remainder = $word;
	    }
	    my $rev_word_remainder = reverse($word);
	    
	    my $num_cands = @cands;
	    
	    my $match_remainder;
	    my $len_match_remainder;
	    
	    
	    
	    if($len_c != $len_word){		
		$match_remainder = 1;				       
	    }
	    
	    
	    if($match_remainder){  # there is a length difference between the candidate and this word.		    
		$num_successors++;
	    }
	    else{
		#
		# There is no match_remainder, so this candidate is the reverse
		# of $word, or the phrase built so far is an "even" palindrome,
		# i.e. it has a word boundary (space) in the middle.
		#
		#
		# This is a special case since there is no match remainder.
		# Because there is no remainder to create new phrase obj from, this 
		# section goes through the whole word list and creates phrase objects
		# for each new word.   The number of new characters offered by each
		# word is recorded to help with guided search.
		#
		# Update:  this case now only goes through the word list for which there
		# are cands.
		
		@words_to_make_phrases = @$words_w_cands;
		#@words_to_make_phrases = @$words;
		
		
		$stored_c = $c;
		my $next_word = shift(@words_to_make_phrases);
		my $w = $next_word;
		
		my $repeated_word_p = 0;
		my $antecedent = $phrase_obj->{_predecessor};
		my $antecedent_dir = $antecedent->{_dir};
		while($antecedent){
		    
		    if(defined($antecedent->{_word}) && $w eq $antecedent->{_word} && $antecedent_dir == 0){
			$repeated_word_p = 1;
			last;
		    }
		    $antecedent = $antecedent->{_predecessor};	
		    if($antecedent){
			$antecedent_dir = $antecedent->{_dir};
		    }
		}
		
		if($repeated_word_p || $w eq $word){
		    next; #skip this word, we are already looking at it
		}
		$num_successors++;	  		
	    }		
	}	
    }

    return $num_successors;

}



#-----------------------------------------------------------------------------
# Get descendants iterator function.
# Generate the next descendant of a phrase object. Each descendant adds
# another word to the phrase that could possibly lead to a palindrome
#
#-----------------------------------------------------------------------------
sub get_descendants_num_iterator
{
    my ($phrase_obj) = @_;
    if(!$phrase_obj){
	return;
    }
	
    my $words = $phrase_obj->{_word_list};
    my $words_w_cands = $phrase_obj->{_words_w_cands_list};
    my $dictionary = $phrase_obj->{_dictionary};
    my $dictionary_rev = $phrase_obj->{_dictionary_rev};
    my $repeated_pal_hash_ref = $phrase_obj->{_repeated_pal_hash_ref};
    my $letters_seen = $phrase_obj->{_letters_seen};
    my $cost = $phrase_obj->{_cost};
    my $cost_so_far = $phrase_obj->{_cost_so_far};
    my $num_chars_so_far = $phrase_obj->{_num_chars_so_far};
    my $no_match_remainder = $phrase_obj->{_no_match_remainder};
    my $depth = $phrase_obj->{_depth};
    
    my $direction = $phrase_obj->{_dir};
    my $word = $phrase_obj->{_start_word};
    my $whole_word = $phrase_obj->{_cand};    
    my $len_word = length($word);
    my @cands;
    my @descendants;

   
    if($direction == 0){
	@cands = AI::Pathfinding::SMAstar::Examples::PalUtils::get_cands_from_left($word, $dictionary, $dictionary_rev);
    }
    elsif($direction == 1){
	@cands = AI::Pathfinding::SMAstar::Examples::PalUtils::get_cands_from_right($word, $dictionary, $dictionary_rev);
    }
        
  
    my @words_to_make_phrases;
    my $stored_c;

    return sub{	       

      LABEL:
	# this is a continuation of the second case below, where there were no 
	# match-remainders for the phrase-so-far, i.e. the palindrome has a space
	# in the middle with mirrored phrases on each side. 'cat tac' for example.
	my $next_word = shift(@words_to_make_phrases);
	if($next_word){
	    
	    my $w = $next_word;

	    my $repeated_word_p = 0;
	    my $antecedent = $phrase_obj->{_predecessor};
	    my $antecedent_dir = $antecedent->{_dir};
	    while($antecedent){

		if(defined($antecedent->{_word}) && $w eq $antecedent->{_word} && $antecedent_dir == 0){
		    $repeated_word_p = 1;
		    last;
		}
		$antecedent = $antecedent->{_predecessor};	
		if($antecedent){
		    $antecedent_dir = $antecedent->{_dir};
		}
	    }

	    if($repeated_word_p || $w eq $word){
		goto LABEL;
		#next;  #skip this word, we are already looking at it
	    }
	    return 1;	  
			    	   
	}
	else{	
	    my $c  = shift(@cands);	
	    if(!$c){
		return;
	    }
	    
	    # ------------- filter for repeated palcands for a particular word------
	    # ----------------------------------------------------------------------
	    # This will avoid many repeated patterns among palindromes to trim down the
	    # number redundant palindromes generated.
	    # 		
	    my $letters_seen_str = join("", @{$phrase_obj->{_letters_seen}});
	    if($letters_seen_str){
		my $repeated_pal_hash_key;
		$repeated_pal_hash_key = $word . "^" . $c . "^" . $letters_seen_str;	
		
		#print "\n\nrepeated_pal_hash_key: $repeated_pal_hash_key\n";
		if(my $hash_val = $repeated_pal_hash_ref->{$repeated_pal_hash_key}){
		    # skip because '$word' <--> '$p' pattern has already appeared in a previous palindrome.
		    if($hash_val != $depth){
			goto LABEL;
			# next;  #skip
		    }
		}
		else{
		    #flag this candidate as already having been tested (below).
		    $repeated_pal_hash_ref->{$repeated_pal_hash_key} = $depth;
		}	
	    }
	    #--------------------------------------------------------------------------
	    #--------------------------------------------------------------------------
	    
	    my $len_c = length($c);
	    my $rev_c = reverse($c);	
	    my $word_remainder;
	    
	    if($len_c < $len_word){
		$word_remainder = $c;
	    }
	    elsif($len_c > $len_word){	
		$word_remainder = $word;
	    }
	    my $rev_word_remainder = reverse($word);
	    
	    my $num_cands = @cands;
	    
	    my $match_remainder;
	    my $len_match_remainder;
	    
	    
	    
	    if($len_c != $len_word){		
		$match_remainder = 1;				       
	    }
	    
	    
	    if($match_remainder){  # there is a length difference between the candidate and this word.		    
		return 1;
	    }
	    else{
		#
		# There is no match_remainder, so this candidate is the reverse
		# of $word, or the phrase built so far is an "even" palindrome,
		# i.e. it has a word boundary (space) in the middle.
		#
		#
		# This is a special case since there is no match remainder.
		# Because there is no remainder to create new phrase obj from, this 
		# section goes through the whole word list and creates phrase objects
		# for each new word.   The number of new characters offered by each
		# word is recorded to help with guided search.
		#
		# Update:  this case now only goes through the word list for which there
		# are cands.
		
		@words_to_make_phrases = @$words_w_cands;
		#@words_to_make_phrases = @$words;
		
		
		$stored_c = $c;
		my $next_word = shift(@words_to_make_phrases);
		my $w = $next_word;
		
		my $repeated_word_p = 0;
		my $antecedent = $phrase_obj->{_predecessor};
		my $antecedent_dir = $antecedent->{_dir};
		while($antecedent){
		    
		    if(defined($antecedent->{_word}) && $w eq $antecedent->{_word} && $antecedent_dir == 0){
			$repeated_word_p = 1;
			last;
		    }
		    $antecedent = $antecedent->{_predecessor};	
		    if($antecedent){
			$antecedent_dir = $antecedent->{_dir};
		    }
		}
		
		if($repeated_word_p || $w eq $word){
		    goto LABEL;
		    #next; #skip this word, we are already looking at it
		}
		return 1;	  		
	    }		
	}	
    }
}


























#-----------------------------------------------------------------------------
# traverse from candidate phrase-object back up to start word, building up the 
# phrase string. iterative version.
#-----------------------------------------------------------------------------
sub roll_up_phrase
{
    my ($pobj, $phrase, $depth) = @_;  # depth == depth of recursion

    if(!$depth){
	$depth = 0;
    }
    
    while($pobj){
	if(!$pobj->{_cand} && $depth == 0){ 
	    # top-level call to roll_up_phrase is called on a root node.
	    return $pobj->{_start_word};
	}
	else{
	    # if depth is 0, that means this is a top-level call.
	    # otherwise this is the nth iteration within this while loop.


	    # if this is a top-level call and _phrase is already defined,
	    # just return _phrase.
	    if(defined($pobj->{_phrase}) && !$depth){  
		return $pobj->{_phrase};		    
	    }
	    
	    my $direction = $pobj->{_dir};
	    my $antecedent = $pobj->{_predecessor};
	    my $antecedent_predecessor;
	    my $no_match_remainder = $pobj->{_no_match_remainder};	   	    
	    my $ant_direction = 0;
	    my $ant_cand;
	   
	    if($antecedent){
		$antecedent_predecessor = $antecedent->{_predecessor};
		$ant_direction = $antecedent->{_dir};
		$ant_cand = $antecedent->{_cand};
	    }
	    
	    

	    my $word = defined($pobj->{_word}) ? $pobj->{_word} : "";
	    my $startword = defined($pobj->{_start_word}) ? $pobj->{_start_word} : "";	
	    my $cand = defined($pobj->{_cand}) ? $pobj->{_cand} : "";
	    
	    if(!$phrase){
		if($direction == 0){	
		    $phrase = $cand;		    
		}
		elsif($direction == 1){		
		    $phrase = $cand;		
		}
	    }
	    else{	    
		if($direction == 0){
		    if($ant_direction == 0){
			#**** special case for root node descendant***
			if(!$antecedent_predecessor){ # antecedent is root node.  
			    if($word){
				$phrase =  $word . " " . $phrase . " " . $cand;
			    }
			    else{
				$phrase = $phrase . " " . $cand;
			    }		    
			}		    
			else{			
			    if($no_match_remainder){  # handle the case where there was no match remainder
				$phrase = $word . " " . $phrase . " " . $cand;
			    }
			    else{
				$phrase = "" . $phrase . " " . $cand;		
			    }			
			}		    
		    }
		    elsif($ant_direction == 1){
			if($no_match_remainder){  # handle the case where there was no match remainder
			    $phrase = $cand . " " . $word . " " . $phrase . "";
			}
			else{
			    $phrase = $cand . " " . $phrase . "";	
			}
		    }
		}
		elsif($direction == 1){
		    if($ant_direction == 0){		    
			$phrase = "" . $phrase . " " . $cand;
			
		    }
		    elsif($ant_direction == 1){
			$phrase = $cand . " " . $phrase . "";
		    }
		}
	    }
	}
	
	$pobj = $pobj->{_predecessor};
	$depth++;
	
    }  # end while($pobj);
    
    return $phrase;
}




sub roll_up_phrase_plus_word
{
    my ($self) = @_;

    my $phrase = $self->{_phrase};
    my $word = $self->{_start_word};
    my $phrase_plus_cand = $phrase . ": " . $word;

    return $phrase_plus_cand;
}




sub DESTROY
{
    my ($self) = @_;

    my $antecedent;
    my $ant_phrase;

    my ($pkg, $filename, $line_num) = caller(); 

    if($self->{_predecessor}){
	$antecedent = $self->{_predecessor};
	$ant_phrase = $antecedent->{_phrase} ? $antecedent->{_phrase} : $antecedent->{_start_word};
    }
    else{	
	$antecedent->{_phrase} = "none";
    }

#    print "     $line_num, destroying phrase object $self, '" . $self->{_start_word} . ", " . $self->{_phrase} .
#	"', parent is $antecedent: '" .  $ant_phrase . "' \n";
    
#    if($line_num != 0){ # if not final sweep at program exit
#	print "        caller is: $pkg, $filename, $line_num\n";	
#    }
    
    if($line_num == 0){ # line_num is zero
	$d++;
#	print "\$d : $d\n";
    }
    
    #${$self->{_predecessor}} = 0;
    #${$self->{_descendants_list}} = 0;

    delete $self->{_predecessor};
    
   
}

































1;  # so the require or use succeeds

