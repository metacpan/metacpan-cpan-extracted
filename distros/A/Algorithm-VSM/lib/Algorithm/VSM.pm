package Algorithm::VSM;

#---------------------------------------------------------------------------
# Copyright (c) 2015 Avinash Kak. All rights reserved.  This program is free
# software.  You may modify and/or distribute it under the same terms as Perl itself.
# This copyright notice must remain attached to the file.
#
# Algorithm::VSM is a Perl module for retrieving the documents from a software
# library that match a list of words in a query. The matching criterion used depends
# on whether you ask the module to construct a full-dimensionality VSM or a
# reduced-dimensionality LSA model for the library.
# ---------------------------------------------------------------------------

#use 5.10.0;
use strict;
use warnings;
use Carp;
use SDBM_File;
use PDL::Lite;
use PDL::MatrixOps;
use File::Basename;
use File::Spec::Functions qw(rel2abs);
use Fcntl;
use Storable;
use Cwd;

our $VERSION = '1.70';

# for camelcase splits (from perlmonks):
my $_regex = qr/[[:lower:]0-9]+|[[:upper:]0-9](?:[[:upper:]0-9]+|[[:lower:]0-9]*)(?=$|[[:upper:]0-9])/; 

###################################   Constructor  #######################################

#  Constructor for creating a VSM or LSA model of a corpus.  The model instance
#  returned by the constructor can be used for retrieving documents from the corpus
#  in response to queries.
sub new { 
    my ($class, %args) = @_;
    my @params = keys %args;
    croak "\nYou have used a wrong name for a keyword argument " .
          "--- perhaps a misspelling\n" 
          if _check_for_illegal_params(@params) == 0;
    bless {
        _corpus_directory           =>  $args{corpus_directory}   || "",
        _save_model_on_disk         =>  $args{save_model_on_disk} || 0,
        _break_camelcased_and_underscored  => exists $args{break_camelcased_and_underscored} ?
                                              $args{break_camelcased_and_underscored} : 1,
        _corpus_vocab_db            =>  $args{corpus_vocab_db} || "corpus_vocab_db",
        _doc_vectors_db             =>  $args{doc_vectors_db} || "doc_vectors_db",
        _normalized_doc_vecs_db     =>  $args{normalized_doc_vecs_db} || "normalized_doc_vecs_db",
        _stop_words_file            =>  $args{stop_words_file} || "",
        _case_sensitive             =>  $args{case_sensitive} || 0,
        _query_file                 =>  $args{query_file} || "",
        _file_types                 =>  $args{file_types} || [],
        _min_word_length            =>  $args{min_word_length} || 4,
        _want_stemming              =>  $args{want_stemming} || 0,
        _idf_filter_option          =>  exists $args{use_idf_filter} ? $args{use_idf_filter} : 1,
        _max_number_retrievals      =>  $args{max_number_retrievals} || 30,
        _lsa_svd_threshold          =>  $args{lsa_svd_threshold} || 0.01,
        _relevancy_threshold        =>  exists $args{relevancy_threshold} ? $args{relevancy_threshold} : 1,
        _relevancy_file             =>  $args{relevancy_file} || "",
        _debug                      =>  $args{debug} || 0,
        _working_directory          =>  cwd,
        _vocab_hist_on_disk         =>  {},
        _vocab_hist                 =>  {},
        _doc_hist_template          =>  {},
        _corpus_doc_vectors         =>  {},
        _normalized_doc_vecs        =>  {},
        _query_vector               =>  {},
        _stop_words                 =>  [],
        _term_document_matrix       =>  [],
        _corpus_vocab_done          =>  0,
        _scan_dir_for_rels          =>  0,
        _vocab_size                 =>  undef,
        _doc_vecs_trunc_lsa         =>  {},
        _lsa_vec_truncator          =>  undef,
        _queries_for_relevancy      =>  {},
        _relevancy_estimates        =>  {},
        _precision_for_queries      =>  {},
        _avg_precision_for_queries  =>  {},
        _recall_for_queries         =>  {},
        _map                        =>  undef,
        _vocab_idf_hist             =>  {},
        _idf_t                      =>  {},
        _total_num_of_docs          =>  0,
    }, $class;
}


######################    Get corpus vocabulary and word counts  #########################

sub get_corpus_vocabulary_and_word_counts {
    my $self = shift;
    die "You must supply the name of the corpus directory to the constructor"
        unless $self->{_corpus_directory};
    print "Scanning the directory '$self->{_corpus_directory}' for\n" .
        "  model construction\n\n" if $self->{_debug};
    $self->_scan_directory( $self->{_corpus_directory} );
    $self->_drop_stop_words() if $self->{_stop_words_file};
    if ($self->{_debug}) {
        foreach ( sort keys %{$self->{_vocab_hist_on_disk}} ) {               
            printf( "%s\t%d\n", $_, $self->{_vocab_hist_on_disk}->{$_} );    
        }
    }
    if ($self->{_save_model_on_disk}) {
        unlink glob "$self->{_corpus_vocab_db}.*";   
        unlink glob "$self->{_doc_vectors_db}.*";   
        unlink glob "$self->{_normalized_doc_vecs_db}.*";   
        tie %{$self->{_vocab_hist_on_disk}}, 'SDBM_File',  
                 $self->{_corpus_vocab_db}, O_RDWR|O_CREAT, 0640
                or die "Can't create DBM files: $!";       
        foreach (keys %{$self->{_vocab_hist}}) {
            $self->{_vocab_hist_on_disk}->{$_} = $self->{_vocab_hist}->{$_};
        }
        untie %{$self->{_vocab_hist_on_disk}};
    }
    $self->{_corpus_vocab_done} = 1;
    $self->{_vocab_size} = scalar( keys %{$self->{_vocab_hist}} );
    print "\n\nVocabulary size:  $self->{_vocab_size}\n\n"
            if $self->{_debug};
    # Calculate idf(t):
    foreach (keys %{$self->{_vocab_idf_hist}}) {
        $self->{_idf_t}->{$_} = abs( (1 + log($self->{_total_num_of_docs}
                                      /
                                      (1 + $self->{_vocab_idf_hist}->{$_}))) 
                                      / log(10) ); 
    }
}

sub display_corpus_vocab {
    my $self = shift;
    die "corpus vocabulary not yet constructed"
        unless keys %{$self->{_vocab_hist}};
    print "\n\nDisplaying corpus vocabulary:\n\n";
    foreach (sort keys %{$self->{_vocab_hist}}){
        my $outstring = sprintf("%30s     %d", $_,$self->{_vocab_hist}->{$_});
        print "$outstring\n";
    }
}

sub display_corpus_vocab_size {
    my $self = shift;
    die "corpus vocabulary not yet constructed"
        unless keys %{$self->{_vocab_hist}};
    my $vocab_size = scalar( keys %{$self->{_vocab_hist}} );
    print "\nSize of the corpus vocabulary: $vocab_size\n\n";
}

sub write_corpus_vocab_to_file {
    my $self = shift;
    my $file = shift;
    die "corpus vocabulary not yet constructed" unless keys %{$self->{_vocab_hist}};
    open OUT, "> $file" 
       or die "unable to open for output a file with name `$file': $!";
    foreach (sort keys %{$self->{_vocab_hist}}){
        my $outstring = sprintf("%30s     %d", $_,$self->{_vocab_hist}->{$_});
        print OUT "$outstring\n";
    }
    close OUT;
}

sub display_inverse_document_frequencies {
    my $self = shift;
    die "corpus vocabulary not yet constructed"
        unless keys %{$self->{_vocab_idf_hist}};
    print "\n\nThe idf values and idf(t) values displayed below are not being used for retrieval since you did not set the use_idf_filter option in the constructor\n"
        unless $self->{_idf_filter_option};
    print "\n\nDisplaying inverse document frequencies:\n";
    foreach ( sort keys %{$self->{_vocab_idf_hist}} ) {               
        my $outstring = sprintf("%30s     %d", 
                       $_, $self->{_vocab_idf_hist}->{$_});
        print "$outstring\n";
    }
    print "\nDisplaying idf(t) = log(D/d(t)) where D is total number of documents and d(t) the number of docs with the word t:\n";
    foreach ( sort keys %{$self->{_idf_t}} ) {               
        my $outstring = sprintf("%30s     %f", $_,$self->{_idf_t}->{$_});
        print "$outstring\n";
    }
}

sub get_all_document_names {
    my $self = shift;
    my @all_files = sort keys %{$self->{_corpus_doc_vectors}};
    return \@all_files;
}

############################  Generate Document Vectors  #################################

sub generate_document_vectors {
    my $self = shift;
    chdir $self->{_working_directory};
    foreach ( sort keys %{$self->{_vocab_hist}} ) {
        $self->{_doc_hist_template}->{$_} = 0;    
    }
    $self->_scan_directory( $self->{_corpus_directory} );
    chdir $self->{_working_directory};
    if ($self->{_save_model_on_disk}) {
        die "You did not specify in the constructor call the names for the diskfiles " .
            "for storing the disk-based hash tables consisting of document vectors " .
            "and their normalized versions" 
            unless $self->{_doc_vectors_db} && $self->{_normalized_doc_vecs_db};
        eval {
            store( $self->{_corpus_doc_vectors}, $self->{_doc_vectors_db} );
        };
        if ($@) {
            print "Something went wrong with disk storage of document vectors: $@";
        }
        eval {
            store($self->{_normalized_doc_vecs}, $self->{_normalized_doc_vecs_db});
        };
        if ($@) {
            print "Something wrong with disk storage of normalized doc vecs: $@";
        }
    }
}

sub display_doc_vectors {
    my $self = shift;
    die "document vectors not yet constructed" 
        unless keys %{$self->{_corpus_doc_vectors}};
    foreach my $file (sort keys %{$self->{_corpus_doc_vectors}}) {        
        print "\n\ndisplay doc vec for $file:\n";
        foreach ( sort keys %{$self->{_corpus_doc_vectors}->{$file}} ) {
            print "$_  =>   $self->{_corpus_doc_vectors}->{$file}->{$_}\n";
        }
        my $docvec_size = keys %{$self->{_corpus_doc_vectors}->{$file}};
        print "\nSize of vector for $file: $docvec_size\n";
    }
}

sub display_normalized_doc_vectors {
    my $self = shift;
    die "normalized document vectors not yet constructed" 
        unless keys %{$self->{_normalized_doc_vecs}};
    unless ($self->{_idf_filter_option}) {
        print "Nothing to display for normalized doc vectors since you did not set the use_idf_filter option in the constructor\n";
        return;
    }
    foreach my $file (sort keys %{$self->{_normalized_doc_vecs}}) {        
        print "\n\ndisplay normalized doc vec for $file:\n";
        foreach ( sort keys %{$self->{_normalized_doc_vecs}->{$file}} ) {
            print "$_  =>   $self->{_normalized_doc_vecs}->{$file}->{$_}\n";
        }
        my $docvec_size = keys %{$self->{_normalized_doc_vecs}->{$file}};
        print "\nSize of normalized vector for $file: $docvec_size\n";
    }
}

########################  Calculate Pairwise Document Similarities  ######################

# Returns the similarity score for two documents whose actual names are are supplied
# as its two arguments.
sub pairwise_similarity_for_docs {
    my $self = shift;
    my $doc1 = shift;
    my $doc2 = shift;
    my @all_files = keys %{$self->{_corpus_doc_vectors}};
    croak "The file $doc1 does not exist in the corpus:  " unless contained_in($doc1, @all_files);
    croak "The file $doc2 does not exist in the corpus:  " unless contained_in($doc2, @all_files);
    my $vec_hash_ref1 = $self->{_corpus_doc_vectors}->{$doc1};
    my $vec_hash_ref2 = $self->{_corpus_doc_vectors}->{$doc2};
    my @vec1 = ();
    my @vec2 = ();
    foreach my $word (sort keys %$vec_hash_ref1) {
        push @vec1, $vec_hash_ref1->{$word};
        push @vec2, $vec_hash_ref2->{$word};
    }
    my $vec_mag1 = vec_magnitude(\@vec1);
    my $vec_mag2 = vec_magnitude(\@vec2);
    my $product = vec_scalar_product(\@vec1, \@vec2);
    $product /= $vec_mag1 * $vec_mag2;
    return $product;
}

