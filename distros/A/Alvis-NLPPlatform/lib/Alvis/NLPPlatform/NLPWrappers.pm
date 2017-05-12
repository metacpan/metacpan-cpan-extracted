package Alvis::NLPPlatform::NLPWrappers;

#use diagnostics;
use strict;
use warnings;

use Alvis::NLPPlatform::Annotation;
use Alvis::TermTagger;

#use Encode;
use Encode qw(:fallbacks);;

our $VERSION=$Alvis::NLPPlatform::VERSION;

my @term_list_EN;
my @regex_term_list_EN;

my @term_list_FR;
my @regex_term_list_FR;



sub tokenize
{
###################################################
    my ($class, $h_config, $doc_hash) = @_;
    my $line;
    my @characters;
    my $char;

    my $offset;
    my $current_char;
    my $last_char;
    my $length;
    my $string;
    my $token_id;

    my $section_id = 0;
    
    my $alpha="[A-Za-z\x{C0}-\x{D6}\x{D8}-\x{F6}\x{F8}-\x{FF}]";

    my $num="[0-9]";
    my $sep="[ \\s\\t\\n\\r]";
    
    my $canonical;
    my @lines;

#     my $shift_offset = 0;
#     my $shift_offset_prec = 0;

    my $dtype;

    my $token_id_str;

###################################################


    $offset=0;
    $last_char=0;
    $length=0;
    $string="";
    $token_id=1;


    
    print STDERR "  Tokenizing...           ";
    
    $canonical = $Alvis::NLPPlatform::Annotation::canonicalDocument;
    $canonical = Alvis::NLPPlatform::Canonical::CleanUp($canonical, $h_config->{"XML_INPUT"}->{"PRESERVEWHITESPACE"});

    @lines=split /\n/,$canonical;
#     map {$_ .= "\n"} @lines;

    foreach $line(@lines)
    {
	$line .= "\n";
	# convert SGML into characters
	
	# character spliting
	@characters=split //, $line;

	foreach $char(@characters){
	    
	    # determine the type of the current character
	    $current_char=4; # default type
	    if($char=~/$alpha/o){$current_char=1;# print STDERR "$char : OK\n";
			     }
	    if($char=~/$num/o){$current_char=2;}
	    if($char=~/$sep/o){$current_char=3;}
	    # comparison with last seen character

	    # if it is the same ...
	    if(($current_char==$last_char) && ($current_char!=4)){
		$string=$string . $char;
		$length++;
	    }else{
		if($length>0){
		    #######################################################
		    if($last_char==1){$dtype="alpha";}
		    if($last_char==2){$dtype="num";}
		    if($last_char==3){$dtype="sep";}
		    if($last_char==4){$dtype="symb";}
		    $token_id_str = "token$token_id";
		    $doc_hash->{$token_id_str}={};
		    $doc_hash->{$token_id_str}->{'datatype'}="token";
		    $doc_hash->{$token_id_str}->{'type'}=$dtype;
		    $doc_hash->{$token_id_str}->{'id'}=$token_id_str;
		    $doc_hash->{$token_id_str}->{'from'}=$offset;
		    $doc_hash->{$token_id_str}->{'to'}=$offset+$length-1;

		    while(($section_id < scalar(@Alvis::NLPPlatform::tab_end_sections_byaddr)) && ($Alvis::NLPPlatform::tab_end_sections_byaddr[$section_id]  <= $offset + $length - 1)) {
			push @Alvis::NLPPlatform::tab_end_sections_bytoken, $token_id_str; #"token$token_id";
			$section_id++;
		    }

		    if($last_char==3){
			$string=~s/\n/\\n/go;
			$string=~s/\r/\\r/go;
			$string=~s/\t/\\t/go;
		    }
		    $doc_hash->{$token_id_str}->{"content"}=$string;	
		    $Alvis::NLPPlatform::hash_tokens{$token_id_str}=$string;
		    $token_id++;
		    $offset+=$length;
		    #######################################################
		}
		$length=1;
		$string=$char;
		$last_char=$current_char;
	    }
	}
    }

###################################################
    if ($#lines > -1) {
	if($last_char==1){$dtype="alpha";}
	if($last_char==2){$dtype="num";}
	if($last_char==3){$dtype="sep";}
	if($last_char==4){$dtype="symb";}
	$token_id_str = "token$token_id";
	while(($section_id < scalar(@Alvis::NLPPlatform::tab_end_sections_byaddr))) {# && ($Alvis::NLPPlatform::tab_end_sections_byaddr[$section_id] <= $offset + $length - 1)) {
	    push @Alvis::NLPPlatform::tab_end_sections_bytoken, $token_id_str;
	    $section_id++;
	}
	$doc_hash->{$token_id_str}={};
	$doc_hash->{$token_id_str}->{"datatype"}="token";
	$doc_hash->{$token_id_str}->{"type"}=$dtype;
	$doc_hash->{$token_id_str}->{"id"}=$token_id_str;
	$doc_hash->{$token_id_str}->{"from"}=$offset;
	$doc_hash->{$token_id_str}->{"to"}=$offset+$length-1;

	if($last_char==3){
	    $string=~s/\n/\\n/go;
	    $string=~s/\r/\\r/go;
	    $string=~s/\t/\\t/go;
	}
	$doc_hash->{$token_id_str}->{"content"}=$string;
	$Alvis::NLPPlatform::hash_tokens{$token_id_str}=$string;
	$token_id++;
	$offset+=$length;
###################################################

	$Alvis::NLPPlatform::Annotation::nb_max_tokens=$token_id-1;
    } else {
	$Alvis::NLPPlatform::Annotation::nb_max_tokens=0;
    }
    print STDERR "done - Found " . $Alvis::NLPPlatform::Annotation::nb_max_tokens ." tokens\n";

    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found Tokens : " . $Alvis::NLPPlatform::Annotation::nb_max_tokens;

#     my $ii = 0;
#     foreach my $sec_token (@Alvis::NLPPlatform::tab_end_sections_bytoken) {
# 	print STDERR "section $ii -> $sec_token\n";
# 	$ii++;
#     }

    return($Alvis::NLPPlatform::Annotation::nb_max_tokens);
}


sub scan_ne
{
    my ($class, $h_config, $doc_hash) = @_;

    my $corpus;
    my $token;
    my $line;
    my $id;
    my $tok_ct;

    my @tab_tokens; # experimental
    my $t; # experimental


    my $NE_type;
    my $NE_start;
    my $NE_end;

    my $offset=0;
    my $i;
    my $en=0;
    my $j;
    my $start;
    my $end;
    my $ref_tab;
    my $refid_n;

    my $en_cont;
    my $number_of_tokens;
    my $last_en;

    my $corpus_filename;
    my $result_filename;

    print STDERR "  Named entites tagging...     ";
    
    $corpus="";

    foreach $token(Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_tokens)){
	$tok_ct=$Alvis::NLPPlatform::hash_tokens{$token}; # why not $token ? (TH)
	Alvis::NLPPlatform::XMLEntities::decode($tok_ct);

	# (TH) those replacements are required to workaround a bug in
	# tagen (Named entity following a \n is not analyse - because
	# n is concatenate with the next word)

	$tok_ct=~s/\\n/\\n /go;
	$tok_ct=~s/\\r/\\r /go;
	$tok_ct=~s/\\t/\\t /go;
	$corpus.=$tok_ct;
	push @tab_tokens,$tok_ct;
    }

    $corpus_filename = $h_config->{'TMPFILE'} . ".corpus_en.txt";
    
    open CORPUS,">$corpus_filename";
#     binmode(CORPUS,":utf8");


    print CORPUS Encode::encode_utf8($corpus);
    close CORPUS;

    print STDERR "done\n";
    
    my $command_line;
    if($Alvis::NLPPlatform::Annotation::ALVISLANGUAGE eq "FR"){
	$command_line = $h_config->{'NLP_tools'}->{'NETAG_FR'} . " $corpus_filename 2>> " . $Alvis::NLPPlatform::ALVISLOGFILE;
    } else {
	$command_line = $h_config->{'NLP_tools'}->{'NETAG_EN'} . " $corpus_filename 2>> " . $Alvis::NLPPlatform::ALVISLOGFILE;
    }
    # nice idea, though TagEN seems to return 0 anyhow...
    #`$command_line` && print STDERR "FAILED TO EXECUTE \"$command_line\": &!\n";
    `$command_line`;
    $Alvis::NLPPlatform::ALVISDEBUG || unlink $corpus_filename;
    @Alvis::NLPPlatform::en_start=();
    @Alvis::NLPPlatform::en_end=();
    @Alvis::NLPPlatform::en_type=();

    $result_filename = $h_config->{'TMPFILE'} . ".corpus_en.tag.txt";

    open REN,"<$result_filename"  or warn "Can't open the file $result_filename";
    binmode REN;
    while($line=<REN>){
	($NE_type, $NE_start, $NE_end) = split /\t/, $line;
# 	$line=~m/(.+)\s+([0-9]+)\s+([0-9]+)/;
# 	$NE_type = $1;
# 	$NE_start = $2;
# 	$NE_end = $3;
	push @Alvis::NLPPlatform::en_type,$NE_type;
	if ((exists($h_config->{'XML_INPUT'}->{"PRESERVEWHITESPACE"})) && ($h_config->{'XML_INPUT'}->{"PRESERVEWHITESPACE"})) {
	    push @Alvis::NLPPlatform::en_start,($NE_start-1);
	    push @Alvis::NLPPlatform::en_end,($NE_end-1);
	} else {
	    push @Alvis::NLPPlatform::en_start,$NE_start;
	    push @Alvis::NLPPlatform::en_end,$NE_end;
	}
    }
    close REN;

    $Alvis::NLPPlatform::ALVISDEBUG || unlink $result_filename;

