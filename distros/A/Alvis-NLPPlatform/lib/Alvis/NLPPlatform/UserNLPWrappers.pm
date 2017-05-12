package Alvis::NLPPlatform::UserNLPWrappers;


use Alvis::NLPPlatform::NLPWrappers;

use strict;
use warnings;

use Data::Dumper;

use UNIVERSAL qw(isa);

our @ISA = ("Alvis::NLPPlatform::NLPWrappers");


our $VERSION=$Alvis::NLPPlatform::VERSION;


sub tokenize {
    my @arg = @_;

    my $class = shift @arg;

    return($class->SUPER::tokenize(@arg));

}



sub scan_ne 
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::scan_ne(@arg);

}

sub word_segmentation 
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::word_segmentation(@arg);

}

sub sentence_segmentation 
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::sentence_segmentation(@arg);

}


sub pos_tag 
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::pos_tag(@arg);

}


sub lemmatization 
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::lemmatization(@arg);

}


sub term_tag
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::term_tag(@arg);
#           &PrintOutputTreeTagger(@arg, \*STDOUT);
#           exit;
#            &execYaTeA(@arg);
#      exit;
}

sub PrintOutputTreeTagger {
    my ($h_config, $doc_hash, $output_stream) = @_;

    my $line;
    my $insentence;
    my $sentence;

    my $tokens;
    my $analyses;
    my $analysis;
    my $nsentence;
    my $token_start;
    my $token_end;
    my $relation;
    my $left_wall;
    my $right_wall;

    my $relation_id;

    my @arr_tokens;
    my $last_token;
    my $wordidshift=0;

    my $phrase_idx=$Alvis::NLPPlatform::Annotation::phrase_idx;

    print STDERR "  Performing TreeTagger like Output\n";

    my $word;
    my $worddecal;
    my $word_cont;
    my $word_id;
    my $i;
    my $sentences_cont="";

    my @tab_word_punct;
    my @tab_word;
    my $idx_tab_word_punct=1;
    my $idx_tab_word=1;
    my @tab_mapping;

    # print out words+punct and fill in a tab
    push @tab_word_punct," ";
    push @tab_word," ";

    my $decal=1;

    my $searchterm;
    my $sti;
    my $word_np;
    
    my @tab_tmp;
    my $tmp_sp;
    my $spi=0;

    my $termsfound=0;
    my $stubs=0;

    my $skip=0;

    my @tab_start_term=();
    my @tab_end_term=();

    my $constituents;
    my $nb_constituents;

    my $min;
    my $max;

    my $btw_start;
    my $btw_end;
    my $token;

    my $start_token=$Alvis::NLPPlatform::word_start[1];

    my $current_sentence_id = 1;
    my $current_section_id = 0;

    my $end_of_sentence = 0;
    my $last_mark_is_end_of_sentence = 0;


    foreach $word (Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_words_punct)){
	if($skip>0){
	    $skip--;
	}
	$min=$Alvis::NLPPlatform::word_start[Alvis::NLPPlatform::Annotation::read_key_id("word$decal")];
	$max=$Alvis::NLPPlatform::word_end[Alvis::NLPPlatform::Annotation::read_key_id("word$decal")];
	$word_cont=$Alvis::NLPPlatform::hash_words_punct{$word};

	push @tab_word_punct,$word_cont;

	$worddecal = "word$decal";

	my $postag=$Alvis::NLPPlatform::hash_postags{"word$decal"};
	my $lemma=$Alvis::NLPPlatform::hash_lemmas{"word$decal"};
#	print STDERR "$word_cont\n";
#  	print STDERR "$lemma\n";

	if((exists $Alvis::NLPPlatform::hash_words{"word$decal"})&&($word_cont ne $Alvis::NLPPlatform::hash_words{"word$decal"})){
	    # punctuation, delay incrementation of index "decal"
	    $decal--;
	    $postag="PUNCT";
	    $lemma=$word_cont;
	}

  	if ((defined $doc_hash->{"$worddecal"}) && (Alvis::NLPPlatform::token_id_just_before_last_of_list_refid_token($doc_hash->{"$worddecal"}->{'list_refid_token'}->{"refid_token"}, $doc_hash->{"sentence$current_sentence_id"}->{'refid_end_token'}))) {
	    if (index(";:.!?", $doc_hash->{$doc_hash->{"sentence$current_sentence_id"}->{'refid_end_token'}}->{"content"}) >-1) {
		$sentences_cont.= $doc_hash->{$doc_hash->{"sentence$current_sentence_id"}->{'refid_end_token'}}->{"content"} . "\tSENT\t" . $doc_hash->{$doc_hash->{"sentence$current_sentence_id"}->{'refid_end_token'}}->{"content"} . "\n";
		$end_of_sentence = 1;
		$last_mark_is_end_of_sentence = 1;
	    } else {
		$sentences_cont.= " \tSENT\t \n";
		$last_mark_is_end_of_sentence = 1;
		if (!defined $postag) {
		    $postag = "FW";
		}
		if (!defined $lemma) {
		    $lemma = $word_cont
		    }
		$sentences_cont.="$word_cont\t$postag\t$lemma\n";
		$last_mark_is_end_of_sentence = 0;
		$end_of_sentence = 1;
	    }
	    $current_sentence_id++;
	}
	if (!$end_of_sentence) {
	    if (!defined $postag) {
		$postag = "SYM";
	    }
	    if (!defined $lemma) {
		$lemma = $word_cont;
	    }
	    $sentences_cont.="$word_cont\t$postag\t$lemma\n";
	    $last_mark_is_end_of_sentence = 0;
	} else {
	    $end_of_sentence = 0;
	}
	# insert tokens between the current word and the next (spaces, punctuation, ...)
	$btw_start=$max+1;

# 	print STDERR (Alvis::NLPPlatform::Annotation::read_key_id("word$decal")+1) . " >? " . $Alvis::NLPPlatform::number_of_words . "\n";

	if(Alvis::NLPPlatform::Annotation::read_key_id("word$decal")+1 > $Alvis::NLPPlatform::number_of_words){
	    # We've reached the end of the document
	    $end_of_sentence = 1;
	    $btw_end=$Alvis::NLPPlatform::Annotation::nb_max_tokens;
# 	    print STDERR "===> $btw_start : $btw_end\n";
	    for($i=$btw_start;$i<=$btw_end;$i++){
		$token = $Alvis::NLPPlatform::hash_tokens{"token".$i};
		if (($token !~ /^ +/o) && ($token ne ".") && ($token ne "\\n")) { 
		    $sentences_cont .= "$token\t$token\t$token\n";
		    $last_mark_is_end_of_sentence = 0;
		}
		if ($token eq ".") {
		    $sentences_cont .= "$token\tSENT\t$token\n";
		    $last_mark_is_end_of_sentence = 1;
		    
		}
	    }
	}else{
	    $btw_end=$Alvis::NLPPlatform::word_start[Alvis::NLPPlatform::Annotation::read_key_id("word$decal")+1]-1;
	    for($i=$btw_start;$i<=$btw_end;$i++){
		$token = $Alvis::NLPPlatform::hash_tokens{"token".$i};
		if (($token !~ /^ +/o) && ($token ne ".") && ($token ne "\\n")) { 
		    $sentences_cont .= "$token\t$token\t$token\n";
		    $last_mark_is_end_of_sentence = 0;
		}
	    }
	}

	$decal++;
    }

    # fill words tab
    foreach $word(Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_words)){
	push @tab_word,$Alvis::NLPPlatform::hash_words{$word};
    }

    # pre-compute mapping between words+punct and words
    my $idx_nopunct=1;
    for($i=0;$i<scalar @tab_word_punct;$i++){
	if(($idx_nopunct<scalar @tab_word)&&($tab_word_punct[$i] eq $tab_word[$idx_nopunct])){
	    $tab_mapping[$i]=$idx_nopunct;
	    $idx_nopunct++;
	}
    }

    # remove whitespaces in NE
    my $ne;
    my $ne_cont;
    my $ne_mod;
    foreach $ne(keys %Alvis::NLPPlatform::hash_named_entities){
	$ne_cont=$Alvis::NLPPlatform::hash_named_entities{$ne};
	$ne_mod=$ne_cont;
	if(($ne_cont =~ / /) && ($ne_cont !~ /^ *$/)) {
	    if($sentences_cont =~ /\Q$ne_cont\E/){
		$ne_mod =~ s/ /\_/g;
		$sentences_cont =~ s/\Q$ne_cont\E/$ne_mod/g;
	    }
	}
# 	if ($ne_cont=~/ /){
# 	    if($sentences_cont=~/\Q$ne_cont\E/){
# 		$ne_mod=~s/ /\_/g;
# 		$sentences_cont=~s/$ne_cont/$ne_mod/g;
# 	    }
# 	}
    }
    if ($last_mark_is_end_of_sentence == 0) {
	$sentences_cont.= " \tSENT\t \n";
    }

    print $output_stream $sentences_cont;
}