sub pairwise_similarity_for_normalized_docs {
    my $self = shift;
    my $doc1 = shift;
    my $doc2 = shift;
    my @all_files = keys %{$self->{_corpus_doc_vectors}};
    croak "The file $doc1 does not exist in the corpus:  " unless contained_in($doc1, @all_files);
    croak "The file $doc2 does not exist in the corpus:  " unless contained_in($doc2, @all_files);
    my $vec_hash_ref1 = $self->{_normalized_doc_vecs}->{$doc1};
    my $vec_hash_ref2 = $self->{_normalized_doc_vecs}->{$doc2};
    my @vec1 = ();
    my @vec2 = ();
    foreach my $word (sort keys %$vec_hash_ref1) {
        push @vec1, $vec_hash_ref1->{$word};
        push @vec2, $vec_hash_ref2->{$word};
    }
    my $vec_mag1 = vec_magnitude(\@vec1);
    my $vec_mag2 = vec_magnitude(\@vec2);
    my $product = vec_scalar_product(\@vec1, \@vec2);
    $product /= $vec_mag1 * $vec_mag2;
    return $product;
}

###############################  Retrieve with VSM Model  ################################

sub retrieve_with_vsm {
    my $self = shift;
    my $query = shift;
    my @clean_words;
    my $min = $self->{_min_word_length};

    if ($self->{_break_camelcased_and_underscored}) {
        my @brokenup = grep $_, split /\W|_|\s+/, "@$query";
        @clean_words = map {$_ =~ /$_regex/g} @brokenup;
        @clean_words = $self->{_case_sensitive} ? 
                       grep $_, map {$_ =~ /([[:lower:]0-9]{$min,})/i;$1?$1:''} @clean_words :
                       grep $_, map {$_ =~ /([[:lower:]0-9]{$min,})/i;$1?"\L$1":''} @clean_words;
    } else {
        my @brokenup = split /\"|\'|\.|\(|\)|\[|\]|\\|\/|\s+/, "@$query";
        @clean_words = grep $_, map { /([a-z0-9_]{$min,})/i;$1 } @brokenup;
    }
    $query = \@clean_words;
    print "\nYour query words are: @$query\n" if $self->{_debug};
    if ($self->{_idf_filter_option}) {
        die "\nYou need to first generate normalized document vectors before you can call  retrieve_with_vsm()"
            unless scalar(keys %{$self->{_vocab_hist}}) 
                  && scalar(keys %{$self->{_normalized_doc_vecs}});
    } else {
        die "\nYou need to first generate document vectors before you can call retrieve_with_vsm()"
            unless scalar(keys %{$self->{_vocab_hist}}) 
                  && scalar(keys %{$self->{_corpus_doc_vectors}});
    }
    foreach ( keys %{$self->{_vocab_hist}} ) {        
        $self->{_query_vector}->{$_} = 0;    
    }
    foreach (@$query) {
        if ($self->{_case_sensitive}) {
            $self->{_query_vector}->{$_}++ if exists $self->{_vocab_hist}->{$_};
        } else {
            $self->{_query_vector}->{"\L$_"}++ if exists $self->{_vocab_hist}->{"\L$_"};
        }
    }
    my @query_word_counts = values %{$self->{_query_vector}};
    my $query_word_count_total = sum(\@query_word_counts);
    die "\nYour query does not contain corpus words. Nothing retrieved.\n"
        unless $query_word_count_total;
    my %retrievals;
    if ($self->{_idf_filter_option}) {
        print "\n\nUsing idf filter option for retrieval:\n\n" 
                                                if $self->{_debug};
        foreach (sort {$self->_doc_vec_comparator} 
                         keys %{$self->{_normalized_doc_vecs}}) {
            $retrievals{$_} = $self->_similarity_to_query($_) if $self->_similarity_to_query($_) > 0;
        }
    } else {
        print "\n\nNOT using idf filter option for retrieval:\n\n"
                                                if $self->{_debug};
        foreach (sort {$self->_doc_vec_comparator} 
                         keys %{$self->{_corpus_doc_vectors}}) {
            $retrievals{$_} = $self->_similarity_to_query($_) if $self->_similarity_to_query($_) > 0;
        }
    }
    if ($self->{_debug}) {
        print "\n\nShowing the VSM retrievals and the similarity scores:\n\n";
        foreach (sort {$retrievals{$b} <=> $retrievals{$a}} keys %retrievals) {
            print "$_   =>   $retrievals{$_}\n";
        }
    }
    return \%retrievals;
}

######################### Upload a Previously Constructed Model  #########################

sub upload_vsm_model_from_disk {
    my $self = shift;
    die "\nCannot find the database files for the VSM model"
        unless -s "$self->{_corpus_vocab_db}.pag" 
            && -s $self->{_doc_vectors_db};
    $self->{_corpus_doc_vectors} = retrieve($self->{_doc_vectors_db});
    tie %{$self->{_vocab_hist_on_disk}}, 'SDBM_File', 
                      $self->{_corpus_vocab_db}, O_RDONLY, 0640
            or die "Can't open DBM file: $!";       
    if ($self->{_debug}) {
        foreach ( sort keys %{$self->{_vocab_hist_on_disk}} ) {               
            printf( "%s\t%d\n", $_, $self->{_vocab_hist_on_disk}->{$_} );    
        }
    }
    foreach (keys %{$self->{_vocab_hist_on_disk}}) {
        $self->{_vocab_hist}->{$_} = $self->{_vocab_hist_on_disk}->{$_};
    }
    $self->{_corpus_vocab_done} = 1;
    $self->{_vocab_size} = scalar( keys %{$self->{_vocab_hist}} );
    print "\n\nVocabulary size:  $self->{_vocab_size}\n\n"
               if $self->{_debug};
    $self->{_corpus_doc_vectors} = retrieve($self->{_doc_vectors_db});
    untie %{$self->{_vocab_hist_on_disk}};
}

sub upload_normalized_vsm_model_from_disk {
    my $self = shift;
    die "\nCannot find the database files for the VSM model"
        unless -s "$self->{_corpus_vocab_db}.pag" 
            && -s $self->{_normalized_doc_vecs_db};
    $self->{_normalized_doc_vecs} = retrieve($self->{_normalized_doc_vecs_db});
    tie %{$self->{_vocab_hist_on_disk}}, 'SDBM_File', 
                      $self->{_corpus_vocab_db}, O_RDONLY, 0640
            or die "Can't open DBM file: $!";       
    if ($self->{_debug}) {
        foreach ( sort keys %{$self->{_vocab_hist_on_disk}} ) {               
            printf( "%s\t%d\n", $_, $self->{_vocab_hist_on_disk}->{$_} );    
        }
    }
    foreach (keys %{$self->{_vocab_hist_on_disk}}) {
        $self->{_vocab_hist}->{$_} = $self->{_vocab_hist_on_disk}->{$_};
    }
    $self->{_corpus_vocab_done} = 1;
    $self->{_vocab_size} = scalar( keys %{$self->{_vocab_hist}} );
    print "\n\nVocabulary size:  $self->{_vocab_size}\n\n"
               if $self->{_debug};
    untie %{$self->{_vocab_hist_on_disk}};
}

############################## Display Retrieval Results  ################################

sub display_retrievals {
    my $self = shift;
    my $retrievals = shift;
    print "\n\nShowing the retrievals and the similarity scores:\n\n";
    my $iter = 0;
    foreach (sort {$retrievals->{$b} <=> $retrievals->{$a}} keys %$retrievals){
        print "$_   =>   $retrievals->{$_}\n"; 
        $iter++;
        last if $iter > $self->{_max_number_retrievals};
    }   
    print "\n\n";
}

###############################    Directory Scanner      ################################

sub _scan_directory {
    my $self = shift;
    my $dir = rel2abs( shift );
    my $current_dir = cwd;
    chdir $dir or die "Unable to change directory to $dir: $!";
    foreach ( glob "*" ) {                                            
        if ( -d and !(-l) ) {
            $self->_scan_directory( $_ );
            chdir $dir                                                
                or die "Unable to change directory to $dir: $!";
        } elsif (-r _ and 
                 -T _ and 
                 -M _ > 0.00001 and  # modification age is at least 1 sec
                !( -l $_ ) and 
                $self->ok_to_filetype($_) ) {
            $self->_scan_file_for_rels($_) if $self->{_scan_dir_for_rels};
            $self->_scan_file($_) unless $self->{_corpus_vocab_done};
            $self->_construct_doc_vector($_) if $self->{_corpus_vocab_done};
        }
    }
    chdir $current_dir;
}

sub _scan_file {
    my $self = shift;
    my $file = shift;
    open IN, $file;
    my $min = $self->{_min_word_length};
    my %uniques = ();
    while (<IN>) {
        next if /^[ ]*\r?\n?$/;
        $_ =~ s/\r?\n?$//;
        my @clean_words;
        if ($self->{_break_camelcased_and_underscored}) {
            my @brokenup = grep $_, split /\W|_|\s+/, $_;
            @clean_words = map {$_ =~ /$_regex/g} @brokenup;
        @clean_words = $self->{_case_sensitive} ? 
                       grep $_, map {$_ =~ /([[:lower:]0-9]{$min,})/i;$1?$1:''} @clean_words :
                       grep $_, map {$_ =~ /([[:lower:]0-9]{$min,})/i;$1?"\L$1":''} @clean_words;
        } else {
            my @brokenup = split /\"|\'|\.|\(|\)|\[|\]|\\|\/|\s+/, $_;
            @clean_words = grep $_, map { /([a-z0-9_]{$min,})/i;$1 } @brokenup;
        }
        next unless @clean_words;
        @clean_words = grep $_, map &simple_stemmer($_), @clean_words
               if $self->{_want_stemming};
        $self->{_case_sensitive} ?
            map { $self->{_vocab_hist}->{$_}++ } grep $_, @clean_words :
            map { $self->{_vocab_hist}->{"\L$_"}++ } grep $_, @clean_words;
        if ($self->{_case_sensitive}) {
            for (@clean_words) { $uniques{$_}++ }
        } else {
           for (@clean_words) { $uniques{"\L$_"}++ }
        }
    }
    close( IN );
    map { $self->{_vocab_idf_hist}->{$_}++ } keys %uniques;
    $self->{_total_num_of_docs}++;
}

sub ok_to_filetype {
    my $self = shift;    
    my $filename = shift;
    my ($base, $dir, $suffix) = fileparse($filename, '\..*');
    croak "You called this module without specifying the file types in the constructor"
        unless @{$self->{_file_types}} > 0;
    return 1 if contained_in($suffix, @{$self->{_file_types}});
    return 0;
}

############################## LSA Modeling and Retrieval ################################