#    print STDERR scalar(@Alvis::NLPPlatform::en_type) . " to find\n";

    print STDERR "  Matching EN with tokens...   ";

    # scan tokens and match with NE

    @Alvis::NLPPlatform::en_tokens_start=();
    @Alvis::NLPPlatform::en_tokens_end=();
    %Alvis::NLPPlatform::en_tokens_hash=();
    $number_of_tokens=scalar @tab_tokens;

    $en=$Alvis::NLPPlatform::last_semantic_unit+1;
    $last_en=0;

    my $en_str = "";
    for($t=0;$t<$number_of_tokens;$t++){
	print STDERR "\r  Matching EN with tokens...   ".($t+1)."/".$number_of_tokens." ";
	for($i=$last_en;$i<scalar @Alvis::NLPPlatform::en_start;$i++){
# 	    print STDERR "\ti = $i :: last_en = $last_en\n";
	    if($Alvis::NLPPlatform::en_start[$i]==$offset){
# 		print STDERR "Found\n";
		$last_en=$i;
		$Alvis::NLPPlatform::en_tokens_start[$en]="token".($t+1);
		$Alvis::NLPPlatform::en_tokens_hash{($t+1)}=$en;
		$start=$t+1;
		while($Alvis::NLPPlatform::en_end[$i]>$offset-1){
		    $Alvis::NLPPlatform::en_tokens_end[$en]="token".($t+1);
		    $end=$t+1;
		    $offset+=length($tab_tokens[$t]);
		    $t++;
		}
		$en_str = "semantic_unit$en";
		
		$doc_hash->{$en_str}={};
		$doc_hash->{$en_str}->{"datatype"}="semantic_unit";
		$doc_hash->{$en_str}->{"named_entity"}={};
		$doc_hash->{$en_str}->{"named_entity"}->{"datatype"}="named_entity";
		$doc_hash->{$en_str}->{"named_entity"}->{"named_entity_type"}=$Alvis::NLPPlatform::en_type[$i];
		$doc_hash->{$en_str}->{"named_entity"}->{"id"}="named_entity$en";

		$ref_tab=$doc_hash->{$en_str}->{"named_entity"}->{"list_refid_token"}={};
		$ref_tab->{'datatype'}="list_refid_token";
		$en_cont="";
		$refid_n=1;
		my @tab_tokens_en;
		$ref_tab->{"refid_token"}=\@tab_tokens_en;
		for($j=$start;$j<=$end;$j++){
		    push @tab_tokens_en, "token$j";
		    $refid_n++;
		    $en_cont.=$Alvis::NLPPlatform::hash_tokens{"token$j"};
		}
		$doc_hash->{$en_str}->{"named_entity"}->{"form"}=$en_cont;

		$Alvis::NLPPlatform::hash_named_entities{$en_str}=$en_cont;

		$en++;
		last; # go out the Named Entity hash table scan
	    }
	}
	$offset+=length($tab_tokens[$t]);
    }
    $Alvis::NLPPlatform::last_semantic_unit=$en ;
    print STDERR "done - Found ". ($Alvis::NLPPlatform::last_semantic_unit - 1) ." named entities\n";
    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found Named Entities : " . ($Alvis::NLPPlatform::last_semantic_unit - 1);
}


sub word_segmentation
{
    my ($class, $h_config, $doc_hash) = @_;
    my $token;
    my $id;
    my $nb_doc;
    my $command_line;

    my $proposedword;
    my $current_word = "";
    my $token_id;
    my $word_id;
    my $ref_tab;
    my $elision;
    my $i;

    my $is_en;
    my $en_id;
    my $token_end;
    my $token_start;
    my $append;
    my $refid_n;

    my $token_tmp;

    my $corpus_filename;
    my $result_filename;

    my $token_id_str;
    my $word_id_str;

####
    print STDERR "  Word segmentation...    ";
    my $content;
#     open CORPUS,">:utf8",$h_config->{'TMPFILE'} . ".corpus.tmp";

    $corpus_filename = $h_config->{'TMPFILE'} . ".corpus_word.tmp";
    $result_filename = $h_config->{'TMPFILE'} . ".words.tmp";

    open CORPUS,">$corpus_filename";
#    binmode(CORPUS);
#     binmode(CORPUS, ":utf8");
    foreach $token(Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_tokens)){
	$content=$Alvis::NLPPlatform::hash_tokens{$token};
	$content=~s/\\n/\n/og;
	$content=~s/\\t/\t/og;
	$content=~s/\\r/\r/og;
	#Encode::decode_utf8("Å“")
#	$content =~ s/\x{65}/oe/g;

	Alvis::NLPPlatform::XMLEntities::decode($content);
#  	Encode::from_to($content, "utf8", "iso-8859-1");
  	print CORPUS Encode::encode("iso-8859-1", $content, Encode::FB_DEFAULT);
#	print CORPUS $content;
    }
    close CORPUS;

    if($Alvis::NLPPlatform::Annotation::ALVISLANGUAGE eq "FR"){
	$command_line = $h_config->{"NLP_tools"}->{'WORDSEG_FR'} . " < $corpus_filename > $result_filename 2>> " . $Alvis::NLPPlatform::ALVISLOGFILE;
    }else{
	$command_line = $h_config->{"NLP_tools"}->{'WORDSEG_EN'} . " < $corpus_filename > $result_filename 2>> ". $Alvis::NLPPlatform::ALVISLOGFILE;
    }

    `$command_line`;
    
    open(MOTS, $result_filename) or warn "Can't open the file $result_filename";;
#    binmode(MOTS,":utf8");
     binmode(MOTS);
    
    $token_id=1;
    $word_id=1;
    
    $token_id_str = "token$token_id";
    while($proposedword=<MOTS>)
    {
#	$proposedword = Encode::encode_utf8($proposedword);
	$word_id_str = "word$word_id";
#	if ($proposedword !~ /^[\s ]*\n$/o) {
	if ($proposedword !~ /^[\s\x{A0}]*\n$/o) {
	    chomp $proposedword;

#	    print STDERR $proposedword;
	    $current_word="";
	    $doc_hash->{$word_id_str}={};
	    $doc_hash->{$word_id_str}->{'id'}=$word_id_str;
	    $doc_hash->{$word_id_str}->{'datatype'}='word';
	    $ref_tab=$doc_hash->{$word_id_str}->{'list_refid_token'}={};
	    $ref_tab->{'datatype'}="list_refid_token";
	    my @tab_tokens;
	    $refid_n=1;
	    $ref_tab->{"refid_token"}=\@tab_tokens;

	    $is_en=0;
	    while(length($current_word)<length($proposedword)){
		if($token_id>$Alvis::NLPPlatform::Annotation::nb_max_tokens){
		    $Alvis::NLPPlatform::dont_annotate=1;
		    return;
		}
		if($doc_hash->{$token_id_str}->{'type'} ne "sep"){
		    if(exists $Alvis::NLPPlatform::en_tokens_hash{$token_id}){
			$en_id=$Alvis::NLPPlatform::en_tokens_hash{$token_id};
			$is_en=1;
		    }

		    $token_tmp=$Alvis::NLPPlatform::hash_tokens{$token_id_str};
		    ################################
		    $token_tmp=~s/\\n/\n/og;
		    $token_tmp=~s/\\t/\t/og;
		    $token_tmp=~s/\\r/\r/og;
		    Alvis::NLPPlatform::XMLEntities::decode($token_tmp);
		    ################################

		    $token_tmp=~s/\s+/ /og;
		    $current_word=$current_word.$token_tmp;
		    push @tab_tokens, $token_id_str;
		    if($refid_n==1){
			$Alvis::NLPPlatform::word_start[$word_id]=$token_id;
		    }
		    $Alvis::NLPPlatform::word_end[$word_id]=$token_id;
		    $refid_n++;
		}
		$token_id++;
		$token_id_str = "token$token_id";
	    }
	    #### is the rebuilt word a named entity ? is it fully built
	    my $append;
	    if($is_en){
		$Alvis::NLPPlatform::en_tokens_start[$en_id] =~ m/^token([0-9]+)/io;
		$token_start=$1;

		$Alvis::NLPPlatform::en_tokens_end[$en_id] =~ m/^token([0-9]+)/io;
		$token_end=$1;

		while($token_end>($token_id-1)){
		    $token_tmp=$Alvis::NLPPlatform::hash_tokens{$token_id_str};
		    ################################
		    $token_tmp=~s/\\n/\n/og;
		    $token_tmp=~s/\\t/\t/og;
		    $token_tmp=~s/\\r/\r/og;
		    Alvis::NLPPlatform::XMLEntities::decode($token_tmp);
		    ################################
		    $token_tmp=~s/\s+/ /og;
		    $current_word=$current_word.$token_tmp;

		    ########################################################
		    # TO BE CHECK!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! (still necessary ?)
		    if(length($current_word)>length($proposedword)){
			$append=<MOTS>;
			chomp $append;
			if($doc_hash->{$token_id_str}->{'type'} eq "sep"){
			    $append=" ".$append;
			}
			$proposedword.=$append;
		    }
		    ########################################################

		    push @tab_tokens, $token_id_str;
		    $Alvis::NLPPlatform::word_end[$word_id]=$token_id; # Added by thierry (10/02/2006)
		    $refid_n++;
		    $token_id++;
		    $token_id_str = "token$token_id";
		}
		########################################################################
		# Chech if the rebuilt word is not too short
		while(length($current_word)<length($proposedword)){
		    if($doc_hash->{$token_id_str}->{'type'} ne "sep"){
			$token_tmp=$Alvis::NLPPlatform::hash_tokens{$token_id_str};
			################################
			$token_tmp=~s/\\n/\n/go;
			$token_tmp=~s/\\t/\t/go;
			$token_tmp=~s/\\r/\r/go;
			Alvis::NLPPlatform::XMLEntities::decode($token_tmp);
			################################
			$token_tmp=~s/\s+/ /og;
			$current_word=$current_word.$token_tmp;
			push @tab_tokens, $token_id_str;
			$Alvis::NLPPlatform::word_end[$word_id]=$token_id;
			$refid_n++;
		    }
		    $token_id++;
		    $token_id_str = "token$token_id";
		}
		########################################################################""
	    }

	    #### the rebuilt word is too long... elision?
	    my $mempos;
	    if(length($current_word)>length($proposedword)){
		# read the next word
		$mempos=tell(MOTS);
		$elision=<MOTS>;
		chomp $elision;
		if($elision=~/(\'s|\'d|\'m|\'ll|\'re|\'ve|\'t)/io){
		    # Elision (english)
		    # Solution: going on the loop
		    $proposedword=$proposedword.$elision;
		}else{
		    # not a elision: going back (backtracking)
		    seek(MOTS,$mempos,0);
		}
	    }
	    ####

	    #### the rebuilt word is too short... it is not an elision
	    if (length($current_word)<length($proposedword)){
		if(index($proposedword,$current_word)==0){
		    # Tokens are missing
		    while(length($current_word)<length($proposedword)){    
			if($doc_hash->{$token_id_str}->{'type'} ne "sep"){
			    $token_tmp=$Alvis::NLPPlatform::hash_tokens{$token_id_str};
			    ################################
			    $token_tmp=~s/\\n/\n/og;
			    $token_tmp=~s/\\t/\t/og;
			    $token_tmp=~s/\\r/\r/og;
			    Alvis::NLPPlatform::XMLEntities::decode($token_tmp);
			    ################################
			    $token_tmp=~s/\s+/ /og;
			    $current_word=$current_word.$token_tmp;
			    push @tab_tokens, $token_id_str;
			    $Alvis::NLPPlatform::word_end[$word_id]=$token_id;
			    $refid_n++;
			}
			$token_id++;
		    $token_id_str = "token$token_id";
		    }
		}
	    }

	    $doc_hash->{$word_id_str}->{'form'}="$current_word";

	    if(length($current_word)!=length($proposedword)){
		print STDERR "**** Alignment error between '$current_word'(re-built word) and '$proposedword'(proposed by segmenter) ****\n";
		print STDERR "Length($current_word)=".length($current_word)."\n";
		print STDERR "Length($proposedword)=".length($proposedword)."\n";
		print STDERR "**** PROCESSING ABORTED ****\n";
		push @Alvis::NLPPlatform::tab_errors,"Word segmentation: alignment error\n";
		push @Alvis::NLPPlatform::tab_errors,"Re-built '$current_word' not aligned with '$proposedword' proposed by used segmenter\n";
		push @Alvis::NLPPlatform::tab_errors,"Respective lengths:".length($current_word)." and ".length($proposedword)."\n";
		push @Alvis::NLPPlatform::tab_errors,"* Processing aborted *\n";
		push @Alvis::NLPPlatform::tab_errors,"\n";
		last;
	    }

	    #####
	    ## Remove punctuation
	    if(($doc_hash->{"token".($token_id-1)}->{'type'} eq "symb") && (length($current_word)==1)){
# 		print STDERR $Alvis::NLPPlatform::hash_tokens{"token".($token_id-1)} . "-\n";
# 		print STDERR index(".;:!?",$Alvis::NLPPlatform::hash_tokens{"token".($token_id-1)}) . "\n";
		## add ... ?
		if(index(".;:!?",$Alvis::NLPPlatform::hash_tokens{"token".($token_id-1)})>-1){
		    # This obviously marks the end of a sentence;
		    # store the "word" ID for sentence segmentation
# 		    print STDERR "We go there\n";
		    $Alvis::NLPPlatform::last_words{"word".($word_id-1)}=($token_id-1); # to be checked carefully - added the 11/05/2007
		}
		delete $doc_hash->{$word_id_str};
		$word_id--;
	    }
	    $word_id++;
	    #####
	}
    }
    close MOTS;
    $Alvis::NLPPlatform::ALVISDEBUG || unlink $corpus_filename;
    $Alvis::NLPPlatform::ALVISDEBUG || unlink $result_filename;

    my $word;
    my $word_punct=1;
    # keys NEED to be sorted here, so we can insert punctuation in the 2ndary word hash table
    foreach $word (Alvis::NLPPlatform::Annotation::sort($doc_hash)){
	if($word=~/^(word[0-9]+)/o){
	    $id=$1;
	    $Alvis::NLPPlatform::hash_words{$id}=$doc_hash->{$id}->{'form'};
	    $Alvis::NLPPlatform::hash_words_punct{"word".$word_punct}=$Alvis::NLPPlatform::hash_words{$id};
#	    $Alvis::NLPPlatform::hash_words_punct2words{"word".$word_punct}=word;
	    $word_punct++;
	    if(exists($Alvis::NLPPlatform::last_words{$id})){

		$Alvis::NLPPlatform::hash_words_punct{"word".$word_punct}=$Alvis::NLPPlatform::hash_tokens{"token". $Alvis::NLPPlatform::last_words{$id}};
		$word_punct++;
	    }
	}
    }
    $Alvis::NLPPlatform::last_words{"word" . ($word_id - 1)} = $token_id; # $Alvis::NLPPlatform::Annotation::nb_max_tokens
    $Alvis::NLPPlatform::number_of_words=$word_id-1;
    print STDERR "done - Found ".$Alvis::NLPPlatform::number_of_words ." words\n";
    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found Words: $Alvis::NLPPlatform::number_of_words";
}