sub execYaTeA {
    my ($h_config, $doc_hash) = @_;

    my $line;
    my $insentence;
    my $sentence;

    my $tokens;
    my $analyses;
    my $analysis;
    my $nsentence;
    my $token_start;
    my $token_end;
    my $relation;
    my $left_wall;
    my $right_wall;

    my $relation_id;

    my @arr_tokens;
    my $last_token;
    my $wordidshift=0;

    my $phrase_idx=$Alvis::NLPPlatform::Annotation::phrase_idx;

    my $word;
    my $word_cont;
    my $word_id;
    my $i;
    my $sentences_cont="";

    my @tab_word_punct;
    my @tab_word;
    my $idx_tab_word_punct=1;
    my $idx_tab_word=1;
    my @tab_mapping;

    # print out words+punct and fill in a tab
    push @tab_word_punct," ";
    push @tab_word," ";
    my $decal=1;

    my $searchterm;
    my $sti;
    my $word_np;
    
    my @tab_tmp;
    my $tmp_sp;
    my $spi=0;

    my $termsfound=0;
    my $stubs=0;

    my $skip=0;

    my @tab_start_term=();
    my @tab_end_term=();

    my $constituents;
    my $nb_constituents;

    my $min;
    my $max;

    my $btw_start;
    my $btw_end;
    my $token;
    my $sentence_cont;

    print STDERR "  Performing term extraction... \n";
    open CORPUS, ">>" . $h_config->{"TMPFILE"} . ".corpus.yatea.tmp";
    binmode(CORPUS, ":utf8");

    print CORPUS $Alvis::NLPPlatform::Annotation::document_record_id . "\tDOCUMENT\t" . $Alvis::NLPPlatform::Annotation::document_record_id . "\n" ;

    &PrintOutputTreeTagger($h_config, $doc_hash, \*CORPUS);

    close CORPUS;

#     if ((exists $h_config->{"XML_OUTPUT"}->{"YATEA"}) && ($h_config->{"XML_OUTPUT"}->{"YATEA"} == 1)) {
# 	%$doc_hash = ();
# 	%Alvis::NLPPlatform::hash_tokens = ();
# 	%Alvis::NLPPlatform::hash_words = ();
# 	%Alvis::NLPPlatform::hash_words_punct = ();
# 	%Alvis::NLPPlatform::hash_sentences = ();
# 	%Alvis::NLPPlatform::hash_postags = ();
# 	%Alvis::NLPPlatform::hash_named_entities = ();
# 	%Alvis::NLPPlatform::hash_lemmas = ();
	
# 	$Alvis::NLPPlatform::number_of_words = 0;
# 	$Alvis::NLPPlatform::number_of_sentences = 0;
# 	$Alvis::NLPPlatform::nb_relations = 0;
# 	$Alvis::NLPPlatform::dont_annotate = 0;
	
# 	@Alvis::NLPPlatform::word_start = ();
# 	@Alvis::NLPPlatform::word_end = ();
	
# 	@Alvis::NLPPlatform::en_start = ();
# 	@Alvis::NLPPlatform::en_end = ();
# 	@Alvis::NLPPlatform::en_type = ();
	
# 	@Alvis::NLPPlatform::en_tokens_start = ();
# 	@Alvis::NLPPlatform::en_tokens_end = ();
# 	%Alvis::NLPPlatform::en_tokens_hash = ();

#     }
    
    if (    $Alvis::NLPPlatform::last_doc == 0) {
	return(1);
    }

    require Lingua::YaTeA::Corpus;
    require Lingua::YaTeA;
    my %config_yatea = Lingua::YaTeA::load_config($h_config->{'NLP_tools'}->{'YATEARC'});


    my $yatea = Lingua::YaTeA->new($config_yatea{"OPTIONS"}, \%config_yatea);

    if (defined $h_config->{'NLP_tools'}->{'YATEAOUTPUT'}) {
	print STDERR "\nYaTeA output defined is " . $h_config->{'NLP_tools'}->{'YATEAOUTPUT'} . "\n\n";
	$yatea->getOptionSet->addOption("output-path", $h_config->{'NLP_tools'}->{'YATEAOUTPUT'});
    } else {
	print STDERR "\nNo YaTeA output defined\n\n";
	$yatea->getOptionSet->addOption("output-path", $h_config->{"ALVISTMP"});
    }

    my $corpus_path = $h_config->{"TMPFILE"} . ".corpus.yatea.tmp";
    my $corpus = Lingua::YaTeA::Corpus->new($corpus_path,$yatea->getOptionSet,$yatea->getMessageSet);

    

########################################################################

    my $sentence_boundary = $yatea->getOptionSet->getSentenceBoundary;
    my $document_boundary = $yatea->getOptionSet->getDocumentBoundary;

#    $yatea->loadTestifiedTerms(\$process_counter,$corpus,$sentence_boundary,$document_boundary,$yatea->getOptionSet->MatchTypeValue,$yatea->getMessageSet,$yatea->getOptionSet->getDisplayLanguage);

    print STDERR $Lingua::YaTeA::process_counter++ . ") " . ($yatea->getMessageSet->getMessage('LOAD_CORPUS')->getContent($yatea->getOptionSet->getDisplayLanguage)) . "\n";

    $corpus->read($sentence_boundary,$document_boundary,$yatea->getFSSet,$yatea->getTestifiedTermSet,$yatea->getMessageSet,$yatea->getOptionSet->getDisplayLanguage);

    my $phrase_set = Lingua::YaTeA::PhraseSet->new;
    
    print STDERR $Lingua::YaTeA::process_counter++ . ") " . ($yatea->getMessageSet->getMessage('CHUNKING')->getContent($yatea->getOptionSet->getDisplayLanguage)) . "\n";
    $corpus->chunk($phrase_set,$sentence_boundary,$document_boundary,$yatea->getChunkingDataSet,$yatea->getFSSet,$yatea->getTagSet,$yatea->getParsingPatternSet,$yatea->getTestifiedTermSet,$yatea->getOptionSet);

    $phrase_set->sortUnparsed;
    
    print STDERR $Lingua::YaTeA::process_counter++ . ") " . ($yatea->getMessageSet->getMessage('PARSING')->getContent($yatea->getOptionSet->getDisplayLanguage)) . "\n";
    
    $phrase_set->parseProgressively($yatea->getTagSet,$yatea->getOptionSet->getParsingDirection,$yatea->getParsingPatternSet,$yatea->getChunkingDataSet,$corpus->getLexicon,$corpus->getSentenceSet,$yatea->getMessageSet,$yatea->getOptionSet->getDisplayLanguage,\*STDERR);
    
    $phrase_set->addTermCandidates($yatea->getOptionSet);
    
    print STDERR $Lingua::YaTeA::process_counter++ . ") " . ($yatea->getMessageSet->getMessage('RESULTS')->getContent($yatea->getOptionSet->getDisplayLanguage)) . "\n";


# coments to keep
    print STDERR "\t-" . ($yatea->getMessageSet->getMessage('DISPLAY_RAW')->getContent($yatea->getOptionSet->getDisplayLanguage)) . "\'". $corpus->getOutputFileSet->getFile('debug')->getPath . "'\n";
    $phrase_set->printPhrases(FileHandle->new(">" . $corpus->getOutputFileSet->getFile('debug')->getPath));
    $phrase_set->printUnparsable($corpus->getOutputFileSet->getFile('unparsable'));


    print STDERR "\t-" . ($yatea->getMessageSet->getMessage('DISPLAY_TC_XML')->getContent($yatea->getOptionSet->getDisplayLanguage)) . "\'". $corpus->getOutputFileSet->getFile('candidates')->getPath . "'\n";
# 
    if ((exists $h_config->{"XML_OUTPUT"}->{"YATEA"}) && ($h_config->{"XML_OUTPUT"}->{"YATEA"} == 1)) {
	$phrase_set->printTermCandidatesXML("stdout",$yatea->getTagSet);
	exit;
    } else {
# 	$phrase_set->printTermCandidatesXML($corpus->getOutputFileSet->getFile("candidates"),$yatea->getTagSet);
	&storeTerms($phrase_set,$doc_hash,$yatea->getTagSet);
    }

########################################################################



########################################################################

#     }


########################################################################

    $Alvis::NLPPlatform::ALVISDEBUG || unlink $h_config->{'TMPFILE'}. ".corpus.tmp";

#    print STDERR "done - Found $Alvis::NLPPlatform::nb_relations relations, $termsfound full terms, $nb_constituents constituents.\n";
}