sub construct_lsa_model {
    my $self = shift;
    if ($self->{_idf_filter_option}) {
        if (!$self->{_normalized_doc_vecs} and 
                            -s $self->{_normalized_doc_vecs_db}) { 
            $self->{_normalized_doc_vecs} = 
                             retrieve($self->{_normalized_doc_vecs_db});
        }
        foreach (sort keys %{$self->{_normalized_doc_vecs}}) {
            my $term_frequency_vec;
            foreach my $word (sort keys 
                      %{$self->{_normalized_doc_vecs}->{$_}}){
                push @$term_frequency_vec,   
                    $self->{_normalized_doc_vecs}->{$_}->{$word};
            }
            push @{$self->{_term_document_matrix}}, $term_frequency_vec;
        } 
    } else {
        if (!$self->{_corpus_doc_vectors} and -s $self->{_doc_vectors_db}) { 
            $self->{_corpus_doc_vectors} = retrieve($self->{_doc_vectors_db});
        }
        foreach (sort keys %{$self->{_corpus_doc_vectors}}) {
            my $term_frequency_vec;
            foreach my $word (sort keys %{$self->{_corpus_doc_vectors}->{$_}}){
                push @$term_frequency_vec,   
                        $self->{_corpus_doc_vectors}->{$_}->{$word};
            }
            push @{$self->{_term_document_matrix}}, $term_frequency_vec;
        }
    }
    my $A = PDL::Basic::transpose( pdl(@{$self->{_term_document_matrix}}) );
    my ($U,$SIGMA,$V) = svd $A;
    print "LSA: Singular Values SIGMA: " . $SIGMA . "\n" if $self->{_debug};
    print "size of svd SIGMA:  ", $SIGMA->dims, "\n" if $self->{_debug};
    my $index = return_index_of_last_value_above_threshold($SIGMA, 
                                          $self->{_lsa_svd_threshold});
    my $SIGMA_trunc = $SIGMA->slice("0:$index")->sever;
    print "SVD's Truncated SIGMA: " . $SIGMA_trunc . "\n" if $self->{_debug};
    # When you measure the size of a matrix in PDL, the zeroth dimension
    # is considered to be along the horizontal and the one-th dimension
    # along the rows.  This is opposite of how we want to look at
    # matrices.  For a matrix of size MxN, we mean M rows and N columns.
    # With this 'rows x columns' convention for matrix size, if you had
    # to check the size of, say, U matrix, you would call
    #  my @size = ( $U->getdim(1), $U->getdim(0) );
    #  print "\nsize of U: @size\n";
    my $U_trunc = $U->slice("0:$index,:")->sever;
    my $V_trunc = $V->slice("0:$index,0:$index")->sever;    
    $self->{_lsa_vec_truncator} = inv(stretcher($SIGMA_trunc)) x 
                                             PDL::Basic::transpose($U_trunc);
    print "\n\nLSA doc truncator: " . $self->{_lsa_vec_truncator} . "\n\n"
            if $self->{_debug};
    my @sorted_doc_names = $self->{_idf_filter_option} ? 
                       sort keys %{$self->{_normalized_doc_vecs}} :
                       sort keys %{$self->{_corpus_doc_vectors}};
    my $i = 0;
    foreach (@{$self->{_term_document_matrix}}) {
        my $truncated_doc_vec = $self->{_lsa_vec_truncator} x 
                                               PDL::Basic::transpose(pdl($_));
        my $doc_name = $sorted_doc_names[$i++];
        print "\n\nTruncated doc vec for $doc_name: " . 
                 $truncated_doc_vec . "\n" if $self->{_debug};
        $self->{_doc_vecs_trunc_lsa}->{$doc_name} 
                                                 = $truncated_doc_vec;
    }
    chdir $self->{_working_directory};
}

sub retrieve_with_lsa {
    my $self = shift;
    my $query = shift;
    my @clean_words;
    my $min = $self->{_min_word_length};
    if ($self->{_break_camelcased_and_underscored}) {
        my @brokenup = grep $_, split /\W|_|\s+/, "@$query";
        @clean_words = map {$_ =~ /$_regex/g} @brokenup;
        @clean_words = grep $_, map {$_ =~ /([[:lower:]0-9]{$min,})/i;$1?"\L$1":''} @clean_words;
    } else {
        my @brokenup = split /\"|\'|\.|\(|\)|\[|\]|\\|\/|\s+/, "@$query";
        @clean_words = grep $_, map { /([a-z0-9_]{$min,})/i;$1 } @brokenup;
    }
    $query = \@clean_words;
    print "\nYour processed query words are: @$query\n" if $self->{_debug};
    die "Your vocabulary histogram is empty" 
        unless scalar(keys %{$self->{_vocab_hist}});
    die "You must first construct an LSA model" 
        unless scalar(keys %{$self->{_doc_vecs_trunc_lsa}});
    foreach ( keys %{$self->{_vocab_hist}} ) {        
        $self->{_query_vector}->{$_} = 0;    
    }
    foreach (@$query) {
        $self->{_query_vector}->{"\L$_"}++ 
                       if exists $self->{_vocab_hist}->{"\L$_"};
    }
    my @query_word_counts = values %{$self->{_query_vector}};
    my $query_word_count_total = sum(\@query_word_counts);
    die "Query does not contain corpus words. Nothing retrieved."
        unless $query_word_count_total;
    my $query_vec;
    foreach (sort keys %{$self->{_query_vector}}) {
        push @$query_vec, $self->{_query_vector}->{$_};
    }
    print "\n\nQuery vector: @$query_vec\n" if $self->{_debug};
    my $truncated_query_vec = $self->{_lsa_vec_truncator} x 
                                               PDL::Basic::transpose(pdl($query_vec));
    print "\n\nTruncated query vector: " .  $truncated_query_vec . "\n"
                                   if $self->{_debug};                  
    my %retrievals;
    foreach (sort keys %{$self->{_doc_vecs_trunc_lsa}}) {
        my $dot_product = PDL::Basic::transpose($truncated_query_vec)
                     x pdl($self->{_doc_vecs_trunc_lsa}->{$_});
        print "\n\nLSA: dot product of truncated query and\n" .
              "     truncated vec for doc $_ is " . $dot_product->sclr . "\n"
                                        if $self->{_debug};                  
        $retrievals{$_} = $dot_product->sclr if $dot_product->sclr > 0;
    }
    if ($self->{_debug}) {
        print "\n\nShowing LSA retrievals and similarity scores:\n\n";
        foreach (sort {$retrievals{$b} <=> $retrievals{$a}} keys %retrievals) {
            print "$_   =>   $retrievals{$_}\n";
        }
        print "\n\n";
    }
    return \%retrievals;
}

sub _construct_doc_vector {
    my $self = shift;
    my $file = shift;
    my %document_vector = %{deep_copy_hash($self->{_doc_hist_template})};
    foreach ( sort keys %{$self->{_doc_hist_template}} ) {  
        $document_vector{$_} = 0;    
    }
    my $min = $self->{_min_word_length};
    my $total_words_in_doc = 0;
    unless (open IN, $file) {
        print "Unable to open file $file in the corpus: $!\n" 
            if $self->{_debug};
        return;
    }
    while (<IN>) {
        next if /^[ ]*\r?\n?$/;
        $_ =~ s/\r?\n?$//;
        my @brokenup = split /\"|\'|\.|\(|\)|\[|\]|\\|\/|\s+/, $_;
        my @clean_words = grep $_, map { /([a-z0-9_]{$min,})/i;$1 } @brokenup;
        next unless @clean_words;
        @clean_words = grep $_, 
                       map &simple_stemmer($_, $self->{_debug}), @clean_words
                       if $self->{_want_stemming};
        $self->{_case_sensitive} ? 
            map { $document_vector{$_}++ } grep {exists $self->{_vocab_hist}->{$_}} @clean_words :
            map { $document_vector{"\L$_"}++ } 
                                       grep {exists $self->{_vocab_hist}->{"\L$_"}} @clean_words; 
    }
    close IN;
    die "Something went wrong. Doc vector size unequal to vocab size"
        unless $self->{_vocab_size} == scalar(keys %document_vector);
    foreach (keys %document_vector) {        
        $total_words_in_doc += $document_vector{$_};
    }
    my %normalized_doc_vec;
    if ($self->{_idf_filter_option}) {
        foreach (keys %document_vector) {        
            $normalized_doc_vec{$_} = $document_vector{$_}
                                      *
                                      $self->{_idf_t}->{$_}
                                      /
                                      $total_words_in_doc;
        }
    }
    my $pwd = cwd;
    $pwd =~ m{$self->{_corpus_directory}.?(\S*)$};
    my $file_path_name;
    unless ( $1 eq "" ) {
        $file_path_name = "$1/$file";
    } else {
        $file_path_name = $file;
    }
    $self->{_corpus_doc_vectors}->{$file_path_name} = \%document_vector;
    $self->{_normalized_doc_vecs}->{$file_path_name} = \%normalized_doc_vec;
}

###################################   Drop Stop Words  ###################################

sub _drop_stop_words {
    my $self = shift;
    open( IN, "$self->{_working_directory}/$self->{_stop_words_file}")
                     or die "unable to open stop words file: $!";
    while (<IN>) {
        next if /^#/;
        next if /^[ ]*\r?\n?$/;
        $_ =~ s/\r?\n?$//;
        delete $self->{_vocab_hist}->{$_} if exists $self->{_vocab_hist}->{$_};
        unshift @{$self->{_stop_words}}, $_;
    }
}

###################################  Support Methods  ####################################

sub _doc_vec_comparator {
    my $self = shift;
    my %query_vector = %{$self->{_query_vector}};
    my $vec1_hash_ref = $self->{_idf_filter_option} ?
                                $self->{_normalized_doc_vecs}->{$a} :
                                $self->{_corpus_doc_vectors}->{$a};
    my $vec2_hash_ref = $self->{_idf_filter_option} ?
                                $self->{_normalized_doc_vecs}->{$b} :
                                $self->{_corpus_doc_vectors}->{$b};
    my @vec1 = ();
    my @vec2 = ();
    my @qvec = ();
    foreach my $word (sort keys %{$self->{_vocab_hist}}) {
        push @vec1, $vec1_hash_ref->{$word};
        push @vec2, $vec2_hash_ref->{$word};
        push @qvec, $query_vector{$word};
    }
    my $vec1_mag = vec_magnitude(\@vec1);
    my $vec2_mag = vec_magnitude(\@vec2);
    my $qvec_mag = vec_magnitude(\@qvec);
    my $product1 = vec_scalar_product(\@vec1, \@qvec);
    $product1 /= $vec1_mag * $qvec_mag;
    my $product2 = vec_scalar_product(\@vec2, \@qvec);
    $product2 /= $vec2_mag * $qvec_mag;
    return 1 if $product1 < $product2;
    return 0  if $product1 == $product2;
    return -1  if $product1 > $product2;
}

sub _similarity_to_query {
    my $self = shift;
    my $doc_name = shift;
    my $vec_hash_ref = $self->{_idf_filter_option} ?
                          $self->{_normalized_doc_vecs}->{$doc_name} :
                          $self->{_corpus_doc_vectors}->{$doc_name};
    my @vec = ();
    my @qvec = ();
    foreach my $word (sort keys %$vec_hash_ref) {
        push @vec, $vec_hash_ref->{$word};
        push @qvec, $self->{_query_vector}->{$word};
    }
    my $vec_mag = vec_magnitude(\@vec);
    my $qvec_mag = vec_magnitude(\@qvec);
    my $product = vec_scalar_product(\@vec, \@qvec);
    $product /= $vec_mag * $qvec_mag;
    return $product;
}

######################  Relevance Judgments for Testing Purposes   #######################

## IMPORTANT: This estimation of document relevancies to queries is NOT for
##            serious work.  A document is considered to be relevant to a
##            query if it contains several of the query words.  As to the
##            minimum number of query words that must exist in a document
##            in order for the latter to be considered relevant is
##            determined by the relevancy_threshold parameter in the VSM
##            constructor.  (See the relevancy and precision-recall related
##            scripts in the 'examples' directory.)  The reason for why the
##            function shown below is not for serious work is because
##            ultimately it is the humans who are the best judges of the
##            relevancies of documents to queries.  The humans bring to
##            bear semantic considerations on the relevancy determination
##            problem that are beyond the scope of this module.