sub sentence_segmentation
{
    my ($class, $h_config, $doc_hash) = @_;
    my $word;
    my $sentence_id=1;
    my $min;
    my $max;

    my $btw_start;
    my $btw_end;
    my $i;
    my $token;
    my $sentence;
    my $sentence_cont="";

    my $current_section_id = 0;

    my $start_token=$Alvis::NLPPlatform::word_start[1];

    my $word_index;

    my $next_wordtoken;
    my $current_wordtoken;

    my $sentence_id_str;

    print STDERR "  Sentence segmentation...";

     foreach $word (Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_words)){

	# get starting and ending tokens for the word
	$min=$Alvis::NLPPlatform::word_start[Alvis::NLPPlatform::Annotation::read_key_id($word)];
	$max=$Alvis::NLPPlatform::word_end[Alvis::NLPPlatform::Annotation::read_key_id($word)];
	for($i=$min;$i<=$max;$i++){
	    $token = $Alvis::NLPPlatform::hash_tokens{"token$i"};
	    $sentence_cont .= $token;
	}

	# insert tokens between the current word and the next (spaces, punctuation, ...)
	$btw_start=$max+1;
	if(Alvis::NLPPlatform::Annotation::read_key_id($word)+1 > $Alvis::NLPPlatform::number_of_words){
	    # We've reached the end of the document
	    $btw_end=$Alvis::NLPPlatform::Annotation::nb_max_tokens;
	}else{
	    $btw_end=$Alvis::NLPPlatform::word_start[Alvis::NLPPlatform::Annotation::read_key_id($word)+1]-1;

	    # we check where is the punctuation mark between the kast
	    # word of the current sentence and the first word of the
	    # next sentence.

	    $next_wordtoken = $Alvis::NLPPlatform::word_start[Alvis::NLPPlatform::Annotation::read_key_id($word)+1];
	    $current_wordtoken = $Alvis::NLPPlatform::word_end[Alvis::NLPPlatform::Annotation::read_key_id($word)];


	    $btw_end=$current_wordtoken + 1;
	    ## add "..." ?

	    while (($btw_end < $next_wordtoken) &&  (index(".;:!?",$Alvis::NLPPlatform::hash_tokens{"token$btw_end"})==-1) &&
		   (($Alvis::NLPPlatform::tab_end_sections_bytoken[$current_section_id] ne "token$btw_end"))){
		$btw_end++;
	    }
	}

# 	print STDERR "==\n";
#  	print STDERR $Alvis::NLPPlatform::hash_tokens{"token".$btw_start} . "\n";
# 	print STDERR $Alvis::NLPPlatform::hash_tokens{"token".$btw_end} . "\n";

	# we add tokens between last word and boundary (next word or end of section)
	for($i=$btw_start;$i<$btw_end;$i++){
	    $token = $Alvis::NLPPlatform::hash_tokens{"token".$i};
	    $sentence_cont .= $token;
	}
	# if the current word is the last word of the sentence,
	# then create an entry in the hash

# 	    print STDERR "$sentence_cont\n";

	if ( ($Alvis::NLPPlatform::tab_end_sections_bytoken[$current_section_id] eq "token$btw_end")
             || (exists($Alvis::NLPPlatform::last_words{$word}))
             || (Alvis::NLPPlatform::Annotation::read_key_id($Alvis::NLPPlatform::tab_end_sections_bytoken[$current_section_id]) <= $Alvis::NLPPlatform::word_start[Alvis::NLPPlatform::Annotation::read_key_id($word)+1])) {
	    $sentence_id_str = "sentence$sentence_id";
	    $doc_hash->{$sentence_id_str}={};
	    $doc_hash->{$sentence_id_str}->{'id'}=$sentence_id_str;
	    $doc_hash->{$sentence_id_str}->{'datatype'}='sentence';
	    $doc_hash->{$sentence_id_str}->{'refid_start_token'}="token$start_token";
	    $doc_hash->{$sentence_id_str}->{'refid_end_token'}="token$btw_end";
	    $sentence_cont .= $Alvis::NLPPlatform::hash_tokens{"token$btw_end"};
	    $sentence_cont =~s /\\n/\n/go;
	    $sentence_cont =~s /\\r/\r/go;
	    $sentence_cont =~s /\\t/\t/go;
	    $doc_hash->{"sentence$sentence_id"}->{'form'}="$sentence_cont" ;# . $Alvis::NLPPlatform::hash_tokens{"token".$btw_end}; # ($current_section_id)";

	    $sentence_id++;
	    $sentence_cont="";

	    # determining the beginning the next sentence
	    if($btw_end != $Alvis::NLPPlatform::Annotation::nb_max_tokens){
		if (Alvis::NLPPlatform::Annotation::read_key_id($Alvis::NLPPlatform::tab_end_sections_bytoken[$current_section_id]) >=
		    $Alvis::NLPPlatform::word_start[Alvis::NLPPlatform::Annotation::read_key_id($word)+1]) {
                    ### To check some token can start the sentence !
		    $start_token=$Alvis::NLPPlatform::word_start[Alvis::NLPPlatform::Annotation::read_key_id($word)+1];
		} else {
		# "while" because we can have sections without sentences !
		while (Alvis::NLPPlatform::Annotation::read_key_id($Alvis::NLPPlatform::tab_end_sections_bytoken[$current_section_id]) < 
		    $Alvis::NLPPlatform::word_start[Alvis::NLPPlatform::Annotation::read_key_id($word)+1]) {
		    $start_token=Alvis::NLPPlatform::Annotation::read_key_id($Alvis::NLPPlatform::tab_end_sections_bytoken[$current_section_id]) + 1;
		    $current_section_id++;
# 		    print STDERR "==> $current_section_id ($word / $start_token / $btw_end)\n";
		} 
	    }
		# making the beginning of the new sentence
		$i=$btw_end + 1;
		    while ($doc_hash->{"token".$i}->{'type'} eq "sep") {$i++;}

		for(;$i < $next_wordtoken;$i++){
		    $token = $Alvis::NLPPlatform::hash_tokens{"token".$i};
		    $sentence_cont .= $token;
		}
		
	    }

	}
    }

    # create an entry for the last sentence, only if it isn't empty
    # (when the last sentence does not contain any ending punctuation)

    if((defined $btw_end) && ($btw_end!=$Alvis::NLPPlatform::Annotation::nb_max_tokens)) {
	$sentence_id_str = "sentence$sentence_id";
	$doc_hash->{$sentence_id_str}={};
	$doc_hash->{$sentence_id_str}->{'id'}=$sentence_id_str;
	$doc_hash->{$sentence_id_str}->{'datatype'}='sentence';
	$doc_hash->{$sentence_id_str}->{'refid_start_token'}="token$start_token";
	$doc_hash->{$sentence_id_str}->{'refid_end_token'}="token$btw_end";
	$sentence_cont =~s /\\n/\n/go;
	$sentence_cont =~s /\\r/\r/go;
	$sentence_cont =~s /\\t/\t/go;
	$doc_hash->{$sentence_id_str}->{'form'}=$sentence_cont;
	$sentence_cont="";
    }

    foreach $sentence(keys %$doc_hash){
	if($sentence=~/^(sentence[0-9]+)/o){
	    $Alvis::NLPPlatform::hash_sentences{$1}=$doc_hash->{$1}->{'form'};
	}
    }
    $Alvis::NLPPlatform::number_of_sentences=$sentence_id-1;
    print STDERR "done - Found ".$Alvis::NLPPlatform::number_of_sentences." sentences\n";
    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found Sentences: $Alvis::NLPPlatform::number_of_sentences";
}