sub storeTerms
{
    my ($phrase_set,$doc_hash,$tagset) = @_;

    my $fh = \*STDOUT;
    
    my $term_candidate;
    my $if;
    my $pos;
    my $lf;
    my $occurrence;
    my $island;
    my $position;

    my $sem_unit;
    my $term;
    my $term_id = 1;
    my $syn_relation_id = 1;

    my $phrase_idx = $Alvis::NLPPlatform::Annotation::phrase_idx;
    my $relation_id = $Alvis::NLPPlatform::Annotation::syntactic_relation_idx;

    my %YateaTerms2AlvisSemUnits;
    my %YateaTermOcc2AlvisSemUnits;

    my $syntactic_relation_id;

    my $term_refid_head;
    my $term_refid_modifier;
    my $refid_head;
    my $refid_modifier;

    my $i_sem;


	    $sem_unit=$Alvis::NLPPlatform::last_semantic_unit + 1;


    foreach $term_candidate (values(%{$phrase_set->getTermCandidates}))
    {
	($if,$pos,$lf) = $term_candidate->buildLinguisticInfos($tagset);

	$term = $if;

	my $sent;
	my $offset;
	my $token_start;
	my $token_end;
	my $offset_start;
	my $offset_end;
	my $j;
	my $token_term;

	my @tabtmp;
	$YateaTerms2AlvisSemUnits{$term_candidate->getID} = \@tabtmp;

	foreach $occurrence (@{$term_candidate->getOccurrences})
	{
	    push @tabtmp, $sem_unit;
	    $YateaTermOcc2AlvisSemUnits{$occurrence->getID} = $sem_unit;

	    $doc_hash->{"semantic_unit$sem_unit"}={};
	    $doc_hash->{"semantic_unit$sem_unit"}->{"datatype"}="semantic_unit";
	    $doc_hash->{"semantic_unit$sem_unit"}->{"term"}={};
	    $doc_hash->{"semantic_unit$sem_unit"}->{"term"}->{"datatype"}="term";
	    $doc_hash->{"semantic_unit$sem_unit"}->{"term"}->{"id"}="term" . ($term_id++); # . ":" . $sem_unit
	    $doc_hash->{"semantic_unit$sem_unit"}->{"term"}->{"form"}=$term;
	    push @Alvis::NLPPlatform::found_terms,$term;
	    push @Alvis::NLPPlatform::found_terms_smidx,($term_id-1);


	    $doc_hash->{"semantic_unit$sem_unit"}->{"term"}->{"canonical_form"} = $lf; # "sentence" . $occurrence->getSentence->getInDocID;
	    $sent = $occurrence->getSentence->getInDocID;
	    $offset = $occurrence->getStartChar;

	    $doc_hash->{"sentence$sent"}->{"refid_start_token"}=~m/token([0-9]+)/i;
	    $token_start=$1;
	    $doc_hash->{"sentence$sent"}->{"refid_end_token"}=~m/token([0-9]+)/i;
	    $token_end=$1;

	    $offset_start=$doc_hash->{$doc_hash->{"sentence$sent"}->{"refid_start_token"}}->{"from"};
	    $offset_end=$doc_hash->{$doc_hash->{"sentence$sent"}->{"refid_start_token"}}->{"to"};

	    $offset+=$offset_start;

	    $j=$token_start;
	    while(($j<$token_end) && ($doc_hash->{"token$j"}->{"from"} < $offset)){
		$j++;
	    }
	    if (index($term, $doc_hash->{"token$j"}->{"content"}) == 0) {
		$token_term=$j;
	    } else {
		$token_term=$j-1;
	    }
	    my @tab_tokens;

 	    for($j=$token_term; $doc_hash->{"token$j"}->{"to"} < ($doc_hash->{"token$token_term"}->{"from"} + ($occurrence->getEndChar - $occurrence->getStartChar) );$j++){
 		push @tab_tokens, "token$j";
 	    }

	    my $k=1;
	    my $term_word_start=-1;
	    my $term_word_end=-1;
	    my @tab_words;
	    for($k=1;$k<=$Alvis::NLPPlatform::number_of_words;$k++){
		if($Alvis::NLPPlatform::word_start[$k]==Alvis::NLPPlatform::Annotation::read_key_id($tab_tokens[0])){
		    $term_word_start=$k;
		}
		if($Alvis::NLPPlatform::word_end[$k]==Alvis::NLPPlatform::Annotation::read_key_id($tab_tokens[(scalar @tab_tokens)-1])){
		    $term_word_end=$k;
		    last;
		}
	    }
	    if (($term_word_start != -1) && ($term_word_end != -1)) {
		for($k=$term_word_start;$k<=$term_word_end;$k++){
		    push @tab_words,"word$k";
		}
	    }
	    if (scalar @tab_words == 0) {
# 			    warn "No word found for the term $term\n";
		$doc_hash->{"semantic_unit$sem_unit"}->{"term"}->{"list_refid_token"}={};
		$doc_hash->{"semantic_unit$sem_unit"}->{"term"}->{"list_refid_token"}->{"datatype"} = "list_refid_token";
		$doc_hash->{"semantic_unit$sem_unit"}->{"term"}->{"list_refid_token"}->{"refid_token"}=\@tab_tokens;
		
	    }
	    if(scalar @tab_words==1){
		$doc_hash->{"semantic_unit$sem_unit"}->{"term"}->{"refid_word"}=$tab_words[0];
	    }
	    if(scalar @tab_words>1){
		$doc_hash->{"phrase$phrase_idx"}={};
		$doc_hash->{"phrase$phrase_idx"}->{'id'}="phrase$phrase_idx";
		$doc_hash->{"phrase$phrase_idx"}->{'datatype'}="phrase";
		$doc_hash->{"phrase$phrase_idx"}->{'list_refid_components'}={};
		$doc_hash->{"phrase$phrase_idx"}->{'list_refid_components'}->{"datatype"}="list_refid_components";
		$doc_hash->{"phrase$phrase_idx"}->{'list_refid_components'}->{"refid_word"}=\@tab_words;

		$doc_hash->{"semantic_unit$sem_unit"}->{"term"}->{"refid_phrase"}="phrase$phrase_idx";
		# At this point, we have created a term and a phrase. We need to commit this to memory,
		# as it will come in handy!
		push @Alvis::NLPPlatform::found_terms_phr,$phrase_idx;
		push @Alvis::NLPPlatform::found_terms_words,\@tab_words;
		
		$phrase_idx++;
	    }
	    else{
		push @Alvis::NLPPlatform::found_terms_phr,-666; # there is no phrase
		push @Alvis::NLPPlatform::found_terms_words,\@tab_words;
	    }

	    $sem_unit++;
	}	    

    }
    $Alvis::NLPPlatform::Annotation::phrase_idx = $phrase_idx - 1;
    $Alvis::NLPPlatform::last_semantic_unit = $sem_unit - 1;


    print STDERR "done - Found ". ($term_id - 1) ." semantic units\n";
    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found Terms: " . ($term_id - 1);
    print STDERR "done - Found ". $Alvis::NLPPlatform::Annotation::phrase_idx ." phrases\n";
    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found Phrase: " . $Alvis::NLPPlatform::Annotation::phrase_idx;


    # Second foreach to add syntactic relations

    foreach $term_candidate (values(%{$phrase_set->getTermCandidates}))
    {
	if(isa($term_candidate,'Lingua::YaTeA::MultiWordTermCandidate'))
	{
	    foreach $occurrence (@{$term_candidate->getOccurrences}) {
		$sem_unit = $YateaTermOcc2AlvisSemUnits{$occurrence->getID};
	    if (($term_refid_head = &getSem_unitFromTermOcc($term_candidate->getRootHead->getKey, $phrase_set, $occurrence->getStartChar, $occurrence->getEndChar, \%YateaTermOcc2AlvisSemUnits)) == -1) {
		warn "Occurrence not found (H)\n";
	    }

	    if (($term_refid_modifier = &getSem_unitFromTermOcc($term_candidate->getRootModifier->getKey, $phrase_set, $occurrence->getStartChar, $occurrence->getEndChar, \%YateaTermOcc2AlvisSemUnits)) == -1) {
		warn "Occurrence not found (M)\n";
	    }

		$syntactic_relation_id = "syntactic_relation$relation_id";
		$doc_hash->{$syntactic_relation_id}={};
		$doc_hash->{$syntactic_relation_id}->{'id'}=$syntactic_relation_id;
		$doc_hash->{$syntactic_relation_id}->{'datatype'}="syntactic_relation";
		$doc_hash->{$syntactic_relation_id}->{'syntactic_relation_type'}="Head_of";
		$doc_hash->{$syntactic_relation_id}->{'refid_head'} = {};
		$doc_hash->{$syntactic_relation_id}->{'refid_head'}->{'datatype'}="refid_head";
		if (exists $doc_hash->{"semantic_unit$term_refid_head"}->{"term"}->{"refid_phrase"}) {
		    $doc_hash->{$syntactic_relation_id}->{'refid_head'}->{"refid_phrase"}=  $doc_hash->{"semantic_unit$term_refid_head"}->{"term"}->{"refid_phrase"};
		} else {
		    if (exists $doc_hash->{"semantic_unit$term_refid_head"}->{"term"}->{"refid_word"}) {
			$doc_hash->{$syntactic_relation_id}->{'refid_head'}->{"refid_word"}= $doc_hash->{"semantic_unit$term_refid_head"}->{"term"}->{"refid_word"};
		    } else {
			warn "Mismath when finding the term (tokens found rather than word or phrase)";
		    }
		}
		$doc_hash->{$syntactic_relation_id}->{'refid_modifier'} = {};
		$doc_hash->{$syntactic_relation_id}->{'refid_modifier'}->{'datatype'}="refid_modifier";
		if (exists $doc_hash->{"semantic_unit$sem_unit"}->{"term"}->{"refid_phrase"}) {
		    $doc_hash->{$syntactic_relation_id}->{'refid_modifier'}->{"refid_phrase"}= $doc_hash->{"semantic_unit$sem_unit"}->{"term"}->{"refid_phrase"};
		} else {
		    if (exists $doc_hash->{"semantic_unit$sem_unit"}->{"term"}->{"refid_word"}) {
			$doc_hash->{$syntactic_relation_id}->{'refid_modifier'}->{"refid_word"} = $doc_hash->{"semantic_unit$sem_unit"}->{"term"}->{"refid_word"};
		    } else {
			warn "Mismath when finding the term (tokens found rather than word or phrase)";
		    }
		}
		$relation_id++;

		$syntactic_relation_id = "syntactic_relation$relation_id";
		$doc_hash->{$syntactic_relation_id}={};
		$doc_hash->{$syntactic_relation_id}->{'id'}=$syntactic_relation_id;
		$doc_hash->{$syntactic_relation_id}->{'datatype'}="syntactic_relation";
		$doc_hash->{$syntactic_relation_id}->{'syntactic_relation_type'}="Modifier_of";
		$doc_hash->{$syntactic_relation_id}->{'refid_head'} = {};
		$doc_hash->{$syntactic_relation_id}->{'refid_head'}->{'datatype'}="refid_head";
		if (exists $doc_hash->{"semantic_unit$term_refid_modifier"}->{"term"}->{"refid_phrase"}) {
		    $doc_hash->{$syntactic_relation_id}->{'refid_head'}->{"refid_phrase"}=  $doc_hash->{"semantic_unit$term_refid_modifier"}->{"term"}->{"refid_phrase"};
		} else {
		    if (exists $doc_hash->{"semantic_unit$term_refid_modifier"}->{"term"}->{"refid_word"}) {
			$doc_hash->{$syntactic_relation_id}->{'refid_head'}->{"refid_word"}= $doc_hash->{"semantic_unit$term_refid_modifier"}->{"term"}->{"refid_word"};
		    } else {
			warn "Mismath when finding the term (tokens found rather than word or phrase)";
		    }
		}
		$doc_hash->{$syntactic_relation_id}->{'refid_modifier'} = {};
		$doc_hash->{$syntactic_relation_id}->{'refid_modifier'}->{'datatype'}="refid_modifier";
		if (exists $doc_hash->{"semantic_unit$term_refid_head"}->{"term"}->{"refid_phrase"}) {
		    $doc_hash->{$syntactic_relation_id}->{'refid_modifier'}->{"refid_phrase"}=  $doc_hash->{"semantic_unit$term_refid_head"}->{"term"}->{"refid_phrase"};
		} else {
		    if (exists $doc_hash->{"semantic_unit$term_refid_head"}->{"term"}->{"refid_word"}) {
			$doc_hash->{$syntactic_relation_id}->{'refid_modifier'}->{"refid_word"}= $doc_hash->{"semantic_unit$term_refid_head"}->{"term"}->{"refid_word"};
		    } else {
			warn "Mismath when finding the term (tokens found rather than word or phrase)";
		    }
		}
		$relation_id++;

		$syntactic_relation_id = "syntactic_relation$relation_id";
		$doc_hash->{$syntactic_relation_id}={};
		$doc_hash->{$syntactic_relation_id}->{'id'}=$syntactic_relation_id;
		$doc_hash->{$syntactic_relation_id}->{'datatype'}="syntactic_relation";
		$doc_hash->{$syntactic_relation_id}->{'syntactic_relation_type'}="Component_in_modifier_position";
		$doc_hash->{$syntactic_relation_id}->{'refid_head'} = {};
		$doc_hash->{$syntactic_relation_id}->{'refid_head'}->{'datatype'}="refid_head";
		if (exists $doc_hash->{"semantic_unit$term_refid_modifier"}->{"term"}->{"refid_phrase"}) {
		    $doc_hash->{$syntactic_relation_id}->{'refid_head'}->{"refid_phrase"}=  $doc_hash->{"semantic_unit$term_refid_modifier"}->{"term"}->{"refid_phrase"};
		} else {
		    if (exists $doc_hash->{"semantic_unit$term_refid_modifier"}->{"term"}->{"refid_word"}) {
			$doc_hash->{$syntactic_relation_id}->{'refid_head'}->{"refid_word"}= $doc_hash->{"semantic_unit$term_refid_modifier"}->{"term"}->{"refid_word"};
		    } else {
			warn "Mismath when finding the term (tokens found rather than word or phrase)";
		    }
		}
		$doc_hash->{$syntactic_relation_id}->{'refid_modifier'} = {};
		$doc_hash->{$syntactic_relation_id}->{'refid_modifier'}->{'datatype'}="refid_modifier";
		if (exists $doc_hash->{"semantic_unit$sem_unit"}->{"term"}->{"refid_phrase"}) {
		    $doc_hash->{$syntactic_relation_id}->{'refid_modifier'}->{"refid_phrase"}= $doc_hash->{"semantic_unit$sem_unit"}->{"term"}->{"refid_phrase"};
		} else {
		    if (exists $doc_hash->{"semantic_unit$sem_unit"}->{"term"}->{"refid_word"}) {
			$doc_hash->{$syntactic_relation_id}->{'refid_modifier'}->{"refid_word"}= $doc_hash->{"semantic_unit$sem_unit"}->{"term"}->{"refid_word"};
		    } else {
			warn "Mismath when finding the term (tokens found rather than word or phrase)";
		    }
		}
		$relation_id++;
	    }
	}
    }
    $Alvis::NLPPlatform::Annotation::syntactic_relation_idx = $relation_id;

    print STDERR "done - Found ". ($relation_id - 1) ." syntactic relations\n";
    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found Syntactic Relations: " . ($relation_id - 1);

    
}