sub estimate_doc_relevancies {
    my $self = shift;
    die "You did not set the 'query_file' parameter in the constructor"
        unless $self->{_query_file};
    open( IN, $self->{_query_file} )
               or die "unable to open the query file $self->{_query_file}: $!";
    croak "\n\nYou need to specify a name for the relevancy file in \n" .
        " in which the relevancy judgments will be dumped." 
                                 unless  $self->{_relevancy_file};
    while (<IN>) {
        next if /^#/;
        next if /^[ ]*\r?\n?$/;
        $_ =~ s/\r?\n?$//;
        die "Format of query file is not correct" unless /^[ ]*q[0-9]+:/;
        /^[ ]*(q[0-9]+):[ ]*(.*)/;
        my $query_label = $1;
        my $query = $2;
        next unless $query;
        $self->{_queries_for_relevancy}->{$query_label} =  $query;
    }
    if ($self->{_debug}) {
        foreach (sort keys %{$self->{_queries_for_relevancy}}) {
            print "$_   =>   $self->{_queries_for_relevancy}->{$_}\n"; 
        }
    }
    $self->{_scan_dir_for_rels} = 1;
    $self->_scan_directory($self->{_corpus_directory});
    $self->{_scan_dir_for_rels} = 0;
    chdir $self->{_working_directory};
    open(OUT, ">$self->{_relevancy_file}") 
       or die "unable to open the relevancy file $self->{_relevancy_file}: $!";
    my @relevancy_list_for_query;
    foreach (sort 
               {get_integer_suffix($a) <=> get_integer_suffix($b)} 
               keys %{$self->{_relevancy_estimates}}) {    
        @relevancy_list_for_query = 
                        keys %{$self->{_relevancy_estimates}->{$_}};
        print OUT "$_   =>   @relevancy_list_for_query\n\n"; 
        print "Number of relevant docs for query $_: " . 
                         scalar(@relevancy_list_for_query) . "\n";
    }
}

#   If there are available human-supplied relevancy judgments in a disk
#   file, use this script to upload that information.  One of the scripts
#   in the 'examples' directory carries out the precision-recall analysis 
#   by using this approach.  IMPORTANT:  The human-supplied relevancy
#   judgments must be in a format that is shown in the sample file
#   relevancy.txt in the 'examples' directory.
sub upload_document_relevancies_from_file {
    my $self = shift;
    chdir $self->{_working_directory};
    open( IN, $self->{_relevancy_file} )
       or die "unable to open the relevancy file $self->{_relevancy_file}: $!";
    while (<IN>) {
        next if /^#/;
        next if /^[ ]*\r?\n?$/;
        $_ =~ s/\r?\n?$//;
        die "Format of query file is not correct" unless /^[ ]*q[0-9]+[ ]*=>/;
        /^[ ]*(q[0-9]+)[ ]*=>[ ]*(.*)/;
        my $query_label = $1;
        my $relevancy_docs_string = $2;
        next unless $relevancy_docs_string;
        my @relevancy_docs  =  grep $_, split / /, $relevancy_docs_string;
        my %relevancies =     map {$_ => 1} @relevancy_docs;
        $self->{_relevancy_estimates}->{$query_label} = \%relevancies;
    }
    if ($self->{_debug}) {
        for (sort keys %{$self->{_relevancy_estimates}}) {
            my @rels = keys %{$self->{_relevancy_estimates}->{$_}};
            print "$_   =>   @rels\n";
        }
    }
}

sub display_doc_relevancies {
    my $self = shift;
    die "You must first estimate or provide the doc relevancies" 
        unless scalar(keys %{$self->{_relevancy_estimates}});
    print "\nDisplaying relevancy judgments:\n\n";
    foreach my $query (sort keys %{$self->{_relevancy_estimates}}) {
        print "Query $query\n";
        foreach my $file (sort {
                          $self->{_relevancy_estimates}->{$query}->{$b}
                          <=>
                          $self->{_relevancy_estimates}->{$query}->{$a}
                          }
            keys %{$self->{_relevancy_estimates}->{$query}}){
            print "     $file  => $self->{_relevancy_estimates}->{$query}->{$file}\n";
        }
    }
}

