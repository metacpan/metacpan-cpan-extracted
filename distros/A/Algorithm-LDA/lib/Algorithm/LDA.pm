# Algorithm::LDA
#
# Perl implementation of an example module 
#
# Copyright (c) 2016
#
# Bridget T McInnes, Virginia Commonwealth University 
# bmcinnes at vcu.edu
#
# Nicholas Jordan, Virginia Commonwealth University 
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to 
#
# The Free Software Foundation, Inc., 
# 59 Temple Place - Suite 330, 
# Boston, MA  02111-1307, USA.

=head1 NAME

Algorithm::LDA

=head1 SYNOPSIS

 use Algorithm::LDA;
 
 my $lda = new Algorithm::LDA("Data", 5, 100, 100, 0, 10, 0.1, 10, "stoplist.txt");
 
=head1 DESCRIPTION

Algorithm::LDA is an implementation of Latent Dirichlet Allocation in Algorithm

=cut

package Algorithm::LDA;


use strict;
use 5.006;
use strict;
use warnings FATAL => 'all';

use constant pi => 4*atan2(1, 1);
use constant e  => exp(1);
use parent qw/Class::Accessor::Fast/;
use List::Util qw(shuffle sum max);
use List::MoreUtils qw(uniq first_index);
use JSON::XS;


use vars qw($VERSION);

$VERSION = '0.03';


#Used for accessing $self->documents
__PACKAGE__->mk_accessors(qw/documents/);


# $documents - Data directory (TXT files)
# $stop - Stopword list (regex)
# $K - Number of Topics
# $k - $K-1 (for convenience)
# %vocabulary - hashmap containing words and IDs
# @words - array containing all words
# @documents - array of arrays of words in each document
    # Doc1 = word1, word2, word3
    # Doc2 = word4, word5, word6
# %map - hashmap used for getting word frequencies

# $V - vocabulary size
# $v - $V-1 (for convenience)
# @alpha - array of alpha values (parameter of topic distribution)
# @theta - array of theta values (topic distribution)
# @beta - array of beta values (parameter of word distribution)
# @phi - array of phi values (word distribution)

# $totalDocs - Total Documents (Only used for computing completeness when loading)
# $maxIterations - Maximum Iterations
# $updateCorpus - 1 = Force update documents, 0 = allow loading from JSON
# $threshold - Minimum number of documents a word must appear in
# $numWords - Number of words per topic
# $alpha - Default alpha value

# $documentNum - Number of documents


my $data;
my $docs;
my $stop; 

my $K;
my $k;
my %vocabulary;
my @words;
my @documents;
my %map = ();

my $V;
my $v;
my @alpha;
my @theta;
my @beta;
my @phi;

my $totalDocs;
my $maxIterations;
my $updateCorpus;
my $threshold;
my $numWords;
my $alpha;

my $documentNum = 0;


my $self;

sub new 
{
    my $class = shift;
    $self = {
        _data => shift,
        _numTopics => shift,
        _maxIterations => shift,
        _totalDocs => shift,
        _updateCorpus => shift,
        _wordThreshold => shift,
        _alpha => shift,
        _numWords => shift,
        _stop => shift,

        docs          => [],

        document_topic_map => {},
        topic_word_map     => {},
        document_map       => {},
        topic_map          => {},
        word_map           => {},
    };
    

    $docs = $self->{_data};
    $data = $self->{_data};
    
    $K = $self->{_numTopics};
    $k = $K - 1;
    $maxIterations = $self->{_maxIterations};
    $totalDocs = $self->{_totalDocs};
    $updateCorpus = $self->{_updateCorpus};
    $threshold = $self->{_wordThreshold};
    $alpha = $self->{_alpha};
    $numWords = $self->{_numWords};
    $stop = $self->{_stop};
    
    @{$self->{documents}} = (); 

    bless $self, $class;
    
    init();
    
    return $self;
}

=head3 add

description:

 Used to add to array of documents ($self->documents)

input:   

 %args <- hash containing data

output:

 1

example:

 while (my $line = <$fh2>) {
    my $obj = decode_json($line);
    add(%$obj);
 }

=cut