sub getSem_unitFromTermOcc
{
    my ($termKey, $phrase_set, $start_char, $end_char, $ref_YateaTermOcc2AlvisSemUnits) = @_;

    my @occurrences;
    my $i;


    my $term_candidate = $phrase_set->getTermCandidates->{$termKey};


    @occurrences = @{$term_candidate->getOccurrences};


    $i = 0;

    while (($i<scalar(@occurrences)) && (($start_char > $occurrences[$i]->getStartChar) || ($occurrences[$i]->getStartChar > $end_char))) {
	$i++;
    }
    if ($i < scalar @occurrences) {
	return($ref_YateaTermOcc2AlvisSemUnits->{$occurrences[$i]->getID});
    }

    return(-1);


}

sub mergeYaTeAResults
{
    my ($doc_hash, $yatea) = @_;

    # creation of the terms

    # creation of the phrases

}

sub syntactic_parsing
{
    my @arg = @_;

    
    my $class = shift @arg;

          $class->SUPER::syntactic_parsing(@arg);
#             &bio_syntactic_parsing(@arg);
}

my $word_id_np=1;

sub parse_constituents {
    my $constituents=$_[0];
    my $tmpptr=$_[1];
    my $decal_phrase_idx=$_[1];
    my $doc_hash=$_[2];
    my $lexer;
    my @tab_type;
    my @tab_string;
    my $lconst = 0;
    my $nconst = 0;
    my $phrase_id = "";
    my $csti;
    my $phrase_idx_start = $Alvis::NLPPlatform::Annotation::phrase_idx;
    require Alvis::NLPPlatform::ParseConstituents;


    my $parser = Alvis::NLPPlatform::ParseConstituents->new();

#     print STDERR $constituents;

    $parser->YYData->{CONSTITUENT_STRING} = $constituents;
    $parser->YYData->{DOC_HASH} = $doc_hash;
    $parser->YYData->{DECAL_PHRASE_IDX} = $decal_phrase_idx;
    $parser->YYData->{WORD_ID_NP_REF} =  \$word_id_np;
    $parser->YYData->{TAB_TYPE_REF} =  \@tab_type;
    $parser->YYData->{TAB_STRING_REF} =  \@tab_string;

    $parser->YYData->{LCONST_REF} =  \$lconst;
    $parser->YYData->{NCONST_REF} =  \$nconst;
;
    $parser->YYParse(yylex => \&Alvis::NLPPlatform::ParseConstituents::_Lexer, yyerror => \&Alvis::NLPPlatform::ParseConstituents::_Error);



    for($csti=1;$csti<scalar @tab_type;$csti++){
	$phrase_id = "phrase" . $Alvis::NLPPlatform::Annotation::phrase_idx;
	$doc_hash->{$phrase_id}={};
	$doc_hash->{$phrase_id}->{"id"}=$phrase_id;
	$doc_hash->{$phrase_id}->{"datatype"}="phrase";
	$doc_hash->{$phrase_id}->{"type"}=$tab_type[$csti];
	$doc_hash->{$phrase_id}->{'list_refid_components'}={};
	$doc_hash->{$phrase_id}->{'list_refid_components'}->{"datatype"}="list_refid_components";
	if (scalar(@{$tab_string[$csti]}) == 1) {
	    $doc_hash->{$phrase_id}->{'list_refid_components'}->{"refid_word"}=$tab_string[$csti];
	} else {
	    $doc_hash->{$phrase_id}->{'list_refid_components'}->{"refid_phrase"}=$tab_string[$csti];
	}
	$Alvis::NLPPlatform::Annotation::phrase_idx++;
   }
    
    print STDERR "done - Found ". ($Alvis::NLPPlatform::Annotation::phrase_idx - $phrase_idx_start) ." semantic units\n";
    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found Terms: " . ($Alvis::NLPPlatform::Annotation::phrase_idx - $phrase_idx_start);

#    $word_count=$word_id_np-$word_count;
#    print STDERR "\nWord count for this sentence: $word_count\n";

    return $decal_phrase_idx+$csti-1;
}