sub _scan_file_for_rels {
    my $self = shift;
    my $file = shift;
    open IN, $file;
    my @all_text = <IN>;
    @all_text = grep $_, map {s/[\r]?\n$//; $_;} @all_text;
    my $all_text = join ' ', @all_text;
    foreach my $query (sort keys %{$self->{_queries_for_relevancy}}) {
        my $count = 0;
        my @query_words = grep $_, 
                split /\s+/, $self->{_queries_for_relevancy}->{$query};
        print "Query words for $query:   @query_words\n" if $self->{_debug};
        foreach my $word (@query_words) {
            my @matches = $all_text =~ /$word/gi;
            print "Number of occurrences for word '$word' in file $file: " . 
                scalar(@matches) . "\n" if $self->{_debug};
            $count += @matches if @matches;         
        }
        print "\nRelevancy count for query $query and file $file: $count\n\n"
            if $self->{_debug};
        $self->{_relevancy_estimates}->{$query}->{$file} = $count 
            if $count >= $self->{_relevancy_threshold};
    }
}

#########################   Calculate Precision versus Recall   ##########################

sub precision_and_recall_calculator {
    my $self = shift;
    my $retrieval_type = shift;
    die "You must specify the retrieval type through an argument to the method " .
        "precision_and_recall_calculator().  The retrieval type must either be 'vsm' " .
        "or 'lsa' \n" unless $retrieval_type;
    die "You must first estimate or provide the doc relevancies" 
        unless scalar(keys %{$self->{_relevancy_estimates}});
    unless (scalar(keys %{$self->{_queries_for_relevancy}})) {
        open( IN, $self->{_query_file})
               or die "unable to open the query file $self->{_query_file}: $!";
        while (<IN>) {
            next if /^#/;
            next if /^[ ]*\r?\n?$/;
            $_ =~ s/\r?\n?$//;
            die "Format of query file is not correct" unless /^[ ]*q[0-9]+:/;
            /^[ ]*(q[0-9]+):[ ]*(.*)/;
            my $query_label = $1;
            my $query = $2;
            next unless $query;
            $self->{_queries_for_relevancy}->{$query_label} =  $query;
        }
        if ($self->{_debug}) {
            print "\n\nDisplaying queries in the query file:\n\n";
            foreach (sort keys %{$self->{_queries_for_relevancy}}) {
                print "$_   =>   $self->{_queries_for_relevancy}->{$_}\n"; 
            }
        }
    }
    foreach my $query (sort keys %{$self->{_queries_for_relevancy}}) {
        print "\n\n====================================== query: $query ========================================\n\n"
                    if $self->{_debug};
        print "\n\n\nQuery $query:\n" if $self->{_debug};
        my @query_words = grep $_, 
                split /\s+/, $self->{_queries_for_relevancy}->{$query};
        croak "\n\nYou have not specified the retrieval type for " . 
              "precision-recall calculation.  See code in 'examples'" .
              "directory:" if !defined $retrieval_type;
        my $retrievals;
        eval {
            if ($retrieval_type eq 'vsm') {
                $retrievals = $self->retrieve_with_vsm( \@query_words );
            } elsif ($retrieval_type eq 'lsa') {
                $retrievals = $self->retrieve_with_lsa( \@query_words );
            }
        };
        if ($@) {
            warn "\n\nNo relevant docs found for query $query.\n" .
                 "Will skip over this query for precision and\n" .
                 "recall calculations\n\n";
            next;
        }
        my %ranked_retrievals;
        my $i = 1;
        foreach (sort {$retrievals->{$b} <=> $retrievals->{$a}} 
                                                      keys %$retrievals) {
            $ranked_retrievals{$i++} = $_;
        }      
        if ($self->{_debug}) {
            print "\n\nDisplaying ranked retrievals for query $query:\n\n";
            foreach (sort {$a <=> $b} keys %ranked_retrievals) {
                print "$_  =>   $ranked_retrievals{$_}\n";   
            }      
        }
        #   At this time, ranking of relevant documents based on their
        #   relevancy counts serves no particular purpose since all we want
        #   for the calculation of Precision and Recall are the total
        #   number of relevant documents.  However, I believe such a
        #   ranking will play an important role in the future.
        #   IMPORTANT:  The relevancy judgments are ranked only when
        #               estimated by the method estimate_doc_relevancies()
        #               of the VSM class.  When relevancies are supplied
        #               directly through a disk file, they all carry the
        #               same rank.
        my %ranked_relevancies;
        $i = 1;
        foreach my $file (sort {
                          $self->{_relevancy_estimates}->{$query}->{$b}
                          <=>
                          $self->{_relevancy_estimates}->{$query}->{$a}
                          }
                          keys %{$self->{_relevancy_estimates}->{$query}}) {
            $ranked_relevancies{$i++} = $file;
        }
        if ($self->{_debug}) {
            print "\n\nDisplaying ranked relevancies for query $query:\n\n";
            foreach (sort {$a <=> $b} keys %ranked_relevancies) {
                print "$_  =>   $ranked_relevancies{$_}\n";   
            }      
        }
        my @relevant_set = values %ranked_relevancies;
        warn "\n\nNo relevant docs found for query $query.\n" .
             "Will skip over this query for precision and\n" .
             "recall calculations\n\n" unless @relevant_set;
        next unless @relevant_set;    
        print "\n\nRelevant set for query $query:  @relevant_set\n\n"
            if $self->{_debug};
        # @retrieved is just to find out HOW MANY docs are retrieved. So no sorting needed.  
        my @retrieved; 
        foreach (keys %ranked_retrievals) {
            push @retrieved, $ranked_retrievals{$_};
        }
        print "\n\nRetrieved items (in no particular order) for query $query: @retrieved\n\n"
            if $self->{_debug};
        my @Precision_values = ();
        my @Recall_values = ();
        my $rank = 1;
        while ($rank < @retrieved + 1) {
            my $index = 1;      
            my @retrieved_at_rank = ();
            while ($index <= $rank) {
                push @retrieved_at_rank, $ranked_retrievals{$index};
                $index++;
            }
            my $intersection =set_intersection(\@retrieved_at_rank,
                                               \@relevant_set);
            my $precision_at_rank = @retrieved_at_rank ? 
                                 (@$intersection / @retrieved_at_rank) : 0;
            push @Precision_values, $precision_at_rank;
            my $recall_at_rank = @$intersection / @relevant_set;
            push @Recall_values, $recall_at_rank;
            $rank++;
        }
        print "\n\nFor query $query, precision values: @Precision_values\n"
            if $self->{_debug};
        print "\nFor query $query, recall values: @Recall_values\n"
            if $self->{_debug};      
        $self->{_precision_for_queries}->{$query} = \@Precision_values;
        my $avg_precision;
        $avg_precision += $_ for @Precision_values;        
        $self->{_avg_precision_for_queries}->{$query} += $avg_precision / (1.0 * @Precision_values);
        $self->{_recall_for_queries}->{$query} = \@Recall_values;
    }
    print "\n\n=========  query by query processing for Precision vs. Recall calculations finished  ========\n\n"  
                    if $self->{_debug};
    my @avg_precisions;
    foreach (keys %{$self->{_avg_precision_for_queries}}) {
        push @avg_precisions, $self->{_avg_precision_for_queries}->{$_};
    }
    $self->{_map} += $_ for @avg_precisions;
    $self->{_map} /= scalar keys %{$self->{_queries_for_relevancy}};
}

sub display_average_precision_for_queries_and_map {
    my $self = shift;
    die "You must first invoke precision_and_recall_calculator function" 
        unless scalar(keys %{$self->{_avg_precision_for_queries}});
    print "\n\nDisplaying average precision for different queries:\n\n";
    foreach my $query (sort 
                         {get_integer_suffix($a) <=> get_integer_suffix($b)} 
                         keys %{$self->{_avg_precision_for_queries}}) {
        my $output = sprintf "Query %s  =>   %.3f", 
                 $query, $self->{_avg_precision_for_queries}->{$query};
        print "$output\n";
    }
    print "\n\nMAP value: $self->{_map}\n\n";
}

sub display_precision_vs_recall_for_queries {
    my $self = shift;
    die "You must first invoke precision_and_recall_calculator function" 
        unless scalar(keys %{$self->{_precision_for_queries}});
    print "\n\nDisplaying precision and recall values for different queries:\n\n";
    foreach my $query (sort 
                         {get_integer_suffix($a) <=> get_integer_suffix($b)} 
                         keys %{$self->{_avg_precision_for_queries}}) {
        print "\n\nQuery $query:\n";
        print "\n   (The first value is for rank 1, the second value at rank 2, and so on.)\n\n";
        my @precision_vals = @{$self->{_precision_for_queries}->{$query}};
        @precision_vals = map {sprintf "%.3f", $_} @precision_vals;
        print "   Precision at rank  =>  @precision_vals\n";
        my @recall_vals = @{$self->{_recall_for_queries}->{$query}};
        @recall_vals = map {sprintf "%.3f", $_} @recall_vals;
        print "\n   Recall at rank   =>  @recall_vals\n";
    }
    print "\n\n";
}

sub get_query_sorted_average_precision_for_queries {
    my $self = shift;
    die "You must first invoke precision_and_recall_calculator function" 
        unless scalar(keys %{$self->{_avg_precision_for_queries}});
    my @average_precisions_for_queries = ();
    foreach my $query (sort 
                         {get_integer_suffix($a) <=> get_integer_suffix($b)} 
                         keys %{$self->{_avg_precision_for_queries}}) {
        my $output = sprintf "%.3f", $self->{_avg_precision_for_queries}->{$query};
        push @average_precisions_for_queries, $output;
    }
    return \@average_precisions_for_queries;
}

###################################  Utility Routines  ###################################

sub _check_for_illegal_params {
    my @params = @_;
    my @legal_params = qw / corpus_directory
                            corpus_vocab_db
                            doc_vectors_db
                            normalized_doc_vecs_db
                            use_idf_filter
                            stop_words_file
                            file_types
                            case_sensitive
                            max_number_retrievals
                            query_file
                            relevancy_file
                            min_word_length
                            want_stemming
                            lsa_svd_threshold
                            relevancy_threshold
                            break_camelcased_and_underscored
                            save_model_on_disk
                            debug
                          /;
    my $found_match_flag;
    foreach my $param (@params) {
        foreach my $legal (@legal_params) {
            $found_match_flag = 0;
            if ($param eq $legal) {
                $found_match_flag = 1;
                last;
            }
        }
        last if $found_match_flag == 0;
    }
    return $found_match_flag;
}

# checks whether an element is in an array:
sub contained_in {
    my $ele = shift;
    my @array = @_;
    my $count = 0;
    map {$count++ if $ele eq $_} @array;
    return $count;
}

# Meant only for an un-nested hash:
sub deep_copy_hash {
    my $ref_in = shift;
    my $ref_out = {};
    foreach ( keys %{$ref_in} ) {
        $ref_out->{$_} = $ref_in->{$_};
    }
    return $ref_out;
}

sub vec_scalar_product {
    my $vec1 = shift;
    my $vec2 = shift;
    croak "Something is wrong --- the two vectors are of unequal length"
        unless @$vec1 == @$vec2;
    my $product;
    for my $i (0..@$vec1-1) {
        $product += $vec1->[$i] * $vec2->[$i];
    }
    return $product;
}

sub vec_magnitude {
    my $vec = shift;
    my $mag_squared = 0;
    foreach my $num (@$vec) {
        $mag_squared += $num ** 2;
    }
    return sqrt $mag_squared;
}

sub sum {
    my $vec = shift;
    my $result;
    for my $item (@$vec) {
        $result += $item;
    }
    return $result;
}

sub simple_stemmer {
    my $word = shift;
    my $debug = shift;
    print "\nStemming the word:        $word\n" if $debug;
    $word =~ s/(.*[a-z][^aeious])s$/$1/i;
    $word =~ s/(.*[a-z]s)es$/$1/i;
    $word =~ s/(.*[a-z][ck])es$/$1e/i;
    $word =~ s/(.*[a-z]+)tions$/$1tion/i;
    $word =~ s/(.*[a-z]+)mming$/$1m/i;
    $word =~ s/(.*[a-z]+[^rl])ing$/$1/i;
    $word =~ s/(.*[a-z]+o[sn])ing$/$1e/i;
    $word =~ s/(.*[a-z]+)tices$/$1tex/i;
    $word =~ s/(.*[a-z]+)pes$/$1pe/i;
    $word =~ s/(.*[a-z]+)sed$/$1se/i;
    $word =~ s/(.*[a-z]+)ed$/$1/i;
    $word =~ s/(.*[a-z]+)tation$/$1t/i;
    print "Stemmed word:                           $word\n\n" if $debug;
    return $word;
}

# Assumes the array is sorted in a descending order, as would be the
# case with an array of singular values produced by an SVD algorithm
sub return_index_of_last_value_above_threshold {
    my $pdl_obj = shift;
    my $size = $pdl_obj->getdim(0);
    my $threshold = shift;
    my $lower_bound = $pdl_obj->slice(0)->sclr * $threshold;
    my $i = 0;
    while ($i < $size && $pdl_obj->slice($i)->sclr > $lower_bound) {$i++;}
    return $i-1;
}

sub set_intersection {
    my $set1 = shift;
    my $set2 = shift;
    my %hset1 = map {$_ => 1} @$set1;
    my  @common_elements = grep {$hset1{$_}} @$set2;
    return @common_elements ? \@common_elements : [];
}

sub get_integer_suffix {
    my $label = shift;
    $label =~ /(\d*)$/;
    return $1;
}

1;

=pod

=head1 NAME

Algorithm::VSM --- A Perl module for retrieving files and documents from a software
library with the VSM (Vector Space Model) and LSA (Latent Semantic Analysis)
algorithms in response to search words and phrases.

=head1 SYNOPSIS

  # FOR CONSTRUCTING A VSM MODEL FOR RETRIEVAL:

        use Algorithm::VSM;

        my $corpus_dir = "corpus";
        my @query = qw/ program ListIterator add ArrayList args /;
        my $stop_words_file = "stop_words.txt";  
        my $vsm = Algorithm::VSM->new( 
                            break_camelcased_and_underscored  => 1, 
                            case_sensitive         => 0,
                            corpus_directory       => $corpus_dir,
                            file_types             => ['.txt', '.java'],
                            max_number_retrievals  => 10,
                            min_word_length        => 4,
                            stop_words_file        => $stop_words_file,
                            use_idf_filter         => 1,
                            want_stemming          => 1,
        );
        $vsm->get_corpus_vocabulary_and_word_counts();
        $vsm->display_corpus_vocab();
        $vsm->display_corpus_vocab_size();
        $vsm->write_corpus_vocab_to_file("vocabulary_dump.txt");
        $vsm->display_inverse_document_frequencies();
        $vsm->generate_document_vectors();
        $vsm->display_doc_vectors();
        $vsm->display_normalized_doc_vectors();
        my $retrievals = $vsm->retrieve_for_query_with_vsm( \@query );
        $vsm->display_retrievals( $retrievals );

     The purpose of each constructor option and what is accomplished by the method
     calls should be obvious by their names.  If not, they are explained in greater
     detail elsewhere in this documentation page.  Note that the methods
     display_corpus_vocab() and display_doc_vectors() are there only for testing
     purposes with small corpora.  If you must use them for large libraries/corpora,
     you might wish to redirect the output to a file.

     By default, a call to a constructor calculates normalized term-frequency vectors
     for the documents.  Normalization consists of first calculating the term
     frequency tf(t) of a term t in a document as a proportion of the total numbers
     of words in the document and then multiplying it by idf(t), where idf(t) stands
     for the inverse document frequency associated with that term.  Note that 'word'
     and 'term' mean the same thing.



  # FOR CONSTRUCTING AN LSA MODEL FOR RETRIEVAL:

        my $lsa = Algorithm::VSM->new( 
                            break_camelcased_and_underscored  => 1, 
                            case_sensitive         => 0,
                            corpus_directory       => $corpus_dir,
                            file_types             => ['.txt', '.java'],
                            lsa_svd_threshold      => 0.01, 
                            max_number_retrievals  => 10,
                            min_word_length        => 4,
                            stop_words_file        => $stop_words_file,
                            use_idf_filter         => 1,
                            want_stemming          => 1,
        );
        $lsa->get_corpus_vocabulary_and_word_counts();
        $lsa->display_corpus_vocab();
        $lsa->display_corpus_vocab_size();
        $lsa->write_corpus_vocab_to_file("vocabulary_dump.txt");
        $lsa->generate_document_vectors();
        $lsa->construct_lsa_model();
        my $retrievals = $lsa->retrieve_for_query_with_lsa( \@query );
        $lsa->display_retrievals( $retrievals );

    The initialization code before the constructor call and the calls for displaying
    the vocabulary and the vectors after the call remain the same as for the VSM case
    shown previously in this Synopsis.  In the call above, the constructor parameter
    'lsa_svd_threshold' determines how many of the singular values will be retained
    after we have carried out an SVD decomposition of the term-frequency matrix for
    the documents in the corpus.  Singular values smaller than this threshold
    fraction of the largest value are rejected.



  # FOR MEASURING PRECISION VERSUS RECALL FOR VSM:

        my $corpus_dir = "corpus";   
        my $stop_words_file = "stop_words.txt";  
        my $query_file      = "test_queries.txt";  
        my $relevancy_file   = "relevancy.txt";   # All relevancy judgments
                                                  # will be stored in this file
        my $vsm = Algorithm::VSM->new( 
                            break_camelcased_and_underscored  => 1, 
                            case_sensitive         => 0,
                            corpus_directory       => $corpus_dir,
                            file_types             => ['.txt', '.java'],
                            min_word_length        => 4,
                            query_file             => $query_file,
                            relevancy_file         => $relevancy_file,
                            relevancy_threshold    => 5, 
                            stop_words_file        => $stop_words_file, 
                            want_stemming          => 1,
        );
        $vsm->get_corpus_vocabulary_and_word_counts();
        $vsm->generate_document_vectors();
        $vsm->estimate_doc_relevancies();
        $vsm->display_doc_relevancies();               # used only for testing
        $vsm->precision_and_recall_calculator('vsm');
        $vsm->display_precision_vs_recall_for_queries();
        $vsm->display_average_precision_for_queries_and_map();

      Measuring precision and recall requires a set of queries.  These are supplied
      through the constructor parameter 'query_file'.  The format of the this file
      must be according to the sample file 'test_queries.txt' in the 'examples'
      directory.  The module estimates the relevancies of the documents to the
      queries and dumps the relevancies in a file named by the 'relevancy_file'
      constructor parameter.  The constructor parameter 'relevancy_threshold' is used
      to decide which of the documents are considered to be relevant to a query.  A
      document must contain at least the 'relevancy_threshold' occurrences of query
      words in order to be considered relevant to a query.



  # FOR MEASURING PRECISION VERSUS RECALL FOR LSA:

        my $lsa = Algorithm::VSM->new( 
                            break_camelcased_and_underscored  => 1, 
                            case_sensitive         => 0,
                            corpus_directory       => $corpus_dir,
                            file_types             => ['.txt', '.java'],
                            lsa_svd_threshold      => 0.01,
                            min_word_length        => 4,
                            query_file             => $query_file,
                            relevancy_file         => $relevancy_file,
                            relevancy_threshold    => 5, 
                            stop_words_file        => $stop_words_file, 
                            want_stemming          => 1,
        );
        $lsa->get_corpus_vocabulary_and_word_counts();
        $lsa->generate_document_vectors();
        $lsa->construct_lsa_model();
        $lsa->estimate_doc_relevancies();
        $lsa->display_doc_relevancies();
        $lsa->precision_and_recall_calculator('lsa');
        $lsa->display_precision_vs_recall_for_queries();
        $lsa->display_average_precision_for_queries_and_map();

      We have already explained the purpose of the constructor parameter 'query_file'
      and about the constraints on the format of queries in the file named through
      this parameter.  As mentioned earlier, the module estimates the relevancies of
      the documents to the queries and dumps the relevancies in a file named by the
      'relevancy_file' constructor parameter.  The constructor parameter
      'relevancy_threshold' is used in deciding which of the documents are considered
      to be relevant to a query.  A document must contain at least the
      'relevancy_threshold' occurrences of query words in order to be considered
      relevant to a query.  We have previously explained the role of the constructor
      parameter 'lsa_svd_threshold'.



  # FOR MEASURING PRECISION VERSUS RECALL FOR VSM USING FILE-BASED RELEVANCE JUDGMENTS:

        my $corpus_dir = "corpus";  
        my $stop_words_file = "stop_words.txt";
        my $query_file      = "test_queries.txt";
        my $relevancy_file   = "relevancy.txt";  
        my $vsm = Algorithm::VSM->new( 
                            break_camelcased_and_underscored  => 1, 
                            case_sensitive         => 0,
                            corpus_directory       => $corpus_dir,
                            file_types             => ['.txt', '.java'],
                            min_word_length        => 4,
                            query_file             => $query_file,
                            relevancy_file         => $relevancy_file,
                            stop_words_file        => $stop_words_file, 
                            want_stemming          => 1,
        );
        $vsm->get_corpus_vocabulary_and_word_counts();
        $vsm->generate_document_vectors();
        $vsm->upload_document_relevancies_from_file();  
        $vsm->display_doc_relevancies();
        $vsm->precision_and_recall_calculator('vsm');
        $vsm->display_precision_vs_recall_for_queries();
        $vsm->display_average_precision_for_queries_and_map();

    Now the filename supplied through the constructor parameter 'relevancy_file' must
    contain relevance judgments for the queries that are named in the file supplied
    through the parameter 'query_file'.  The format of these two files must be
    according to what is shown in the sample files 'test_queries.txt' and
    'relevancy.txt' in the 'examples' directory.



  # FOR MEASURING PRECISION VERSUS RECALL FOR LSA USING FILE-BASED RELEVANCE JUDGMENTS:

        my $corpus_dir = "corpus";  
        my $stop_words_file = "stop_words.txt";
        my $query_file      = "test_queries.txt";
        my $relevancy_file   = "relevancy.txt";  
        my $lsa = Algorithm::VSM->new( 
                            break_camelcased_and_underscored  => 1,  
                            case_sensitive      => 0,                
                            corpus_directory    => $corpus_dir,
                            file_types          => ['.txt', '.java'],
                            lsa_svd_threshold   => 0.01,
                            min_word_length     => 4,
                            query_file          => $query_file,
                            relevancy_file      => $relevancy_file,
                            stop_words_file     => $stop_words_file,
                            want_stemming       => 1,                
        );
        $lsa->get_corpus_vocabulary_and_word_counts();
        $lsa->generate_document_vectors();
        $lsa->upload_document_relevancies_from_file();  
        $lsa->display_doc_relevancies();
        $lsa->precision_and_recall_calculator('vsm');
        $lsa->display_precision_vs_recall_for_queries();
        $lsa->display_average_precision_for_queries_and_map();

    As mentioned for the previous code block, the filename supplied through the
    constructor parameter 'relevancy_file' must contain relevance judgments for the
    queries that are named in the file supplied through the parameter 'query_file'.
    The format of this file must be according to what is shown in the sample file
    'relevancy.txt' in the 'examples' directory.  We have already explained the roles
    played by the constructor parameters such as 'lsa_svd_threshold'.



  # FOR MEASURING THE SIMILARITY MATRIX FOR A SET OF DOCUMENTS:

        my $corpus_dir = "corpus";
        my $stop_words_file = "stop_words.txt";
        my $vsm = Algorithm::VSM->new(
                   break_camelcased_and_underscored  => 1,  
                   case_sensitive           => 0,           
                   corpus_directory         => $corpus_dir,
                   file_types               => ['.txt', '.java'],
                   min_word_length          => 4,
                   stop_words_file          => $stop_words_file,
                   want_stemming            => 1,           
        );
        $vsm->get_corpus_vocabulary_and_word_counts();
        $vsm->generate_document_vectors();
        # code for calculating pairwise similarities as shown in the
        # script calculate_similarity_matrix_for_all_docs.pl in the
        # examples directory.  This script makes calls to
        #
        #   $vsm->pairwise_similarity_for_docs($docs[$i], $docs[$j]);        
        #
        # for every pair of documents.

=head1 CHANGES

Version 1.70: All of the changes made in this version affect only that part of the
module that is used for calculating precision-vs.-recall curve for the estimation of
MAP (Mean Average Precision).  The new formulas that go into estimating MAP are
presented in the author's tutorial on significance testing.  Additionally, when
estimating the average retrieval precision for a query, this version explicitly
disregards all documents that have zero similarity with the query.

Version 1.62 removes the Perl version restriction on the module. This version also
fixes two bugs, one in the file scanner code and the other in the
precision-and-recall calculator.  The file scanner bug was related to the new
constructor parameter C<case_sensitive> that was introduced in Version 1.61.  And the
precision-and-recall calculator bug was triggered if a query consisted solely of
non-vocabulary words.

Version 1.61 improves the implementation of the directory scanner to make it more
platform independent.  Additionally, you are now required to specify in the
constructor call the file types to be considered for computing the database model.
If, say, you have a large software library and you want only Java and text files to
be scanned for creating the VSM (or the LSA) model, you must supply that information
to the module by setting the constructor parameter C<file_types> to the anonymous
list C<['.java', '.txt']>.  An additional constructor parameter introduced in this
version is C<case_sensitive>.  If you set it to 1, that will force the database model
and query matching to become case sensitive.

Version 1.60 reflects the fact that people are now more likely to use this module by
keeping the model constructed for a corpus in the fast memory (as opposed to storing
the models in disk-based hash tables) for its repeated invocation for different
queries.  As a result, the default value for the constructor option
C<save_model_on_disk> was changed from 1 to 0.  For those who still wish to store on
a disk the model that is constructed, the script
C<retrieve_with_VSM_and_also_create_disk_based_model.pl> shows how you can do that.
Other changes in 1.60 include a slight reorganization of the scripts in the
C<examples> directory.  Most scripts now do not by default store their models in
disk-based hash tables.  This reorganization is reflected in the description of the
C<examples> directory in this documentation.  The basic logic of constructing VSM and
LSA models and how these are used for retrievals remains unchanged.

Version 1.50 incorporates a couple of new features: (1) You now have the option to
split camel-cased and underscored words for constructing your vocabulary set; and (2)
Storing the VSM and LSA models in database files on the disk is now optional.  The
second feature, in particular, should prove useful to those who are using this module
for large collections of documents.

Version 1.42 includes two new methods, C<display_corpus_vocab_size()> and
C<write_corpus_vocab_to_file()>, for those folks who deal with very large datasets.
You can get a better sense of the overall vocabulary being used by the module for
file retrieval by examining the contents of a dump file whose name is supplied as an
argument to C<write_corpus_vocab_to_file()>.

Version 1.41 downshifts the required version of the PDL module. Also cleaned up are
the dependencies between this module and the submodules of PDL.

Version 1.4 makes it easier for a user to calculate a similarity matrix over all the
documents in the corpus. The elements of such a matrix express pairwise similarities
between the documents.  The pairwise similarities are based on the dot product of two
document vectors divided by the product of the vector magnitudes.  The 'examples'
directory contains two scripts to illustrate how such matrices can be calculated by
the user.  The similarity matrix is output as a CSV file.

Version 1.3 incorporates IDF (Inverse Document Frequency) weighting of the words in a
document file. What that means is that the words that appear in most of the documents
get reduced weighting since such words are non-discriminatory with respect to the
retrieval of the documents. A typical formula that is used to calculate the IDF
weight for a word is the logarithm of the ratio of the total number of documents to
the number of documents in which the word appears.  So if a word were to appear in
all the documents, its IDF multiplier would be zero in the vector representation of a
document.  If so desired, you can turn off the IDF weighting of the words by
explicitly setting the constructor parameter C<use_idf_filter> to zero.

Version 1.2 includes a code correction and some general code and documentation
cleanup.

With Version 1.1, you can access the retrieval precision results so that you can
compare two different retrieval algorithms (VSM or LSA with different choices for
some of the constructor parameters) with significance testing. (Version 1.0 merely
sent those results to standard output, typically your terminal window.)  In Version
1.1, the new script B<significance_testing.pl> in the 'examples' directory
illustrates significance testing with Randomization and with Student's Paired t-Test.

=head1 DESCRIPTION

B<Algorithm::VSM> is a I<perl5> module for constructing a Vector Space Model (VSM) or
a Latent Semantic Analysis Model (LSA) of a collection of documents, usually referred
to as a corpus, and then retrieving the documents in response to search words in a
query.

VSM and LSA models have been around for a long time in the Information Retrieval (IR)
community.  More recently such models have been shown to be effective in retrieving
files/documents from software libraries. For an account of this research that was
presented by Shivani Rao and the author of this module at the 2011 Mining Software
Repositories conference, see L<http://portal.acm.org/citation.cfm?id=1985451>.

VSM modeling consists of: (1) Extracting the vocabulary used in a corpus.  (2)
Stemming the words so extracted and eliminating the designated stop words from the
vocabulary.  Stemming means that closely related words like 'programming' and
'programs' are reduced to the common root word 'program' and the stop words are the
non-discriminating words that can be expected to exist in virtually all the
documents. (3) Constructing document vectors for the individual files in the corpus
--- the document vectors taken together constitute what is usually referred to as a
'term-frequency' matrix for the corpus. (4) Normalizing the document vectors to
factor out the effect of document size and, if desired, multiplying the term
frequencies by the IDF (Inverse Document Frequency) values for the words to reduce
the weight of the words that appear in a large number of documents. (5) Constructing
a query vector for the search query after the query is subject to the same stemming
and stop-word elimination rules that were applied to the corpus. And, lastly, (6)
Using a similarity metric to return the set of documents that are most similar to the
query vector.  The commonly used similarity metric is one based on the cosine
distance between two vectors.  Also note that all the vectors mentioned here are of
the same size, the size of the vocabulary.  An element of a vector is the frequency
of occurrence of the word corresponding to that position in the vector.

LSA modeling is a small variation on VSM modeling.  Now you take VSM modeling one
step further by subjecting the term-frequency matrix for the corpus to singular value
decomposition (SVD).  By retaining only a subset of the singular values (usually the
N largest for some value of N), you can construct reduced-dimensionality vectors for
the documents and the queries.  In VSM, as mentioned above, the size of the document
and the query vectors is equal to the size of the vocabulary.  For large corpora,
this size may involve tens of thousands of words --- this can slow down the VSM
modeling and retrieval process.  So you are very likely to get faster performance
with retrieval based on LSA modeling, especially if you store the model once
constructed in a database file on the disk and carry out retrievals using the
disk-based model.


=head1 CAN THIS MODULE BE USED FOR GENERAL TEXT RETRIEVAL?

This module has only been tested for software retrieval.  For more general text
retrieval, you would need to replace the simple stemmer used in the module by one
based on, say, Porter's Stemming Algorithm.  You would also need to vastly expand the
list of stop words appropriate to the text corpora of interest to you. As previously
mentioned, the stop words are the commonly occurring words that do not carry much
discriminatory power from the standpoint of distinguishing between the documents.
See the file 'stop_words.txt' in the 'examples' directory for how such a file must be
formatted.


=head1 HOW DOES ONE DEAL WITH VERY LARGE LIBRARIES/CORPORA?

It is not uncommon for large software libraries to consist of tens of thousands of
documents that include source-code files, documentation files, README files,
configuration files, etc.  The bug-localization work presented recently by Shivani
Rao and this author at the 2011 Mining Software Repository conference (MSR11) was
based on a relatively small iBUGS dataset involving 6546 documents and a vocabulary
size of 7553 unique words. (Here is a link to this work:
L<http://portal.acm.org/citation.cfm?id=1985451>.  Also note that the iBUGS dataset
was originally put together by V. Dallmeier and T. Zimmermann for the evaluation of
automated bug detection and localization tools.)  If C<V> is the size of the
vocabulary and C<M> the number of the documents in the corpus, the size of each
vector will be C<V> and size of the term-frequency matrix for the entire corpus will
be C<V>xC<M>.  So if you were to duplicate the bug localization experiments in
L<http://portal.acm.org/citation.cfm?id=1985451> you would be dealing with vectors of
size 7553 and a term-frequency matrix of size 7553x6546.  Extrapolating these numbers
to really large libraries/corpora, we are obviously talking about very large matrices
for SVD decomposition.  For large libraries/corpora, it would be best to store away
the model in a disk file and to base all subsequent retrievals on the disk-stored
models.  The 'examples' directory contains scripts that carry out retrievals on the
basis of disk-based models.  Further speedup in retrieval can be achieved by using
LSA to create reduced-dimensionality representations for the documents and by basing
retrievals on the stored versions of such reduced-dimensionality representations.


=head1 ESTIMATING RETRIEVAL PERFORMANCE WITH PRECISION VS. RECALL CALCULATIONS

The performance of a retrieval algorithm is typically measured by two properties:
C<Precision at rank> and C<Recall at rank>.  As mentioned in my tutorial
L<https://engineering.purdue.edu/kak/Tutorials/SignificanceTesting.pdf>, at a given
rank C<r>, C<Precision> is the ratio of the number of retrieved documents that are
relevant to the total number of retrieved documents up to that rank.  And, along the
same lines, C<Recall> at a given rank C<r> is the ratio of the number of retrieved
documents that are relevant to the total number of relevant documents.  The Average
Precision associated with a query is the average of all the Precision-at-rank values
for all the documents relevant to that query.  When query specific Average Precision
is averaged over all the queries, you get Mean Average Precision (MAP) as a
single-number characterizer of the retrieval power of an algorithm for a given
corpus.  For an oracle, the value of MAP should be 1.0.  On the other hand, for
purely random retrieval from a corpus, the value of MAP will be inversely
proportional to the size of the corpus.  (See the discussion in
L<https://engineering.purdue.edu/kak/Tutorials/SignificanceTesting.pdf> for further
explanation on these retrieval precision evaluators.)  

This module includes methods that allow you to carry out these retrieval accuracy
measurements using the relevancy judgments supplied through a disk file.  If
human-supplied relevancy judgments are not available, the module will be happy to
estimate relevancies for you just by determining the number of query words that exist
in a document.  Note, however, that relevancy judgments estimated in this manner
cannot be trusted. That is because ultimately it is the humans who are the best
judges of the relevancies of documents to queries.  The humans bring to bear semantic
considerations on the relevancy determination problem that are beyond the scope of
this module.


=head1 METHODS

The module provides the following methods for constructing VSM and LSA models of a
corpus, for using the models thus constructed for retrieval, and for carrying out
precision versus recall calculations for the determination of retrieval accuracy on
the corpora of interest to you.

=over

=item B<new():>

A call to C<new()> constructs a new instance of the C<Algorithm::VSM> class:

    my $vsm = Algorithm::VSM->new( 
                     break_camelcased_and_underscored  => 1, 
                     case_sensitive         => 0,
                     corpus_directory       => "",
                     corpus_vocab_db        => "corpus_vocab_db",
                     doc_vectors_db         => "doc_vectors_db",
                     file_types             => $my_file_types,
                     lsa_svd_threshold      => 0.01, 
                     max_number_retrievals  => 10,
                     min_word_length        => 4,
                     normalized_doc_vecs_db => "normalized_doc_vecs_db",
                     query_file             => "",  
                     relevancy_file         => $relevancy_file,
                     relevancy_threshold    => 5, 
                     save_model_on_disk     => 0,  
                     stop_words_file        => "", 
                     use_idf_filter         => 1,
                     want_stemming          => 1,
              );       

The values shown on the right side of the big arrows are the B<default values for the
parameters>.  The value supplied through the variable C<$my_file_types> would be
something like C<['.java', '.txt']> if, say, you wanted only Java and text files to
be included in creating the database model.  The following nested list will now
describe each of the constructor parameters shown above:

=over 16

=item I<break_camelcased_and_underscored:>

The parameter B<break_camelcased_and_underscored> when set causes the
underscored and camel-cased words to be split.  By default the parameter is
set.  So if you don't want such words to be split, you must set it
explicitly to 0.

=item I<case_sensitive:>

When set to 1, this parameter forces the module to maintain the case of the terms in
the corpus files when creating the vocabulary and the document vectors.  Setting
C<case_sensitive> to 1 also causes the query matching to become case sensitive.
(This constructor parameter was introduced in Version 1.61.)

=item I<corpus_directory:>

The parameter B<corpus_directory> points to the root of the directory of documents
for which you want to create a VSM or LSA model.

=item I<corpus_vocab_db:>

The parameter B<corpus_vocab_db> is for naming the DBM in which the corpus vocabulary
will be stored after it is subject to stemming and the elimination of stop words.
Once a disk-based VSM model is created and stored away in the file named by this
parameter and the parameter to be described next, it can subsequently be used
directly for speedier retrieval.

=item I<doc_vectors_db:>

The database named by B<doc_vectors_db> stores the document vector representation for
each document in the corpus.  Each document vector has the same size as the
corpus-wide vocabulary; each element of such a vector is the number of occurrences of
the word that corresponds to that position in the vocabulary vector.

=item I<file_types:>

This parameter tells the module what types of files in the corpus directory you want
scanned for creating the database model. The value supplied for this parameter is an
anonymous list of the file suffixes for the file types.  For example, if you wanted
only Java and text files to be scanned, you will set this parameter to C<['.java',
'.txt']>.  The module throws an exception if this parameter is left unspecified.
(This constructor parameter was introduced in Version 1.61.)

=item I<lsa_svd_threshold:>

The parameter B<lsa_svd_threshold> is used for rejecting singular values that are
smaller than this threshold fraction of the largest singular value.  This plays a
critical role in creating reduced-dimensionality document vectors in LSA modeling of
a corpus.

=item I<max_number_retrievals:>

The constructor parameter B<max_number_retrievals> stands for what it means.

=item I<min_word_length:> 

The parameter B<min_word_length> sets the minimum number of characters in a
word in order for it to be included in the corpus vocabulary.

=item I<normalized_doc_vecs_db:>

The database named by B<normalized_doc_vecs_db> stores the normalized document
vectors.  Normalization consists of factoring out the size of the documents by
dividing the term frequency for each word in a document by the number of words in the
document, and then multiplying the result by the idf (Inverse Document Frequency)
value for the word.

=item I<query_file:>

The parameter B<query_file> points to a file that contains the queries to be used for
calculating retrieval performance with C<Precision> and C<Recall> numbers. The format
of the query file must be as shown in the sample file C<test_queries.txt> in the
'examples' directory.

=item I<relevancy_file:> 

This option names the disk file for storing the relevancy judgments.

=item I<relevancy_threshold:> 

The constructor parameter B<relevancy_threshold> is used for automatic determination
of document relevancies to queries on the basis of the number of occurrences of query
words in a document.  You can exercise control over the process of determining
relevancy of a document to a query by giving a suitable value to the constructor
parameter B<relevancy_threshold>.  A document is considered relevant to a query only
when the document contains at least B<relevancy_threshold> number of query words.

=item I<save_model_on_disk:>

The constructor parameter B<save_model_on_disk> will cause the basic
information about the VSM and the LSA models to be stored on the disk.
Subsequently, any retrievals can be carried out from the disk-based model.

=item I<stop_words_file:>

The parameter B<stop_words_file> is for naming the file that contains the stop words
that you do not wish to include in the corpus vocabulary.  The format of this file
must be as shown in the sample file C<stop_words.txt> in the 'examples' directory.

=item I<use_idf_filter:>

The constructor parameter B<use_idf_filter> is set by default.  If you want
to turn off the normalization of the document vectors, including turning
off the weighting of the term frequencies of the words by their idf values,
you must set this parameter explicitly to 0.

=item I<want_stemming:>

The boolean parameter B<want_stemming> determines whether or not the words extracted
from the documents would be subject to stemming.  As mentioned elsewhere, stemming
means that related words like 'programming' and 'programs' would both be reduced to
the root word 'program'.

=back

=begin html

<br>

=end html

=item B<construct_lsa_model():>

You call this subroutine for constructing an LSA model for your corpus
after you have extracted the corpus vocabulary and constructed document
vectors:

    $vsm->construct_lsa_model();

The SVD decomposition that is carried out in LSA model construction uses the
constructor parameter C<lsa_svd_threshold> to decide how many of the singular values
to retain for the LSA model.  A singular is retained only if it is larger than the
C<lsa_svd_threshold> fraction of the largest singular value.


=item B<display_average_precision_for_queries_and_map():>

The Average Precision for a query is the average of the Precision-at-rank values
associated with each of the corpus documents relevant to the query.  The mean of the
Average Precision values for all the queries is the Mean Average Precision (MAP).
The C<Average Precision> values for the queries and the overall C<MAP> can be printed
out by calling

    $vsm->display_average_precision_for_queries_and_map();


=item B<display_corpus_vocab():>

If you would like to see corpus vocabulary as constructed by the previous call, make
the call

    $vsm->display_corpus_vocab();

Note that this is a useful thing to do only on small test corpora. If you need
to examine the vocabulary for a large corpus, call the two methods listed below.


=item B<display_corpus_vocab_size():>

If you would like for the module to print out in your terminal window the size of the
vocabulary, make the call

    $vsm->display_corpus_vocab_size();


=item B<display_doc_relevancies():>

If you would like to see the document relevancies generated by the previous method,
you can call

    $vsm->display_doc_relevancies()


=item B<display_doc_vectors():>

If you would like to see the document vectors constructed by the previous call, make
the call:

    $vsm->display_doc_vectors();

Note that this is a useful thing to do only on small test corpora. If you must call
this method on a large corpus, you might wish to direct the output to a file.  


=item B<display_inverse_document_frequencies():>

You can display the idf value associated with each word in the corpus by

    $vsm->display_inverse_document_frequencies();

The idf of a word in the corpus is calculated typically as the logarithm of the ratio
of the total number of documents in the corpus to the number of documents in which
the word appears (with protection built in to prevent division by zero).  Ideally, if
a word appears in all the documents, its idf would be small, close to zero. Words
with small idf values are non-discriminatory and should get reduced weighting in
document retrieval.


=item B<display_normalized_doc_vectors():>

If you would like to see the normalized document vectors, make the call:

    $vsm->display_normalized_doc_vectors();

See the comment made previously as to what is meant by the normalization of a
document vector.


=item B<display_precision_vs_recall_for_queries():>

A call to C<precision_and_recall_calculator()> will normally be followed by the
following call

    $vsm->display_precision_vs_recall_for_queries();

for displaying the C<Precision@rank> and C<Recall@rank> values.


=item B<display_retrievals( $retrievals ):>

You can display the retrieved document names by calling this method using the syntax:

    $vsm->display_retrievals( $retrievals );

where C<$retrievals> is a reference to the hash returned by a call to one of the
C<retrieve> methods.  The display method shown here respects the retrieval size
constraints expressed by the constructor parameter C<max_number_retrievals>.


=item B<estimate_doc_relevancies():>

Before you can carry out precision and recall calculations to test the accuracy of
VSM and LSA based retrievals from a corpus, you need to have available the relevancy
judgments for the queries.  (A relevancy judgment for a query is simply the list of
documents relevant to that query.)  Relevancy judgments are commonly supplied by the
humans who are familiar with the corpus.  But if such human-supplied relevance
judgments are not available, you can invoke the following method to estimate them:

    $vsm->estimate_doc_relevancies();

For the above method call, a document is considered to be relevant to a query if it
contains several of the query words.  As to the minimum number of query words that
must exist in a document in order for the latter to be considered relevant, that is
determined by the C<relevancy_threshold> parameter in the VSM constructor.

But note that this estimation of document relevancies to queries is NOT for serious
work.  The reason for that is because ultimately it is the humans who are the best
judges of the relevancies of documents to queries.  The humans bring to bear semantic
considerations on the relevancy determination problem that are beyond the scope of
this module.

The generated relevancies are deposited in a file named by the constructor parameter
C<relevancy_file>.


=item B<get_all_document_names():>

If you want to get hold of all the filenames in the corpus in your own script, you
can call

    my @docs = @{$vsm->get_all_document_names()};

The array on the left will contain an alphabetized list of the files.


=item B<generate_document_vectors():>

This is a necessary step after the vocabulary used by a corpus is constructed. (Of
course, if you will be doing document retrieval through a disk-stored VSM or LSA
model, then you do not need to call this method.  You construct document vectors
through the following call:

    $vsm->generate_document_vectors();


=item B<get_corpus_vocabulary_and_word_counts():>

After you have constructed a new instance of the C<Algorithm::VSM> class, you must
now scan the corpus documents for constructing the corpus vocabulary. This you do by:

    $vsm->get_corpus_vocabulary_and_word_counts();

The only time you do NOT need to call this method is when you are using a previously
constructed disk-stored VSM model for retrieval.


=item B<get_query_sorted_average_precision_for_queries():>

If you want to run significance tests on the retrieval accuracies you obtain on a
given corpus and with different algorithms (VSM or LSA with different choices for the
constructor parameters), your own script would need access to the average precision
data for a set of queries. You can get hold of this data by calling

    $vsm->get_query_sorted_average_precision_for_queries();

The script C<significance_testing.pl> in the 'examples' directory shows how you can
use this method for significance testing.


=item B<pairwise_similarity_for_docs():>

=item B<pairwise_similarity_for_normalized_docs():>

If you would like to compare in your own script any two documents in the corpus, you
can call

    my $similarity = $vsm->pairwise_similarity_for_docs("filename_1", "filename_2");
or
    my $similarity = $vsm->pairwise_similarity_for_normalized_docs("filename_1", "filename_2");

Both these calls return a number that is the dot product of the two document vectors
normalized by the product of their magnitudes.  The first call uses the regular
document vectors and the second the normalized document vectors.


=item B<precision_and_recall_calculator():>

After you have created or obtained the relevancy judgments for your test queries, you
can make the following call to calculate C<Precision@rank> and C<Recall@rank>:

    $vsm->precision_and_recall_calculator('vsm');
or 
    $vsm->precision_and_recall_calculator('lsa');

depending on whether you are testing VSM-based retrieval or LSA-based retrieval.

=item B<retrieve_with_lsa():>

After you have built an LSA model through the call to C<construct_lsa_model()>, you
can retrieve the document names most similar to the query by:

    my $retrievals = $vsm->retrieve_with_lsa( \@query );

Subsequently, you can display the retrievals by calling the
C<display_retrievals($retrieval)> method described previously.


=item B<retrieve_with_vsm():>

After you have constructed a VSM model, you call this method for document retrieval
for a given query C<@query>.  The call syntax is:

    my $retrievals = $vsm->retrieve_with_vsm( \@query );

The argument, C<@query>, is simply a list of words that you wish to use for
retrieval. The method returns a hash whose keys are the document names and whose
values the similarity distance between the document and the query.  As is commonly
the case with VSM, this module uses the cosine similarity distance when comparing a
document vector with the query vector.


=item B<upload_document_relevancies_from_file():>

When human-supplied relevancies are available, you can upload them into the program
by calling

    $vsm->upload_document_relevancies_from_file();

These relevance judgments will be read from a file that is named with the
C<relevancy_file> constructor parameter.


=item B<upload_normalized_vsm_model_from_disk():>

When you invoke the methods C<get_corpus_vocabulary_and_word_counts()> and
C<generate_document_vectors()>, that automatically deposits the VSM model in the
database files named with the constructor parameters C<corpus_vocab_db>,
C<doc_vectors_db> and C<normalized_doc_vecs_db>.  Subsequently, you can carry out
retrieval by directly using this disk-based VSM model for speedier performance.  In
order to do so, you must upload the disk-based model by

    $vsm->upload_normalized_vsm_model_from_disk();

Subsequently you call 

    my $retrievals = $vsm->retrieve_with_vsm( \@query );
    $vsm->display_retrievals( $retrievals );

for retrieval and for displaying the results.  


=item B<write_corpus_vocab_to_file():>

This is the method to call for large text corpora if you would like to examine the
vocabulary created. The call syntax is

    $vsm->write_corpus_vocab_to_file($filename);

where C<$filename> is the name of the file that you want the vocabulary to be written
out to.  This call will also show the frequency of each vocabulary word in your
corpus.


=back


=head1 REQUIRED

This module requires the following modules:

    SDBM_File
    Storable
    PDL
    File::Basename
    File::Spec::Functions

The first two of these are needed for creating disk-based database records for the
VSM and LSA models.  The third is needed for calculating the SVD of the
term-frequency matrix. (PDL stands for Perl Data Language.)  The last two are needed
by the directory scanner to make pathnames platform independent.

=head1 EXAMPLES

See the 'examples' directory in the distribution for the scripts listed below:

=over

=item B<For Basic VSM-Based Retrieval:>

For basic VSM-based model construction and retrieval, run the script:

    retrieve_with_VSM.pl

Starting with version 1.60, this script does not store away the VSM model in
disk-based hash tables.  If you want your model to be stored on the disk, you must
run the script C<retrieve_with_VSM_and_also_create_disk_based_model.pl> for that.

=item B<For a Continuously Running VSM-Based Search Engine for Repeated Retrievals:>

If you want to run an infinite loop for repeated retrievals from a VSM model, run the
script

    continuously_running_VSM_retrieval_engine.pl

You can create a script similar to this for doing the same with LSA models.

=item B<For Storing the Model Information in Disk-Based Hash Tables:>

For storing the model information in disk-based DBM files that can subsequently be
used for both VSM and LSA retrieval, run the script:

    retrieve_with_VSM_and_also_create_disk_based_model.pl

=item B<For Basic LSA-Based Retrieval:>

For basic LSA-based model construction and retrieval, run the script:

    retrieve_with_LSA.pl

Starting with version 1.60, this script does not store away the model information in
disk-based hash tables.  If you want your model to be stored on the disk, you must
run the script C<retrieve_with_VSM_and_also_create_disk_based_model.pl> for that.

=item B<For VSM-Based Retrieval with a Disk-Stored Model:>

If you have previously run a script like
C<retrieve_with_VSM_and_also_create_disk_based_model.pl>, you can run the script

    retrieve_with_disk_based_VSM.pl

for repeated VSM-based retrievals from a disk-based model.

=item B<For LSA-Based Retrieval with a Disk-Stored Model:>

If you have previously run a script like
C<retrieve_with_VSM_and_also_create_disk_based_model.pl>, you can run the script

    retrieve_with_disk_based_LSA.pl

for repeated LSA-based retrievals from a disk-based model.

=item B<For Precision and Recall Calculations with VSM:>

To experiment with precision and recall calculations for VSM retrieval, run the
script:

    calculate_precision_and_recall_for_VSM.pl

Note that this script will carry out its own estimation of relevancy judgments ---
which in most cases would not be a safe thing to do.

=item B<For Precision and Recall Calculations with LSA:>

To experiment with precision and recall calculations for LSA retrieval, run the
script:

    calculate_precision_and_recall_for_LSA.pl

Note that this script will carry out its own estimation of relevancy judgments ---
which in most cases would not be a safe thing to do.

=item B<For Precision and Recall Calculations for VSM with
Human-Supplied Relevancies:>

Precision and recall calculations for retrieval accuracy determination are best
carried out with human-supplied judgments of relevancies of the documents to queries.
If such judgments are available, run the script:

    calculate_precision_and_recall_from_file_based_relevancies_for_VSM.pl

This script will print out the average precisions for the different test queries and
calculate the MAP metric of retrieval accuracy.

=item B<For Precision and Recall Calculations for LSA with
Human-Supplied Relevancies:>

If human-supplied relevancy judgments are available and you wish to experiment with
precision and recall calculations for LSA-based retrieval, run the script:

    calculate_precision_and_recall_from_file_based_relevancies_for_LSA.pl

This script will print out the average precisions for the different test queries and
calculate the MAP metric of retrieval accuracy.

=item B<To carry out significance tests on the retrieval precision results with
Randomization or with Student's Paired t-Test:>

    significance_testing.pl  randomization

or

    significance_testing.pl  t-test

Significance testing consists of forming a null hypothesis that the two retrieval
algorithms you are considering are the same from a black-box perspective and then
calculating what is known as a C<p-value>.  If the C<p-value> is less than, say,
0.05, you reject the null hypothesis.

=item B<To calculate a similarity matrix for all the documents in your corpus:>

    calculate_similarity_matrix_for_all_docs.pl

or

    calculate_similarity_matrix_for_all_normalized_docs.pl

The former uses regular document vectors for calculating the similarity between every
pair of documents in the corpus. And the latter uses normalized document vectors for
the same purpose.  The document order used for row and column indexing of the matrix
corresponds to the alphabetic ordering of the document names in the corpus directory.

=back


=head1 EXPORT

None by design.

=head1 SO THAT YOU DO NOT LOSE RELEVANCY JUDGMENTS

You have to be careful when carrying out Precision verses Recall calculations if you
do not wish to lose the previously created relevancy judgments. Invoking the method
C<estimate_doc_relevancies()> in your own script will cause the file C<relevancy.txt>
to be overwritten.  If you have created a relevancy database and stored it in a file
called, say, C<relevancy.txt>, you should make a backup copy of this file before
executing a script that calls C<estimate_doc_relevancies()>.

=head1 BUGS

Please notify the author if you encounter any bugs.  When sending email, please place
the string 'VSM' in the subject line to get past my spam filter.

=head1 INSTALLATION

Download the archive from CPAN in any directory of your choice.  Unpack the archive
with a command that on a Linux machine would look like:

    tar zxvf Algorithm-VSM-1.70.tar.gz

This will create an installation directory for you whose name will be
C<Algorithm-VSM-1.70>.  Enter this directory and execute the following commands for a
standard install of the module if you have root privileges:

    perl Makefile.PL
    make
    make test
    sudo make install

If you do not have root privileges, you can carry out a non-standard install the
module in any directory of your choice by:

    perl Makefile.PL prefix=/some/other/directory/
    make
    make test
    make install

With a non-standard install, you may also have to set your PERL5LIB environment
variable so that this module can find the required other modules. How you do that
would depend on what platform you are working on.  In order to install this module in
a Linux machine on which I use tcsh for the shell, I set the PERL5LIB environment
variable by

    setenv PERL5LIB /some/other/directory/lib64/perl5/:/some/other/directory/share/perl5/

If I used bash, I'd need to declare:

    export PERL5LIB=/some/other/directory/lib64/perl5/:/some/other/directory/share/perl5/


=head1 THANKS

Many thanks are owed to Shivani Rao and Bunyamin Sisman for sharing with me their
deep insights in IR.  Version 1.4 was prompted by Zahn Bozanic's interest in
similarity matrix characterization of a corpus. Thanks, Zahn!  

Several of the recent changes to the module are a result of the feedback I have
received from Naveen Kulkarni of Infosys Labs. Thanks, Naveen!

Version 1.62 was a result of Slaven Rezic's recommendation that I remove the Perl
version restriction on the module since he was able to run it with Perl version
5.8.9.  Another important reason for v. 1.62 was the discovery of the two bugs
mentioned in Changes, one of them brought to my attention by Naveen Kulkarni.

=head1 AUTHOR

The author, Avinash Kak, recently finished a 17-year long "Objects Trilogy" project
with the publication of the book "B<Designing with Objects>" by John-Wiley.  If
interested, check out his web page at Purdue to find out what the Objects Trilogy
project was all about.  You might like "B<Designing with Objects>" especially if you
enjoyed reading Harry Potter as a kid (or even as an adult, for that matter).  The
other two books in the trilogy are "B<Programming with Objects>" and "B<Scripting
with Objects>".

For all issues related to this module, contact the author at C<kak@purdue.edu>

If you send email, please place the string "VSM" in your subject line to get past the
author's spam filter.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

 Copyright 2015 Avinash Kak

=cut