sub pos_tag 
{
    my ($class, $h_config, $doc_hash) = @_;
    my $word;
    my $cont;
    my $i;
    my $line;
    my $word_id = 0;
    my $tag;
    my $lemma;
    my %hash_validtags_en;
    my %hash_validtags_fr;
    my $inflected;

    my $corpus_filename;
    my $result_filename;

    my $morphosyntactic_features_id;
    my $lemma_id;
    my $word_id_str;
    my $word_punct_id_str;

    my @words;

    $corpus_filename = $h_config->{'TMPFILE'} . ".corpus_pos.tmp";
    $result_filename = $h_config->{'TMPFILE'} . ".tags.tmp";

    print STDERR "  Part-Of-Speech tagging..";
    open CORPUS,">$corpus_filename";
#      binmode(CORPUS,":encoding(latin1)");
    # TH - 16/07/2007 - replacement of hash_words by hash_words_punct

    my $fullcontent = "";
    foreach $word (Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_words_punct)){
	$cont=$Alvis::NLPPlatform::hash_words_punct{$word};
  	$fullcontent .= Encode::encode("iso-8859-1", $cont, Encode::FB_DEFAULT);
  	$fullcontent .= "\n";
#   	Encode::from_to($cont, "utf8", "iso-8859-1");
# 	$fullcontent .= "$cont\n";
    }
    print CORPUS $fullcontent;
    close CORPUS;

    my $command_line;
    if($Alvis::NLPPlatform::Annotation::ALVISLANGUAGE eq "FR"){
	$command_line = $h_config->{'NLP_tools'}->{'POSTAG_FR'} . " < $corpus_filename  > $result_filename 2>> " . $Alvis::NLPPlatform::ALVISLOGFILE;
    }else{
	$command_line = $h_config->{'NLP_tools'}->{'POSTAG_EN'} . " < $corpus_filename  > $result_filename 2>> " . $Alvis::NLPPlatform::ALVISLOGFILE;
    }
    `$command_line`;

    open TAGS,"<$result_filename";
    binmode(TAGS); #, ":encoding(latin9)");
    $word_id=0;

    my $decal = 0;
    my $wordecal;
    my $word_punct_id = 1;
    $word_punct_id_str = "word$word_punct_id";  

    while ($line = <TAGS>) {
	# Read $Alvis::NLPPlatform::hash_words_punct{"word$word_punct"}
#	Encode::from_to($line, "iso-8859-9", "utf8");
	$line = Encode::decode("latin9",$line);
	chomp $line;
	($inflected, $tag, $lemma) = split /\t/, $line;

	$word_id = $word_punct_id + $decal;
	$word_id_str = "word$word_id";  

        if ((!exists $Alvis::NLPPlatform::hash_words{$word_id_str}) || ($Alvis::NLPPlatform::hash_words_punct{$word_punct_id_str} ne $Alvis::NLPPlatform::hash_words{$word_id_str})) {
	      # it is not a word
	      # punctuation, delay incrementation of index "decal"
	    $decal--;
	} else { 
	    #######################################################
	    # Correct outputs from treetagger
	    if (!defined $tag) { $tag = "NP"; $lemma = $inflected;}

	    if ((($Alvis::NLPPlatform::Annotation::ALVISLANGUAGE eq "FR") && (!exists($h_config->{"NLP_misc"}->{"POSTAG_LIST"}->{"FR"}->{$tag})))||
                (($Alvis::NLPPlatform::Annotation::ALVISLANGUAGE ne "FR") && (!exists($h_config->{"NLP_misc"}->{"POSTAG_LIST"}->{"EN"}->{$tag})))){
		if ($inflected ne $tag){ # ???
		    $tag="NP";
		}
	    }

	    # in case of named entities, we remove '_' in lemma and inflected form
            # and we force the POS tag to be NP	    
	    if ((index($lemma,"_")>-1)&&(index($inflected,"_")==-1)){
		$lemma=~s/\_/ /og;
		$tag="NP";
	    }
	    
	    # in case of number, lemma is the same as the inflected form
	    if ($lemma eq '@card@'){
		$lemma=$inflected;
	    }
	    #######################################################
	    
	    # POS tag
	    $morphosyntactic_features_id = "morphosyntactic_features$word_id";
	    $doc_hash->{$morphosyntactic_features_id}={};
	    $doc_hash->{$morphosyntactic_features_id}->{'id'}=$morphosyntactic_features_id;
	    $doc_hash->{$morphosyntactic_features_id}->{'datatype'}="morphosyntactic_features";
	    $doc_hash->{$morphosyntactic_features_id}->{'refid_word'}=$word_id_str;
	    $doc_hash->{$morphosyntactic_features_id}->{'syntactic_category'}="$tag";
	    
	    $Alvis::NLPPlatform::hash_postags{$word_id_str}=$tag;
	    
	    # lemma
	    $lemma_id = "lemma$word_id";
	    $doc_hash->{$lemma_id}={};
	    $doc_hash->{$lemma_id}->{'id'}=$lemma_id;
	    $doc_hash->{$lemma_id}->{'datatype'}="lemma";
	    $doc_hash->{$lemma_id}->{'refid_word'}=$word_id_str;
	    $doc_hash->{$lemma_id}->{'canonical_form'}="$lemma";

	    
	    $Alvis::NLPPlatform::hash_lemmas{$word_id_str}=$lemma;
	}
        $word_punct_id++;
	$word_punct_id_str = "word$word_punct_id";  
    }
    close TAGS;

    $Alvis::NLPPlatform::ALVISDEBUG || unlink $corpus_filename;
    $Alvis::NLPPlatform::ALVISDEBUG || unlink $result_filename;

    print STDERR "done - Found " . $word_id ." tags.\n";
    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found POS Tags: " . $word_id ;
}

# sub pos_tag # WRAPPER FOR BRILL
# {
#     my $word;
#     my $cont;

#     print STDERR "   Part-Of-Speech tagging...";
#     open CORPUS,">$TMPFILE.corpus.tmp";
#     binmode(CORPUS,":utf8");
#     foreach $word(sort Alvis::NLPPlatform::Annotation::sort_keys keys %Alvis::NLPPlatform::hash_words){
# 	$cont=$Alvis::NLPPlatform::hash_words{$word};
# 	print CORPUS "$cont ";
# 	if($cont eq "."){
# 	    print CORPUS "\n";
# 	}
#     }
#     close CORPUS;
# }


sub lemmatization
{
    my ($class, $h_config, $doc_hash) = @_;

    # done with the postagging
}


# TODO : Check that term tagging is only performed on english texts

sub term_tag
{
    my ($class, $h_config, $doc_hash) = @_;

    my $cont;
    my $word;
    my $sentence;
    my $i;
    my $s;
    my $line;
    my $tmp;
    my %tabh_sent_terms;
    my $key;
    my $sent;
    my $term_regex;
    my $term;
    my $phrase_idx=1;
    my $canonical_form;
    my %corpus;
    my %lc_corpus;
    my $sent_id;
    my $command_line;
    my %corpus_index;
    my %idtrm_select;
    my @tab_results;
    my $semtag;

    my $token_start;
    my $token_end;
    my $offset_start;
    my $offset_end;
    my $offset;

    my $semantic_unit_id_str;
    my $semantic_feature_id_str;
    my $sf = 1;

    my $token_term;
    my $token_term_end;
    my $j;


    print STDERR "  Term tagging...         ";

    $sent_id = 1;
    foreach $sentence(Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_sentences)){
	$tmp = "$Alvis::NLPPlatform::hash_sentences{$sentence}\n";
 	$tmp=~s/\n/ /go;
	$tmp=~s/\r/ /go;
	$tmp=~s/\t/ /go;
# 	$tmp=~s/\n/\\n/go;
# 	$tmp=~s/\r/\\r/go;
# 	$tmp=~s/\t/\\t/go;
# 	print STDERR "$tmp\n";
	$corpus{$sent_id} = $tmp;
	$lc_corpus{$sent_id} = lc($tmp);
	$sent_id++;
    }



    # Term list loading 

    if($Alvis::NLPPlatform::Annotation::ALVISLANGUAGE eq "FR"){
	if (scalar(@term_list_FR) == 0) {
	    Alvis::TermTagger::load_TermList($h_config->{'NLP_misc'}->{'TERM_LIST_FR'},\@term_list_FR);
	      Alvis::TermTagger::get_Regex_TermList(\@term_list_FR, \@regex_term_list_FR);
	  }
	Alvis::TermTagger::corpus_Indexing(\%lc_corpus, \%corpus_index);
	Alvis::TermTagger::term_Selection(\%corpus_index, \@term_list_FR, \%idtrm_select);
	Alvis::TermTagger::term_tagging_offset_tab(\@term_list_FR, \@regex_term_list_FR, \%idtrm_select, \%corpus, \%tabh_sent_terms);
    } else {
	if (scalar(@term_list_EN) == 0) {
	    Alvis::TermTagger::load_TermList($h_config->{'NLP_misc'}->{'TERM_LIST_EN'},\@term_list_EN);
	      Alvis::TermTagger::get_Regex_TermList(\@term_list_EN, \@regex_term_list_EN);
	  }
	Alvis::TermTagger::corpus_Indexing(\%lc_corpus, \%corpus_index);
	Alvis::TermTagger::term_Selection(\%corpus_index, \@term_list_EN, \%idtrm_select);
	Alvis::TermTagger::term_tagging_offset_tab(\@term_list_EN, \@regex_term_list_EN, \%idtrm_select, \%corpus, \%tabh_sent_terms);
      }
    %lc_corpus = ();
    %corpus_index = ();
    %idtrm_select = ();
    %corpus = ();