sub parse_constituents_old {
    my $constituents=$_[0];
    my $tmpptr=$_[1];
    my $decal_phrase_idx=$_[1];
    my $doc_hash=$_[2];
    my $lexer;
    my $debug_mode=0;
    my $lconst=0;
    my $nconst=0;

    my @tab_nconst;
    my @tab_type;
    my @tab_string;

    my $word_count=$word_id_np;
    my $lastword="";

#    print STDERR "PHRASE DECAL: $decal_phrase_idx\n";

    my @cst_token=(
	# OPEN
	'type1','\[([A-Z]+)', sub {
	    # open constituent
	    if($lconst>0){
		$tab_string[$tab_nconst[$lconst]].="phrase".($decal_phrase_idx+$nconst+1)." ";
	    }
	    $lconst++;
	    $nconst++;
	    $tab_nconst[$lconst]=$nconst;

	    # get type
	    $tab_type[$tab_nconst[$lconst]]=$1;
	    $lexer->end('type1');
	    $lexer->start('string');

	    print STDERR "*** DEBUG *** Opened constituent $nconst with type ".$1."\n" unless ($debug_mode==0);

	},
	# CLOSE
	'type2','([A-Z]+)\]', sub {
	    # check type
	    if($1 ne $tab_type[$tab_nconst[$lconst]]){
		print STDERR "Error found at level $lconst: types don't match!\n";
		$lexer->end('ALL');
		exit 0;
	    }
	    # remove ending space
	    $tab_string[$tab_nconst[$lconst]]=~s/\s+$//sgo;
	    # close constituent
	    print STDERR "*** DEBUG *** Closing constituent $tab_nconst[$lconst]\n" unless ($debug_mode==0);
	    $lconst--;
	},
	# STRING
	'string','[^\s]+\s', sub {
	    print STDERR "*** DEBUG *** Found string '".$_[0]->text."'\n" unless ($debug_mode==0);
	    if((defined $tab_string[$tab_nconst[$lconst]])&&($tab_string[$tab_nconst[$lconst]] ne "")){
		print STDERR "*** DEBUG *** Appended to previously found string\n" unless ($debug_mode==0);
#		$tab_string[$tab_nconst[$lconst]].=$_[0]->text;
		if(($_[0]->text eq $lastword) || ($_[0]->text=~/^\./)){
		}else{
		    $tab_string[$tab_nconst[$lconst]].="word$word_id_np ";
		    $word_id_np++;
		    $lastword=$_[0]->text;
		}
	    }else{
#		$tab_string[$tab_nconst[$lconst]]=$_[0]->text;
		if(!(($_[0]->text eq $lastword)||($_[0]->text=~/^\./))){
		    $lastword=$_[0]->text;
		    $tab_string[$tab_nconst[$lconst]]="word$word_id_np ";
		    $word_id_np++;
		}else{
		}
	    }
	    $lexer->end('string');
	    $lexer->start('type2');
	},
	# MISC
	'espace','\s+', sub {
	},
	'newline','\n', sub {
	    # dump result and reset automaton memory
	},

	# ERROR HANDLER
	'ALL:ERROR' => '' => sub {
	    print STDERR "Syntax error: malformed string\n";
	    $lexer->end('ALL');
	    #return $decal_phrase_idx;
	}

	);

    Parse::Lex->exclusive('parse');
    $lexer=Parse::Lex->new(@cst_token);
#    print STDERR "\nPARSING CONSTITUENTS STRING\n$constituents\n";
    $lexer->from($constituents);
    $lexer->every(sub{});

# my $parametre;
# my $format=0;
# foreach $parametre (@ARGV){
#     if($parametre eq "--xml"){
# 	$format=1;
#     }
# }

    # create phrases (constituents)
#				$doc_hash->{"syntactic_relation$relation_id"}={};
#				$doc_hash->{"syntactic_relation$relation_id"}->{'id'}="syntactic_relation$relation_id";
#				$doc_hash->{"syntactic_relation$relation_id"}->{'datatype'}="syntactic_relation";
#				$doc_hash->{"syntactic_relation$relation_id"}->{'syntactic_relation_type'}="$relation";
#				$doc_hash->{"syntactic_relation$relation_id"}->{'refid_head'} = {};
#				$doc_hash->{"syntactic_relation$relation_id"}->{'refid_head'}->{'datatype'}="refid_head";
    my $csti=1;
#    for($csti=1;$csti<scalar @tab_type;$csti++){
#	$doc_hash->{"phrase$csti"}={};
#	$doc_hash->{"phrase$csti"}->{"id"}="phrase$csti";
#	$doc_hash->{"phrase$csti"}->{"datatype"}="phrase";
#	$doc_hash->{"phrase$csti"}->{"type"}=$tab_type[$csti];
#	$doc_hash->{"phrase$csti"}->{"contents"}=$tab_string[$csti];
#	print STDERR "<phrase>\n";
#	print STDERR "  <id>phrase".($decal_phrase_idx+$csti)."</id>\n";
#	print STDERR "  <type>$tab_type[$csti]</type>\n";
#	print STDERR "  <form>$tab_string[$csti]</form>\n";
#	print STDERR "</phrase>\n";
#    }
    
    $lexer->end('ALL');
    undef $lexer;

#    $word_count=$word_id_np-$word_count;
#    print STDERR "\nWord count for this sentence: $word_count\n";

    return $decal_phrase_idx+$csti-1;
}



# TODO : Check that parsing is only performed on english texts

sub bio_syntactic_parsing {
    my ($h_config, $doc_hash) = @_;

    my $line;
    my $insentence;
    my $sentence;

    my $parsedconstituent = 0;

    my $tokens;
    my $analyses;
    my $analysis;
    my $nsentence;
    my $token_start;
    my $token_end;
    my $relation;
    my $left_wall;
    my $right_wall;

    my $relation_id;

    my @arr_tokens;
    my $last_token;
    my $wordidshift=0;

    my $phrase_idx=$Alvis::NLPPlatform::Annotation::phrase_idx;


    my $word;
    my $word_cont;
    my $word_id;
    my $i;
    my $sentences_cont="";

    my @tab_word_punct;
    my @tab_word;
    my $idx_tab_word_punct=1;
    my $idx_tab_word=1;
    my @tab_mapping;

    # print out words+punct and fill in a tab
    push @tab_word_punct," ";
    push @tab_word," ";
    my $decal=1;

    my $searchterm;
    my $sti;
    my $word_np;
	    
    my @tab_tmp;
    my $tmp_sp;
    my $spi=0;

    my $termsfound=0;
    my $stubs=0;

    my $skip=0;

    my @tab_start_term=();
    my @tab_end_term=();

    my $constituents;
    my $nb_constituents;


    print STDERR "  Performing syntactic analysis...";

    $sentences_cont .= "<sentences>\n\n";

    $sentences_cont .= "\n<sentence>\n";


    foreach $word(Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_words_punct)){
	if($skip>0){
	    $skip--;
#	    next;
	}

# 	print STDERR "word\n";
	$word_cont=$Alvis::NLPPlatform::hash_words_punct{$word};
	push @tab_word_punct,$word_cont;

	my $postag=$Alvis::NLPPlatform::hash_postags{"word$decal"};
	if((exists $Alvis::NLPPlatform::hash_words{"word$decal"})&&($word_cont ne $Alvis::NLPPlatform::hash_words{"word$decal"})){
	    # punctuation, delay incrementation of index "decal"
	    $decal--;
	    $postag="PUNCT";
	}

	if($word_cont eq "."){
	    $sentences_cont.="<w c=\"SENT\">.</w>\n";
	    $sentences_cont.="</sentence>\n";
	    $sentences_cont.="<sentence>\n";
	}else{
	    # determine if current word is part of a term
	    $searchterm="";
	    @tab_tmp=();
	    $tmp_sp=0;

	    $word_np=$Alvis::NLPPlatform::hash_words{"word$decal"};
	    for($sti=0;$sti<scalar @Alvis::NLPPlatform::found_terms;$sti++){
		my $ref_tab_tmp_words;
		$searchterm=$Alvis::NLPPlatform::found_terms[$sti];
#		print STDERR "Searching for term $searchterm / comparing with word ".$Alvis::NLPPlatform::hash_words{"word$decal"}."\n";
		$ref_tab_tmp_words=$Alvis::NLPPlatform::found_terms_words[$sti];
#		print STDERR "word$decal- Searching for term ($sti) $searchterm / words ";
#		print STDERR join ",",@$ref_tab_tmp_words;
#		print STDERR "\n";

		if(lc($Alvis::NLPPlatform::hash_words{"word$decal"}) eq lc($searchterm)){
		    # look for one-word terms
#		    print STDERR "\n--== Found term $searchterm ==--\n";
#		    print STDERR "word$decal makes up '$searchterm' on its own (single word/NE).\n";
		    $termsfound++;
		    push @Alvis::NLPPlatform::found_terms_tidx,$sti;
		    $sti=scalar @Alvis::NLPPlatform::found_terms;
		    $tmp_sp=1;
		    last;
		}else{
		    # look for multiple word terms (they have to be phrases)
		    if($Alvis::NLPPlatform::found_terms_phr[$sti] != -666){
			# determine if the current word ($decal) is part of it
			# then set $tmp_sp to the nb of words involved
			if(@$ref_tab_tmp_words[0] eq "word$decal"){
			    # the current word is the first word of the term
#			    print STDERR "word$decal is the first word of the term '$searchterm'.\n";
			    $termsfound++;
			    push @Alvis::NLPPlatform::found_terms_tidx,$sti;
			    $sti=scalar @Alvis::NLPPlatform::found_terms;
			    $tmp_sp=scalar @$ref_tab_tmp_words;
			    last;
			}
		    }
		    
###############################################
# 		    if($searchterm=~/^$word_np/i){
# 			print STDERR "\n--== $word_np is the beginning of $searchterm ==--\n";
# 			$stubs++;

# 			@tab_tmp=split / /,$searchterm;
# 			$tmp_sp=scalar @tab_tmp;
#		        print STDERR "--== $tmp_sp words, right? ==--\n";
# 			$skip=$tmp_sp;

# 			for($spi=$decal+1;$spi<$decal+$tmp_sp;$spi++){
# 			    $word_np.=" ".$Alvis::NLPPlatform::hash_words{"word$spi"};
# 			}
# 			print STDERR "--== Rebuilt term to $word_np ==--\n";
# 			$termsfound++;
# 			push @Alvis::NLPPlatform::found_terms_tidx,$sti;
# 			$sti=scalar @Alvis::NLPPlatform::found_terms;
# 			last;
# 		    }
###############################################
		}
		$searchterm="";
	    }
	    #
	    if($searchterm eq ""){
		# there was no term
		if (!defined($postag)) { warn "no POStag defined for $word_cont - setting to symbol\n"; $postag = "SYM";}
		if (!defined($word_cont)) { warn "no word_cont $word_cont\n";}
		$sentences_cont.="<w c=\"$postag\">$word_cont</w>\n";
	    }else{
		# there was a term
#		print STDERR "Searchterm : $searchterm\n";
#		print STDERR "word_np : $word_np\n";
		$sentences_cont.="<term c=\"$postag\" parse_as=\"$word_cont.n\" internal=\"\" head=\"0\">\n";
		# insert all the words that make up this term
		my $nbsteps=$decal+$tmp_sp;
		if($nbsteps==$decal){
		    $nbsteps++;
		}
		push @tab_start_term,$decal;
		push @tab_end_term,($nbsteps-1);
		for($spi=$decal;$spi<$nbsteps;$spi++){
		    $sentences_cont.="<w c=\"NN\">".$Alvis::NLPPlatform::hash_words{"word$spi"}."</w>\n";
#		    print STDERR "Adding ".$Alvis::NLPPlatform::hash_words{"word$spi"}."\n";
		}
		##
		$sentences_cont.="</term>\n";
	    }
	}

	$decal++;

    }

    # fill words tab
    foreach $word(Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_words)){
	push @tab_word,$Alvis::NLPPlatform::hash_words{$word};
    }

    # pre-compute mapping between words+punct and words
    my $idx_nopunct=1;
    for($i=0;$i<scalar @tab_word_punct;$i++){
	if(($idx_nopunct<scalar @tab_word)&&($tab_word_punct[$i] eq $tab_word[$idx_nopunct])){
	    $tab_mapping[$i]=$idx_nopunct;
	    $idx_nopunct++;
	}
    }
#     for($i=0;$i<scalar @tab_mapping;$i++){
# 	print STDERR "$i : " . $tab_mapping[$i] . "\n";
#     }

    # remove whitespaces in NE
    my $ne;
    my $ne_cont;
    my $ne_mod;
    foreach $ne(keys %Alvis::NLPPlatform::hash_named_entities){
	$ne_cont=$Alvis::NLPPlatform::hash_named_entities{$ne};
	$ne_mod=$ne_cont;
	if($ne_cont=~/ /){
	    if($sentences_cont=~/\Q$ne_cont\E/){
		$ne_mod=~s/ /\_/g;
		$sentences_cont=~s/\Q$ne_cont\E/$ne_mod/g;
	    }
	}
    }

    $sentences_cont=~s/<sentence>\n$//sgo;

    if ($sentences_cont !~ /<\sentence>\n/) {
	# to remove after checking the wrapper (above)
	    $sentences_cont.="</sentence>\n";
    }

    $sentences_cont .= "\n\n</sentences>\n";

    # Setting options

    $sentences_cont = "<command string=\"constituents=2\">\n" . $sentences_cont;
    $sentences_cont .= "</command>";
    $sentences_cont = "<command string=\"graphics\">\n" . $sentences_cont;
    $sentences_cont .= "</command>";
#    $sentences_cont = "<command string=\"timeout=60\">\n" . $sentences_cont;
#     $sentences_cont .= "</command>";
    $sentences_cont = "<command string=\"postscript\">\n" . $sentences_cont;
    $sentences_cont .= "</command>";
#      $sentences_cont = "<command string=\"null\">\n" . $sentences_cont;
#      $sentences_cont .= "</command>";
#     $sentences_cont = "<command string=\"ask\">\n" . $sentences_cont;
#     $sentences_cont .= "</command>";
#     $sentences_cont = "<command string=\"walls\">\n" . $sentences_cont;
#     $sentences_cont .= "</command>";
#     $sentences_cont = "<command string=\"union\">\n" . $sentences_cont;
#     $sentences_cont .= "</command>";

    open CORPUS, ">" . $h_config->{"TMPFILE"} . ".corpus.tmp";

    print CORPUS Encode::encode_utf8($sentences_cont);
#     print CORPUS $sentences_cont;
    close CORPUS;

    my $command_line;
    my $command_line2;
    my $command_line3;
    if($Alvis::NLPPlatform::Annotation::ALVISLANGUAGE eq "FR"){
	# French parser command line
    }else{
	$command_line = $h_config->{'NLP_tools'}->{'SYNTACTIC_ANALYSIS_EN'} . " < " . $h_config->{'TMPFILE'} . ".corpus.tmp > " . $h_config->{'TMPFILE'} . ".result.tmp.1 2>> " . $Alvis::NLPPlatform::ALVISLOGFILE;
 	$command_line2 = $h_config->{'NLP_tools'}->{'SYNTACTIC_ANALYSIS_EN_LP2LP_CLEAN'} . " < " . $h_config->{'TMPFILE'} . ".result.tmp.1 > " . $h_config->{'TMPFILE'} . ".result.tmp.2 2>> " . $Alvis::NLPPlatform::ALVISLOGFILE;

 	$command_line3 = $h_config->{'NLP_tools'}->{'SYNTACTIC_ANALYSIS_EN_LP2LP'} . " " . $h_config->{'TMPFILE'} . ".result.tmp.2 > " . $h_config->{'TMPFILE'} . ".result.tmp 2>> " . $Alvis::NLPPlatform::ALVISLOGFILE;
    }
#        print STDERR "$command_line\n";
    `$command_line`;

	&clean_bioLG($h_config->{'TMPFILE'} . ".result.tmp.1", $h_config->{'TMPFILE'} . ".result.tmp.2");
#       print STDERR "$command_line2\n";
#     `$command_line2`;

#        print STDERR "$command_line3\n";
    `$command_line3`;

#    print STDERR "\n$command_line\n$command_line2\n";
    $Alvis::NLPPlatform::ALVISDEBUG || unlink $h_config->{'TMPFILE'} . ".result.tmp.1";
    $Alvis::NLPPlatform::ALVISDEBUG || unlink $h_config->{'TMPFILE'} . ".result.tmp.2";

    # process syntactic analysis

    $insentence=0;
    $nsentence=0;
    $relation_id=1;

    $constituents="";
    $nb_constituents=0;

    open SYN_RES, "<" . $h_config->{'TMPFILE'}. ".result.tmp";

    open CONSTITUENT_OUTPUT,">" . $Alvis::NLPPlatform::Annotation::document_record_id . ".constituents";

    while($line=<SYN_RES>)
    {
	if (index($line, "[Sentence") == 0) {
	    $parsedconstituent = 0;
	}
	if(index($line,"[(")==0){
	    $insentence=1;
            # XXX
	    $nsentence++;
	    $sentence="";
	    $tokens="";
	    $analyses="";
	    $left_wall=0;
	}
	if(index($line,"[S ")==0){
	    $constituents=$line;
#	    print STDERR "**** FOUND CONSTITUENTS SENDING DECAL $phrase_idx ****\n";
	    if ($parsedconstituent == 0) {
		$nb_constituents++;
		$phrase_idx=parse_constituents($constituents,$phrase_idx,$doc_hash);
	    }
	    $parsedconstituent = 1;
	    $constituents=~s/\[([A-Z]+) /($1 /sgo;
# 	    $constituents=~s/\[([A-Z]+) /<constituent>$1 /sgo;
	    $constituents=~s/[A-Z]+\]/)/sgo;
# 	    $constituents=~s/[A-Z]+\]/<\/constituent>/sgo;
# 	    print CONSTITUENT_OUTPUT $Alvis::NLPPlatform::Annotation::document_record_id . "\t";
	    print CONSTITUENT_OUTPUT "$constituents\n";

#	    print STDERR "**** RECUP $phrase_idx ****\n";
	}
	if($insentence==1){
	    $sentence.=$line;
	}
# 	if(index($line,"diagram")==0){
	if(index($line,"[]")==0){
	    # process the line
	    $sentence=~s/\[Sentence\s+[0-9]+\]//sgo;
	    $sentence=~s/\[Linkage\s+[0-9]+\]//sgo;
	    $sentence=~s/\[\]//sgo;
	    $sentence=~s/\n//sgo;
# 	    $sentence=~s/\[[0-9\s]*\]diagram$//g;
	    if ($sentence=~m/^(.+)\[\[/) {
		$tokens=$1;
	#	print STDERR "\n\n--> $sentence\n\n";
		$analyses = $';
            # '
		# output
		# search left-wall to shift identifiers
		if($tokens =~ /LEFT\-WALL/so){
		    $left_wall=1;
		}else{
		    $left_wall=0;
		}
		
		# search right-wall, simply to ignore it
		if($tokens =~ /RIGHT\-WALL/so){
		    $right_wall=1;
		}else{
		    $right_wall=0;
		}

		# parse tokens
		@arr_tokens=split /\)\(/,$tokens;
		$last_token=(scalar @arr_tokens)-1;
		$arr_tokens[0]=~s/^\[\(//sgo;
		$arr_tokens[$last_token]=~s/\)\]$//sgo;

#	    my $tmpfdsf;
# 	    for($tmpfdsf=0;$tmpfdsf<=$last_token;$tmpfdsf++){
# 		#print STDERR "******\$\$\$\$\$\$****** ($tmpfdsf) $arr_tokens[$tmpfdsf]\n";
# 	    }

		# Parsing
		my $valid_analysis;
		while($analyses=~/(\[[0-9]+\s[0-9]+\s[0-9]+\s[^\]]+\])/sgoc){
		    my $kref=0;
		    $analysis=$1;
		    if($analysis=~m/\[([0-9]+)\s([0-9]+)\s([0-9]+)\s\(([^\]]+)\)\]/sgo){ # m??
			$valid_analysis=1;
		    }else{
			$valid_analysis=0;
		    }
		    $token_start=$1;
		    $token_end=$2;
		    $relation=$4;
		    if(
		       (($left_wall==1)&&(($token_start==0) || ($token_end==0)))
		       ||(($right_wall==1)&&(($token_start==$last_token) || ($token_end==$last_token)))
			|| ($valid_analysis==0)
		       ){
			# ignore any relation with the left or right wall
#		    print STDERR "$relation [$token_start $token_end] ==> ignored\n";
		    }else{
			if($left_wall==0){
			    $token_start++;
			    $token_end++;
			}
			# make sure we're not dealing with punctuation, otherwise just ignore
			my $tmp1=$token_start+$wordidshift;
			my $tmp2=$token_end+$wordidshift;
			my $tmp1_within=0;
			my $tmp2_within=0;
			if(($tmp1 < scalar @tab_mapping) && ($tmp2 < scalar @tab_mapping)){
# 			print STDERR "$tmp1 $tmp2\n";
# 			if (defined($tab_mapping[$tmp1])) { print STDERR $tab_mapping[$tmp1] . "\n";}
# 			if (defined($tab_mapping[$tmp2])) { print STDERR $tab_mapping[$tmp2] . "\n";}
			    if ((defined($tab_mapping[$tmp1])) && (defined($tab_mapping[$tmp2])) && ($tab_mapping[$tmp1] ne "") && ($tab_mapping[$tmp2] ne "")){
				# determine if there is a relation between a word inside a term and another word not inside a term
				my $lft;
				for($lft=0;$lft<scalar @tab_start_term;$lft++){
				    # is head within term?
				    if(
				    ($tab_mapping[$tmp1]>=$tab_start_term[$lft] &&
					$tab_mapping[$tmp1]<=$tab_end_term[$lft])
					){
					$tmp1_within=1;
				    }

				    # is modifier within term?
				    if(
				    ($tab_mapping[$tmp2]>=$tab_start_term[$lft] &&
					$tab_mapping[$tmp2]<=$tab_end_term[$lft])
					){
					$tmp2_within=1;
				    }

				    # rules set here:
				    # relation between two words in a term: W-W relation
				    # relation between two words outside of a term: W-W relation
				    # relation between a word in a term and another word outside this term: W-P relation
				    if(($tmp1_within+$tmp2_within)==1){
					# one of them is in, the other is out
#					print STDERR "\n";
					# find term id
					$kref=$Alvis::NLPPlatform::found_terms_tidx[$lft];
					$kref++; # it's always >0
					last;
				    }
				}
				$doc_hash->{"syntactic_relation$relation_id"}={};
				$doc_hash->{"syntactic_relation$relation_id"}->{'id'}="syntactic_relation$relation_id";
				$doc_hash->{"syntactic_relation$relation_id"}->{'datatype'}="syntactic_relation";
				$doc_hash->{"syntactic_relation$relation_id"}->{'syntactic_relation_type'}="$relation";
				$doc_hash->{"syntactic_relation$relation_id"}->{'refid_head'} = {};
				$doc_hash->{"syntactic_relation$relation_id"}->{'refid_head'}->{'datatype'}="refid_head";
				if(($kref>0)&&($tmp1_within==1)&&($Alvis::NLPPlatform::found_terms_phr[($kref-1)]!=-666)){
				    $doc_hash->{"syntactic_relation$relation_id"}->{'refid_head'}->{"refid_phrase"}="phrase".$Alvis::NLPPlatform::found_terms_phr[($kref-1)];
#				    print STDERR "\n\nSize: ".scalar @Alvis::NLPPlatform::found_terms_phr."\n";
#				    print STDERR "Index: $kref\n\n";
				}else{
				    $doc_hash->{"syntactic_relation$relation_id"}->{'refid_head'}->{"refid_word"}="word".$tab_mapping[($token_start+$wordidshift)];
				}
# 				$doc_hash->{"syntactic_relation$relation_id"}->{'refid_head'}="word".$tab_mapping[($token_start+$wordidshift)];
				$doc_hash->{"syntactic_relation$relation_id"}->{'refid_modifier'} = {};
				$doc_hash->{"syntactic_relation$relation_id"}->{'refid_modifier'}->{'datatype'}="refid_modifier";
				if(($kref>0)&&($tmp2_within==1)&&($Alvis::NLPPlatform::found_terms_phr[($kref-1)]!=-666)){
				    $doc_hash->{"syntactic_relation$relation_id"}->{'refid_modifier'}->{"refid_phrase"}="phrase".$Alvis::NLPPlatform::found_terms_phr[($kref-1)];
#				    print STDERR "\n\nIndex: $kref\n\n";
				}else{
				    $doc_hash->{"syntactic_relation$relation_id"}->{'refid_modifier'}->{"refid_word"}="word".$tab_mapping[($token_end+$wordidshift)];
				}
# 				$doc_hash->{"syntactic_relation$relation_id"}->{'refid_modifier'}="word".$tab_mapping[($token_end+$wordidshift)];
				
				$relation_id++;
			    }
			}
		    }
		}
		
		# trash everything and continue the loop

		$insentence=0;
		$wordidshift+=$last_token-1;
	    }
	}
    }
    close CONSTITUENT_OUTPUT;
    close SYN_RES;