#Used to add to array of documents ($self->documents)
#Adds a word with document ID and random topic
sub add 
{
    my (%args) = @_;
    return unless (valid($args{data}));
    

    my $document_id = @{$self->documents};
    my @data_list = map {
    	{ document => $document_id, topic => int(rand($K)), word => $_ }
    } @{$args{data}};

    for my $data (@data_list) 
    {
        $self->increaseMap($document_id, $data->{topic}, $data->{word});
    }

    push(@{$self->documents}, \@data_list);

    return 1;
}

=head3 init

description:

 Initializes alpha, initializes beta, loads documents, starts main loop

input:   

 None

output:

 1

example:

 init();

=cut

#Initialization Method
sub init 
{    
    #Load Documents
    load();
    
    #Initialize @alpha to default value
    $alpha[$_] = $alpha for(0..$k);

    #Randomly initialize beta distribution
    beta();
    
    #Start Main loop
    for my $iter (1..$maxIterations) 
    {   
        #Calculate and print percentage completed
        my $a = $iter * 100 / $maxIterations;
        print "Iteration: $iter   |   $a% Completed...\n";
        
        #Shuffle Documents
        @{$self->documents} = shuffle(@{$self->documents});
        
        #Loop through each word in each document and sample its topic
        for my $document (@{$self->documents}) 
        {
	    print STDERR "Processing Document $document\n";
            for my $data (@$document) 
            {
                $self->decreaseMap($data->{document}, $data->{topic}, $data->{word});
                $data->{topic} = $self->sample_topic($data->{document}, $data->{word});
                $self->increaseMap($data->{document}, $data->{topic}, $data->{word});
            }
        }
        
        #print results for this iteration
        printResults($iter);
    }
        
    return 1;
}

=head3 printResults

description:

 Prints words in each topic, topics in each document, phi values, 
 and theta values to text files in the 'Results/$data' directory

input:   

 None

output:

 None

example:

 printResults();

=cut

#Creates four files in "Results/$data"
    # Documents.$data.txt - topic distribution for each document
    # Topics.$data.txt - word distribution for each topic
    # phi.$data.txt - Phi values per topic
    # theta.$data.txt Theta values per document

sub printResults
{
    print STDERR "Printing Results\n";

    my $iter = shift; 

    if(! (-e "Results")) { 
	system "mkdir Results"; 
    }
    
    if(! (-e "Results/$iter") ) { 
	system "mkdir Results/$iter"; 
    }

    my $file = "Results/" . $iter . "/Topics." . $iter . ".txt";
    open(my $fh, '>', $file) or die "Could not open file '$file' $!";
    
    my $file2 = "Results/" . $iter . "/Documents." . $iter . ".txt";
    open(my $fh2, '>', $file2) or die "Could not open file '$file2' $!";
    
    for my $topic (0 .. $k) 
	{
        my $words_on_topic = wordsPerTopic(topic => $topic);
        splice(@$words_on_topic, $numWords);
        print $fh join("\n", "Topic[$topic]:\n", map { "$_->{word}\t$_->{prob}"; } @$words_on_topic)."\n\n\n";
    }
    
    for my $doc (0 .. $#documents) {
        my $topics_on_document= topicsPerDocument(document => $doc);
        splice(@$topics_on_document, $numWords);
        print $fh2 join("\n", "Document[$doc]:\n", map { "$_->{topic}\t$_->{prob}"; } @$topics_on_document)."\n\n\n";
    }

    close($fh);
    close($fh2);
    
    my $file3 = "Results/" . $iter . "/phi." . $iter . ".txt";
    open(my $fh3, '>', $file3) or die "Could not open file '$file3' $!";
    
    my $file4 = "Results/" . $iter . "/theta." . $iter . ".txt";
    open(my $fh4, '>', $file4) or die "Could not open file '$file4' $!";
    
    for my $i (0..$k)
    {
        print $fh3 "$i  :  " . join(", ", @{$phi[$i]}) . "\n";
    }
    
    for my $i (0..scalar @{$self->documents} - 1)
    {
        print $fh4 "$i  :  " . join(", ", @{$theta[$i]}) . "\n";
    }
    
    close($fh3);
    close($fh4);
}

=head3 load

description:

 Loads documents from text files (in "data/$data") or JSON file (in "Documents")

input:   

 None

output:

 None

example:

 load();

=cut

#Loads document data from files or JSON

