package Algorithm::TicketClusterer;

#---------------------------------------------------------------------------
# Copyright (c) 2014 Avinash Kak. All rights reserved.  This program is
# free software.  You may modify and/or distribute it under the same terms
# as Perl itself.  This copyright notice must remain attached to the file.
#
# Algorithm::TicketClusterer is a Perl module for retrieving Excel-stored
# past tickets that are most similar to a new ticket.  Tickets are commonly
# used in software services industry and customer support businesses to
# record requests for service, product complaints, user feedback, and so
# on.
# ---------------------------------------------------------------------------

use 5.10.0;
use strict;
use warnings;
use Carp;
use Storable;
use Spreadsheet::ParseExcel;
use Spreadsheet::XLSX;
use WordNet::QueryData;
use Text::Iconv;
use SDBM_File;
use Fcntl;

our $VERSION = '1.01';

############################### The Constructor #############################

sub new { 
    my ($class, %args) = @_;
    my @params = keys %args;
    croak "\nYou have used a wrong name for a keyword argument " .
          "--- perhaps a misspelling\n" 
          if _check_for_illegal_params(@params) == 0;
    bless {
        _excel_filename         =>   $args{excel_filename}, 
        _which_worksheet        =>   $args{which_worksheet},
        _raw_tickets_db         =>   $args{raw_tickets_db}, 
        _processed_tickets_db   =>   $args{processed_tickets_db}, 
        _synset_cache_db        =>   $args{synset_cache_db}, 
        _stemmed_tickets_db     =>   $args{stemmed_tickets_db}, 
        _inverted_index_db      =>   $args{inverted_index_db},
        _tickets_vocab_db       =>   $args{tickets_vocab_db},
        _idf_db                 =>   $args{idf_db}, 
        _tkt_doc_vecs_db        =>   $args{tkt_doc_vecs_db},
        _tkt_doc_vecs_normed_db =>   $args{tkt_doc_vecs_normed_db},
        _clustering_fieldname   =>   $args{clustering_fieldname}, 
        _unique_id_fieldname    =>   $args{unique_id_fieldname}, 
        _stop_words_file        =>   $args{stop_words_file},
        _misspelled_words_file  =>   $args{misspelled_words_file},
        _min_word_length        =>   $args{min_word_length} || 4,
        _add_synsets_to_tickets =>   $args{add_synsets_to_tickets} || 0,
        _want_stemming          =>   $args{want_stemming} || 0,
        _how_many_retrievals    =>   $args{how_many_retrievals} || 5,
        _min_idf_threshold      =>   $args{min_idf_threshold},
        _max_num_syn_words      =>   $args{max_num_syn_words} || 3,
        _want_synset_caching    =>   $args{want_synset_caching} || 0,
        _stop_words             =>   {},
        _all_tickets            =>   [],
        _column_headers         =>   [],
        _good_columns           =>   [],
        _tickets_by_ids         =>   {},
        _processed_tkts_by_ids  =>   {},
        _stemmed_tkts_by_ids    =>   {},
        _misspelled_words       =>   {},
        _total_num_tickets      =>   0,
        _synset_cache           =>   {},
        _vocab_hash             =>   {},
        _vocab_idf_hist         =>   {},
        _idf_t                  =>   {},
        _vocab_size             =>   undef,
        _doc_vector_template    =>   {},
        _tkt_doc_vecs           =>   {},
        _tkt_doc_vecs_normed    =>   {},
        _query_ticket_id        =>   undef,
        _inverted_index         =>   {},
        _debug1                 =>   $args{debug1} || 0, # for processing Excel
        _debug2                 =>   $args{debug2} || 0, # for modeling tickets
        _debug3                 =>   $args{debug3} || 0, # for retrieving similar tickets
        _wn                     =>   WordNet::QueryData->new( verbose => 0, 
                                                              noload => 1 ),
    }, $class;
}

#############################  Extract info from Excel  #######################

sub get_tickets_from_excel {
    my $self = shift;
    unlink $self->{_raw_tickets_db} if -s $self->{_raw_tickets_db};
    unlink $self->{_processed_tickets_db} if -s $self->{_processed_tickets_db};
    unlink $self->{_synset_cache_db} if -s $self->{_synset_cache_db};
    unlink $self->{_stemmed_tickets_db} if -s $self->{_stemmed_tickets_db};
    unlink $self->{_inverted_index_db} if -s $self->{_inverted_index_db};
    unlink $self->{_tkt_doc_vecs_db} if -s $self->{_tkt_doc_vecs_db};
    unlink $self->{_tkt_doc_vecs_normed_db} if -s $self->{_tkt_doc_vecs_normed_db};   
    unlink glob "$self->{_tickets_vocab_db}.*";   
    unlink glob "$self->{_idf_db}.*";
    my $filename = $self->{_excel_filename} || die("Excel file required"),
    my $clustering_fieldname = $self->{_clustering_fieldname} 
      || die("\nYou forgot to specify a value for the constructor parameter clustering_fieldname that points to the data to be clustered in your Excel sheet -- ");
    my $unique_id_fieldname = $self->{_unique_id_fieldname} 
      || die("\nYou forgot to specify a value for the constructor parameter unique_id_fieldname that is a unique integer identifier for the rows of your Excel sheet -- ");
    my $workbook;
    if ($filename =~ /\.xls$/) {
        my $parser = Spreadsheet::ParseExcel->new();
        $workbook = $parser->parse($filename);
        die $parser->error() unless defined $workbook;
    } elsif ($filename =~ /\.xlsx$/) {
#        use Text::Iconv;
        my $converter = Text::Iconv->new("utf-8", "windows-1251");
        $workbook = Spreadsheet::XLSX->new($filename, $converter);
    } else {
        die "File suffix on the Excel file not recognized";
    }
    my @worksheets = $workbook->worksheets();
    my $which_worksheet = $self->{_which_worksheet} || 
        die "\nYou have not specified which Excel worksheet contains the tickets\n";
    my ( $row_min, $row_max ) = $worksheets[$which_worksheet-1]->row_range();
    my ( $col_min, $col_max ) = $worksheets[$which_worksheet-1]->col_range();
    my @good_columns;
    my $col_headers_row;
    my $col_headers_found = 0;
    my $col_index_for_unique_id;
    my $col_index_for_clustering_field;
    for my $row ( $row_min .. $row_max ) {
        last if $col_headers_found;
        @good_columns = ();
        for my $col ( $col_min .. $col_max ) {
            my $cell = 
                   $worksheets[$which_worksheet-1]->get_cell( $row, $col );
            next unless $cell;
            my $cell_value = _get_rid_of_wide_chars($cell->value());
            push @good_columns, $col if $cell_value;
            if ($cell_value eq $unique_id_fieldname) {
                $col_index_for_unique_id = $col;
                $col_headers_row = $row;
                $col_headers_found = 1;
            }
            if ($cell_value eq $clustering_fieldname) {
                $col_index_for_clustering_field = $col;
            }
        }
    }
    $self->{_good_columns} = \@good_columns;
    print "\nThe unique id is in column: $col_index_for_unique_id\n"
        if $self->{_debug1};
    print "The clustering field is in column: " .
                "$col_index_for_clustering_field\n\n" if $self->{_debug1};
    my %Column_Headers;
    foreach my $field_index (0..@good_columns-1) {
        my $key = "field_" . $field_index;
        $Column_Headers{$key} = "";
    }
    my @col_headers = map {
        my $cell = 
           $worksheets[$which_worksheet-1]->get_cell($col_headers_row, $_);
        $cell ? _get_rid_of_wide_chars($cell->value()) : '';
    } @good_columns;
    $self->{_column_headers} = \@col_headers;
    $self->_display_column_headers() if $self->{_debug1};
    my $unique_id_field_index_in_good_columns = 
     _find_index_for_given_element( $col_index_for_unique_id, \@good_columns );
    my $clustering_field_index_in_good_columns =
     _find_index_for_given_element( $col_index_for_clustering_field, 
                             \@good_columns );
    die "Something is wrong with the info extracted from Excel " .
        "as the index for the column with unique IDs is not one of " .
        "good columns\n\n" 
        unless (defined $unique_id_field_index_in_good_columns) &&
               (defined $clustering_field_index_in_good_columns);
    for my $row_index ( $col_headers_row+1..$row_max-1) { 
        my @values = map {
            my $cell = 
              $worksheets[$which_worksheet-1]->get_cell($row_index, $_);
            $cell ? _get_rid_of_wide_chars($cell->value()) : '';
        } @good_columns;
        next unless $values[$unique_id_field_index_in_good_columns] =~ /\d+/;
        next unless $values[$clustering_field_index_in_good_columns] =~ /\w+/;
        my %onerow;
        foreach my $field_index (0..@good_columns-1) {
            my $key = "field_" . $field_index;
            die "The Columns Headers hash has no field for index " .
                   "$field_index\n    "
                unless exists $col_headers[$field_index];
            $onerow{$col_headers[$field_index]} = $values[$field_index];
        }
        push @{$self->{_all_tickets}}, \%onerow;
    }
    my @duplicates_for_id_field = @{$self->_check_unique_id_field()};
    if (@duplicates_for_id_field > 0) {
        print "Your supposedly unique ID field values for duplicates: @duplicates_for_id_field\n";
        die "\n\nYour unique id field for tickets contains duplicate id's";
    }
    foreach my $ticket (@{$self->{_all_tickets}}) {    
        $self->{_tickets_by_ids}->{$ticket->{$unique_id_fieldname}} =
            lc($ticket->{$clustering_fieldname});
    }
    $self->{_total_num_tickets} = scalar @{$self->{_all_tickets}};
    $self->store_raw_tickets_on_disk();
}

sub _test_excel_for_tickets {
    my $self = shift;
    use Text::Iconv;
    my $converter = Text::Iconv->new("utf-8", "windows-1251");
    my $filename = $self->{_excel_filename} || die("Excel sheet needed for testing is missing");
    my $workbook = Spreadsheet::XLSX->new( $filename, $converter );
    my @worksheets = $workbook->worksheets();
    my ( $row_min, $row_max ) = $worksheets[0]->row_range();
    my ( $col_min, $col_max ) = $worksheets[0]->col_range();
    return ($row_min, $row_max, $col_min, $col_max);
}

sub _display_column_headers {
    my $self = shift;
    print "\nThe good columns are: @{$self->{_good_columns}}\n\n";
    my $overall_header_string = join '  <>  ', @{$self->{_column_headers}};
    print "The column headers are: $overall_header_string\n\n";
}

sub _check_unique_id_field {
    my $self = shift;
    my %check_hash;
    my @duplicates;
    foreach my $ticket (@{$self->{_all_tickets}}) {
        if (exists $ticket->{$self->{_unique_id_fieldname}}) {
            push @duplicates, $ticket->{$self->{_unique_id_fieldname}} 
               if exists $check_hash{$ticket->{$self->{_unique_id_fieldname}}};
            $check_hash{$ticket->{$self->{_unique_id_fieldname}}} = 1;
        }
    }
    if ($self->{_debug1}) {
        my $num_of_tickets = @{$self->{_all_tickets}};
        my $num_entries_check_hash = keys %check_hash;
        print "Number of tickets: $num_of_tickets\n";
        print "Number of keys in check hash: $num_entries_check_hash\n";
    }
    return \@duplicates;
}

sub show_original_ticket_for_given_id {
    my $self = shift;
    my $id = shift;
    print "\n\nDisplaying the fields for the ticket $id:\n\n";
    foreach my $ticket (@{$self->{_all_tickets}}) {
        if ( $ticket->{$self->{_unique_id_fieldname}} == $id) {
            foreach my $key (sort keys %{$ticket}) {
                my $value = $ticket->{$key};
                $value =~ s/^\s+//;
                $value =~ s/\s+$//;
                printf("%20s  ==>  %s\n", $key, $value);
            }
        }
    }
}

sub show_raw_ticket_clustering_data_for_given_id {
    my $self = shift;
    my $ticket_id = shift;
    my $record = $self->{_tickets_by_ids}->{$ticket_id};
    print "\n\nDISPLAYING THE RAW CLUSTERING DATA FOR TICKET $ticket_id:\n\n" .
        "$record\n\n";
    return $record;
}

# Needed by test.t
sub _raw_ticket_clustering_data_for_given_id {
    my $self = shift;
    my $ticket_id = shift;
    my $record = $self->{_tickets_by_ids}->{$ticket_id};
    return $record;
}


sub show_processed_ticket_clustering_data_for_given_id {
    my $self = shift;
    my $ticket_id = shift;
    my $record = $self->{_processed_tkts_by_ids}->{$ticket_id};
    print "\n\nDISPLAYING PROCESSED CLUSTERING DATA FOR TICKET $ticket_id:\n\n" .
        "$record\n\n";
}

sub show_stemmed_ticket_clustering_data_for_given_id {
    my $self = shift;
    my $ticket_id = shift;
    my $record = $self->{_stemmed_tkts_by_ids}->{$ticket_id};
    print "\n\nDISPLAYING STEMMED CLUSTERING DATA FOR TICKET $ticket_id:\n\n" .
        "$record\n\n";
}

# The following function is a good diagnostic tool to look into the
# array stored in $self->{_all_tickets}.  Each element of this array
# is a record that represents one row of the Excel file.
sub _show_row {
    my $self = shift;
    my $row_num = shift;
    my $total_rows = @{$self->{_all_tickets}};
    print "There are $total_rows items in the \$all_tickets array\n";
    die "The row that you want to see does not exist" 
        unless $row_num < $total_rows;
    my %record = %{$self->{_all_tickets}->[$row_num]};
    foreach my $field (sort keys %record) {
        my $value = $record{$field};
        no warnings;
        print "$field  ==>  $value\n";
    }
}

sub store_raw_tickets_on_disk {
    my $self = shift;
    $self->{_raw_tickets_db} = "raw_tickets.db" unless $self->{_raw_tickets_db};
    unlink $self->{_raw_tickets_db};
    eval {                    
        store( $self->{_all_tickets}, $self->{_raw_tickets_db} ); 
    };
    if ($@) {                                 
        die "Something went wrong with disk storage of ticket data: $@";
    }
}

sub restore_raw_tickets_from_disk {
    my $self = shift;
    my $clustering_fieldname = $self->{_clustering_fieldname} 
      || die("\nYou forgot to specify a value for the constructor parameter clustering_fieldname that points to the data to be clustered in your Excel sheet -- ");
    my $unique_id_fieldname = $self->{_unique_id_fieldname} 
      || die("\nYou forgot to specify a value for the constructor parameter unique_id_fieldname that is a unique integer identifier for the rows of your Excel sheet -- ");
    eval {                    
        $self->{_all_tickets} = retrieve( $self->{_raw_tickets_db} );
    };
    if ($@) {                                 
        die "Unable to retrieve raw tickets from disk: $@";
    }
    foreach my $ticket (@{$self->{_all_tickets}}) {    
        $self->{_tickets_by_ids}->{$ticket->{$unique_id_fieldname}} =
            lc($ticket->{$clustering_fieldname});
    }
    $self->{_total_num_tickets} = scalar keys %{$self->{_tickets_by_ids}};
}

sub delete_markup_from_all_tickets {
    my $self = shift;    
    foreach my $ticket (@{$self->{_all_tickets}}) {
        $self->_delete_markup_from_one_ticket($ticket->{$self->{_unique_id_fieldname}});
    }
}

sub _delete_markup_from_one_ticket {
    my $self = shift;    
    my $ticket_id = shift;
    my $ticket_strings = $self->{_tickets_by_ids}->{$ticket_id};
    my @strings = grep $_, split /\s+/, $ticket_strings;
    my $cleaned_up_strings = join ' ', grep {$_ !~ /^<[^<>]+>$/} @strings;
    $self->{_tickets_by_ids}->{$ticket_id} = $cleaned_up_strings;
    foreach my $ticket (@{$self->{_all_tickets}}) {
        if ( $ticket->{$self->{_unique_id_fieldname}} == $ticket_id ) {
            $ticket->{$self->{_clustering_fieldname}} = $cleaned_up_strings;
            last;
        }
    }
}

sub apply_filter_to_all_tickets {
    my $self = shift;
    my $stop_words_file = $self->{_stop_words_file} 
        || die("\nYou forgot to supply the name of the stop words file in your constructor call\n");
    my @stop_words = @{_fetch_words_from_file($stop_words_file)};
    my $misspelled_words_file = $self->{_misspelled_words_file} 
        || die("\nYou forgot to supply the name of the misspelled words file in your constructor call\n");
    foreach my $word (@stop_words) {
        $self->{_stop_words}->{$word} = 1;
    }
    if ($self->{_misspelled_words_file}) {
        my @misspelled_word_pairs = 
            @{_fetch_word_pairs_from_file($self->{_misspelled_words_file})};
        foreach my $wordpair (@misspelled_word_pairs) {
            my ($wrong_word, $good_word) = grep $_, split /\s+/, $wordpair;
            $self->{_misspelled_words}->{$wrong_word} = $good_word;
        }
    }
    my $i = 1;
    foreach my $ticket_id (sort {$a <=> $b} keys %{$self->{_tickets_by_ids}}) {
        print "\nApplying filter to ticket $ticket_id ($i out of $self->{_total_num_tickets})\n";
        $self->_apply_filter_to_one_ticket($ticket_id);
        $i++;
    }
}

sub _apply_filter_to_one_ticket {
    my $self = shift;
    my $ticket_id = shift;

    unless (keys %{$self->{_stop_words}} > 0) {
        my @stop_words = @{_fetch_words_from_file($self->{_stop_words_file})};
        foreach my $word (@stop_words) {
            $self->{_stop_words}->{$word} = 1;
        }
    }
    unless (keys %{$self->{_misspelled_words}} > 0) {
        if ($self->{_misspelled_words_file}) {
            my @misspelled_word_pairs = 
                @{_fetch_word_pairs_from_file($self->{_misspelled_words_file})};
            foreach my $wordpair (@misspelled_word_pairs) {
                my ($wrong_word, $good_word) = grep $_, split /\s+/, $wordpair;
                $self->{_misspelled_words}->{$wrong_word} = $good_word;
            }
        }
    }
    my $record = $self->{_tickets_by_ids}->{$ticket_id};
    my $min = $self->{_min_word_length};
    my @words = split /\n|\r|\"|\'|\.|\,|\;|\?|\(|\)|\[|\]|\\|\/|\s+|\&/, $record;
    my @clean_words = grep $_, map { /([a-z0-9_]{$min,})/i;$1 } @words;
    return unless @clean_words;
    my @new_words;
    foreach my $word (@words) {
        $word =~ s/(.+)[.,:!-]$/$1/;
        unless (($word eq 'no') or ($word eq 'not')) {
            next if length($word) < $self->{_min_word_length};
        }
        if (exists $self->{_misspelled_words}->{lc($word)}) {
            push @new_words, $self->{_misspelled_words}->{$word}; 
            next;
        }
        push @new_words, $word unless exists $self->{_stop_words}->{lc($word)};
    }
    my $new_record = join ' ', @new_words;
    $self->{_processed_tkts_by_ids}->{$ticket_id} = $new_record;
}

sub _get_synonyms_for_word {
    my $self = shift;
    my $word = shift;
    my $no_sense_indicators = 1;
    my $wn = $self->{_wn};
    my @parts_of_speech = $wn->querySense("$word");  

    my %noun_synonyms;
    my %verb_synonyms;
    my %adj_synonyms;
    my %adv_synonyms;
    foreach my $pos (@parts_of_speech) {
        if ($pos =~ /n$/) {
            my @all_noun_syn_sense_labels = $wn->querySense( $pos, "syns");
            my $how_many = @all_noun_syn_sense_labels;
            foreach my $noun_sense (@all_noun_syn_sense_labels) {
                my @noun_synonyms = $wn->querySense($noun_sense, "syns");
                my $answer = "";
                foreach my $noun_syn (@noun_synonyms) {
                    next if $noun_syn eq $noun_sense;
                    $noun_syn =~ s/\#.+$// if $no_sense_indicators;
                    $noun_synonyms{$noun_syn} = 1;
                    $answer .= " $noun_syn ";
                }
            }
        } elsif ($pos =~ /v$/) {
            my @all_verb_syn_sense_labels = $wn->querySense( $pos, "syns");
            my $how_many = @all_verb_syn_sense_labels;
            foreach my $verb_sense (@all_verb_syn_sense_labels) {
                my @verb_synonyms = $wn->querySense($verb_sense, "syns");
                my $answer = "";
                foreach my $verb_syn (@verb_synonyms) {
                    next if $verb_syn eq $verb_sense;
                    $verb_syn =~ s/\#.+$// if $no_sense_indicators;
                    $verb_synonyms{$verb_syn} = 1;
                    $answer .= " $verb_syn ";
                }
            }
        } elsif ($pos =~ /a$/) {
            my @all_adj_syn_sense_labels = $wn->querySense( $pos, "syns");
            my $how_many = @all_adj_syn_sense_labels;
            foreach my $adj_sense (@all_adj_syn_sense_labels) {
                my @adj_synonyms = $wn->querySense($adj_sense, "syns");
                my $answer = "";
                foreach my $adj_syn (@adj_synonyms) {
                    next if $adj_syn eq $adj_sense;
                    $adj_syn =~ s/\#.+$// if $no_sense_indicators;
                    $adj_synonyms{$adj_syn} = 1;
                    $answer .= " $adj_syn ";
                }
            }
        } elsif ($pos =~ /r$/) {
            my @all_adv_syn_sense_labels = $wn->querySense( $pos, "syns");
            my $how_many = @all_adv_syn_sense_labels;
            foreach my $adv_sense (@all_adv_syn_sense_labels) {
                my @adv_synonyms = $wn->querySense($adv_sense, "syns");
                my $answer = "";
                foreach my $adv_syn (@adv_synonyms) {
                    next if $adv_syn eq $adv_sense;
                    $adv_syn =~ s/\#.+$// if $no_sense_indicators;
                    $adv_synonyms{$adv_syn} = 1;
                    $answer .= " $adv_syn ";
                }
            }
        } else {
            die "\nThe Part of Speech $pos not recognized\n\n";
        }
    }
    my @all_synonyms;
    my @all_noun_synonyms = keys %noun_synonyms;
    my @all_verb_synonyms = keys %verb_synonyms;
    my @all_adj_synonyms =  keys %adj_synonyms;
    my @all_adv_synonyms =  keys %adv_synonyms;
    push @all_synonyms, @all_noun_synonyms if @all_noun_synonyms > 0;
    push @all_synonyms, @all_verb_synonyms if @all_verb_synonyms > 0;
    push @all_synonyms, @all_adj_synonyms  if @all_adj_synonyms > 0;
    push @all_synonyms, @all_adv_synonyms  if @all_adv_synonyms > 0;
    my %synonym_set;
    foreach my $synonym (@all_synonyms) {
        $synonym_set{$synonym} = 1;
    }
    my @synonym_set = sort keys %synonym_set;
    return \@synonym_set;
}

sub _get_antonyms_for_word {
    my $self = shift;
    my $word = shift;
    my $no_sense_indicators = 1;
    my $wn = $self->{_wn};
    my @parts_of_speech = $wn->querySense("$word");  
    my %noun_antonyms;
    my %verb_antonyms;
    my %adj_antonyms;
    my %adv_antonyms;
    foreach my $pos (@parts_of_speech) {
        if ($pos =~ /n$/) {
            my @all_noun_ant_sense_labels = $wn->queryWord( $pos, "ants");
            my $how_many = @all_noun_ant_sense_labels;
            foreach my $noun_sense (@all_noun_ant_sense_labels) {
                my @noun_antonyms = $wn->queryWord($noun_sense, "ants");
                my $answer = "";
                foreach my $noun_ant (@noun_antonyms) {
                    next if $noun_ant eq $noun_sense;
                    $noun_ant =~ s/\#.+$// if $no_sense_indicators;
                    $noun_antonyms{$noun_ant} = 1;
                    $answer .= " $noun_ant ";
                }
            }
        } elsif ($pos =~ /v$/) {
            my @all_verb_ant_sense_labels = $wn->queryWord( $pos, "ants");
            my $how_many = @all_verb_ant_sense_labels;
            foreach my $verb_sense (@all_verb_ant_sense_labels) {
                my @verb_antonyms = $wn->queryWord($verb_sense, "ants");
                my $answer = "";
                foreach my $verb_ant (@verb_antonyms) {
                    next if $verb_ant eq $verb_sense;
                    $verb_ant =~ s/\#.+$// if $no_sense_indicators;
                    $verb_antonyms{$verb_ant} = 1;
                    $answer .= " $verb_ant ";
                }
            }
        } elsif ($pos =~ /a$/) {
            my @all_adj_ant_sense_labels = $wn->queryWord( $pos, "ants");
            my $how_many = @all_adj_ant_sense_labels;
            foreach my $adj_sense (@all_adj_ant_sense_labels) {
                my @adj_antonyms = $wn->queryWord($adj_sense, "ants");
                my $answer = "";
                foreach my $adj_ant (@adj_antonyms) {
                    next if $adj_ant eq $adj_sense;
                    $adj_ant =~ s/\#.+$// if $no_sense_indicators;
                    $adj_antonyms{$adj_ant} = 1;
                    $answer .= " $adj_ant ";
                }
            }
        } elsif ($pos =~ /r$/) {
            my @all_adv_ant_sense_labels = $wn->queryWord( $pos, "ants");
            my $how_many = @all_adv_ant_sense_labels;
            foreach my $adv_sense (@all_adv_ant_sense_labels) {
                my @adv_antonyms = $wn->queryWord($adv_sense, "ants");
                my $answer = "";
                foreach my $adv_ant (@adv_antonyms) {
                    next if $adv_ant eq $adv_sense;
                    $adv_ant =~ s/\#.+$// if $no_sense_indicators;
                    $adv_antonyms{$adv_ant} = 1;
                    $answer .= " $adv_ant ";
                }
            }
        } else {
            die "\nThe Part of Speech $pos not recognized\n\n";
        }
    }
    my @all_antonyms;
    my @all_noun_antonyms = keys %noun_antonyms;
    my @all_verb_antonyms = keys %verb_antonyms;
    my @all_adj_antonyms =  keys %adj_antonyms;
    my @all_adv_antonyms =  keys %adv_antonyms;
    push @all_antonyms, @all_noun_antonyms if @all_noun_antonyms > 0;
    push @all_antonyms, @all_verb_antonyms if @all_verb_antonyms > 0;
    push @all_antonyms, @all_adj_antonyms  if @all_adj_antonyms > 0;
    push @all_antonyms, @all_adv_antonyms  if @all_adv_antonyms > 0;
    my %antonym_set;
    foreach my $antonym (@all_antonyms) {
        $antonym_set{$antonym} = 1;
    }
    my @antonym_set = sort keys %antonym_set;
    return \@antonym_set;
}

sub expand_all_tickets_with_synonyms {
    my $self = shift;
    return unless $self->{_add_synsets_to_tickets};
    my $num_of_tickets = $self->{_total_num_tickets};
    if ($self->{_want_synset_caching}) {
        eval {
            $self->{_synset_cache} = retrieve( $self->{_synset_cache_db} );
        } if -s $self->{_synset_cache_db};
        if ($@) {                                 
           print "Something went wrong with restoration of synset cache: $@";
        }
    }
    my $i = 1;
    foreach my $ticket_id (sort {$a <=> $b} keys %{$self->{_processed_tkts_by_ids}}) {
        $self->_expand_one_ticket_with_synonyms($ticket_id);
        print "Finished syn expansion of ticket $ticket_id ($i out of $num_of_tickets)\n";
        $i++;
    }
    if ($self->{_want_synset_caching}) {
        $self->{_synset_cache_db} = "synset_cache.db" unless $self->{_synset_cache_db};
        eval {                    
            store( $self->{_synset_cache}, $self->{_synset_cache_db} ); 
        };
        if ($@) {                                 
           die "Something went wrong with disk storage of synset cache: $@";
        }
    }
}

sub _expand_one_ticket_with_synonyms {
    my $self = shift;
    my $ticket_id = shift;
    print "\n\nEXPANDING TICKET $ticket_id WITH SYN-SETS:\n\n" 
                                              if $self->{_debug2};
    $self->_replace_negated_words_with_antonyms_one_ticket( $ticket_id );
    $self->_add_to_words_their_synonyms_one_ticket( $ticket_id );
}

sub _replace_negated_words_with_antonyms_one_ticket {
    my $self = shift;
    my $ticket_id = shift;
    my $record = $self->{_processed_tkts_by_ids}->{$ticket_id};
    my @words_negated_with_not = $record =~ /\bnot\s+(\w+)/ig;
    foreach my $word (@words_negated_with_not) {
        next unless (($word =~ /^\w+$/) && 
                     (length($word) > $self->{_min_word_length}));
        my @antonym_words = @{$self->_get_antonyms_for_word( $word )};
        next unless @antonym_words > 0;
        $#antonym_words = $self->{_max_num_syn_words} - 1
              if @antonym_words > $self->{_max_num_syn_words};
        my $antonym_replacement_string = join ' ', @antonym_words;
        print "Antonym for $word is $antonym_replacement_string\n"
            if $self->{_debug2};
        $record =~ s/not\s+$word/$antonym_replacement_string/g;
    }
    my @words_negated_with_no = $record =~ /\bno\s+(\w+)/ig;
    foreach my $word (@words_negated_with_no) {
        next unless (($word =~ /^\w+$/) && 
                    (length($word) > $self->{_min_word_length}));
        my @antonym_words = @{$self->_get_antonyms_for_word( $word )};
        next unless @antonym_words > 0;
        $#antonym_words = $self->{_max_num_syn_words} - 1
              if @antonym_words > $self->{_max_num_syn_words};
        my $antonym_replacement_string = join ' ', @antonym_words;
        print "Antonym for $word is $antonym_replacement_string\n"
            if $self->{_debug2};
        $record =~ s/no\s+$word/$antonym_replacement_string/g;
    }
    $self->{_processed_tkts_by_ids}->{$ticket_id} = $record;
}

sub _add_to_words_their_synonyms_one_ticket {
    my $self = shift;
    my $ticket_id = shift;
    my $record = $self->{_processed_tkts_by_ids}->{$ticket_id};
    my @words = split /\s+/, $record;
    my @synonym_bag;
    foreach my $word (@words) {
        next if $word eq 'no';
        next if $word eq 'not';
        next unless $word =~ /^\w+$/ && 
                    length($word) > $self->{_min_word_length};
        my @synonym_words;
        @synonym_words = @{$self->{_synset_cache}->{$word}}
                      if exists $self->{_synset_cache}->{$word};        
        unless (exists $self->{_synset_cache}->{$word}) {
            @synonym_words = @{$self->_get_synonyms_for_word( $word )};
            print "syn-set for $word  =>   @synonym_words\n\n"
                if $self->{_debug2};
            my $word_root;
            if (@synonym_words == 0) {
                if ((length($word) > 4) && ($word =~ /(.+)s$/)) {
                    $word_root = $1;
                    @synonym_words = @{$self->_get_synonyms_for_word( $word_root )}
                        if length($word_root) >= $self->{_min_word_length};
                } elsif ((length($word) > 6) && ($word =~ /(.+)ing$/)) {
                    $word_root = $1;
                    @synonym_words = @{$self->_get_synonyms_for_word( $word_root )}
                        if length($word_root) >= $self->{_min_word_length};
                }
            }
            print "syn-set for word root $word_root  =>   @synonym_words\n\n" 
                if ( $self->{_debug2} && defined $word_root );
            _fisher_yates_shuffle( \@synonym_words ) if @synonym_words > 0;
            $#synonym_words = $self->{_max_num_syn_words} - 1
                  if @synonym_words > $self->{_max_num_syn_words};
            print "Retained syn-set for $word  =>   @synonym_words\n\n"
                if $self->{_debug2};
            $self->{_synset_cache}->{$word} = \@synonym_words;
            push @synonym_bag, @synonym_words;
        }
    }
    foreach my $syn_word (@synonym_bag) {
        push @words, lc($syn_word) 
            unless ((exists $self->{_stop_words}->{$syn_word}) || 
                        (length($syn_word) <= $self->{_min_word_length}));
    }
    my @sorted_words = sort @words;
    my $new_record = join ' ', @sorted_words;
    $self->{_processed_tkts_by_ids}->{$ticket_id} = $new_record;
}

sub store_processed_tickets_on_disk {
    my $self = shift;
    $self->{_processed_tickets_db} = "processed_tickets.db" unless $self->{_processed_tickets_db};
    unlink $self->{_processed_tickets_db};
    eval {                    
        store( $self->{_processed_tkts_by_ids}, $self->{_processed_tickets_db} ); 
    };
    if ($@) {                                 
       die "Something went wrong with disk storage of processed tickets: $@";
    }
}

sub store_stemmed_tickets_and_inverted_index_on_disk {
    my $self = shift;
    $self->{_stemmed_tickets_db} = "stemmed_tickets.db" unless $self->{_stemmed_tickets_db};
    unlink $self->{_stemmed_tickets_db};
    eval {                    
        print "\n\nStoring stemmed tickets on disk\n\n";
        store( $self->{_stemmed_tkts_by_ids}, $self->{_stemmed_tickets_db} ); 
    };
    if ($@) {                                 
       die "Something went wrong with disk storage of stemmed tickets: $@";
    }
    $self->{_inverted_index_db} = "inverted_index.db" unless $self->{_inverted_index_db};
    unlink $self->{_inverted_index_db};
    eval { 
        print "\nStoring inverted index on disk\n\n";
        store( $self->{_inverted_index}, $self->{_inverted_index_db} ); 
    };
    if ($@) {                                 
       die "Something went wrong with disk storage of the inverted index: $@";
    }
}

sub restore_processed_tickets_from_disk {
    my $self = shift;
    eval {
        $self->{_processed_tkts_by_ids} = retrieve( $self->{_processed_tickets_db} );
    };
    if ($@) {                                 
       die "Something went wrong with restoration of processed tickets: $@";
    }
}

sub restore_stemmed_tickets_from_disk {
    my $self = shift;
    eval {
        $self->{_stemmed_tkts_by_ids} = retrieve( $self->{_stemmed_tickets_db} );
    };
    if ($@) {                                 
       die "Something went wrong with restoration of stemmed tickets: $@";
    }
}

####################  Get Ticket Vocabulary and Word Counts #################

sub get_ticket_vocabulary_and_construct_inverted_index {
    my $self = shift;
    my $total_num_of_tickets = keys %{$self->{_processed_tkts_by_ids}};
    $self->{_tickets_vocab_db} = "tickets_vocab.db" unless $self->{_tickets_vocab_db};
    unlink glob "$self->{_tickets_vocab_db}.*";   
    my %vocab_hist_on_disk;
    tie %vocab_hist_on_disk, 'SDBM_File',  
             $self->{_tickets_vocab_db}, O_RDWR|O_CREAT, 0640
            or die "Can't create DBM files: $!";       
    my %inverted_index;
    my $min = $self->{_min_word_length};
    foreach my $ticket_id (sort {$a <=> $b} keys %{$self->{_processed_tkts_by_ids}}) {
        my %uniques = ();
        my $record = $self->{_processed_tkts_by_ids}->{$ticket_id};
        my @brokenup = split /\n|\r|\"|\'|\.|\(|\)|\[|\]|\\|\/|\s+/, $record;
        my @clean_words = grep $_, map { /([a-z0-9_]{$min,})/i;$1 } @brokenup;
        next unless @clean_words;
        @clean_words = grep $_, map &_simple_stemmer($_, $self->{_debug2}), 
                                                                 @clean_words;
        map { $vocab_hist_on_disk{"\L$_"}++ } grep $_, @clean_words;
        for (@clean_words) { $uniques{"\L$_"}++ };
        map { $self->{_vocab_idf_hist}->{"\L$_"}++ } keys %uniques;
        map { push @{$self->{_inverted_index}->{"\L$_"}}, $ticket_id } 
                                                            keys %uniques;
        $self->{_stemmed_tkts_by_ids}->{$ticket_id} = join ' ', @clean_words;
    }
    foreach (keys %vocab_hist_on_disk) {
        $self->{_vocab_hist}->{$_} = $vocab_hist_on_disk{$_};
    }
    untie %vocab_hist_on_disk;
    $self->{_tkt_vocab_done} = 1;
    $self->{_vocab_size} = scalar( keys %{$self->{_vocab_hist}} );
    print "\n\nVocabulary size:  $self->{_vocab_size}\n\n"
        if $self->{_debug2};
    # Calculate idf(t):
    $self->{_idf_db} = "idf.db" unless $self->{_idf_db};
    unlink glob "$self->{_idf_db}.*";   
    tie my %idf_t_on_disk, 'SDBM_File', $self->{_idf_db}, O_RDWR|O_CREAT, 0640
                                            or die "Can't create DBM files: $!";       
    foreach (keys %{$self->{_vocab_idf_hist}}) {
        $idf_t_on_disk{$_} = abs( (1 + log($total_num_of_tickets
                                           /
                                           (1 + $self->{_vocab_idf_hist}->{$_}))) 
                                           / log(10) ); 
    }
    foreach (keys %idf_t_on_disk) {
        $self->{_idf_t}->{$_} = $idf_t_on_disk{$_};
    }
    untie %idf_t_on_disk;
}

sub display_tickets_vocab {
    my $self = shift;
    die "tickets vocabulary not yet constructed"
        unless keys %{$self->{_vocab_hist}};
    print "\n\nDisplaying tickets vocabulary (the number shown against each word is the number of times each word appears in ALL the tickets):\n\n";
    foreach (sort keys %{$self->{_vocab_hist}}){
        my $outstring = sprintf("%30s     %d", $_,$self->{_vocab_hist}->{$_});
        print "$outstring\n";
    }
    my $vocab_size = scalar( keys %{$self->{_vocab_hist}} );
    print "\nSize of the tickets vocabulary: $vocab_size\n\n";
}

sub display_inverse_document_frequencies {
    my $self = shift;
    die "tickets vocabulary not yet constructed"
        unless keys %{$self->{_vocab_idf_hist}};
    print "\n\nDisplaying inverse document frequencies (the number of tickets in which each word appears):\n\n";
    foreach ( sort keys %{$self->{_vocab_idf_hist}} ) {               
        my $outstring = sprintf("%30s     %d", 
                       $_, $self->{_vocab_idf_hist}->{$_});
        print "$outstring\n";
    }
    print "\nDisplaying idf(t) = log(D/d(t)) where D is total number of tickets and d(t) the number of tickets with the word t:\n";
    foreach ( sort keys %{$self->{_idf_t}} ) {               
        my $outstring = sprintf("%30s     %f", $_,$self->{_idf_t}->{$_});
        print "$outstring\n";
    }
}

# The following subroutine is useful for diagnostic purposes.  It
# lists the number of tickets that a word appears in and also lists
# the tickets.  But be careful in interpreting its results.  Note
# if you invoke this subroutine after the synsets have been added
# to the tickets, you may find words being attributed to tickets
# that do not actually contain them in the original Excel sheet.
sub list_processed_tickets_for_a_word {
    my $self = shift;
    while (my $word = <STDIN>) {    #enter ctrl-D to exit the loop
        chomp $word;
        my @ticket_list;
        foreach my $ticket_id (sort {$a <=> $b} keys %{$self->{_processed_tkts_by_ids}}) {
            my $record = $self->{_processed_tkts_by_ids}->{$ticket_id};
            push @ticket_list, $ticket_id if $record =~ /\b$word\b/i;
        }
        my $num = @ticket_list;
        print "\nThe number of processed tickets that mention the word `$word': $num\n\n";
        print "The processed tickets: @ticket_list\n\n";
    }
}

sub list_stemmed_tickets_for_a_word {
    my $self = shift;
    while (my $word = <STDIN>) {    #enter ctrl-D to exit the loop
        chomp $word;
        my @ticket_list;
        foreach my $ticket_id (sort {$a <=> $b} keys %{$self->{_stemmed_tkts_by_ids}}) {
            my $record = $self->{_stemmed_tkts_by_ids}->{$ticket_id};
            push @ticket_list, $ticket_id if $record =~ /\b$word\b/i;
        }
        my $num = @ticket_list;
        print "\nThe number of stemmed tickets that mention the word `$word': $num\n\n";
        print "The stemmed tickets: @ticket_list\n\n";
    }
}

##############  Generate Document Vectors for Tickets  ####################

sub construct_doc_vectors_for_all_tickets {
    my $self = shift;
    foreach ( sort keys %{$self->{_vocab_hist}} ) {
        $self->{_doc_vector_template}->{$_} = 0;    
    }
    my $num_of_tickets = keys %{$self->{_stemmed_tkts_by_ids}};
    my $i = 1;
    foreach my $ticket_id (sort {$a <=> $b} keys %{$self->{_stemmed_tkts_by_ids}}) {
        my $doc_vec_ref = 
            $self->_construct_doc_vector_for_one_ticket($ticket_id);
        print "Finished constructing two doc vecs for ticket $ticket_id ($i out of $num_of_tickets)\n";
        $i++;
    }
}

sub _construct_doc_vector_for_one_ticket {
    my $self = shift;
    my $ticket_id = shift;
    unless (keys %{$self->{_doc_vector_template}}) {
        foreach ( sort keys %{$self->{_vocab_hist}} ) {
            $self->{_doc_vector_template}->{$_} = 0;      
        }
    }
    my %doc_vector = %{_deep_copy_hash($self->{_doc_vector_template})};
    foreach ( sort keys %{$self->{_doc_vector_template}} ) {  
        $doc_vector{$_} = 0;    
    }
    my $min = $self->{_min_word_length};
    my $total_words_in_ticket = 0;
    my $record = $self->{_stemmed_tkts_by_ids}->{$ticket_id};
    my @clean_words = split /\s+/, $record;
    map { $doc_vector{"\L$_"}++ } 
            grep {exists $self->{_vocab_hist}->{"\L$_"}} @clean_words; 
    die "Something went wrong. Doc vector size unequal to vocab size"
        unless $self->{_vocab_size} == scalar(keys %doc_vector);
    foreach (keys %doc_vector) {        
        $total_words_in_ticket += $doc_vector{$_};
    }
    my %normalized_doc_vector;
    foreach (keys %doc_vector) {        
        $normalized_doc_vector{$_} = $doc_vector{$_}
                                     *
                                     $self->{_idf_t}->{$_}
                                     /
                                     $total_words_in_ticket;
    }
    $self->{_tkt_doc_vecs}->{$ticket_id} = \%doc_vector;
    $self->{_tkt_doc_vecs_normed}->{$ticket_id} = \%normalized_doc_vector;
}

sub store_ticket_vectors {
    my $self = shift;
    die "You have not yet created doc vectors for tickets"
        unless keys %{$self->{_tkt_doc_vecs}};
    $self->{_tkt_doc_vecs_db} = "tkt_doc_vecs.db" unless $self->{_tkt_doc_vecs_db};
    $self->{_tkt_doc_vecs_normed_db} = "tkt_doc_vecs_normed.db" 
                                           unless $self->{_tkt_doc_vecs_normed_db};
    unlink $self->{_tkt_doc_vecs_db};   
    unlink $self->{_tkt_doc_vecs_normed_db};   
    print "\nStoring the ticket doc vecs on disk. This could take a while.\n\n";
    eval {
        store( $self->{_tkt_doc_vecs}, $self->{_tkt_doc_vecs_db} );
    };
    if ($@) {
        die "Something went wrong with disk storage of ticket doc vectors: $@";
    }
    print "\nStoring normalized ticket doc vecs on disk. This could take a while.\n\n";
    eval {
        store($self->{_tkt_doc_vecs_normed}, $self->{_tkt_doc_vecs_normed_db});
    };
    if ($@) {
        die "Something wrong with disk storage of normalized doc vecs: $@";
    }
}

sub restore_ticket_vectors_and_inverted_index {
    my $self = shift;
    $self->restore_raw_tickets_from_disk();
    $self->restore_processed_tickets_from_disk();
    $self->restore_stemmed_tickets_from_disk();
    tie my %vocab_hist_on_disk, 'SDBM_File', $self->{_tickets_vocab_db}, O_RDONLY, 0640
            or die "Can't connect with DBM file: $!";       
    foreach (keys %vocab_hist_on_disk) {
        $self->{_vocab_hist}->{$_} = $vocab_hist_on_disk{$_};
    }
    untie %vocab_hist_on_disk;
    tie my %idf_t_on_disk, 'SDBM_File', $self->{_idf_db}, O_RDONLY, 0640
            or die "Can't connect with DBM file: $!";       
    foreach (keys %idf_t_on_disk) {
        $self->{_idf_t}->{$_} = $idf_t_on_disk{$_};
    }
    untie %idf_t_on_disk;
    eval {
        $self->{_tkt_doc_vecs} = retrieve( $self->{_tkt_doc_vecs_db} );
    };
    if ($@) {                                 
       print "Something went wrong with retrieval of ticket doc vectors: $@";
    }
    eval {
        $self->{_tkt_doc_vecs_normed} = retrieve( $self->{_tkt_doc_vecs_normed_db} );
    };
    if ($@) {                                 
       print "Something went wrong with retrieval of normed ticket doc vectors: $@";
    }
    eval {
        $self->{_inverted_index} = 
                   retrieve( $self->{_inverted_index_db} );
    };
    if ($@) {                                 
       print "Something went wrong with retrieval of inverted_index: $@";
    }
}

sub display_all_doc_vectors {
    my $self = shift;
    die "Ticket doc vectors not yet constructed" 
        unless keys %{$self->{_tkt_doc_vecs}};
    foreach my $ticket_id (sort {$a <=> $b} keys %{$self->{_tkt_doc_vecs}}) {
        $self->_display_a_single_ticket_doc_vector($ticket_id);
    }
}

sub _display_a_single_ticket_doc_vector {
    my $self = shift;
    my $ticket_id = shift;
    die "Ticket doc vectors not yet constructed" 
        unless keys %{$self->{_tkt_doc_vecs}};
    print "\n\nDISPLAYING Doc Vec FOR TICKET $ticket_id:\n\n";
    foreach ( sort keys %{$self->{_tkt_doc_vecs}->{$ticket_id}} ) {
        print "$_  =>   $self->{_tkt_doc_vecs}->{$ticket_id}->{$_}\n";
    }
    my $docvec_size = keys %{$self->{_tkt_doc_vecs}->{$ticket_id}};
    print "\nSize of vector for ticket $ticket_id: $docvec_size\n";
}

sub display_all_normalized_doc_vectors {
    my $self = shift;
    die "normalized document vectors not yet constructed" 
        unless keys %{$self->{_tkt_doc_vecs_normed}};
    foreach my $ticket_id (sort {$a <=> $b} keys %{$self->{_tkt_doc_vecs_normed}}) {
        $self->_display_a_single_normalized_doc_vector($ticket_id);
    }
}

sub _display_a_single_normalized_doc_vector {
    my $self = shift;
    my $ticket_id = shift;
    die "Normalized ticket doc vectors not yet constructed" 
        unless keys %{$self->{_tkt_doc_vecs_normed}};
    print "\n\nDISPLAYING Normalized Doc Vec FOR TICKET $ticket_id:\n\n";
    foreach ( sort keys %{$self->{_tkt_doc_vecs_normed}->{$ticket_id}} ) {
        print "$_  =>   $self->{_tkt_doc_vecs_normed}->{$ticket_id}->{$_}\n";
    }
    my $docvec_size = keys %{$self->{_tkt_doc_vecs_normed}->{$ticket_id}};
    print "\nSize of normalized vector for ticket $ticket_id: $docvec_size\n";
}

##########################  Display Inverted Index  ###########################

sub display_inverted_index {
    my $self = shift;
    print "\n\nDisplaying inverted index:\n\n";
    foreach my $word (sort keys %{$self->{_vocab_hist}}) {
        $self->display_inverted_index_for_given_word($word);
    }
}

sub display_inverted_index_for_given_word {
    my $self = shift;
    my $word = shift;
    defined $self->{_inverted_index}->{$word} ?
        print "$word =>  @{$self->{_inverted_index}->{$word}}\n"  :
        die "Something is wrong with your inverted index\n";
}

sub display_inverted_index_for_given_query {
    my $self = shift;
    my $query_ticket_id = shift;
    my $query_record = $self->{_stemmed_tkts_by_ids}->{$query_ticket_id};
    my @query_words = grep $_, split /\s+/, $query_record;
    foreach my $qword (@query_words) {
        my $idf_t = $self->{_idf_t}->{$qword};
        my @relevant_tickets = @{$self->{_inverted_index}->{$qword}};
        print "\n$qword ($idf_t)  ===>  @relevant_tickets\n\n";
    }
}

#############  Retrieve Most Similar Tickets with VSM Model  ###################

sub retrieve_similar_tickets_with_vsm {
    my $self = shift;
    $self->{_query_ticket_id} = shift;
    die "\nFirst generate normalized doc vectors for tickets before you can call retrieve with vsm function()\n"
        unless scalar(keys %{$self->{_vocab_hist}}) 
                  && scalar(keys %{$self->{_tkt_doc_vecs_normed}});
    print "\nCalculating the similarity set for query ticket $self->{_query_ticket_id}\n\n";
    my $query_record = $self->{_stemmed_tkts_by_ids}->{$self->{_query_ticket_id}};
    my @query_words = grep $_, split /\s+/, $query_record;
    my %relevant_tickets_set;
    die "\n\nYou did not set a value for the constructor parameter min_idf_threshold -- "
        unless $self->{_min_idf_threshold};
    foreach my $qword (@query_words) {
        map {$relevant_tickets_set{$_} = 1} @{$self->{_inverted_index}->{$qword}}
            if $self->{_idf_t}->{$qword} > $self->{_min_idf_threshold};
    }
    my @relevant_tickets = sort {$a <=> $b} keys %relevant_tickets_set;
    print "The relevant tickets for query: @relevant_tickets" 
        if $self->{_debug3};
    my $num_relevant_tkts = @relevant_tickets;
    print "\nThe number of tickets relevant to the query: $num_relevant_tkts\n\n";
    my %retrievals;
    my $rank = 0;
    foreach (sort {$self->_doc_vec_comparator} @relevant_tickets ) {
        $retrievals{$_} = $self->_similarity_to_query_ticket($_);
        $rank++;
        last if $rank == $self->{_how_many_retrievals};
    }
    if ($self->{_debug3}) {
        print "\n\nShowing the VSM retrievals and the similarity scores:\n\n";
        foreach (sort {$retrievals{$b} <=> $retrievals{$a}} keys %retrievals) {
            print "$_   =>   $retrievals{$_}\n";
        }
    }
    return \%retrievals;
}

sub _doc_vec_comparator {
    my $self = shift;
    my %query_ticket_data_normed = 
           %{$self->{_tkt_doc_vecs_normed}->{$self->{_query_ticket_id}}};
    my $vec1_hash_ref = $self->{_tkt_doc_vecs_normed}->{$a};
    my $vec2_hash_ref = $self->{_tkt_doc_vecs_normed}->{$b};
    my @vec1 = ();
    my @vec2 = ();
    my @qvec = ();
    foreach my $word (sort keys %{$self->{_vocab_hist}}) {
        push @vec1, $vec1_hash_ref->{$word};
        push @vec2, $vec2_hash_ref->{$word};
        push @qvec, $query_ticket_data_normed{$word};
    }
    my $vec1_mag = _vec_magnitude(\@vec1);
    my $vec2_mag = _vec_magnitude(\@vec2);
    my $qvec_mag = _vec_magnitude(\@qvec);
    my $product1 = _vec_scalar_product(\@vec1, \@qvec);
    $product1 /= $vec1_mag * $qvec_mag;
    my $product2 = _vec_scalar_product(\@vec2, \@qvec);
    $product2 /= $vec2_mag * $qvec_mag;
    return 1 if $product1 < $product2;
    return 0  if $product1 == $product2;
    return -1  if $product1 > $product2;
}

sub _similarity_to_query_ticket {
    my $self = shift;
    my $ticket_id = shift;
    my $ticket_data_normed = $self->{_tkt_doc_vecs_normed}->{$ticket_id};
    my @vec = ();
    my @qvec = ();
    foreach my $word (sort keys %$ticket_data_normed) {
        push @vec, $ticket_data_normed->{$word};
        push @qvec, 
            $self->{_tkt_doc_vecs_normed}->{$self->{_query_ticket_id}}->{$word};
    }
    my $vec_mag = _vec_magnitude(\@vec);
    my $qvec_mag = _vec_magnitude(\@qvec);
    die "\nThe query ticket appears to be empty\n" if $qvec_mag == 0;
    my $product = _vec_scalar_product(\@vec, \@qvec);
    $product /= $vec_mag * $qvec_mag;
    return $product;
}


########################  Utility Subroutines  ##########################

sub _simple_stemmer {
    my $word = shift;
    my $debug = shift;
    print "\nStemming the word:        $word\n" if $debug;
    $word =~ s/(.*[a-z]t)ted$/$1/i;
    $word =~ s/(.*[a-z]t)ting$/$1/i;
    $word =~ s/(.*[a-z]l)ling$/$1/i;
    $word =~ s/(.*[a-z]g)ging$/$1/i;
    $word =~ s/(.*[a-z]ll)ed$/$1/i;
    $word =~ s/(.*[a-z][^aeious])s$/$1/i;
    $word =~ s/(.*[a-z])ies$/$1y/i;
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

sub _exists {
    my $element = shift;
    my $array   = shift;
    my %hash;
    for my $item (@$array) {
        $hash{$item} = 1;
    }
    return exists $hash{$element};
}

sub _fetch_words_from_file {
    my $file = shift;
    my @words;
    open( IN, "$file" ) or die "unable to open the file $file: $!";
    while (<IN>) {
        next if /^#/;
        next if /^[ ]*\r?\n?$/;
        $_ =~ s/\r?\n?$//;
        my @how_many_in_line = grep $_, split /\s+/, $_;
        die "File $file: Exactly one word allowed in each line  -- " 
                    unless @how_many_in_line == 1;
        push @words, $_;
    }
    close IN;
    return \@words;
}

sub _fetch_word_pairs_from_file {
    my $file = shift;
    my @word_pairs;
    open( IN, "$file" ) or die "unable to open the file $file: $!";
    while (<IN>) {
        next if /^#/;
        next if /^[ ]*$/;
        chomp;
        my @how_many_in_line = grep $_, split /\s+/, $_;
        die "File: $file --- Exactly two words must be in each non-comment or not-empty line -- " 
                    unless @how_many_in_line == 2;
        push @word_pairs, $_;
    }
    close IN;
    return \@word_pairs;
}

sub _get_rid_of_wide_chars {
    my $string = shift;
    $string =~ s/[^[:ascii:]]+//g;
#    $string =~ s/\x{FEFF}//g;           to get rid of wide characters
    return $string;
}    

sub _find_index_for_given_element {
    my $ele = shift;
    my $array_ref = shift;
    foreach my $i (0..@{$array_ref}-1) {
        return $i if $ele == $array_ref->[$i];
    }
}

sub _check_for_illegal_params {
    my @params = @_;
    my @legal_params = qw / excel_filename
                            which_worksheet
                            raw_tickets_db
                            processed_tickets_db
                            stemmed_tickets_db
                            inverted_index_db
                            tickets_vocab_db
                            idf_db
                            tkt_doc_vecs_db
                            tkt_doc_vecs_normed_db
                            synset_cache_db
                            want_synset_caching
                            add_synsets_to_tickets
                            clustering_fieldname
                            min_word_length
                            min_idf_threshold
                            max_num_syn_words
                            stop_words_file
                            misspelled_words_file
                            unique_id_fieldname
                            want_stemming
                            how_many_retrievals
                            debug1
                            debug2
                            debug3
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

# Meant only for an un-nested hash:
sub _deep_copy_hash {
    my $ref_in = shift;
    my $ref_out = {};
    foreach ( keys %{$ref_in} ) {
        $ref_out->{$_} = $ref_in->{$_};
    }
    return $ref_out;
}

# from perl docs:
sub _fisher_yates_shuffle {                
    my $arr =  shift;                
    my $i = @$arr;                   
    while (--$i) {                   
        my $j = int rand( $i + 1 );  
        @$arr[$i, $j] = @$arr[$j, $i]; 
    }
}

sub _vec_scalar_product {
    my $vec1 = shift;
    my $vec2 = shift;
    die "Something is wrong --- the two vectors are of unequal length"
        unless @$vec1 == @$vec2;
    my $product;
    for my $i (0..@$vec1-1) {
        $product += $vec1->[$i] * $vec2->[$i];
    }
    return $product;
}

sub _vec_magnitude {
    my $vec = shift;
    my $mag_squared = 0;
    foreach my $num (@$vec) {
        $mag_squared += $num ** 2;
    }
    return sqrt $mag_squared;
}

1;

__END__

=head1 NAME

Algorithm::TicketClusterer - A Perl module for retrieving Excel-stored past
tickets that are most similar to a new ticket.  Tickets are commonly used
in software services industry and customer support businesses to record
requests for service, product complaints, user feedback, and so on.

=head1 SYNOPSIS

    use Algorithm::TicketClusterer;

    #  Extract the tickets from the Excel spreadsheet and subject the
    #  textual content of the tickets to various preprocessing and doc
    #  modeling steps.  The preprocessing steps consist of removing markup,
    #  dropping the words in a stop list, correcting spelling errors,
    #  detecting the need for antonyms, and, finally, adding word synonyms
    #  to the tickets in order to ground the tickets in a common
    #  vocabulary. The doc modeling steps consist of fitting a standard
    #  vector space model to the tickets.

    my $clusterer = Algorithm::TicketClusterer->new( 
    
                         excel_filename            => $excel_filename,
                         clustering_fieldname      => $fieldname_for_clustering,
                         which_worksheet           => $which_worksheet,
                         unique_id_fieldname       => $unique_id_fieldname,
                         raw_tickets_db            => $raw_tickets_db,
                         processed_tickets_db      => $processed_tickets_db,
                         stemmed_tickets_db        => $stemmed_tickets_db,
                         inverted_index_db         => $inverted_index_db,
                         tickets_vocab_db          => $tickets_vocab_db,
                         idf_db                    => $idf_db,
                         tkt_doc_vecs_db           => $tkt_doc_vecs_db,
                         tkt_doc_vecs_normed_db    => $tkt_doc_vecs_normed_db,
                         synset_cache_db           => $synset_cache_db,
                         stop_words_file           => $stop_words_file,
                         misspelled_words_file     => $misspelled_words_file,
                         add_synsets_to_tickets    => 1,
                         want_synset_caching       => 1,
                         max_num_syn_words         => 3,
                         min_word_length           => 4,
                         want_stemming             => 1,
                    );
    
    ## Extract information from Excel spreadsheets:
    $clusterer->get_tickets_from_excel();
    
    ## Apply cleanup filters and add synonyms:
    $clusterer->delete_markup_from_all_tickets();
    $clusterer->apply_filter_to_all_tickets();
    $clusterer->expand_all_tickets_with_synonyms();
    
    ## Construct the VSM doc model for the tickets:
    $clusterer->get_ticket_vocabulary_and_construct_inverted_index();
    $clusterer->construct_doc_vectors_for_all_tickets();

    #  Of the various constructor parameters shown above, the following two
    #  are critical to how information is extracted from an Excel
    #  spreadsheet: `clustering_fieldname' and `unique_id_fieldname'.  The
    #  first is the heading of the column that contains the textual content
    #  of the tickets.  The second is the heading of the column that
    #  contains a unique integer identifier for each ticket.

    #  The nine database related constructor parameters (these end in the
    #  suffix `_db') are there in order to avoid repeated parsing of the
    #  spreadsheet and preprocessing of the tickets every time you need to
    #  make a retrieval for a new ticket.  The goal here is that after the
    #  ticket information has been ingested from a spreadsheet, you would
    #  want to carry out similar-ticket retrieval in real time.  (Whether
    #  or not real-time retrieval would be feasible in actual practice
    #  would also depend on what hardware you are using, obviously.)

    #  After the above preprocessing and doc modeling steps, you can
    #  extract the most similar past tickets for a new query ticket with a
    #  script in which the constructor call would look like:

    my $clusterer = Algorithm::TicketClusterer->new( 
    
                         clustering_fieldname      => $fieldname_for_clustering,
                         unique_id_fieldname       => $unique_id_fieldname,
                         raw_tickets_db            => $raw_tickets_db,
                         processed_tickets_db      => $processed_tickets_db,
                         stemmed_tickets_db        => $stemmed_tickets_db,
                         inverted_index_db         => $inverted_index_db,
                         tickets_vocab_db          => $tickets_vocab_db,
                         idf_db                    => $idf_db,
                         tkt_doc_vecs_db           => $tkt_doc_vecs_db,
                         tkt_doc_vecs_normed_db    => $tkt_doc_vecs_normed_db,
                         min_idf_threshold         => 1.8,
                         how_many_retrievals       => 5,
                    );
    
    my $query_tkt = 1393548;
    $clusterer->restore_ticket_vectors_and_inverted_index();
    my %retrieved = %{$clusterer->retrieve_similar_tickets_with_vsm($query_tkt)};
    foreach my $tkt_id (sort {$retrieved{$b} <=> $retrieved{$a}} keys %retrieved) {
        $clusterer->show_original_ticket_for_given_id( $tkt_id );
    }

    #  Of all the parameters shown above in the constructor call, the
    #  parameter min_idf_threshold plays a large role in what tickets are
    #  returned by the retrieval function. The value of this parameter
    #  depends on the number of tickets in your Excel spreadsheet.  If the
    #  number of tickets is in the low hundreds, this parameter is likely to
    #  require a value of 1.5 to 1.8.  If the number of tickets is in the
    #  thousands, the value of this parameter is likely to be between 2 and
    #  3. See the writeup on this parameter in the API description in the
    #  rest of this documentation.


=head1 CHANGES

Version 1.01 of the module removes the platform dependency of the functions used for
reading the text files for stop words, misspelled words, etc.


=head1 DESCRIPTION

B<Algorithm::TicketClusterer> is a I<perl5> module for retrieving
previously processed Excel-stored tickets similar to a new ticket.  Routing
decisions made for the past similar tickets can be useful in expediting the
routing of a new ticket.

Tickets are commonly used in software services industry and customer
support businesses to record requests for service, product complaints,
user feedback, and so on.

With regard to the routing of a ticket, you would want each new ticket to
be handled by the tech support individual who is most qualified to address
the issue raised in the ticket.  Identifying the right individual for each
new ticket in real-time is no easy task for organizations that man large
service centers and helpdesks.  So if it were possible to quickly identify
the previously processed tickets that are most similar to a new ticket, one
could think of constructing semi-automated (or, perhaps, even fully
automated) ticket routers.

Identifying old tickets similar to a new ticket is made challenging by the
fact that folks who submit tickets often write them quickly and informally.
The informal style of writing means that different people may use different
colloquial terms to describe the same thing. And the quickness associated
with their submission causes the tickets to frequently contain spelling and
other errors such as conjoined words, fragmentation of long words, and so
on.

This module is an attempt at dealing with these challenges.

The problem of different people using different words to describe the same
thing is taken care of by using WordNet to add to each ticket a designated
number of synonyms for each word in the ticket.  The idea is that after all
the tickets are expanded in this manner, they would become grounded in a
common vocabulary. The synonym expansion of a ticket takes place only after
the negated phrases (that is, the words preceded by 'no' or 'not') are
replaced by their antonyms.

Obviously, expanding a ticket by synonyms makes sense only after it is
corrected for spelling and other errors.  What sort of errors one looks for
and corrects would, in general, depend on the application domain of the
tickets.  (It is not uncommon for engineering services to use jargon words
and acronyms that look like spelling errors to those not familiar with the
services.)  The module expects to see a file that is supplied through the
constructor parameter C<misspelled_words_file> that contains misspelled
words in the first column and their corrected versions in the second
column.  An example of such a file is included in the C<examples>
directory.  You would need to create your own version of such a file for
your application domain. Since conjuring up the misspellings that your
ticket submitters are likely to throw at you is futile, you might consider
using the following approach which I prefer to actually reading the tickets
for such errors: Turn on the debugging options in the constructor for some
initially collected spreadsheets and watch what sort of words the WordNet
is not able to supply any synonyms for.  In a large majority of cases,
these would be the misspelled words.

Expanding a ticket with synonyms is made complicated by the fact that some
common words have such a large number of synonyms that they can overwhelm
the relatively small number of words in a ticket.  Adding too many synonyms
in relation to the size of a ticket can not only distort the sense of the
ticket but it can also increase the computational cost of processing all
the tickets.

In order to deal with the pros and the cons of using synonyms, the present
module strikes a middle ground: You can specify how many synonyms to use
for a word (assuming that the number of synonyms supplied by WordNet is
larger than the number specified).  This allows you to experiment with
retrieval precision by altering the number of synonyms used.  The retained
synonyms are selected randomly from those supplied by WordNet.  (A smarter
way to select synonyms would be to base them on the context.  For example,
you would not want to use the synonym `programmer' for the noun `developer'
if your application domain is real-estate.  However, such context-dependent
selection of synonyms would take us into the realm of ontologies that I
have chosen to stay away from in this first version of the module.)

Another issue related to the overall run-time performance of this module is
the computational cost of the calls to WordNet through its Perl interface
C<WordNet::QueryData>.  This module uses what I have referred to as
I<synset caching> to make this process as efficient as possible.  The
result of each WordNet lookup is cached in a database file whose name you
supply through the constructor option C<synset_cache_db>.  If you are doing
a good job of catching spelling errors, the module will carry out a
decreasing number of WordNet lookups as the tickets are scanned for
expansion with synonyms.  In an experiment with a spreadsheet that
contained over 1400 real tickets, the last several hundred resulted in
hardly any calls to WordNet.

As currently programmed, the synset cache is deleted and then created
afresh at every call to the function that extracts information from an
Excel spreadsheet. You would want to change this behavior of the module if
you are planning to use it in a production environment where the different
spreadsheets are likely to deal with the same application domain.  To give
greater persistence to the synset cache, comment out the C<unlink
$self->{_synset_cache_db}> line in the method C<get_tickets_from_excel()>.
After a few updates of the synset cache, the module would almost never need
to make direct calls to WordNet, which would enhance the speed of the
module even further.

The textual content of the tickets, as produced by the preprocessing steps,
is used for document modeling and the doc model thus created used
subsequently for retrieving similar tickets.  The doc modeling is carried
out using the Vector Space Model (VSM) in which each ticket is represented
by a vector whose size equals the size of the vocabulary used in all the
tickets and whose elements represent the word frequencies in the
ticket. After such a model is constructed, a query ticket is compared with
the other tickets on the basis of the cosine similarity distance between
the corresponding vectors.

My decision to use the simplest of the text models --- the Vector Space
Model --- was based of the work carried out by Shivani Rao at Purdue who
has demonstrated that the simpler models are more effective at retrieval
from software libraries than the more complex models. (See the paper by
Shivani Rao and Avinash Kak at the MSR'11 Conference.) Although tickets, in
general, are not the same as software libraries, I have a strong feeling
that Shivani's conclusions would extend to other domains as well.  Having
said that, it is important to mention that there remains the possibility
that automated ticket routing for some applications may respond better to
more elaborate text models.

The module uses three mechanisms to speed up the retrieval of tickets
similar to a query ticket: (1) It uses the inverted index for all the words
to construct for each query ticket a candidate pool of only those tickets
in the database that have words in common with the query ticket; (2) Only
those query-ticket words are used for retrieval whose
inverse-document-frequency values exceed a user-specified threshold; and
(3) The module uses stemming to reduce the variants of the same word to a
common root in order to limit the size of the vocabulary.  The stemming
used in the current module is rudimentary.  However, it would be easy to
plug into the module more powerful stemmers through their Perl interfaces.
Future versions of this module may do exactly that.



=head1 THE THREE STAGES OF PROCESSING

The tickets are processed in the following three stages:

=over

=item B<Ticket Preprocessing:>

This stage involves extracting the textual content of each ticket from the
Excel spreadsheet and subjecting it to the following steps: (1) deleting
markup; (2) dropping the stop words supplied through a file whose name is
provided as a value for the constructor parameter C<stop_words_file>; (3)
correcting spelling errors through the `bad-word good-word' entries in a
file whose name is supplied as a value for the constructor parameter
C<misspelled_words_file>; (4) replacing negated words with their antonyms;
and, finally, (5) adding synonyms.

=item B<Doc Modeling:>

Doc modeling consists of creating a Vector Space Model for the tickets
after they have been processed as described above.  VSM modeling involves
scanning the preprocessed tickets, stemming the words, and constructing a
vocabulary for all of the stemmed words in all the tickets.  Subsequently,
the alphabetized list of the vocabulary serves as a vector template for the
tickets. Each ticket is represented by a vector whose dimensionality equals
the size of the vocabulary; each element of this vector is an integer that
is the frequency of the vocabulary word corresponding to the index of the
element.  Doc modeling also involves calculating the inverse document
frequencies (IDF) values for the words and the inverted index for the
words.  The IDF values are used to diminish the importance of the words
that carry little discriminatory power vis-a-vis the tickets.  IDF for a
word is the logarithm of the ratio of the total number of tickets to the
number of tickets in which the word appears.  Obviously, if a word were to
appear in all the tickets, its IDF value would be zero.  The inverted index
entry for a word is the list of all the tickets that contain that word.
The inverted index greatly expedites the retrieval of tickets similar to a
given query ticket.

=item B<Similarity Based Retrieval:>

A query ticket is subject to the same preprocessing steps as all other
tickets.  Subsequently, it is also represented by a vector in the same
manner as the other tickets.  Using the stemmed words in the query ticket,
the inverted index is used to create a candidate list of ticket vectors for
matching with the query ticket vector.  For this, only those query words
are chosen whose IDF values exceed a threshold.  Finally, we compute the
cosine similarity distance between the query ticket vector and the ticket
vectors in the candidate list.  The matching ticket vectors are returned in
the order of decreasing similarity.

=back

=begin html

<br>

=end html

=head1 METHODS

The module provides the following methods for ticket preprocessing and for the
retrieval of tickets most similar to a given ticket:

=over

=item B<new()>

A call to C<new()> constructs a new instance of the C<Algorithm::TicketClusterer>
class:

    my $clusterer = Algorithm::TicketClusterer->new( 

                     excel_filename            => $excel_filename,
                     clustering_fieldname      => $fieldname_for_clustering,
                     unique_id_fieldname       => $unique_id_fieldname,
                     which_worksheet           => $which_worksheet,
                     raw_tickets_db            => $raw_tickets_db,
                     processed_tickets_db      => $processed_tickets_db,
                     stemmed_tickets_db        => $stemmed_tickets_db,
                     inverse_index_db          => $inverse_index_db,
                     tickets_vocab_db          => $tickets_vocab_db,
                     idf_db                    => $idf_db,
                     tkt_doc_vecs_db           => $tkt_doc_vecs_db,
                     tkt_doc_vecs_normed_db    => $tkt_doc_vecs_normed_db,
                     synset_cache_db           => $synset_cache_db,
                     stop_words_file           => $stop_words_file,
                     misspelled_words_file     => $misspelled_words_file,
                     add_synsets_to_tickets    => 1,
                     want_synset_caching       => 1,
                     min_idf_threshold         => 2.0,
                     max_num_syn_words         => 3,
                     min_word_length           => 4,
                     want_stemming             => 1,
                     how_many_retrievals       => 5,
                     debug1                    => 1,  # for processing, filtering Excel
                     debug2                    => 1,  # for doc modeling
                     debug3                    => 1,  # for retrieving similar tickets

                   );

Obviously, before you can invoke the constructor, you must provide values for the
variables shown to the right of the big arrows.  As to what these values should be is
made clear by the following alphabetized list that describes each of the constructor
parameters shown above:

=over 24

=item I<add_synsets_to_tickets:>

You can turn off the addition of synonyms to the tickets by setting this boolean
parameter to 0.

=item I<clustering_fieldname:>

This is for supplying to the constructor the heading of the column in your Excel
spreadsheet that contains the textual data for the tickets.  For example, if the
column heading for the textual content of the tickets is `Description', you must
supply this string as the value for the parameter C<clustering_fieldname>.

=item I<debug1:>

When this parameter is set, the module prints out information regarding what columns
of the spreadsheet it is extracting information from, the headers for those columns,
the index of the column that contains the textual content of the tickets, and of the
column that contains the unique integer identifier for each ticket.  If you are
dealing with spreadsheets with a large number of tickets, it is best to pipe the
output of the module into a file to see the debugging information.

=item I<debug2:>

When this parameter is set, you will see how WordNet is being utilized to generate
word synonyms. This debugging output is also useful to see the extent of misspellings
in the tickets.  If WordNet is unable to find the synonyms for a word, chances are
that the word is not spelled correctly (or that it is a jargon word or a jargon
acronym).

=item I<debug3:>

This debug flag applies to the calculations carried out during the retrieval of
similar tickets.  When this flag is set, the module will display the candidate set of
tickets to be considered for matching with the query ticket.  This candidate set is
chosen by using the inverted index to collect all the tickets that share words with
the query word provided the IDF value for each such word exceeds the threshold set by
the constructor parameter C<min_idf_threshold>.

=item I<excel_filename:>

This is obviously the name of the Excel file that contains the tickets you want to
process.

=item I<how_many_retrievals:>

The integer value supplied for this parameter determines how many tickets that are
most similar to a query ticket will be returned.

=item I<idf_db:>

You store the inverse document frequencies for the vocabulary words in a database
file whose name is supplied through this constructor parameter.  As mentioned
earlier, the IDF for a word is, in principle, the logarithm of the ratio of the total
number of tickets to the DF (Document Frequency) for the word.  The DF of a word is
the number of tickets in which the word appears.

=item I<inverted_index_db:>

If you plan to create separate scripts for the three stages of processing described
earlier, you must store the inverted index in a database file so that it can be used
by the script whose job is to carry out similarity based ticket retrieval. The
inverted index is stored in a database file whose name is supplied through this
constructor parameter.

=item I<max_num_syn_words:>

As mentioned in B<DESCRIPTION>, some words can have a very large number of synonyms
--- much larger than the number of words that may exist in a typical ticket.  If you
were to add all such synonyms to a ticket, you run the danger of altering the sense
of the ticket, besides unnecessarily increasing the size of the vocabulary. This
parameter limits the number of synonyms chosen to the value used for the parameter.
When the number of synonyms returned by WordNet is greater than the value set for
this parameter, the synonyms retained are chosen randomly from the list returned by
WordNet.

=item I<min_idf_threshold:>

First recall that IDF stands for Inverse Document Frequency.  It is calculated during
the second of the three-stage processing of the tickets as described in the section
B<THE THREE STAGES OF PROCESSING TICKETS>.  The IDF value of a word gives us a
measure of the discriminatory power of the word.  Let's say you have a word that
occurs in only one out of 1000 tickets.  Such a word is obviously highly
discriminatory and its IDF would be the logarithm (to base 10) of the ratio of 1000
to 1, which is 3.  On the other hand, for a word that occurs in every one of 1000
tickets, its IDF value would be the logarithm of the ratio of 1000 to 1000, which is
0.  So, for the case when you have 1000 tickets, the upper bound on IDF is 3 and the
lower bound 0. This constructor parameter controls which of the query words you will
use for constructing the initial pool of tickets that will be used for matching.  The
larger the value of this threshold, the smaller the pool obviously.

=item I<min_word_length:> 

This parameter sets the minimum number of characters in a word in order for it to be
included for ticket processing.

=item I<misspelled_words_file:>

As to what extent you can improve ticket retrieval precision with the addition of
synonyms depends on the degree to which you can make corrections on the fly for the
spelling errors that occur frequently in tickets.  That fact makes the file you
supply through this constructor parameter very important.  For the current version of
the module, this file must contain exactly two columns, with the first entry in each
row the misspelled word and the second entry the correctly spelled word.  See this
file in the C<examples> directory for how to format it.

=item I<processed_tickets_db:>

As mentioned earlier in B<DESCRIPTION>, the tickets must be subject to various
preprocessing steps before they can be used for document modeling for the purpose of
retrieval. Preprocessing consists of stop words removal, spelling corrections,
antonym detection, synonym addition, etc.  The tickets resulting from preprocessing
are stored in a database file whose name you supply through this constructor
parameter.

=item I<raw_tickets_db:>

The raw tickets extracted from the Excel spreadsheet are stored in a database file
whose name you supply through this constructor parameter.  The idea here is that we
do not want to process an Excel spreadsheet for each new attempt at matching a query
ticket with the previously recorded tickets in the same spreadsheet.  It is much
faster to load the database back into the runtime environment than to process a large
spreadsheet.

=item I<stemmed_tickets_db:>

As mentioned in the section B<THE THREE STAGES OF PROCESSING>, one of the first
things you do in the second stage of processing is to stem the words in the tickets.
Stemming is important because it reduces the size of the vocabulary.  To illustrate,
stemming would reduce both the words `programming' and `programmed' to the common
root 'program'.  This module uses a very simple stemmer whose rules can be found in
the utility subroutine C<_simple_stemmer()>.  It would be trivial to expand on these
rules, or, for that matter, to use the Perl module C<Lingua::Stem::En> for a full
application of the Porter Stemming Algorithm.  The stemmed tickets are saved in a
database file whose name is supplied through this constructor parameter.

=item I<stop_words_file:>

This constructor parameter is for naming the file that contains the stop words, these
being words you do not wish to be included in the vocabulary.  The format of this
file must be as shown in the sample file C<stop_words.txt> in the C<examples>
directory.

=item I<synset_cache_db:>

As mentioned in B<DESCRIPTION>, we expand each ticket with a certain number of
synonyms for the words in the ticket for the purpose of grounding all the tickets in
a common vocabulary.  This entails making calls to WordNet through its Perl interface
C<WordNet::QueryData>.  Since these calls can be expensive, you can vastly improve
the runtime performance of the module by caching the results returned by WordNet.
This constructor parameter is for naming a diskfile in which the cache will be
stored.

=item I<tickets_vocab_db:>

This parameter is for naming the DBM in which the ticket vocabulary is stored after
it is subject to stemming.

=item I<tkt_doc_vecs_db:>

The database file named by this constructor parameter stores the document vector
representations for the tickets.  Each document vector has the same size as the
vocabulary for all the tickets; each element of such a vector is the number of
occurrences of the corresponding word in the ticket.

=item I<tkt_doc_vecs_normed_db:>

The database file named by this parameter stores the normalized document vectors.
Normalization of a ticket vector consists of factoring out the size of the ticket by
dividing the term frequency for each word in the ticket by the number of words in the
ticket, and then multiplying the result by the IDF value for the word.

=item I<unique_id_fieldname:>

One of the columns of your Excel spreadsheet must contain a unique integer identifier
for each ticket-bearing row of the sheet.  The head of this column, a string
obviously, is supplied as the value for this constructor parameter.

=item I<want_stemming:>

This boolean parameter determines whether or not the words extracted from the tickets
would be subject to stemming.  As mentioned elsewhere, stemming means that related
words like `programming' and `programs' would both be reduced to the root word
`program'.  Stemming is important for limiting the size of the vocabulary.

=item I<want_synset_caching:>

Turning this boolean parameter on is a highly effective way to improve the
computational speed of the module.  As mentioned earlier, it is important to ground
the tickets in a common vocabulary and this module does that by adding to the tickets
a designated number of the synonyms for the words in the tickets.  However, the calls
to WordNet for the synonyms through the Perl interface C<WordNet::QueryData> can be
expensive. Caching means that only one call would need to be made to WordNet for any
given word regardless of how many times the word appears in all of the tickets.

=item I<which_worksheet:>

This specifies the Excel worksheet that contains the tickets.  Its value should be 1
for the first sheet, 2 for the second, and so on.

=back

=begin html

<br>

=end html

=item  B<apply_filter_to_all_tickets()>

    $clusterer->apply_filter_to_all_tickets()

The filtering consists of dropping words from the tickets that are in your stop-list
file, fixing spelling errors using the `bad-word good-word' pairs in your spelling
errors file, and deleting short words.

=item  B<construct_doc_vectors_for_all_tickets()>

    $clusterer->construct_doc_vectors_for_all_tickets()

This method is used in the doc modeling stage of the computations.  As stated
earlier, doc modeling of the tickets consists of representing each ticket by a vector
whose size equals that of the vocabulary and whose elements represent the frequencies
of the corresponding words in the ticket.  In addition to calculating the doc
vectors, this method also constructs a normalized version of the doc vectors.  The
normalization for a ticket consists of multiplying the word frequencies in the
vectors by the IDF values associated with the words and dividing the result by the
total number of words in the ticket.

=item  B<delete_markup_from_all_tickets()>

    $clusterer->delete_markup_from_all_tickets()

It is not uncommon for the textual content of a ticket to contain HTML markup. This
method deletes such strings.  Note that this method is not capable of deleting
complex markup that may include HTML comment blocks, may cross line boundaries, or
when the textual content includes angle brackets that denote "less than" or "greater
then".  If your tickets require more sophisticated processing for the removal of
markup, you might consider using the C<HTML::Restrict> module.


=item  B<display_all_doc_vectors()>

=item  B<display_all_normalized_doc_vectors()>

These two methods are useful for troubleshooting if things don't look right with
regard to retrieval.

=item  B<display_inverse_document_frequencies()>

    $clusterer->display_inverse_document_frequencies()

As mentioned earlier, the document frequency (DF) of a word is the number of tickets
in which the word appears.  The IDF of a word is the logarithm of the ratio of the
total number of tickets to the DF of the word.  A call to this method displays the
IDF values for the words in the vocabulary.

=item  B<display_inverted_index()>

=item  B<display_inverted_index_for_given_word( $word )>

=item  B<display_inverted_index_for_given_query( $ticket_id )>

The above three methods are useful for troubleshooting the issues that are related to
the generation of the inverted index.  The first method shows the entire inverted
index, the second the inverted index for a single specified word, and the third for
all the words in a query ticket.

=item  B<display_tickets_vocab()>

    $clusterer->display_tickets_vocab()

This method displays the ticket vocabulary constructed by a call to
C<get_ticket_vocabulary_and_construct_inverted_index()>.  The vocabulary display
consists of an alphabetized list of the words in all the tickets along with the
frequency of each word.

=item  B<expand_all_tickets_with_synonyms()>

    $clusterer->expand_all_tickets_with_synonyms();

This is the final step in the preprocessing of the tickets before they are ready for
the doc modeling stage.  This method calls other functions internal to the module
that ultimately make calls to WordNet through the Perl interface provided by the
C<WordNet::QueryData> module.

=item B<get_tickets_from_excel():>

    $clusterer->get_tickets_from_excel()

This method calls on the C<Spreadsheet::ParseExcel> module to extract the tickets
from the old-style Excel spreadsheets and the C<Spreadsheet::XLSX> module for doing
the same from the new-style Excel spreadsheets.

=item  B<get_ticket_vocabulary_and_construct_inverted_index()>

    $clusterer->get_ticket_vocabulary_and_construct_inverted_index()

As mentioned in B<THE THREE STAGES OF PROCESSING>, the second stage of processing ---
doc modeling of the tickets --- starts with the stemming of the words in the tickets,
constructing a vocabulary of all the stemmed words in all the tickets, and
constructing an inverted index for the vocabulary words.  All of these things are
accomplished by this method.

=item  B<restore_processed_tickets_from_disk()>

    $clusterer->restore_processed_tickets_from_disk()

This loads into your script the output of the ticket preprocessing stage.  This
method is called internally by C<restore_ticket_vectors_and_inverted_index()>, which
you would use in your ticket retrieval script, assuming it is separate from the
ticket preprocessing script.

=item B<restore_raw_tickets_from_disk()>

    $clusterer->restore_raw_tickets_from_disk()    

With this method, you are spared the trouble of having to repeatedly parse the same
Excel spreadsheet during the development phase as you are testing the module with
different query tickets.  This method is called internally by
C<restore_ticket_vectors_and_inverted_index()>.

=item  B<restore_stemmed_tickets_from_disk()>

        $clusterer->restore_stemmed_tickets_from_disk();

This method is called internally by
C<restore_ticket_vectors_and_inverted_index()>.

=item  B<restore_ticket_vectors_and_inverted_index()>

    $clusterer->restore_ticket_vectors_and_inverted_index()

If you are going to be doing ticket preprocessing and doc modeling in one script and
ticket retrieval in another, then this is the first method you would need to call in
the latter for the restoration of the VSM model for the tickets and the inverted
index.

=item B<retrieve_similar_tickets_with_vsm()>

    my $retrieved_hash_ref = $clusterer->retrieve_similar_tickets_with_vsm( $ticket_num )

It is this method that retrieves tickets that are most similar to a query ticket.
The method first utilizes the inverted index to construct a candidate list of the
tickets that share words with the query ticket.  Only those words play a role here
whose IDF values exceed C<min_idf_threshold>.  Subsequently, the query ticket vector
is matched with each of the ticket vectors in the candidate list.  The method returns
a reference to a hash whose keys are the IDs for the tickets that match the query
ticket and whose values the cosine similarity distance.

=item B<show_original_ticket_for_given_id()>

    $clusterer->show_original_ticket_for_given_id( $ticket_num )

The argument to the method is the unique integer ID of a ticket for which
you want to see all the fields as stored in the Excel spreadsheet.

=item B<show_raw_ticket_clustering_data_for_given_id()>

While the previous method shows all the fields for a ticket, this method
shows only the textual content --- the content you want to use for
establishing similarity between a query ticket and the other tickets.

=item B<show_processed_ticket_clustering_data_for_given_id()>

    $clusterer->show_processed_ticket_clustering_data_for_given_id( $ticket_num );

This is the method to call if you wish to examine the textual content of a ticket
after it goes through the preprocessing steps.  In particular, you will see the
corrections made, the synonyms added, etc.  You would need to set the argument
C<$ticket_num> to the unique integer ID of the ticket you are interested in.

=item  B<store_processed_tickets_on_disk()>

    $clusterer->store_processed_tickets_on_disk();

This stores in a database file the preprocessed textual content of the
tickets.

=item B<store_raw_tickets_on_disk()>

    $clusterer->store_raw_tickets_on_disk();

This method is called by the C<get_tickets_from_excel()> method to store on the disk
the tickets extracted from the Excel spreadsheet.  Obviously, you can also call it in
your own script for doing the same.

=item  B<store_stemmed_tickets_and_inverted_index_on_disk()>

    $clusterer->store_stemmed_tickets_and_inverted_index_on_disk()

This method stores in a database file the stemmed tickets and the inverted index that
are produced at the end of the second stage of processing.

=item B<show_stemmed_ticket_clustering_data_for_given_id()>

    $clusterer->show_stemmed_ticket_clustering_data_for_given_id( $ticket_num );

If you want to see what sort of a job the stemmer is doing for a ticket, this is the
method to call.  You would need to set the argument C<$ticket_num> to the unique
integer ID of the ticket you are interested in.

=item  B<store_ticket_vectors()>

    $clusterer->store_ticket_vectors()

As the name implies, this call stores the vectors, both regular and normalized, in a
database file on the disk.

=back

=head1 HOW THE MATCHING TICKETS ARE RETRIEVED

It is the method C<retrieve_similar_tickets_with_vsm()> that returns the best ticket
matches for a given query ticket.  What this method returns is a hash reference; the
keys in this hash are the integer IDs of the matching tickets and the values the
cosine similarity distance between the query ticket and the matching tickets.  The
number of matching tickets returned by C<retrieve_similar_tickets_with_vsm()> is set
by the constructor parameter C<how_many_retrievals>.  Note that
C<retrieve_similar_tickets_with_vsm()> takes a single argument, which is the integer
ID of the query ticket.


=head1 THE C<examples> DIRECTORY

The C<examples> directory contains the following two scripts that would be your
quickest way to become familiar with this module:

=over

=item B<For ticket preprocessing and doc modeling:>

Run the script

    ticket_preprocessor_and_doc_modeler.pl

This will carry out preprocessing and doc modeling of the tickets that are stored in
the Excel file C<ExampleExcelFile.xls> that you will find in the same directory.

=item B<For retrieving similar tickets:>

Next, run the script

    retrieve_similar_tickets.pl

to retrieve five tickets that are closest to the query ticket whose integer ID is
supplied to the C<retrieve_similar_tickets_with_vsm()> method in the script.

=back

Note that the tickets in the C<ExampleExcelFil.xls> file are contrived.  The sole
purpose of executing the above two scripts is just to get you started with the use of
this module.


=head1 HOW YOU CAN TURN THIS MODULE INTO A PRODUCTION-QUALITY TOOL

By a production-quality tool, I mean a software package that you can I<actually> use
in a production environment for automated or semi-automated ticket routing in your
organization.  I am assuming you already have the tools in place that insert in
real-time the new tickets in an Excel spreadsheet.

Turning this module into a production tool will require that you find the best values
to use for the following three parameters that are needed by the constructor: (1)
C<min_idf_threshold> for the minimum C<idf> value for the words in a query ticket in
order for them to be considered for matching with the other tickets; (2)
C<min_word_length> for discarding words that are too short; and (3)
C<max_num_syn_words> for how many synonyms to retain for a word if the number of
synonyms returned by WordNet is too large.  In addition, you must also come up with a
misspelled-words file that is appropriate to your application domain and a stop-words
file.

In order to find the best values to use for the parameters that are mentioned above,
I suggest creating a graphical front-end for this module that would allow for
altering the values of the three parameters listed above in response to the
prevailing mis-routing rates for the tickets.  The front-end will display to an
operator the latest ticket that needs to be routed and a small set of the
best-matching previously routed tickets as returned by this module.  Used either in a
fully-automated mode or a semi-automated mode, this front-end would contain a
feedback recorder that would keep track of mis-routed tickets --- the mis-routed
tickets would presumably bounce back to the central operator monitoring the
front-end. The front-end display could be equipped with slider controls for altering
the values used for the three parameters. Obviously, as a parameter is changed, some
of the database files stored on the disk would need to be recomputed.  The same would
be the case if you make changes to the misspelled-words file or to the stop-words
file.

=head1 REQUIRED

This module requires the following five modules:

    Spreadsheet::ParseExcel
    Spreadsheet::XLSX
    WordNet::QueryData
    Storable
    SDBM_File

the first for extracting information from the old-style Excel sheets that are
commonly used for storing tickets, the second for extracting the same information
from the new-style Excel sheets, the third for interfacing with WordNet for
extracting the synonyms and antonyms, the fourth for creating the various disk-based
database files needed by the module, and the last for disk-based hashes used to lend
persistence to the extraction of the alphabet used by the tickets and the inverse
document frequencies of the words.

=head1 EXPORT

None by design.

=head1 CAVEATS

An automated or semi-automated ticket router based on the concepts incorporated in
this module may not be appropriate for all applications, especially in domains where
highly jargonified expressions are used to describe faults and problems associated
with an application.

=head1 BUGS

Please notify the author if you encounter any bugs.  When sending email, please place
the string 'TicketClusterer' in the subject line to get past my spam filter.

=head1 INSTALLATION

Download the archive from CPAN in any directory of your choice.  Unpack the archive
with a command that on a Linux machine would look like:

    tar zxvf Algorithm-TicketClusterer-1.01.tar.gz

This will create an installation directory for you whose name will be
C<Algorithm-TicketClusterer-1.01>.  Enter this directory and execute the following
commands for a standard install of the module if you have root privileges:

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

I owe Shivani Rao many thanks for sharing with me the deep insights she has
developed over the years in practically every facet of information
retrieval.


=head1 AUTHOR

Avinash Kak, kak@purdue.edu

If you send email, please place the string "TicketClusterer" in your subject line to
get past my spam filter.


=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

 Copyright 2014 Avinash Kak

=cut