#    print STDERR $h_config->{'TMPFILE'}. ".corpus.tmp" . "\n";
    $Alvis::NLPPlatform::ALVISDEBUG || unlink $h_config->{'TMPFILE'}. ".corpus.tmp";
    $Alvis::NLPPlatform::ALVISDEBUG || unlink $h_config->{'TMPFILE'} . ".result.tmp";

    $Alvis::NLPPlatform::nb_relations=$relation_id-1;
    $Alvis::NLPPlatform::Annotation::phrase_idx=$phrase_idx;

    print STDERR "done - Found $Alvis::NLPPlatform::nb_relations relations, $termsfound full terms, $nb_constituents constituents.\n";
    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found Syntactic Relations : " . $Alvis::NLPPlatform::nb_relations;
}


sub clean_bioLG {

    my ($infile, $outfile) = @_;


    my $line = "";
    my $sentence_counter = 0;
    my $linkage_counter = 0;
    
    my @linkage_output;
    
#     my $line_prec = "";

    open INFILE, $infile or die "No such file $infile\n";
    binmode INFILE;
    open OUTFILE, ">$outfile" or die "No such file $outfile\n";
 
    # puts the text on only one line
    do {
	# We first remove the outputting input 
	while((defined  ($line = <INFILE>)) && ($line !~ /^\+\+\+\+Time/o)) {
# 	print $line;
# 	    $line_prec = $line;
	};

	if ((defined $line) && ($line =~ /^\+\+\+\+Time/o)) {
	    $linkage_counter = 0;
	    @linkage_output = ();
	    do {
		#We remove the postscript output until we found constituent part
		while((defined ($line = <INFILE>)) && ($line !~ /^\[/o)) {
		    # nothing 
		}
		# we print the output until we find the next postscript part 
		$linkage_output[$linkage_counter] = $line;
# 	    print $line;
		while((defined ($line = <INFILE>)) && ($line ne "diagram\n")) {
# 		    print STDERR "=> $line\n";
		    $linkage_output[$linkage_counter] .= $line;
# 		print $line;
		}
		# we remove the next postscript part 
		while ((defined ($line =<INFILE>)) && ($line ne "%%EndDocument\n")) {
		    # nothing 
		}
		$line = <INFILE>;
		$linkage_output[$linkage_counter] .= "\n";
		$linkage_counter++;
# 	    print "\n";
		# Next Linkage ?
	    } while((defined ($line = <INFILE>)) && ($line =~ /^%!PS-Adobe/o));
	    # we print the constituent
	    print OUTFILE "[Sentence " . $sentence_counter . "]\n";
	    $sentence_counter++;
	    for($linkage_counter = 0; $linkage_counter < scalar(@linkage_output); $linkage_counter++) {
		print OUTFILE "[Linkage " . $linkage_counter ."]\n";
		print OUTFILE $linkage_output[$linkage_counter];
		print OUTFILE "$line\n";
		
	    }
	    # we remove all it remains
	    while((defined ($line = <INFILE>)) && ($line ne "Press RETURN for the next linkage.\n")) {
		#nothing
	    }
	}

    } while ($line = <INFILE>);

    close INFILE;
    close OUTFILE;

    return 0;

}

sub semantic_feature_tagging
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::semantic_feature_tagging(@arg);

}

sub semantic_relation_tagging
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::semantic_relation_tagging(@arg);

}


sub anaphora_resolution
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::anaphora_resolution(@arg);

}



1;

__END__

=head1 NAME

Alvis::NLPPlatform::UserNLPWRapper - User interface for customizing
the NLP wrappers used to linguistically annotating of XML documents
in Alvis

=head1 SYNOPSIS

use Alvis::NLPPlatform::UserNLPWrapper;

Alvis::NLPPlatform::UserNLPWrappers::tokenize($h_config,$doc_hash);

=head1 DESCRIPTION

This module is a mere interface for allowing the cutomisation of the
NLP Wrappers. Anyone who wants to integrated a new NLP tool has to
overwrite the default wrapper. The aim of this module is to simplify
the development a specific wrapper, its integration and its use in the
platform.


Before developing a new wrapper, it is necessary to copy and modify
this file in a local directory and add this directory to the PERL5LIB
variable.

=head1 METHODS


=head2 tokenize()

    tokenize($h_config, $doc_hash);

This method carries out the tokenisation process of the input
document. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document. See documentation in
C<Alvis::NLPPlatform::NLPWrappers>.  It is not recommended to
overwrite this method.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

The method returns the number of tokens.



=head2 scan_ne()

    scan_ne($h_config, $doc_hash);

This method wraps the Named entity recognition and tagging
step. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document.  It aims at annotating semantic
units with syntactic and semantic types. Each text sequence
corresponding to a named entity will be tagged with a unique tag
corresponding to its semantic value (for example a "gene" type for
gene names, "species" type for species names, etc.). All these text
sequences are also assumed to be equivalent to nouns: the tagger
dynamically produces linguistic units equivalent to words or noun
phrases.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.



=head2 word_segmentation()

    word_segmentation($h_config, $doc_hash);

This method wraps the default word segmentation step.  C<$doc_hash> is
the hashtable containing containing all the annotations of the input
document.  

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.




=head2 sentence_segmentation()

    sentence_segmentation($h_config, $doc_hash);

This method wraps the default sentence segmentation step.
C<$doc_hash> is the hashtable containing containing all the
annotations of the input document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.



=head2 pos_tag()

    pos_tag($h_config, $doc_hash);

The method wraps the Part-of-Speech (POS) tagging.  C<$doc_hash> is
the hashtable containing containing all the annotations of the input
document.  For every input word, the wrapped Part-Of-Speech tagger
outputs its tag.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.



=head2 lemmatization()

    lemmatization($h_config, $doc_hash);

This methods wraps the lemmatizer. C<$doc_hash> is the hashtable
containing containing all the annotations of the input document. For
every input word, the wrapped lemmatizer outputs its lemma i.e. the
canonical form of the word..

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.



=head2 term_tag()

    term_tag($h_config, $doc_hash);

The method wraps the term tagging step of the ALVIS NLP
Platform. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document. This step aims at recognizing terms
in the documents differing from named entities, like I<gene
expression>, I<spore coat cell>.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.


=head2 syntactic_parsing()

    syntactic_parsing($h_config, $doc_hash);

This method wraps the sentence parsing. It aims at exhibiting the
graph of the syntactic dependency relations between the words of the
sentence. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

Here is a example of how to tune the platform according to the
domain. We integrated and wrapped the BioLG parser, specialized for
biology text parsing.




=head2 bio_syntactic_parsing()

    bio_syntactic_parsing($h_config, $doc_hash);

This method wraps the sentence parsing tuned for biology texts. As the
default wrapper (C<syntactic_parsing>), it aims at exhibiting the
graph of the syntactic dependency relations between the words of the
sentence. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document.

C<$h_config> is the reference to the hashtable containing the
variables defined in the configuration file.

We actually integrage a version of the Link Parser tuned for the
biology: BioLG (Sampo Pyysalo, Tapio Salakoski, Sophie Aubin and
Adeline Nazarenko. I<Lexical Adaptation of Link Grammar to the
Biomedical Sublanguage: a Comparative Evaluation of Three
Approaches>. Proceedings of the Second International Symposium on
Semantic Mining in Biomedicine (SMBM 2006). Pages 60-67. Jena,
Germany, 2006).




=head2 semantic_feature_tagging()

    semantic_feature_tagging($h_config, $doc_hash)

The method wraps the semantic typing step, that is the attachment of a
semantic type to the words, terms and named-entities (referred to as
lexical items in the following) in documents according to the
conceptual hierarchies of the ontology of the domain.

C<$doc_hash> is the hashtable containing containing all the
annotations of the input document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.


=head2 semantic_relation_tagging()

    semantic_relation_tagging($h_config, $doc_hash)


This method wraps the semantic relation identification step. These
semantic relation annotations give another level of semantic
representation of the document that makes explicit the role that these
semantic units (usually named-entities and/or terms) play with respect
to each other, pertaining to the ontology of the domain.

C<$doc_hash> is the hashtable containing containing all the
annotations of the input document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.



=head2 anaphora_resolution()

    anaphora_resolution($h_config, $doc_hash)

The methods wraps the anaphora solver. C<$doc_hash> is the hashtable
containing containing all the annotations of the input document. It
aims at identifing and solving the anaphora present in a document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.



# =head1 ENVIRONMENT

=head1 SEE ALSO

Alvis web site: http://www.alvis.info

=head1 AUTHORS

Thierry Hamon <thierry.hamon@lipn.univ-paris13.fr> and Julien Deriviere <julien.deriviere@lipn.univ-paris13.fr>

=head1 LICENSE

Copyright (C) 2005 by Thierry Hamon and Julien Deriviere

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