sub load
{    
    #open data directory
    opendir(DH, "$docs"); 
    my @files = grep { $_ ne '.' and $_ ne '..' } readdir DH;
    closedir(DH);
    
    #array holding string of words in each document
    my @documents1 = ();
    
    #stopword regex
    
    my $regex = ""; 
    if(defined $stop) { 
	my $rstop = stop();
	$regex = qr/($rstop)/;
    }
        
    #Load Files from TXTs
                
    print "Loading Documents from TXTs...\n";
    
    foreach my $filename (@files)
    {
	print "Loading Document $documentNum ($filename): Corpus ";
	print (($documentNum + 1) * 100 / $totalDocs);
	print "% completed...\n";
	open(FILE, "$docs/$filename")
	    || die "Could not open file '$docs/$filename' $!";
	
	#Load file into single string, remove stopwords, and split by whitespace into array
	my $document = do { local $/; lc(<FILE>)};
	$document =~ s/($regex)//g;
	my @temp = split(/\s+/, $document);
	
	#remove all special characters and add to @words and @documents1
	for my $i (0..scalar @temp - 1)
	{
	    $temp[$i] = removeSpecialChars($temp[$i]);
	}
	push(@words, @temp);
	
	$documents1[$documentNum] = join(" ", @temp);
	$documentNum++;
    }
    

    chomp @words;
    @words = grep {$_ if $_ } @words;
    %vocabulary = map {   $words[$_]=>$_   } (0..$#words);
    $V = scalar keys %vocabulary;
    $v = $V-1;
    
    #Loop through @documents1, remove special characters and populate @documents
    for my $text (@documents1) 
    {
        my @ws = split(/\s+/, $text);
        chomp @ws;
        @ws = map { removeSpecialChars($_) } @ws;
        @ws  = grep {  exists $vocabulary{$_} } @ws;
        @ws = uniq(@ws);
        push @documents, \@ws;
    }
    
    print "Vocabulary (Uncleaned): $V\n";
    
    #Get word frequencies
    for my $d (0..$#documents) 
    {
        for my $wrd (@{$documents[$d]}) 
        {
            next unless exists $vocabulary{$wrd};
            $map{$wrd}=0 unless exists $map{$wrd};
            $map{$wrd}++; 
        }
    }
    
    #Remove words that appear in more than half of the corpus, and less than $threshold documents
    #Also remove words of less than three letters
    my $D = @documents;
    for my $wd (0..$#words) 
    {
        my $times = $map{$words[$wd]};
        my $test = ($times > 0.5*$D  || $times<=$threshold || length($words[$wd]) <=3);    
	
        if($test)   
        {   
            $words[$wd]=0;
        }
    }
    
    #Repopulate %vocabulary with cleaned words
    @words = grep { $_ } (@words);
    @words = uniq(@words);
    %vocabulary = map { $words[$_] => $_ } (0..$#words);
    $V = scalar keys %vocabulary;
    $v = $V-1;
    
    print "Vocabulary (Cleaned): $V\n";
    
    
    #Convert words to hashmap (for use of "exists") and remove unclean 
    # words from documents array
    my %h;
    @h{@words} = ();
    for my $i (0..$#documents)
    {
        @{$documents[$i]} = grep{exists $h{$_}} @{$documents[$i]};
    }

    
    open(my $fh, '>', "JSON") or die "Could not open file 'JSON' $!";
	
    foreach my $i (@documents)
    {
	print $fh "{\"data\":[\"" . join("\", \"", @{$i})."\"]}\n";
    }
    close $fh;
	
   
        open(my $fh2, '<', "JSON") or die "Could not open file 'JSON' $!";
        while (my $line = <$fh2>) {
            my $obj = decode_json($line);
            add(%$obj);
        }
        close $fh2;
}


=head3 wordsPerTopic
    
  description:
    
 Creates an array of words in each topic

input:   

 %args -> hash containing topic

output:

 @words -> Array containing words and probabilities (phi value) for $args{topic}

example:

 my $words_on_topic = wordsPerTopic(topic => $topic);

=cut

sub wordsPerTopic 
{
    my (%args) = @_;

    return unless (defined $args{topic});
    my @words = sort { $b->{prob} <=> $a->{prob} } map {
        { word => $_, prob => $self->computePhi($args{topic}, $_) }
    } keys %{$self->{word_map}};
    return \@words;
}

=head3 topicsPerDocument

description:

 Creates an array of topics in each document

input:   

 %args -> hash containing document

output:

 @topics -> Array containing topics and probabilities (theta value) for $args{document}

example:

 my $topics_on_document= topicsPerDocument(document => $doc);

=cut

sub topicsPerDocument 
{
    my (%args) = @_;

    return unless (defined $args{document});
    my @topics = sort { $b->{prob} <=> $a->{prob} } map {
        { topic => $_, prob => $self->computeTheta($args{document}, $_) }
    } keys %{$self->{topic_map}};
    return \@topics;
}

=head3 sample_topic

description:

 Uses Gibbs Sampling to determine a topic given a document and word

input:   

 $document -> ID of document word is in
 $word -> word that is to be evaluated

output:

 $topic -> topic ID
 $k -> last topic if topic can't be found

example:

 my $topics_on_document= topicsPerDocument(document => $doc);

=cut

sub sample_topic 
{
    my ($self, $document, $word) = @_;

    my @dists;
    my $dist = 0.0;
    for my $topic (0 .. $k) 
	{
        $dist += ($self->computePhi($topic, $word) * $self->computeTheta($document, $topic));

        $phi[$topic][first_index { $_ eq $word } @words] = $self->computePhi($topic, $word);
        $theta[$document][$topic] = $self->computeTheta($document, $topic);
         
        push(@dists, $dist);
    }

    my $sampled_dist = rand($dist);
    for my $topic (0 .. $k) 
	{
        return $topic if ($sampled_dist < $dists[$topic]);
    }
    return ($k);
}

=head3 computePhi

description:

 Computes the expected phi value for a word given a topic ID

input:   

 $topic -> ID of topic (iteration 0..$k)
 $word -> word that is to be evaluated

output:

 Phi value

example:

 $dist += ($self->computePhi($topic, $word) * $self->computeTheta($document, $topic));

=cut

sub computePhi 
{
    my ($self, $topic, $word) = @_;

    $self->{topic_word_map}{$topic}{$word} //= 0.0;
    $self->{topic_map}{$topic}             //= 0.0;

    #print $vocabulary{$word} . "  |  ";
    #print first_index { $_ eq $word } @words;
    #print "\n"; 
    
    return ($self->{topic_word_map}{$topic}{$word} + $beta[$topic][first_index { $_ eq $word } @words]) /
           ($self->{topic_map}{$topic} + $V * $beta[$topic][first_index { $_ eq $word } @words]);
}

=head3 computeTheta

description:

 Computes the expected theta value for a topic given a document ID

input:   

 $document -> ID of document
 $topic -> ID of topic (iteration 0..$k)

output:

 Theta value

example:

 $dist += ($self->computePhi($topic, $word) * $self->computeTheta($document, $topic));

=cut

sub computeTheta 
{
    my ($self, $document, $topic) = @_;

    $self->{document_topic_map}{$document}{$topic} //= 0.0;
    $self->{document_map}{$document}               //= 0.0;
    return ($self->{document_topic_map}{$document}{$topic} + $alpha[$topic]) /
           ($self->{document_map}{$document} + $K * $alpha[$topic]);
}

=head3 increaseMap

description:

 Increases the values of all of the hashmaps

input:   

 $document -> ID of document
 $topic -> ID of topic
 $word -> word in document $document

output:

 None

example:

 $self->increaseMap($data->{document}, $data->{topic}, $data->{word});

=cut

sub increaseMap 
{
    my ($self, $document, $topic, $word) = @_;

    $self->{document_topic_map}{$document}{$topic}++;
    $self->{topic_word_map}{$topic}{$word}++;
    $self->{document_map}{$document}++;
    $self->{topic_map}{$topic}++;
    $self->{word_map}{$word}++;
}

=head3 decreaseMap

description:

 Decreases the values of all of the hashmaps

input:   

 $document -> ID of document
 $topic -> ID of topic
 $word -> word in document $document

output:

 None

example:

 $self->decreaseMap($data->{document}, $data->{topic}, $data->{word});

=cut


sub decreaseMap 
{
    my ($self, $document, $topic, $word) = @_;

    $self->{document_topic_map}{$document}{$topic}--;
    $self->{topic_word_map}{$topic}{$word}--;
    $self->{document_map}{$document}--;
    $self->{topic_map}{$topic}--;
    $self->{word_map}{$word}--;
}

=head3 valid

description:

 Returns whether or not $data is a valid array (able to be added to the dataset)

input:   

 $data -> data to be evaluated

output:

 Boolean/Integer -> true/1 - $data is an array | false/0 - $data is not an array;

example:

 return unless (valid($args{data}));

=cut


sub valid 
{
    my ($data) = @_;

    return unless ($data);
    return (ref($data) eq 'ARRAY') ? 1 : 0;
}

=head3 removeSpecialChars

description:

 Removes special characters from a word (non-ascii/non-letter characters)

input:   

 $word -> word to be cleaned

output:

 $newWord -> $word without non-ascii/non-letter characters

example:

 @ws = map { removeSpecialChars($_) } @ws;

=cut

sub removeSpecialChars
{
    my($word) = @_;
    $word =~ s/([^\w\d])+?//g;
    $word =~ s/[^[:ascii:]]//g;
    my $newWord =  lc($word);
    return $newWord;
}

=head3 beta

description:

 Randomly initializes beta values

input:   

 None

output:

 None

example:

 beta();

=cut

sub beta
{    
    my $e_value = 1.0 / $K;
            
    for my $i (0..$k) 
    {
        for my $n (0..$v) 
        {
            $beta[$i][$n] = $e_value;
        }
    }
      
    for(1..1000000) 
    {
        my $d = rand()* $e_value;
        my $i = int(rand($K));
        my $n1 = int(rand($V));
        my $n2 = int(rand($V));
               
        $beta[$i][$n1]+=$d;
        $beta[$i][$n2]-=$d;
               
        if($beta[$i][$n2] <= 0 || $beta[$i][$n1] >=1)
        {
            $beta[$i][$n1]-=$d;
            $beta[$i][$n2]+=$d;              
        }
    }
    
    
}

=head3 stop

description:

 Stopword subroutine.  Generates a regex to remove words in a stopword list

input:   

 None

output:

 $stop_regex -> regex containing stopwords

example:

 my $stop = stop();
 my $regex = qr/($stop)/;

=cut

#STOPWORD SUBROUTINE
sub stop 
{ 
    my $stop_regex = "";
    my $stop_mode = "AND";

    open ( STP, $stop ) ||
        die ("Couldn't open the stoplist file $stop\n");
    
    while ( <STP> ) 
    {
	chomp; 
	
	if(/\@stop.mode\s*=\s*(\w+)\s*$/) 
        {
	    $stop_mode=$1;
	    if(!($stop_mode=~/^(AND|and|OR|or)$/)) 
            {
		print STDERR "Requested Stop Mode $1 is not supported.\n";
		exit;
	    }
	    next;
	} 
	
	# accepting Perl Regexs from Stopfile
	s/^\s+//;
	s/\s+$//;
	
	#handling a blank lines
	if(/^\s*$/) { next; }
	
	#check if a valid Perl Regex
        if(!(/^\//)) 
        {
	    print STDERR "Stop token regular expression <$_> should start with '/'\n";
	    exit;
        }
        if(!(/\/$/)) 
        {
	    print STDERR "Stop token regular expression <$_> should end with '/'\n";
	    exit;
        }

        #remove the / s from beginning and end
        s/^\///;
        s/\/$//;
        
	#form a single big regex
        $stop_regex.="(".$_.")|";
    }

    if(length($stop_regex)<=0) 
    {
	print STDERR "No valid Perl Regular Experssion found in Stop file $stop";
	exit;
    }
    
    chop $stop_regex;
    
    # making AND a default stop mode
    if(!defined $stop_mode) 
    {
	$stop_mode="AND";
    }
    
    close STP;
    
    return $stop_regex; 
}

1;

__END__

=head1 REFERENCING

    If you have a reference paper for this module put it here in bibtex form

=head1 CONTACT US

  If you have any trouble installing and using <module name> 
  please contact us via :

      Bridget T. McInnes: btmcinnes at vcu.edu

=head1 SEE ALSO

Additional modules associated with the package

=head1 AUTHORS

  Nick Jordan, Virginia Commonwealth University 

  Bridget McInnes, Virginia Commonwealth University

=head1 COPYRIGHT AND LICENSE

Copyright 2016 by Bridget McInnes, Nicholas Jordan

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to 

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut
