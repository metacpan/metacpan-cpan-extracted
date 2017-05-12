#!/usr/bin/perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl AI-Pathfinding-SMAstar.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;



BEGIN { use_ok('AI::Pathfinding::SMAstar');
        use_ok('Tree::AVL');
	use_ok('AI::Pathfinding::SMAstar::Examples::PalUtils');
	use_ok('AI::Pathfinding::SMAstar::Examples::WordObj');
	use_ok('AI::Pathfinding::SMAstar::Examples::Phrase');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $dictionary_file;
my $min_letters;
my $caching;
my @words;
my @words_w_cands;
my @word_objs;
my $num_word_objs;
my @rev_word_objs;
my $num_words;
my $sparsity;
my $max_states_in_queue;
my %letter_freq;
my $max_word_length = 0;

my $MAX_COST = 99;

#my $collisions_per_length = PalUtils::collisions_per_length("ocid", "abo gad abalones rot abdicators enol aba dagoba");
#print "collisions: $collisions_per_length\n";
#exit;


$dictionary_file = 't/test8.lst';
$min_letters = 4;
$sparsity = 2;
$max_states_in_queue = 4;
  
diag("\ncreating AVL trees");

# create trees of WordObj objects, so that we can use
# WordObj::compare_up_to(), the 'relaxed' comparison function
my $avltree = Tree::AVL->new(
     fcompare => \&AI::Pathfinding::SMAstar::Examples::WordObj::compare,
     fget_key => \&AI::Pathfinding::SMAstar::Examples::WordObj::word,
     fget_data => \&AI::Pathfinding::SMAstar::Examples::WordObj::word,
    );

my $avltree_rev = Tree::AVL->new(
    fcompare => \&AI::Pathfinding::SMAstar::Examples::WordObj::compare,
    fget_key => \&AI::Pathfinding::SMAstar::Examples::WordObj::word,
    fget_data => \&AI::Pathfinding::SMAstar::Examples::WordObj::word,
    );


print STDERR "-" x 80 . "\n";
print STDERR "-" x 80 . "\n";


diag("reading dictionary '$dictionary_file'");
eval{

    ($num_words, @words) = AI::Pathfinding::SMAstar::Examples::PalUtils::read_dictionary_filter_by_density($dictionary_file, $sparsity);
};
is( $@, '', '$@ is not set after object insert' );

diag("loaded words: '$num_words'");
isnt( $num_words, undef, 'num_words is $num_words');



%letter_freq = AI::Pathfinding::SMAstar::Examples::PalUtils::find_letter_frequencies(@words);


foreach my $w (@words){
    my $length = length($w);
    if($length > $max_word_length){
	$max_word_length = $length;
    }
}


$num_words_filtered = @words;
diag("$num_words words in the currently loaded dictionary.  Minimum letters specified = $min_letters");
diag("$num_words_filtered words that meet the initial sparsity constraint max_sparsity = $sparsity.");

if(!@words){
    print STDERR "no words to process.  exiting\n";
    exit;
}

@word_objs = AI::Pathfinding::SMAstar::Examples::PalUtils::process_words_by_density(\@words, $sparsity);
@rev_word_objs = AI::Pathfinding::SMAstar::Examples::PalUtils::process_rev_words_by_density(\@words, $sparsity);
if(!@word_objs){ 
    print STDERR "no words achieve density specified by max sparsity $sparsity\n"; 
    exit;
}
$num_word_objs = @word_objs;


diag("loading avl trees.");
for (my $i = 0; $i < @word_objs; $i++) {
    show_progress($i/$num_words); 
    
    my $word = $word_objs[$i]->{_word};
    my $rev_word = $rev_word_objs[$i]->{_word};
 
    $avltree->insert($word_objs[$i]);    
    $avltree_rev->insert($rev_word_objs[$i]);
}
show_progress(1);
print STDERR "\n";


#
# Build the words-with-candidates list.   This will be used for phrases that are
# palindromes with a space in the middle position.   The descendants of these
# types of palindromes are found by sort-of starting all over again... any word becomes
# a candidate for the extension of the palindrome-  any word that has candidates,
# that is.   By building a list of only the words that have candidates, 
# the search time is greatly reduced.
#
my $i = 0;
diag("building words_w_cands_list.");
foreach my $w (@words){
    show_progress($i/$num_words); 
    my @candidates = AI::Pathfinding::SMAstar::Examples::PalUtils::get_cands_from_left($w, $avltree, $avltree_rev);
    if(@candidates){
	push(@words_w_cands, $w);
    }
    $i++;
}
show_progress(1);
print STDERR "\n";
my $num_words_w_cands = @words_w_cands;
diag("number of word/candidate pairs is: $num_words_w_cands.");

$avltree_height = $avltree->get_height();
$avltree_rev_height = $avltree_rev->get_height();

diag("AVL trees loaded.  Heights are $avltree_height, $avltree_rev_height\n\n");


my @phrase_obj_list;
my $smastar;

ok(
$smastar = AI::Pathfinding::SMAstar->new(
    _state_eval_func           => AI::Pathfinding::SMAstar::Examples::Phrase::evaluate($min_letters),
    _state_goal_p_func         => AI::Pathfinding::SMAstar::Examples::Phrase::phrase_is_palindrome_min_num_chars($min_letters),
    _state_num_successors_func => \&AI::Pathfinding::SMAstar::Examples::Phrase::get_num_successors,
    _state_successors_iterator => \&AI::Pathfinding::SMAstar::Examples::Phrase::get_descendants_iterator,		
    _state_get_data_func       => \&AI::Pathfinding::SMAstar::Examples::Phrase::roll_up_phrase,
    _show_prog_func            => sub{ },
    #_show_prog_func            => \&AI::Pathfinding::SMAstar::Examples::PalUtils::show_progress_so_far,
    ),
    'created smastar');


diag("smastar object created");


foreach my $word (@words_w_cands){
    my $sparsity = AI::Pathfinding::SMAstar::Examples::PalUtils::get_word_sparsity($word);   
    my $len_word = length($word);
    my $num_chars = AI::Pathfinding::SMAstar::Examples::PalUtils::num_chars_in_word($word);
    my $cost = $sparsity + $len_word;
    my $phrase = AI::Pathfinding::SMAstar::Examples::Phrase->new(
	_word_list      => \@words,
	_words_w_cands_list => \@words_w_cands,
	_dictionary     => $avltree,
	_dictionary_rev => $avltree_rev,
	_start_word     => $word,
	_word           => $word,
	_cost           => $cost,
	_letters_seen   => [],
	_cost_so_far    => 0,
	_num_chars_so_far => 0,	
	_num_new_chars  => $num_chars,
	);
    
    diag("inserting word $word");
    $smastar->add_start_state($phrase);

}


# diag("starting SMA* search...");
my $palindorme_phr_obj;
$palindrome_phr_obj = $smastar->start_search(
	\&log_function,
	\&str_function,
	$max_states_in_queue,
	$MAX_COST,
    );

my $palindrome;
if($palindrome_phr_obj){
    $palindrome = $palindrome_phr_obj->{_state}->roll_up_phrase();
}
diag("ran SMA search:   palindrome is '$palindrome'");

is( $palindrome, 'lid off a daffodil ', 'palindrome is [lid off a daffodil ]' );






###########################################################################
#
#  Auxiliary functions
#
###########################################################################



#----------------------------------------------------------------------------
sub log_function
{
    my ($path_obj) = @_;  
    
    if(!$path_obj){

	my ($pkg, $filename, $line) = caller();
	
	print "$pkg, $filename, $line\n";
	

    }

    my $str = "";
    # $cand is the parent's word (the candidate that generated this phrase)
    my $cand = "";  
    my $cost = "";
    my $cost_so_far = "";
    my $num_new_chars = "";
    my $num_chars_so_far = "";
    my $letters_seen = [];
    my $letters_seen_str = join("", @$letters_seen); 
    my $phrase = "";   
    my $evaluation = -1;
    my $depth = 0;
    
    $str = $path_obj->{_state}->{_start_word};
    # $cand is the parent's word (the candidate that generated this phrase)
    $cand = defined($path_obj->{_state}->{_cand}) ? $path_obj->{_state}->{_cand} : "";  
    $cost = $path_obj->{_state}->{_cost};
    $cost_so_far = $path_obj->{_state}->{_cost_so_far};
    $num_new_chars = $path_obj->{_state}->{_num_new_chars};
    $num_chars_so_far = $path_obj->{_state}->{_num_chars_so_far};
    $letters_seen = $path_obj->{_state}->{_letters_seen};
    $letters_seen_str = join("", @$letters_seen); 
    $phrase = defined($path_obj->{_state}->{_phrase}) ? $path_obj->{_state}->{_phrase} : "";    
    $evaluation = AI::Pathfinding::SMAstar::Path::fcost($path_obj);
    $depth = $path_obj->{_depth};
        
    
    $num_chars_so_far = sprintf("%02d", $num_chars_so_far);
    $num_new_chars = sprintf("%02d", $num_new_chars);
    $cost = sprintf("%02d", $cost);
    $cost_so_far = sprintf("%02d", $cost_so_far);
    $depth = sprintf("%02d", $depth);

    my $specifier = "%" . $max_word_length . "s";
    $str = sprintf($specifier, $str);
    $evaluation = sprintf("%04f", $evaluation);

    $letters_seen_str = sprintf("%26s", $letters_seen_str);
    
    my $log_str = "";

    $log_str = $log_str . "depth: $depth, ";
    $log_str = $log_str . "eval: $evaluation, ";
    $log_str = $log_str . "letters: '$letters_seen_str', ";
    $log_str = $log_str . "'$str', ";
    $log_str = $log_str . "'$phrase', ";
    $log_str = $log_str . "cand: $cand";
    

    
    return $log_str;   
}



#----------------------------------------------------------------------------

sub str_function
{
    my ($path_obj) = @_;    
    
    my $sw = defined($path_obj->{_state}->{_start_word}) ? $path_obj->{_state}->{_start_word} : "";    
    my $phrase = defined($path_obj->{_state}->{_phrase}) ? $path_obj->{_state}->{_phrase} : "";    
 
    my $str = "$sw, $phrase";
    
    return $str;   
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
    
    print STDERR "\r$stars $spinny_thing $percent.";
    flush(STDERR);
}
}