# TODO : taking into account the case where terms appear at least twice in a sentence

    $i=0;
    for $key (keys %tabh_sent_terms) {
	$sent = $tabh_sent_terms{$key}->[0];
	$term = $tabh_sent_terms{$key}->[1];
	$term_regex = $term;
 	$term_regex =~ s/ /\[ \n\]+/go;
#  	print STDERR "try to find $term in sentence$sent\n";


        $canonical_form = $tabh_sent_terms{$key}->[2];
        $semtag = $tabh_sent_terms{$key}->[3];

	# look for the term in the sentence, compute the reference to the words
	$token_term = -1;
	$offset = 0;
	while (($offset != -1)&&($token_term == -1)) {
	    if ($Alvis::NLPPlatform::hash_sentences{"sentence$sent"} =~ /$term_regex/igc) { # replace regex by index/subtring ?
		$offset = length($`);
	    } else {
		$offset = -1;
	    }
#  		print STDERR "Found (offset = $offset)\n";
	    if ($offset != -1) {
		$doc_hash->{"sentence$sent"}->{"refid_start_token"}=~m/token([0-9]+)/i;
		$token_start=$1;
		$doc_hash->{"sentence$sent"}->{"refid_end_token"}=~m/token([0-9]+)/i;
		$token_end=$1;
		$offset_start=$doc_hash->{"token$token_start"}->{"from"};
		$offset_end=$doc_hash->{"token$token_end"}->{"to"};

		$offset+=$offset_start;

#  		print STDERR "Search token starting at $offset\n";
		for($j=$token_start;$j<$token_end;$j++){
# 		    print STDERR "Current offset : " . $doc_hash->{"token$j"}->{"from"} . "\n";
		    if($doc_hash->{"token$j"}->{"from"}==$offset){
			$token_term=$j;
			last;
		    }
		}
# 		print STDERR "Token Term start at $token_term\n";
		if ($token_term != -1) {
		    $cont="";
		    my @tab_tokens;
		    for($j=$token_term;length($cont)<length($term);$j++){
			$cont.=$Alvis::NLPPlatform::hash_tokens{"token$j"};
			push @tab_tokens, "token$j";
			$cont =~ s/\\[nrt]/ /go;
		    }
# 		    print STDERR "$cont\n";
		    if (length($cont) == length($term)) {
			$token_term_end=$j-1;
			$Alvis::NLPPlatform::hash_sentences{"sentence$sent"} =~ /^/g;
			
			# Creation of a semantic unit
			$s=$Alvis::NLPPlatform::last_semantic_unit;
			$semantic_unit_id_str = "semantic_unit$s";
			$doc_hash->{$semantic_unit_id_str}={};
			$doc_hash->{$semantic_unit_id_str}->{"datatype"}="semantic_unit";
			$doc_hash->{$semantic_unit_id_str}->{"term"}={};
			$doc_hash->{$semantic_unit_id_str}->{"term"}->{"datatype"}="term";
			$doc_hash->{$semantic_unit_id_str}->{"term"}->{"id"}="term" . (++$i);
			$doc_hash->{$semantic_unit_id_str}->{"term"}->{"form"}=$term;
			push @Alvis::NLPPlatform::found_terms,$term;
			push @Alvis::NLPPlatform::found_terms_smidx,$i;

			if (defined($canonical_form)) {
			    $doc_hash->{$semantic_unit_id_str}->{"term"}->{"canonical_form"}=$canonical_form;
			}
			if (defined($semtag)) {
# 			    print STDERR "Add $semtag for $term\n";
			    $sf=$Alvis::NLPPlatform::last_semantic_feature + 1;
			    $semantic_feature_id_str = "semantic_features$sf";
			    $doc_hash->{$semantic_feature_id_str}={};
 			    $doc_hash->{$semantic_feature_id_str}->{"datatype"}="semantic_features";
 			    $doc_hash->{$semantic_feature_id_str}->{"id"}=$semantic_feature_id_str; #"term" . ($i-1);
 			    $doc_hash->{$semantic_feature_id_str}->{"refid_semantic_unit"}="term$i";
			    $doc_hash->{$semantic_feature_id_str}->{"semantic_category"}={};
			    $doc_hash->{$semantic_feature_id_str}->{"semantic_category"}->{"datatype"}="semantic_category";
			    $doc_hash->{$semantic_feature_id_str}->{"semantic_category"}->{"list_refid_ontology_node"}={};
			    $doc_hash->{$semantic_feature_id_str}->{"semantic_category"}->{"list_refid_ontology_node"}->{"datatype"}="list_refid_ontology_node";
			    my @semtag = split /[\.\/]/, $semtag;
			    $doc_hash->{$semantic_feature_id_str}->{"semantic_category"}->{"list_refid_ontology_node"}->{"refid_ontology_node"} = \@semtag;
			    $Alvis::NLPPlatform::last_semantic_feature++;
			}


			# XXX TO BE OPTIMIZED !!!

			my $k=1;
			my $term_word_start=-1;
			my $term_word_end=-1;
			my @tab_words;
			for($k=1;$k<$Alvis::NLPPlatform::number_of_words;$k++){
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
			# XXX
                        if (scalar @tab_words == 0) {
			    $doc_hash->{$semantic_unit_id_str}->{"term"}->{"list_refid_token"}={};
			    $doc_hash->{$semantic_unit_id_str}->{"term"}->{"list_refid_token"}->{"datatype"} = "list_refid_token";
			    $doc_hash->{$semantic_unit_id_str}->{"term"}->{"list_refid_token"}->{"refid_token"}=\@tab_tokens;
			    
			}
			if(scalar @tab_words==1){
			    $doc_hash->{$semantic_unit_id_str}->{"term"}->{"refid_word"}=\@tab_words;
			}
			if(scalar @tab_words>1){
			    $doc_hash->{"phrase$phrase_idx"}={};
			    $doc_hash->{"phrase$phrase_idx"}->{'id'}="phrase$phrase_idx";
			    $doc_hash->{"phrase$phrase_idx"}->{'datatype'}="phrase";
			    $doc_hash->{"phrase$phrase_idx"}->{'list_refid_components'}={};
			    $doc_hash->{"phrase$phrase_idx"}->{'list_refid_components'}->{"datatype"}="list_refid_components";
			    $doc_hash->{"phrase$phrase_idx"}->{'list_refid_components'}->{"refid_word"}=\@tab_words;

			    $doc_hash->{$semantic_unit_id_str}->{"term"}->{"refid_phrase"}="phrase$phrase_idx";
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

			$Alvis::NLPPlatform::last_semantic_unit++;
		    } else {
			if ($j <$token_end) {
			    $token_term = -1;
			} else {
			    warn "+++ Term content not found ($term -- $cont)\n"; 

			}
		    }
		}
	    }
	}
    }
    $Alvis::NLPPlatform::Annotation::phrase_idx=$phrase_idx;
    print STDERR "done - Found " . ($phrase_idx - 1) . " phrases\n";
    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found Phrases: " . ($phrase_idx - 1);

    $Alvis::NLPPlatform::last_semantic_feature=$sf;
    print STDERR "done - Found " . ($sf - 1) . " semantic features\n";
    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found Semantic Features: " . ($sf - 1);

    print STDERR "done - Found ". ($i) ." terms\n";
    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found Terms: " . $i;
}


# TODO : Check that parsing is only performed on english texts

# TODO TODO : Check this method

sub syntactic_parsing{
    my ($class, $h_config, $doc_hash) = @_;
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
    my $last_token = 1;
    my $wordidshift=0;

    my $corpus_filename;
    my $result_filename;

    my $command_line;

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
    my $inpostscript_output = 0;
    my $ingraphics_output = 0;

    my $syntactic_relation_id;

    $corpus_filename = $h_config->{'TMPFILE'}. ".corpus_syn.tmp";

    print STDERR "  Performing syntactic analysis...";
    open CORPUS,">$corpus_filename";
    print CORPUS "!whitespace\n";
    print CORPUS "!postscript\n";
    print CORPUS "!graphics\n";
    print CORPUS "!union\n";
    print CORPUS "!walls\n";
#    print CORPUS "!width=10000\n";

    # print out words+punct and fill in a tab
    push @tab_word_punct," ";
    push @tab_word," ";

    foreach $word (Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_words_punct)){

	# print word
	$word_cont=$Alvis::NLPPlatform::hash_words_punct{$word};
	push @tab_word_punct,$word_cont;
	if($word_cont eq "."){
	    $sentences_cont.="\n";
	}else{
	    my $word_tmp=$word_cont;
	    $word_tmp=~s/ /\_/g;
	    $sentences_cont.="$word_tmp ";
	}
    }

    # fill words tab
    foreach $word (Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_words)){
	push @tab_word,$Alvis::NLPPlatform::hash_words{$word};
    }

    # pre-compute mapping between words+punct and words
    my $idx_nopunct=1;
    for($i=0;$i<scalar @tab_word_punct;$i++){
	if(($idx_nopunct<scalar @tab_word)&&($tab_word_punct[$i] eq $tab_word[$idx_nopunct])){
#	    print STDERR "$tab_word_punct[$i] => $tab_word[$idx_nopunct] ($i => $idx_nopunct)    $Alvis::NLPPlatform::hash_words{'word'.$idx_nopunct}\n";
	    $tab_mapping[$idx_nopunct]=$idx_nopunct;
	    $idx_nopunct++;
	}
    }

    # remove whitespaces in NE
#     my $ne;
#     my $ne_cont;
#     my $ne_mod;
#     foreach $ne(keys %Alvis::NLPPlatform::hash_named_entities){
# 	$ne_cont=$Alvis::NLPPlatform::hash_named_entities{$ne};
# 	$ne_mod=$ne_cont;
# 	if($ne_cont=~/ /){
# 	    if($sentences_cont=~/$ne_cont/){
# 		print STDERR "Found NE $ne_cont in sentence\n";
# 		$ne_mod=~s/ /\_/g;
# 		$sentences_cont=~s/$ne_cont/$ne_mod/g;
# 	    }
# 	}
#     }
    
    print CORPUS $sentences_cont;
    close CORPUS;

    # generate input for syntactic analyser


    $result_filename = $h_config->{'TMPFILE'} . ".result.tmp";

    if($Alvis::NLPPlatform::Annotation::ALVISLANGUAGE eq "FR"){
	# French parser command line
    }else{
	$command_line = $h_config->{'NLP_tools'}->{'SYNTACTIC_ANALYSIS_EN'} . " < $corpus_filename > $result_filename 2>> " . $Alvis::NLPPlatform::ALVISLOGFILE;
    }
    if (defined $command_line) {

	`$command_line`;

	$Alvis::NLPPlatform::ALVISDEBUG || unlink $corpus_filename;

	# process syntactic analysis

	$insentence=0;
	$nsentence=0;
	$relation_id=1;

	open SYN_RES,"<$result_filename";

	while($line=<SYN_RES>)
	{
#  	print STDERR $line;
	    if(index($line,"[(")==0){
		$insentence=1;
		# XXX
		$nsentence++;
		$sentence="";
		$tokens="";
		$analyses="";
		$left_wall=0;
	    }
	    if($insentence==1){
		$sentence.=$line;
	    }
	    if(index($line,"[]")==0){
		# process the line
		$sentence=~s/\[Sentence\s+[0-9]+\]//sgo;
		$sentence=~s/\[Linkage\s+[0-9]+\]//sgo;
		$sentence=~s/\[\]//sgo;
		$sentence=~s/\n//sgo;
		if ($sentence=~m/^(.+)\[\[/so) {
		    $tokens=$1;
		    $analyses = $';
	    # output'
		    # search left-wall to shift identifiers
		    if($tokens=~/LEFT\-WALL/so){
			$left_wall=1;
		    }else{
			$left_wall=0;
		    }
		    
		    # search right-wall, simply to ignore it
		    if($tokens=~/RIGHT\-WALL/so){
			$right_wall=1;
		    }else{
			$right_wall=0;
		    }

		    # parse tokens
		    @arr_tokens=split /\)\(/,$tokens;
		    $last_token=(scalar @arr_tokens)-1;
		    $arr_tokens[0]=~s/^\[\(//sgo;
		    $arr_tokens[$last_token]=~s/\)\]$//sgo;

		    # Parsing
		    while($analyses=~/(\[[0-9]+\s[0-9]+\s[0-9]+\s[^\]]+\])/sgoc){
			$analysis=$1;
			$analysis=~m/\[([0-9]+)\s([0-9]+)\s([0-9]+)\s\(([^\]]+)\)\]/sgo;
			$token_start=$1;
			$token_end=$2;
			$relation=$4;
			if(
			   (($left_wall==1)&&(($token_start==0) || ($token_end==0)))
			   ||(($right_wall==1)&&(($token_start==$last_token) || ($token_end==$last_token)))
			   ){
			    # ignore any relation with the left or right wall
			}else{
			    if($left_wall==0){
				$token_start++;
				$token_end++;
			    }
			    # make sure we're not dealing with punctuation, otherwise just ignore'
			    if((defined($tab_mapping[$token_start+$wordidshift])) && (defined($tab_mapping[$token_end+$wordidshift]) ne "")){
				$syntactic_relation_id = "syntactic_relation$relation_id";
				$doc_hash->{$syntactic_relation_id}={};
				$doc_hash->{$syntactic_relation_id}->{'id'}=$syntactic_relation_id;
				$doc_hash->{$syntactic_relation_id}->{'datatype'}="syntactic_relation";
				$doc_hash->{$syntactic_relation_id}->{'syntactic_relation_type'}="$relation";
				$doc_hash->{$syntactic_relation_id}->{'refid_head'} = {};
				$doc_hash->{$syntactic_relation_id}->{'refid_head'}->{'datatype'}="refid_head";
				$doc_hash->{$syntactic_relation_id}->{'refid_head'}->{"refid_word"}="word".$tab_mapping[($token_start+$wordidshift)];
				$doc_hash->{$syntactic_relation_id}->{'refid_modifier'} = {};
				$doc_hash->{$syntactic_relation_id}->{'refid_modifier'}->{'datatype'}="refid_modifier";
				$doc_hash->{$syntactic_relation_id}->{'refid_modifier'}->{"refid_word"}="word".$tab_mapping[($token_end+$wordidshift)];
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
	close SYN_RES;

	$Alvis::NLPPlatform::ALVISDEBUG || unlink $h_config->{'TMPFILE'} . ".result.tmp";

	$Alvis::NLPPlatform::nb_relations=$relation_id-1;

	print STDERR "done - Found $Alvis::NLPPlatform::nb_relations relations.\n";
    } else {
	print STDERR "No parser for language $Alvis::NLPPlatform::Annotation::ALVISLANGUAGE - continue to the next step\n";
    }
    
    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found Syntactic Relations : " . $Alvis::NLPPlatform::nb_relations;
}



sub semantic_feature_tagging
{

    my ($class, $h_config, $doc_hash) = @_;

#    &temp_semantic_feature_tagging(@arg);

}

sub temp_semantic_feature_tagging
{
    my ($class, $h_config, $doc_hash) = @_;

    print STDERR "  Semantic tagging...     ";

    my $in_fn = $h_config->{'TMPFILE'} . ".ast.in";

    if($Alvis::NLPPlatform::Annotation::ALVISLANGUAGE eq "FR"){
	# French parser command line
    }else{
	open DOC,">$in_fn";
	binmode(DOC,":utf8");
	Alvis::NLPPlatform::Annotation::render_xml($doc_hash, \*DOC, 1);
	close DOC;
    
	my $cmdline = $h_config->{'NLP_tools'}->{'SEMTAG_EN'} . " $in_fn > " . $h_config->{'TMPFILE'} . ".ast.out 2>> " . $Alvis::NLPPlatform::ALVISLOGFILE;
#  	print STDERR "$cmdline\n";
	
 	`$cmdline`;
	$Alvis::NLPPlatform::ALVISDEBUG || unlink $h_config->{'TMPFILE'} . ".ast.in";
	$Alvis::NLPPlatform::ALVISDEBUG || unlink $h_config->{'TMPFILE'} . ".ast.out";
	# $semtagout == doc XML enriched-document
# 	return $semtagout;

    }
    print STDERR "done\n";
}



sub semantic_relation_tagging
{

    my ($class, $h_config, $doc_hash) = @_;

}


sub anaphora_resolution
{
    my ($class, $h_config, $doc_hash) = @_;


}


1;

__END__

=head1 NAME

Alvis::NLPPlatform::NLPWrapper - Perl extension for the wrappers used
for linguistically annotating XML documents in Alvis

=head1 SYNOPSIS

use Alvis::NLPPlatform::NLPWrappers;

Alvis::NLPPlatform::NLPWrappers::tokenize($h_config,$doc_hash);

=head1 DESCRIPTION

This module provides defaults wrappers of the Natural Language
Processing (NLP) tools. These wrappers are called in the ALVIS NLP
Platform (see C<Alvis::NLPPlatform>).

Default wrappers can be overwritten by defining new wrappers in a new
and local UserNPWrappers module.

=head1 METHODS


=head2 tokenize()

    tokenize($h_config, $doc_hash);

This method carries out the tokenisation process on the input
document. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document. 

The tokenization has been written for ALVIS. This is a task that
depends largely on the choice made as to what tokens are for our
purpose. Hence, this function is not a wrapper but the specific
tokenizing tool itself.  Its input is the plain text corpus, which is
segmented into tokens. Tokens are in fact a group of characters
belonging to the same category. Below is a list of the four possible
categories:

=over 

=item * alphabetic characters (all letters from 'a' to 'z', including accentuated characters)

=item * numeric characters (numbers from '0' to '9')

=item * space characters (carriage return, line feed, space and tab)

=item * symbols: all characters that do not fit in the previous categories

=back


During the tokenization process, all tokens are stored in memory via a
hash table (C<%hash_tokens>).

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

The method returns the number of tokens.




=head2 scan_ne()

    scan_ne($h_config, $doc_hash);

This method wraps the default Named entity recognition and tags the
input document. C<$doc_hash> is the hashtable containing containing
all the annotations of the input document.  It aims at annotating
semantic units with syntactic and semantic types. Each text sequence
corresponding to a named entity will be tagged with a unique tag
corresponding to its semantic value (for example a "gene" type for
gene names, "species" type for species names, etc.). All these text
sequences are also assumed to be equivalent to nouns: the tagger
dynamically produces linguistic units equivalent to words or noun
phrases.

C<$hash_config> is the reference to the hashtable containing the
variables defined in the configuration file.

We integrated TagEn (Jean-Francois Berroyer. I<TagEN, un analyseur
d'entites nommees : conception, developpement et
evaluation>. Universite Paris-Nord, France. 2004. Memoire de
D.E.A. d'Intelligence Artificielle), as default named entity tagger,
which is based on a set of linguistic resources and grammars. TagEn
can be downloaded here:
http://www-lipn.univ-paris13.fr/~hamon/ALVIS/Tools/TagEN.tar.gz



=head2 word_segmentation()

    word_segmentation($h_config, $doc_hash);

This method wraps the default word segmentation step. C<$doc_hash> is
the hashtable containing containing all the annotations of the input
document.

We use simple regular expressions, based on the algorithm proposed in
G. Grefenstette and P. Tapanainen. I<What is a word, what is a
sentence? problems of tokenization>.  The 3rd International Conference
on Computational Lexicography. pages 79-87. 1994. Budapest.  The
method is a wrapper for the awk script implementing the approach, has
been proposed on the Corpora list (see the achives
http://torvald.aksis.uib.no/corpora/ ). The script carries out Word
segmentation as week the sentence segmentation. Information related to
the sentence segmentation will be used in the default
sentence_segmentation method.


C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

In the default wrapper, segmented words are then aligned with tokens
and named entities. For example, let ``Bacillus subtilis'' be a named
entity made of three tokens: ``Bacillus'', the space character and
``subtilis''. The word segmenter will find two words: ``Bacillus'' and
``subtilis''. The wrapper however creates a single word, since
``Bacillus subtilis'' was found to be a named entity, and should thus
be considered a single word, made of the three same tokens.





=head2 sentence_segmentation()

    sentence_segmentation($h_config, $doc_hash);

This method wraps the default sentence segmentation step. C<$doc_hash>
is the hashtable containing containing all the annotations of the
input document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

The sentence segmentation function does not invoke any external tool (
See the C<word_segmentation()> method for more explaination.) It scans
the token hash table for full stops, i.e. dots that were not
considered to be part of words. All of these full stops then mark the
end of a sentence.  Each sentence is then assigned an identifier, and
two offsets: that of the starting token, and that of the ending
token.




=head2 pos_tag()

    pos_tag($h_config, $doc_hash);

The method wraps the Part-of-Speech (POS) tagging. C<$doc_hash> is the
hashtable containing containing all the annotations of the input
document. It works as follows: every word is input to the external
Part-Of-Speech tagging tool. For every input word, the tagger outputs
its tag. Then, the wrapper creates a hash table to associate the tag
to the word.  It assumes that word and sentence segmentations have
been performed.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

Be default, we are using the probabilistic Part-Of-Speech tagger
TreeTagger (Helmut Schmid. I<Probabilistic Part-of-Speech Tagging
Using Decision Trees>.  New Methods in Language Processing Studies in
Computational Linguistics.  1997.  Daniel Jones and Harold
Somers. http://www.ims.uni-stuttgart.de/projekte/corplex/TreeTagger/ ).


As this POS tagger also carries out the lemmatization, the method also
adds annotation at this level step.


The GeniaTagger (Yoshimasa Tsuruoka and Yuka Tateishi and Jin-Dong Kim
and Tomoko Ohta and John McNaught and Sophia Ananiadou and Jun'ichi
Tsujii.  I<Developing a Robust Part-of-Speech Tagger for Biomedical
Text> Proceedings of Advances in Informatics - 10th Panhellenic
Conference on Informatics.  pages 382-392.  2005.  LNCS 3746.) can
also be used, by modifying column order (see defintion of the command
line in C<client.pl>).



=head2 lemmatization()

    lemmatisation($h_config, $doc_hash);

This methods wraps the default lemmatizer. C<$doc_hash> is the
hashtable containing containing all the annotations of the input
document. However, as POS Tagger TreeTagger also gives lemma, this
method does ... nothing. It is here just for conformance.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.


=head2 term_tag()

    term_tag($h_config, $doc_hash);

The method wraps the term tagging step of the ALVIS NLP
Platform. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document. This step aims at recognizing terms
in the documents differing from named entities (see
C<Alvis::TermTagger>), like I<gene expression>, I<spore coat
cell>. Term lists can be provided as terminological resources such as
the Gene Ontology (http://www.geneontology.org/ ), the MeSH
(http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=mesh ) or more widely
UMLS (http://umlsinfo.nlm.nih.gov/ ). They can also be acquired through
corpus analysis.


The term matching in the document is carried out according to
typographical and inflectional variations. 
The typographical variation requires a slight preprocessing of the
terms.

We first assume a less strict use of the dash character. For instance,
the term I<UDP-glucose> can appear in the documents as I<UDP glucose>
and vice versa.  The inflectional variation requires a lemmatization
of the input documents. It makes it possible to identify
I<transcription factors> from I<transcription factor>.  Both variation
types can be taken into account altogether or separately during the
term matching.  Previous annotation levels, such as lemmatisation and
word segmentation but also named entities, are required.

C<$hash_config> is the reference to the hashtable containing the
variables defined in the configuration file.

Canonical forms and semantic tags which can be provided with the term
tagger and associated to the terms are taken into account. Canonical
forms are associated to the terms. Semantic tags are added at the
semantic features level. Semantic tags can be considered as a path in
a ontology. Each dot or slash characters are considered as a separator
of the node identifiers.

=head2 syntactic_parsing()

    syntactic_parsing($h_config, $doc_hash);

This method wraps the default sentence parsing. It aims at exhibiting
the graph of the syntactic dependency relations between the words of
the sentence. C<$doc_hash> is the hashtable containing containing all
the annotations of the input document.

C<$hash_config> is the reference to the hashtable containing the
variables defined in the configuration file.

The Link Grammar Parser (Daniel D. Sleator and Davy Temperley.
I<Parsing {E}nglish with a link grammar>. Third International Workshop
on Parsing Technologies. 1993. http://www.link.cs.cmu.edu/link/ ) is
actually integrated.


Processing time is a critical point for syntactic parsing, but we
expect that a good recognition of the terms can reduce significantly
the number of possible parses and consequently the parsing processing
time.  Term identification is therefore performed prior to parsing.
The word level of annotation is required. Depending on the choice of
the parser, the morphosyntactic level may be needed. 




=head2 semantic_feature_tagging()

    semantic_feature_tagging($h_config, $doc_hash)

The semantic typing function attaches a semantic type to the words,
terms and named-entities (referred to as lexical items in the
following) in documents according to the conceptual hierarchies of the
ontology of the domain. C<$doc_hash> is the hashtable containing
containing all the annotations of the input document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

Currently, this step is not integrated in the platform.


=head2 semantic_relation_tagging()

    semantic_relation_tagging($h_config, $doc_hash)


This method wraps the semantic relation identification
step. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document. In the Alvis project, the default
behaviour is the identification of domain specific semantic relations,
i.e. relations occurring between instances of the ontological concepts
in the document. These instances are identified and tagged accordingly
by the semantic typing. As a result, these semantic relation
annotations give another level of semantic representation of the
document that makes explicit the role that these semantic units
(usually named-entities and/or terms) play with respect to each other,
pertaining to the ontology of the domain.  However, this annotation
depends on previous document annotations and two different tagging
strategies, depending on the two different processing lines
(annotation of web documents and acquisition of resources used at the
web document annotation process) that impact the implementation of the
semantic relation tagging:

=over 

=item * If the document is syntactically parsed, the method can
exploit this information to tag relations mentioned explicitly. This
is achieved through the pattern matching of information extraction
rules. The rule matcher
that exploits them. The semantic relation tagger is therefore a mere
wrapper for the inference method.

=item * In the case where the document is not syntactically parsed,
the method will base its tagging on relations given by the ontology,
that is to say all known relations holding between semantic units
described in the document will be added, whether those relations be
explicitly mentioned in the document or not.

=back

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

Currently, this step is not integrated in the platform.


=head2 anaphora_resolution()

    anaphora_resolution($h_config, $doc_hash)

The methods wraps the tool which aims at identifing and solving the
anaphora present in a document. C<$doc_hash> is the hashtable
containing containing all the annotations of the input document. We
restrict the resolution to the anaphoras for the pronoun I<it>.  The
anaphora resolution takes as input an annotated document coming from
the semantic type tagging, in the ALVIS format and produces an
augmented text with XML tags corresponding to anaphora relations
between antecedents and pronouns, in the ALVIS format.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

Currently, this step is not integrated in the platform.



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


