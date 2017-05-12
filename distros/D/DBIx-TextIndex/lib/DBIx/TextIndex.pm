package DBIx::TextIndex;

use strict;
use warnings;

our $VERSION = '0.28';

require XSLoader;
XSLoader::load('DBIx::TextIndex', $VERSION);

use Bit::Vector ();
use Carp qw(carp croak);
use DBIx::TextIndex::Exception qw(:all);
use DBIx::TextIndex::QueryParser;
use DBIx::TextIndex::TermDocsCache;
use HTML::Entities ();

my $unac;
BEGIN {
    eval { require Text::Unaccent; import Text::Unaccent qw(unac_string) };
    $unac = $@ ? 0 : 1;
}
use constant DO_UNAC => $unac;
use constant COLLECTION_NAME_MAX_LENGTH => 100;

# Version number when collection table definition last changed
use constant LAST_COLLECTION_TABLE_UPGRADE => 0.24;

# Largest size word to be indexed
use constant MAX_WORD_LENGTH => 20;

# Minimum number of alphanumeric characters in a term before a wildcard
use constant MIN_WILDCARD_LENGTH => 1;

# Maximum number of words a wildcard term can expand to
use constant MAX_WILDCARD_TERM_EXPANSION => 30;

 # Used to screen stop words from the scoring process
use constant IDF_MIN_OKAPI => -1.8;

# What can be considered too many results, NO LONGER USED
use constant RESULT_THRESHOLD => 5000;

# Document score accumulator, higher numbers increase scoring accuracy
# but use more memory and cpu
use constant ACCUMULATOR_LIMIT => 20000;

# Clear out the hash key caches after this many searches
use constant SEARCH_CACHE_FLUSH_INTERVAL => 1000;

# Practical number of rows RDBMS can scan in acceptable amount of time
use constant PHRASE_THRESHOLD => 1000;

# Charset of data to be indexed
use constant CHARSET => 'iso-8859-1';

# SQL datatype to store document keys
use constant DOC_KEY_SQL_TYPE => 'varchar';

# Maximum length of above key
use constant DOC_KEY_LENGTH => '200';


my %ERROR = (
    empty_query       => "You must be searching for something!",
    quote_count       => "Quotes must be used in matching pairs.",
    no_results        => "Your search did not produce any matching documents.",
    no_results_stop   => "Your search did not produce any matching " .
        "documents. These common words were not included in the search:",

    wildcard_length   => MIN_WILDCARD_LENGTH > 1
	 ?
	    "Use at least " . MIN_WILDCARD_LENGTH . " letters or " .
	    "numbers at the beginning of the word before wildcard characters."
	 :
	    "Use at least one letter or number at the beginning of the word " .
	    "before wildcard characters.",
    wildcard_expansion => "The wildcard term you used was too broad, " .
	"please use more characters before or after the wildcard",
	     );

my @MASK_TYPES = qw(and_mask or_mask not_mask);

use constant COLLECTION_TABLE => 'collection';

my @COLLECTION_FIELDS = qw(
    collection
    version
    max_indexed_id
    doc_table
    doc_id_field
    doc_fields
    charset
    stoplist
    proximity_index
    error_empty_query
    error_quote_count
    error_no_results
    error_no_results_stop
    error_wildcard_length
    error_wildcard_expansion
    max_word_length
    result_threshold
    phrase_threshold
    min_wildcard_length
    max_wildcard_term_expansion
    decode_html_entities
    scoring_method
    update_commit_interval
);

my %COLLECTION_FIELD_DEFAULT = (
    collection => '',
    version => $DBIx::TextIndex::VERSION,
    max_indexed_id => '0',
    doc_table => '',
    doc_id_field => '',
    doc_fields => '',
    charset => CHARSET,
    stoplist => '',
    proximity_index => '1',
    error_quote_count => $ERROR{quote_count},
    error_empty_query => $ERROR{empty_query},
    error_no_results => $ERROR{no_results},
    error_no_results_stop => $ERROR{no_results_stop},
    error_wildcard_length => $ERROR{wildcard_length},
    error_wildcard_expansion => $ERROR{wildcard_expansion},
    max_word_length => MAX_WORD_LENGTH,
    result_threshold => RESULT_THRESHOLD,
    phrase_threshold => PHRASE_THRESHOLD,
    min_wildcard_length => MIN_WILDCARD_LENGTH,
    max_wildcard_term_expansion => MAX_WILDCARD_TERM_EXPANSION,
    decode_html_entities => '1',
    scoring_method => 'okapi',
    update_commit_interval => 20000,
);


my $PA = 0;		# just a shortcut to $self->{PRINT_ACTIVITY}

sub new {
    my $pkg = shift;
    my $args = shift;

    my $class = ref($pkg) || $pkg;
    my $self = bless {}, $class;

    $self->{COLLECTION_FIELDS} = \@COLLECTION_FIELDS;

    foreach my $arg ('collection', 'index_dbh') {
	if ($args->{$arg}) {
	    $self->{uc $arg} = $args->{$arg};
	} else {
	    throw_gen( error => "new $pkg needs $arg argument" );
	}
    }

    my $coll = $self->{COLLECTION};

    if ($args->{doc_dbh}) {
	$self->{DOC_DBH} = $args->{doc_dbh};
    }

    # deprecated arguments
    if ($args->{db}) {
	throw_gen( error => "new $pkg no longer needs 'db' argument" );
    }

    # term_docs field can have character 32 at end of string,
    # so DBI ChopBlanks must be turned off
    $self->{INDEX_DBH}->{ChopBlanks} = 0;

    $self->{PRINT_ACTIVITY} = 0;
    $self->{PRINT_ACTIVITY} = $args->{'print_activity'} || 0;
    $PA = $self->{PRINT_ACTIVITY};

    $args->{dbd} = $self->{INDEX_DBH}->{Driver}->{Name};
    my $dbd_class = 'DBIx::TextIndex::DBD::' . $args->{dbd};
    eval "require $dbd_class";
    throw_gen( error => "Unsupported DBD driver: $dbd_class",
	       detail => $@ ) if $@;
    $self->{DB} = $dbd_class->new({
	index_dbh => $self->{INDEX_DBH},
	collection_table => COLLECTION_TABLE,
	collection_fields => $self->{COLLECTION_FIELDS},
    });

    $self->{DBD_TYPE} = $args->{dbd};

    unless ($self->_fetch_collection_info) {
	$self->{DOC_TABLE} = $args->{doc_table};
	$self->{DOC_FIELDS} = $args->{doc_fields};
	$self->{DOC_ID_FIELD} = $args->{doc_id_field};

    	$self->{STOPLIST} = $args->{stoplist};

	# override default error messages
	while (my($error, $msg) = each %{$args->{errors}}) {
	    $ERROR{$error} = $msg;
	}

	foreach my $field ( qw(max_word_length
			       result_threshold
			       phrase_threshold
			       min_wildcard_length
			       max_wildcard_term_expansion
			       decode_html_entities
			       scoring_method
			       update_commit_interval
			       charset
			       proximity_index) )
	{
	    $self->{uc($field)} = defined $args->{$field} ?
		$args->{$field} :
		$COLLECTION_FIELD_DEFAULT{$field};
	}
    }
    $self->{CZECH_LANGUAGE} = $self->{CHARSET} eq 'iso-8859-2' ? 1 : 0;
    $self->{MASK_TABLE} = $coll . '_mask';
    $self->{DOCWEIGHTS_TABLE} = $coll . '_docweights';
    $self->{ALL_DOCS_VECTOR_TABLE} = $coll . '_all_docs_vector';
    $self->{DELETE_QUEUE_TABLE} = $coll . '_delete_queue';
    $self->{DOC_KEY_TABLE} = $coll . '_doc_key';

    # Field number, assign each field a number 0 .. N
    my $fno = 0;

    foreach my $field ( @{$self->{DOC_FIELDS}} ) {
	$self->{FIELD_NO}->{$field} = $fno;
	push @{$self->{INVERTED_TABLES}},
	    ($coll . '_' . $field . '_inverted');
    	$fno++;
    }

    # Initialize stoplists
    if ($self->{STOPLIST} and ref($self->{STOPLIST})) {
	$self->{STOPLISTED_WORDS} = {};
    	foreach my $stoplist (@{$self->{STOPLIST}}) {
	    my $stop_package = "DBIx::TextIndex::StopList::$stoplist";
	    _log("initializing stoplist: $stop_package\n") if $PA;
	    eval "require $stop_package";
            no strict 'refs';
            my @words =  @{$stop_package . '::words'};
            foreach my $word (@words) {
            	$self->{STOPLISTED_WORDS}->{$word} = 1;
            }
        }
    }
    $self->{STOPLISTED_QUERY} = [];

    # Database driver object
    $self->{DB}->set({
	all_docs_vector_table => $self->{ALL_DOCS_VECTOR_TABLE},
	delete_queue_table => $self->{DELETE_QUEUE_TABLE},
	doc_table => $self->{DOC_TABLE},
	doc_fields => $self->{DOC_FIELDS},
	doc_id_field => $self->{DOC_ID_FIELD},
	docweights_table => $self->{DOCWEIGHTS_TABLE},
	doc_key_table => $self->{DOC_KEY_TABLE},
	mask_table => $self->{MASK_TABLE},
	max_word_length => $self->{MAX_WORD_LENGTH},
	doc_key_sql_type => $args->{doc_key_sql_type} || DOC_KEY_SQL_TYPE,
	doc_key_length => exists $args->{doc_key_length} ?
	    $args->{doc_key_length} : DOC_KEY_LENGTH,
    });

    # Cache for term_doc postings
    $self->{C} = DBIx::TextIndex::TermDocsCache->new({
	db => $self->{DB},
	index_dbh => $self->{INDEX_DBH},
        max_indexed_id => $self->max_indexed_id,
	inverted_tables => $self->{INVERTED_TABLES},
    });

    # Query parser object 
    $self->{QP} = DBIx::TextIndex::QueryParser->new({
        charset => $self->{CHARSET},
        stoplist => $self->{STOPLIST},
        stoplisted_words => $self->{STOPLISTED_WORDS}
    });

    # Number of searches performed on this instance
    $self->{SEARCH_COUNT} = 0;
    return $self;
}

sub add_mask {
    my $self = shift;
    my $mask = shift;
    my $doc_keys = shift;

    my $ids = $self->{DB}->fetch_doc_ids($doc_keys);

    my $max_indexed_id = $self->max_indexed_id;

    # Trim ids from end instead here.
    if ($ids->[-1] > $max_indexed_id) {
	throw_gen( error => "Greatest doc_id ($ids->[-1]) in mask ($mask) is larger than greatest doc_id in index" );
    }

    my $vector = Bit::Vector->new($max_indexed_id + 1);
    $vector->Index_List_Store(@$ids);

    _log("Adding mask ($mask) to table $self->{MASK_TABLE}\n") if $PA > 1;
    $self->{DB}->add_mask($mask, $vector->to_Enum);
    return 1;
}

sub _log {
    my @messages = @_;
    print @messages;
}

sub delete_mask {
    my $self = shift;
    my $mask = shift;
    _log("Deleting mask ($mask) from table $self->{MASK_TABLE}\n") if $PA > 1;
    $self->{INDEX_DBH}->do($self->{DB}->delete_mask, undef, $mask);
}

# Stub method for older deprecated name
sub add_document { shift->add_doc(@_) }

sub add_doc {
    my $self = shift;
    my @keys = @_;

    throw_gen( error => 'add_doc() needs doc_dbh to be defined' ) unless
	defined $self->{DOC_DBH};

    my $keys;
    if (ref $keys[0] eq 'ARRAY') {
	$keys = $keys[0];
    } elsif ($keys[0] =~ m/^\d+$/) {
	$keys = \@keys;
    }

    return if $#$keys < 0;

    my $add_count_guess = $#$keys + 1;
    my $add_count = 0;
    _log("Adding $add_count_guess docs\n") if $PA;

    my @added_ids;
    my $batch_count = 0;

    foreach my $doc_key (@$keys) {
	unless ($self->_ping_doc($doc_key)) {
	    _log("$doc_key skipped, no doc $doc_key found\n") if $PA;
	    next;
	}

	my $doc_id =
	    $self->_add_one($doc_key, $self->_fetch_doc_all_fields($doc_key));

	push @added_ids, $doc_id;
	$add_count++;
	$batch_count++;
	if ($self->{UPDATE_COMMIT_INTERVAL}
	    && $batch_count >= $self->{UPDATE_COMMIT_INTERVAL}) {
	    # Update database
	    $self->_commit_docs(\@added_ids);
	    $batch_count = 0;
	    @added_ids = ();
	}

    }	# end of doc indexing


    # Update database
    $self->_commit_docs(\@added_ids);
    return $add_count;
}

sub _add_one {
    my $self = shift;
    my ($doc_key, $doc_fields) = @_;

    my $doc_id = $self->{DB}->fetch_doc_id($doc_key);
    if (defined $doc_id) {
	# FIXME: need optimization if more than one doc is replaced at once
	_log("Replacing doc $doc_key\n") if $PA;
	$self->_remove($doc_id);
    }
    $doc_id = $self->{DB}->insert_doc_key($doc_key);

    my $do_prox = $self->{PROXIMITY_INDEX};

    _log("$doc_key - $doc_id") if $PA;

    foreach my $fno ( 0 .. $#{$self->{DOC_FIELDS}} ) {
	my $field = $self->{DOC_FIELDS}->[$fno];
	_log(" $field") if $PA;

	my %positions;
	my %frequency;

	my @terms = $self->_terms($doc_fields->{$field});

	my $term_count = 1;
	foreach my $term (@terms) {
	    push @{$positions{$term}}, $term_count if $do_prox;
	    $frequency{$term}++;
	    $term_count++;
	}
	_log(" $term_count") if $PA;
	while (my ($term, $frequency) = each %frequency) {
	    $self->_docs($fno, $term, $doc_id, $frequency);
	    $self->_positions($fno, $term, $positions{$term}) if $do_prox;
	}
	# Doc weight
	$self->{NEW_W_D}->[$fno]->[$doc_id] = $term_count ?
	    sprintf("%.5f", sqrt((1 + log($term_count))**2)) : 0;
    } # end of field indexing
    _log("\n") if $PA;
    return $doc_id;
}

sub add {
    my $self = shift;

    my $add_count = 0;
    unless ($self->{IN_ADD_TRANSACTION}) {
	$self->{ADD_BATCH_COUNT} = 0;
	$self->{ADDED_IDS} = [];
    }

    while (my ($doc_key, $doc_fields) = splice(@_, 0, 2)) {
	my $doc_id = $self->_add_one($doc_key, $doc_fields);
	push @{$self->{ADDED_IDS}}, $doc_id;
	$add_count++;
	$self->{ADD_BATCH_COUNT}++;
	if ($self->{UPDATE_COMMIT_INTERVAL}
	    && $self->{ADD_BATCH_COUNT} >= $self->{UPDATE_COMMIT_INTERVAL}) {
	    # Update database
	    $self->_commit_docs();
	    $self->{ADD_BATCH_COUNT} = 0;
	    $self->{ADDED_IDS} = [];
	}
    }

    # Update database
    unless ($self->{IN_ADD_TRANSACTION}) {
	$self->_commit_docs();
	delete($self->{ADDED_IDS});
    }
    return $add_count;
}

sub begin_add {
    my $self = shift;
    $self->{IN_ADD_TRANSACTION} = 1;
    $self->{ADD_BATCH_COUNT} = 0;
    $self->{ADDED_IDS} = [];
}

sub commit_add {
    my $self = shift;
    $self->_commit_docs();
    delete($self->{ADDED_IDS});
    $self->{IN_ADD_TRANSACTION} = 0;
}

# Stub methods for older deprecated names
sub remove_document { shift->remove(@_) }
sub remove_doc { shift->remove(@_) }

sub remove {
    my $self = shift;
    my @doc_keys = @_;

    my $doc_keys;
    if (ref $doc_keys[0] eq 'ARRAY') {
	$doc_keys = $doc_keys[0];
    } elsif ($doc_keys[0] =~ m/^\d+$/) {
	$doc_keys = \@doc_keys;
    }

    my $doc_ids = $self->{DB}->fetch_doc_ids($doc_keys);
    return $self->_remove($doc_ids);
}

sub _remove {
    my $self = shift;
    my @ids = @_;

    my $ids;
    if (ref $ids[0] eq 'ARRAY') {
	$ids = $ids[0];
    } elsif ($ids[0] =~ m/^\d+$/) {
	$ids = \@ids;
    }

    return if $#$ids < 0;

    my $remove_count = $#$ids + 1;
    _log("Removing $remove_count docs\n") if $PA;

    _log("Removing docs from docweights table\n") if $PA;
    $self->_docweights_remove($ids);

    $self->_all_doc_ids_remove($ids);

    $self->{DB}->delete_doc_key_doc_ids($ids);

    $self->_add_to_delete_queue($ids);

    return $remove_count; 	# return count of removed ids
}

sub _docweights_remove {
    my $self = shift;
    my $docs_ref = shift;

    my @docs = @{$docs_ref};
    my $use_all_fields = 1;
    $self->_fetch_docweights($use_all_fields);

    my $sql = $self->{DB}->update_docweights;
    my $sth = $self->{INDEX_DBH}->prepare($sql);
    foreach my $fno ( 0 .. $#{$self->{DOC_FIELDS}} ) {
	my @w_d = @{$self->{W_D}->[$fno]};
	foreach my $doc_id (@docs) {
	    $w_d[$doc_id] = 0;
	}
	my $packed_w_d = pack 'f*', @w_d;
	# FIXME: we should update the average, leave it alone for now
	$self->{DB}->update_docweights_execute(
	    $sth,
	    $fno,
	    $self->{AVG_W_D}->[$fno],
	    $packed_w_d
	);
    }
    $sth->finish;
}

sub stat {
    my $self = shift;
    my $query = shift;

    if (lc($query) eq 'total_words') {
	my $total_terms = 0;
	foreach my $table (@{$self->{INVERTED_TABLES}}) {
	    my $sql = $self->{DB}->total_terms($table);
	    $total_terms += scalar $self->{INDEX_DBH}->selectrow_array($sql);
	}
	return $total_terms;
    }

    return undef;
}

sub unscored_search {
    my $self = shift;
    my $query = shift;
    my $args = shift;
    $args->{unscored_search} = 1;
    return $self->search($query, $args);
}

sub search {
    my $self = shift;
    my $query = shift;
    my $args = shift;

    $self->{SEARCH_COUNT}++;

    $self->_flush_cache;

    $self->{OR_TERM_COUNT} = 0;
    $self->{AND_TERM_COUNT} = 0;

    throw_query( error => $ERROR{empty_query}) unless $query;

    my @query_field_nos;
    my %term_field_nos;
    while (my ($field, $query_string) = each %$query) {
	next unless $query_string =~ m/\S+/;
	throw_gen( error => "invalid field ($field) in search()" )
	    unless exists $self->{FIELD_NO}->{$field};
	my $fno = $self->{FIELD_NO}->{$field};
	$self->{QUERY}->[$fno] = $self->{QP}->parse($query_string);
        $self->{STOPLISTED_QUERY} = $self->{QP}->stoplisted_query;
	foreach my $fld ($self->{QP}->term_fields) {
	    if ($fld eq '__DEFAULT') {
		$term_field_nos{$fno}++;
	    } else {
		if (exists $self->{FIELD_NO}->{$fld}) {
		    $term_field_nos{$self->{FIELD_NO}->{$fld}}++;
		}
		# FIXME: should we throw a query exception here if $fld
		# does not exist?
	    }
	}
	push @query_field_nos, $self->{FIELD_NO}->{$field};
    }

    throw_query( error => $ERROR{'empty_query'} )
	unless $#query_field_nos >= 0;

    @{$self->{QUERY_FIELD_NOS}} = sort { $a <=> $b } @query_field_nos;
    @{$self->{TERM_FIELD_NOS}} = sort { $a <=> $b } keys %term_field_nos;

    foreach my $mask_type (@MASK_TYPES) {
	if ($args->{$mask_type}) {
	    $self->{MASK}->{$mask_type} = $args->{$mask_type};
	    foreach my $mask (@{$args->{$mask_type}}) {
		if (ref $mask) {
		    $self->{VALID_MASK} = 1;
		} else {
		    push @{$self->{MASK_FETCH_LIST}}, $mask;
		}
	    }
	}
    }

    if ($args->{or_mask_set}) {
	$self->{MASK}->{or_mask_set} = $args->{or_mask_set};
	foreach my $mask_set (@{$args->{or_mask_set}}) {
	    foreach my $mask (@$mask_set) {
		if (ref $mask) {
		    $self->{VALID_MASK} = 1;
		} else {
		    push @{$self->{MASK_FETCH_LIST}}, $mask;
		}
	    }
	}
    }

    $self->_optimize_or_search;
    $self->_resolve_mask;
    $self->_boolean_search;

    if ($args->{unscored_search}) {
	my @result_docs = $self->{RESULT_VECTOR}->Index_List_Read;
	throw_query( error => $ERROR{'no_results'} ) if $#result_docs < 0;
	return $self->{DB}->fetch_doc_keys(\@result_docs);
    }

    my $scoring_method = $args->{scoring_method} || $self->{SCORING_METHOD};

    my $results = {};
    if ($scoring_method eq 'okapi') {
	$results = $self->_search_okapi;
    } else {
	throw_gen( error => "Invalid scoring method $scoring_method, only choice is okapi");
    }
    $self->{C}->flush_term_docs;

    return $results;
}


sub _boolean_search {
    my $self = shift;
    $self->fetch_all_docs_vector;

    my @query_fnos = @{$self->{QUERY_FIELD_NOS}};

    if ($#query_fnos == 0) {
	my $fno = $query_fnos[0];
	$self->{RESULT_VECTOR} =
	    $self->_boolean_search_field($fno, $self->{QUERY}->[$fno]);
    } else {
	my $max_id = $self->max_indexed_id + 1;
	$self->{RESULT_VECTOR} = Bit::Vector->new($max_id);
	foreach my $fno (@query_fnos) {
	    my $field_vec =
		$self->_boolean_search_field($fno, $self->{QUERY}->[$fno]);
	    $self->{RESULT_VECTOR}->Union($self->{RESULT_VECTOR}, $field_vec);
	}
    }

    if ($self->{RESULT_MASK}) {
	$self->{RESULT_VECTOR}->Intersection($self->{RESULT_VECTOR},
					     $self->{RESULT_MASK});
    }

    no warnings qw(uninitialized);
    foreach my $fno (@{$self->{TERM_FIELD_NOS}}) {
	my %f_t;
	foreach my $term (@{$self->{TERMS}->[$fno]}) {
	    $f_t{$term} = $self->{C}->f_t($fno, $term);
	    # query term frequency
	    $self->{F_QT}->[$fno]->{$term}++;
	}
	# Set TERMS to frequency-sorted list
	my @freq_sort = sort {$f_t{$a} <=> $f_t{$b}} keys %f_t;
	$self->{TERMS}->[$fno] = \@freq_sort;
    }
}

sub _boolean_search_field {

    no warnings qw(uninitialized);

    my $self = shift;
    my ($field_no, $clauses) = @_;

    my $max_id = $self->max_indexed_id + 1;
    my $field_vec = $self->{ALL_DOCS_VECTOR}->Clone;

    my @or_vecs;

    my $scorable_clause_count = 0; # Any clause without 'NOT' modifier

    foreach my $clause (@$clauses) {
	my $clause_vec;
	my $expanded_terms = [];
	my $fno = $field_no;
	if (exists $self->{FIELD_NO}->{$clause->{FIELD}}) {
	    $fno = $self->{FIELD_NO}->{$clause->{FIELD}};
	}
	if ($clause->{TYPE} eq 'QUERY') {
	    $clause_vec =
		$self->_boolean_search_field($fno, $clause->{QUERY});
	} elsif ($clause->{TYPE} eq 'PLURAL') {
	    ($clause_vec, $expanded_terms) =
		$self->_resolve_plural($fno, $clause->{TERM});
	} elsif ($clause->{TYPE} eq 'WILD') {
	    ($clause_vec, $expanded_terms) =
		$self->_resolve_wild($fno, $clause->{TERM});
	} elsif ($clause->{TYPE} eq 'PHRASE'
		 || $clause->{TYPE} eq 'IMPLICITPHRASE') {
	    $clause_vec = $self->_resolve_phrase($fno, $clause);
	} elsif ($clause->{TYPE} eq 'TERM') {
	    $clause_vec = $self->{C}->vector($fno, $clause->{TERM});
	} else {
	    next;
	}

	# AND/OR terms will be used later in scoring process
	unless ($clause->{MODIFIER} eq 'NOT') {
	    if ($clause->{TYPE} eq 'PHRASE'
		|| $clause->{TYPE} eq 'IMPLICITPHRASE') {
		foreach my $term_clause (@{$clause->{PHRASETERMS}}) {
		    push @{$self->{TERMS}->[$fno]}, $term_clause->{TERM};
		}
	    } elsif ($clause->{TYPE} eq 'WILD' ||
		     $clause->{TYPE} eq 'PLURAL') {
		push @{$self->{TERMS}->[$fno]}, @$expanded_terms;
	    } else {
		push @{$self->{TERMS}->[$fno]}, $clause->{TERM};
	    }
	    $scorable_clause_count++;
	}

	if ($clause->{MODIFIER} eq 'NOT') {
	    my $not_vec = $clause_vec->Clone;
	    $not_vec->Flip;
	    $field_vec->Intersection($field_vec, $not_vec);
	} elsif ($clause->{MODIFIER} eq 'AND'
		 || $clause->{CONJ} eq 'AND') {
	    $field_vec->Intersection($field_vec, $clause_vec);
	} elsif ($clause->{CONJ} eq 'OR') {
	    if ($#or_vecs >= 0) {
		my $all_ors_vec = Bit::Vector->new($max_id);
		foreach my $or_vec (@or_vecs) {
		    $all_ors_vec->Union($all_ors_vec, $or_vec);
		}
		$field_vec->Intersection($field_vec, $all_ors_vec);
		@or_vecs = ();
	    }
	    $field_vec->Union($field_vec, $clause_vec);
	} else {
	    push @or_vecs, $clause_vec;
	}
    }

    # Handle edge case where we only have NOT words
    if ($scorable_clause_count <= 0) {
	$field_vec->Empty;
	return $field_vec;
    }

    # Take the union of all the OR terms and intersect with result vector
    if ($#or_vecs >= 0) {
	my $all_ors_vec = Bit::Vector->new($max_id);
	foreach my $or_vec (@or_vecs) {
	    $all_ors_vec->Union($all_ors_vec, $or_vec);
	}
	$field_vec->Intersection($field_vec, $all_ors_vec);
    }

    return $field_vec;

}

sub _resolve_phrase {
    my $self = shift;
    my ($fno, $clause) = @_;
    my (@term_docs, @term_pos);
    my $max_id = $self->max_indexed_id + 1;
    my $and_vec = Bit::Vector->new($max_id);
    $and_vec->Fill;

    foreach my $term_clause (@{$clause->{PHRASETERMS}}) {
	$and_vec->Intersection($and_vec,
			       $self->{C}->vector($fno, $term_clause->{TERM}));
    }

    if ($self->{RESULT_MASK}) {
	$and_vec->Intersection($and_vec, $self->{RESULT_MASK});
    }

    return $and_vec if $and_vec->is_empty();


    foreach my $term_clause (@{$clause->{PHRASETERMS}}) {
	my $term = $term_clause->{TERM};
	push @term_docs, $self->{C}->term_docs($fno, $term);
	push @term_pos, $self->{C}->term_pos($fno, $term);
    }

    my $phrase_ids;

    if ($self->{PROXIMITY_INDEX}) {
	$phrase_ids = pos_search($and_vec, \@term_docs, \@term_pos,
		          $clause->{PROXIMITY}, $and_vec->Min, $and_vec->Max);
    } else {
	my @and_ids = $and_vec->Index_List_Read;
	return $and_vec if $#and_ids < 0;
	return $and_vec if $#and_ids > $self->{PHRASE_THRESHOLD};
	$phrase_ids = $self->_phrase_fullscan(\@and_ids,$fno, $clause->{TERM});
    }

    $and_vec->Empty;
    $and_vec->Index_List_Store(@$phrase_ids);

    return $and_vec;
}

# perl prototype, we use pos_search from TextIndex.xs
sub pos_search_perl {
    my ($and_vec, $term_docs, $term_pos, $proximity) = @_;
    $proximity ||= 1;
    my @phrase_ids;
    my $term_count = $#$term_docs + 1;
    my $and_vec_min = $and_vec->Min;
    my $and_vec_max = $and_vec->Max;
    return if $and_vec_min <= 0;

    my @pos_lists;
    my @td; # term docs
    my @last_td_pos;
    my @pos_idx;
    foreach my $i (0 .. $#$term_docs) {
	@{$pos_lists[$i]} = unpack 'w*', $term_pos->[$i]; 
	$td[$i] = term_docs_arrayref($term_docs->[$i]);
	$last_td_pos[$i] = 0;
	$pos_idx[$i] = 0;
    }

    for (my $i = 0 ; $i <= $#{$td[0]} ; $i += 2) {
	my $doc_id = $td[0]->[$i];
	my $freq = $td[0]->[$i+1];
	$pos_idx[0] += $freq;
	next if ($doc_id < $and_vec_min);
	next unless $and_vec->contains($doc_id);
	my @pos_delta =
	    @{$pos_lists[0]}[$pos_idx[0] - $freq .. $pos_idx[0] - 1];
	my @pos_first_term;
	push @pos_first_term, $pos_delta[0];
	foreach my $a (1 .. $#pos_delta) {
	    push @pos_first_term, $pos_delta[$a] + $pos_first_term[$a - 1];
	}
	my @next_pos;
	foreach my $j (1 .. $term_count - 1) {
	    my $freq = 0;
	    for (my $k = $last_td_pos[$j] ;
		 $k <= $#{$td[$j]}        ;
		 $k += 2)
	    {
		my $id = $td[$j]->[$k];
		$freq = $td[$j]->[$k+1];
		$pos_idx[$j] += $freq;
		$last_td_pos[$j] = $k;
		if ($id >= $doc_id) {
		    $last_td_pos[$j] += 2;
		    last;
		}

	    }
	    my @pos_delta =
		@{$pos_lists[$j]}[$pos_idx[$j] - $freq .. $pos_idx[$j] - 1];
	    push @{$next_pos[$j]}, $pos_delta[0];
	    foreach my $a (1 .. $#pos_delta) {
		push @{$next_pos[$j]}, $pos_delta[$a] + $next_pos[$j]->[$a - 1];
	    }
	}
	foreach my $pos (@pos_first_term) {
	    my $seq_count = 1;
	    my $last_pos = $pos;
	    foreach my $j (1 .. $term_count - 1) { # FIXME: short circuit the search by remember positions already looked at
		foreach my $next_pos (@{$next_pos[$j]}) {
		    if ($next_pos > $last_pos &&
			$next_pos <= $last_pos + $proximity) {
			$seq_count++;
			$last_pos = $next_pos;
		    }
		}
	    }
	    if ($seq_count == $term_count) {
		push @phrase_ids, $doc_id;
	    }
	}
	last if $doc_id > $and_vec_max;
    }
    return \@phrase_ids;
}

sub _resolve_plural {
    no warnings qw(uninitialized);
    my $self = shift;
    my ($fno, $term) = @_;
    my $max_id = $self->max_indexed_id + 1;
    my $terms_union = Bit::Vector->new($max_id);
    my $count = 0;
    my $sum_f_t;
    # FIXME: cheap hack
    my $max_t;
    my $max_f_t = 0;
    foreach my $t ($term, $term.'s') {
	my $f_t = $self->{C}->f_t($fno, $t);
	if ($f_t) {
	    $count++;
	    $sum_f_t += $f_t;
	}
	$max_t = $t, $max_f_t = $f_t if $f_t > $max_f_t;
	$terms_union->Union($terms_union, $self->{C}->vector($fno, $t));
    }
    if ($count) {
	$self->{F_T}->[$fno]->{$term} = int($sum_f_t/$count);
    # FIXME: need to do a real merge
#    $self->{TERM_DOCS}->[$fno]->{$term} = $self->{C}->term_docs($fno, $max_t);
    }
    return $terms_union, [$term, $term.'s'];
}

sub _resolve_wild {
    my $self = shift;
    my ($fno, $term) = @_;
    my $max_id = $self->max_indexed_id + 1;
    my $prefix = (split(/[\*\?]/, $term))[0];
    throw_query( error => $ERROR{wildcard_length} )    
	if length($prefix) < $self->{MIN_WILDCARD_LENGTH};
    my $sql = $self->{DB}->fetch_terms($self->{INVERTED_TABLES}->[$fno]);
    my $terms = [];
    my $sql_term = $term;
    $sql_term =~ tr/\*\?/%_/;
    $terms = $self->{INDEX_DBH}->selectcol_arrayref($sql, undef, $sql_term);
    # To save resources, check to make sure wildcard search is not too broad
    throw_query( error => $ERROR{wildcard_expansion} )
	if $#$terms + 1 > $self->{MAX_WILDCARD_TERM_EXPANSION};

    my $terms_union = Bit::Vector->new($max_id);
    my $count = 0;
    my $sum_f_t;
    # FIXME: cheap hack
    my $max_t;
    my $max_f_t = 0;
    foreach my $t (@$terms) {
	my $f_t = $self->{C}->f_t($fno, $t);
	if ($f_t) {
	    $count++;
	    $sum_f_t += $f_t;
	}
	$max_t = $t, $max_f_t = $f_t if $f_t > $max_f_t;
	$terms_union->Union($terms_union, $self->{C}->vector($fno, $t));
    }
    if ($count) {
	$self->{F_T}->[$fno]->{$term} = int($sum_f_t/$count);
	# FIXME: need to do a real merge
#	$self->{TERM_DOCS}->[$fno]->{$term} = $self->{C}->term_docs($fno, $max_t);
    }
    # FIXME: what should TERM_DOCS contain if count is 0?
    return ($terms_union, $terms);
}

sub _flush_cache {
    my $self = shift;

    my @delete = qw(result_vector
                    result_mask
		    valid_mask
                    mask
		    mask_fetch_list
		    mask_vector
		    terms
		    f_qt
		    f_t
		    term_docs
    		    term_pos);

    delete @$self{map { uc $_ } @delete};

    $self->{STOPLISTED_QUERY} = [];
    # check to see if documents have been added since we last called new()
    my $new_max_indexed_id = $self->fetch_max_indexed_id;
    if (($new_max_indexed_id != $self->{MAX_INDEXED_ID})
	|| ($self->{SEARCH_COUNT} > SEARCH_CACHE_FLUSH_INTERVAL)) {
	# flush things that stick around
	$self->max_indexed_id($new_max_indexed_id);
	$self->{C}->max_indexed_id($new_max_indexed_id);
	delete($self->{ALL_DOCS_VECTOR});
	delete($self->{W_D});
	delete($self->{AVG_W_D});
	$self->{SEARCH_COUNT} = 0;
    }
}

sub highlight {
    return $_[0]->{HIGHLIGHT};
}

sub html_highlight {
    my $self = shift;
    my $field = shift;

    my $fno = $self->{FIELD_NO}->{$field};

    my @terms = @{$self->{QUERY_HIGHLIGHT}->[$fno]};
    push (@terms, @{$self->{QUERY_PHRASES}->[$fno]});

    return (\@terms, $self->{QUERY_WILDCARDS}->[$fno]);
}

sub initialize {
    my $self = shift;

    $self->{MAX_INDEXED_ID} = 0;

    if ($self->_collection_table_exists) {
	if ($self->_collection_table_upgrade_required ||
	    $self->collection_count < 1)
	{
	    $self->upgrade_collection_table;
	}
    } else {
	$self->_create_collection_table;
    }
    $self->_create_tables;
    $self->_delete_collection_info;
    $self->_store_collection_info;

    return $self;
}

# FIXME: probably breaks if max_indexed_id has been removed. Test.
sub last_indexed_key {
    my $self = shift;
    my $doc_keys = $self->{DB}->fetch_doc_keys([ $self->{MAX_INDEXED_ID} ]);

    if (ref $doc_keys) {
	return $doc_keys->[0];
    } else {
	return undef;
    }
}

sub indexed {
    my $self = shift;
    my $doc_key = shift;

    my $doc_ids = $self->{DB}->fetch_doc_ids([$doc_key]);

    if (ref $doc_ids) {
	return $doc_ids->[0];
    } else {
	return 0;
    }
}

sub max_indexed_id {
    my $self = shift;
    my $max_indexed_id = shift;

    if (defined $max_indexed_id) {
	$self->_update_collection_info('max_indexed_id', $max_indexed_id);
	$self->{C}->max_indexed_id($max_indexed_id);
	return $self->{MAX_INDEXED_ID};
    } else {
	return $self->{MAX_INDEXED_ID};
    }
}

sub fetch_max_indexed_id {
    my $self = shift;
    my ($max_indexed_id) = $self->{INDEX_DBH}->selectrow_array(
                               $self->{DB}->fetch_max_indexed_id,
                               undef, $self->{COLLECTION} );
    return $max_indexed_id;
}

sub delete {

    my $self = shift;

    _log("Deleting $self->{COLLECTION} from collection table\n") if $PA;
    $self->_delete_collection_info;

    _log("Dropping mask table ($self->{MASK_TABLE})\n") if $PA;
    $self->{DB}->drop_table($self->{MASK_TABLE});

    _log("Dropping docweights table ($self->{DOCWEIGHTS_TABLE})\n") if $PA;
    $self->{DB}->drop_table($self->{DOCWEIGHTS_TABLE});

    _log("Dropping docs vector table ($self->{ALL_DOCS_VECTOR_TABLE})\n")
	if $PA;
    $self->{DB}->drop_table($self->{ALL_DOCS_VECTOR_TABLE});

    _log("Dropping delete queue table ($self->{DELETE_QUEUE_TABLE})\n")
	if $PA;
    $self->{DB}->drop_table($self->{DELETE_QUEUE_TABLE});

    _log("Dropping doc key table ($self->{DOC_KEY_TABLE})\n") if $PA;
    $self->{DB}->drop_doc_key_table();

    foreach my $table ( @{$self->{INVERTED_TABLES}} ) {
	_log("Dropping inverted table ($table)\n") if $PA;
	$self->{DB}->drop_table($table);
    }
}

sub _collection_table_exists {
    my $self = shift;
    return $self->{DB}->table_exists(COLLECTION_TABLE);
}

sub _create_collection_table {
    my $self = shift;
    my $sql = $self->{DB}->create_collection_table;
    $self->{INDEX_DBH}->do($sql);
    _log("Creating collection table (" . COLLECTION_TABLE . ")\n") if $PA;
}

sub collection_count {
    my $self = shift;
    my $collection_count = $self->{INDEX_DBH}->selectrow_array(
			       $self->{DB}->collection_count );
    croak $DBI::errstr if $DBI::errstr;
    return $collection_count;
}

sub _collection_table_upgrade_required {
    my $self = shift;
    my $version = 0;
    _log("Checking if collection table upgrade required ...\n") if $PA > 1;
    unless ($self->collection_count) {
	_log("... Collection table contains no rows\n") if $PA > 1;
	return 0;
    }
    eval {
	$version = $self->{INDEX_DBH}->selectrow_array(
		       $self->{DB}->fetch_collection_version );
	die $DBI::errstr if $DBI::errstr;
    };
    if ($@) {
	_log("... Problem fetching version column, must upgrade\n") if $PA > 1;
	return 1;
    }
    if ($version && ($version < LAST_COLLECTION_TABLE_UPGRADE)) {
	_log("... Collection table version too low, must upgrade\n")
	    if $PA > 1;
	return 1;
    }
    _log("... Collection table up-to-date\n") if $PA > 1;
    return 0;
}

sub upgrade_collection_table {
    my $self = shift;
    my $sth = $self->{INDEX_DBH}->prepare($self->{DB}->fetch_all_collection_rows);
    $sth->execute;
    croak $sth->errstr if $sth->errstr;
    if ($sth->rows < 1) {
	_log("No rows in collection table, dropping collection table ("
	    . COLLECTION_TABLE . ")\n") if $PA;
	$self->{DB}->drop_table(COLLECTION_TABLE);
	$self->_create_collection_table;
	return 1;
    } 
    my @table;
    while (my $row = $sth->fetchrow_hashref) {
	push @table, $row;
    }

    _log("Upgrading collection table ...\n") if $PA;
    _log("... Dropping old collection table ...\n") if $PA;
    $self->{DB}->drop_table(COLLECTION_TABLE);
    _log("... Recreating collection table ...\n") if $PA;
    $self->_create_collection_table;

    foreach my $old_row (@table) {
	my %new_row;
	foreach my $field (@COLLECTION_FIELDS) {
	    $new_row{$field} = exists $old_row->{$field} ?
		$old_row->{$field} : $COLLECTION_FIELD_DEFAULT{$field};
	    $new_row{version} = $COLLECTION_FIELD_DEFAULT{version};
	}
	# 'czech_language', 'language' options replaced with 'charset'
	if (exists $old_row->{czech_language}) {
	    $new_row{charset} = 'iso-8859-2' if $old_row->{czech_language};
	}
	if (exists $old_row->{language}) {
	    if ($old_row->{language} eq 'cz') {
		$new_row{charset} = 'iso-8859-2';
	    } else {
		$new_row{charset} = $COLLECTION_FIELD_DEFAULT{charset}
	    }
	}
	if (exists $old_row->{document_table}) {
	    $new_row{doc_table} = $old_row->{document_table};
	}
	if (exists $old_row->{document_id_field}) {
	    $new_row{doc_id_field} = $old_row->{document_id_field};
	}
	if (exists $old_row->{document_fields}) {
	    $new_row{doc_fields} = $old_row->{document_fields};
	}

	_log("... Inserting collection ($new_row{collection})\n") if $PA;
	$self->{DB}->insert_collection_table_row(\%new_row)
    }
    return 1;
}

sub _update_collection_info {
    my $self = shift;
    my ($field, $value) = @_;

    my $attribute = $field;
    $attribute =~ tr/[a-z]/[A-Z]/;
    my $sql = $self->{DB}->update_collection_info($field);
    $self->{INDEX_DBH}->do($sql, undef, $value, $self->{COLLECTION});
    $self->{$attribute} = $value;
}

sub _delete_collection_info {
    my $self = shift;

    my $sql = $self->{DB}->delete_collection_info;
    $self->{INDEX_DBH}->do($sql, undef, $self->{COLLECTION});
    _log("Deleting collection $self->{COLLECTION} from collection table\n")
	if $PA;
}

sub _store_collection_info {

    my $self = shift;

    _log(qq(Inserting collection $self->{COLLECTION} into collection table\n))
	if $PA;

    my $sql = $self->{DB}->store_collection_info;
    my $doc_fields = join (',', @{$self->{DOC_FIELDS}});
    my $stoplists = ref $self->{STOPLIST} ?
	join (',', @{$self->{STOPLIST}}) : '';

    my $version = $DBIx::TextIndex::VERSION;

    if ($version =~ m/(\d+)\.(\d+)\.(\d+)/) {
	$version = "$1.$2$3" + 0;
    }

    $self->{INDEX_DBH}->do($sql, undef,

			   $self->{COLLECTION},
			   $version,
			   $self->{MAX_INDEXED_ID},
			   $self->{DOC_TABLE},
			   $self->{DOC_ID_FIELD},

			   $doc_fields,
			   $self->{CHARSET},
			   $stoplists,
			   $self->{PROXIMITY_INDEX},

			   $ERROR{empty_query},
			   $ERROR{quote_count},
			   $ERROR{no_results},
			   $ERROR{no_results_stop},
			   $ERROR{wildcard_length},
			   $ERROR{wildcard_expansion},

			   $self->{MAX_WORD_LENGTH},
			   $self->{RESULT_THRESHOLD},
			   $self->{PHRASE_THRESHOLD},
			   $self->{MIN_WILDCARD_LENGTH},
			   $self->{MAX_WILDCARD_TERM_EXPANSION},

			   $self->{DECODE_HTML_ENTITIES},
			   $self->{SCORING_METHOD},
			   $self->{UPDATE_COMMIT_INTERVAL},
			   ) || croak $DBI::errstr;

}

sub _fetch_collection_info {

    my $self = shift;

    return 0 unless $self->{COLLECTION};

    return 0 unless $self->_collection_table_exists;

    if ($self->_collection_table_upgrade_required) {
	carp __PACKAGE__ . ": Collection table must be upgraded, call \$index->upgrade_collection_table() or create a new() \$index and call \$index->initialize() to upgrade the collection table";
	return 0;
    }

    my $sql = $self->{DB}->fetch_collection_info;

    my $sth = $self->{INDEX_DBH}->prepare($sql);

    $sth->execute($self->{COLLECTION});

    my $doc_fields = '';
    my $stoplists = '';

    my $collection;
    $sth->bind_columns(\(
		       $collection,
		       $self->{VERSION},
		       $self->{MAX_INDEXED_ID},
		       $self->{DOC_TABLE},
		       $self->{DOC_ID_FIELD},

		       $doc_fields,
		       $self->{CHARSET},
		       $stoplists,
		       $self->{PROXIMITY_INDEX},

		       $ERROR{empty_query},
		       $ERROR{quote_count},
		       $ERROR{no_results},
		       $ERROR{no_results_stop},
		       $ERROR{wildcard_length},
		       $ERROR{wildcard_expansion},

		       $self->{MAX_WORD_LENGTH},
		       $self->{RESULT_THRESHOLD},
		       $self->{PHRASE_THRESHOLD},
		       $self->{MIN_WILDCARD_LENGTH},
		       $self->{MAX_WILDCARD_TERM_EXPANSION},

		       $self->{DECODE_HTML_ENTITIES},
		       $self->{SCORING_METHOD},
		       $self->{UPDATE_COMMIT_INTERVAL},
		       ));

    $sth->fetch;
    $sth->finish;

    my @doc_fields = split(/,/, $doc_fields);
    my @stoplists = split (/,\s*/, $stoplists);

    $self->{DOC_FIELDS} = \@doc_fields;
    $self->{STOPLIST} = \@stoplists;

    $self->{CHARSET} = $self->{CHARSET} || $COLLECTION_FIELD_DEFAULT{charset};
    $self->{CZECH_LANGUAGE} = $self->{CHARSET} eq 'iso-8859-2' ? 1 : 0;

    return $collection ? 1 : 0;

}

sub _phrase_fullscan {
    my $self = shift;
    my $docref = shift;
    my $fno = shift;
    my $phrase = shift;

    my @docs = @{$docref};
    my $docs = join(',', @docs);
    my @found;

    my $sql = $self->{CZECH_LANGUAGE} ? 
	$self->{DB}->phrase_scan_cz($docs, $fno) :
	$self->{DB}->phrase_scan($docs, $fno);

    my $sth = $self->{DOC_DBH}->prepare($sql);

    if ($self->{CZECH_LANGUAGE}) {
	$sth->execute;
    } else {
	$sth->execute("%$phrase%");
    }

    my ($doc_id, $content);
    if ($self->{CZECH_LANGUAGE}) {
	$sth->bind_columns(\$doc_id, \$content);
    } else {
	$sth->bind_columns(\$doc_id);
    }

    # FIXME: this now works on doc_keys, not ids
    # FIXME: come up with unit tests for indexes without proximity_index

    while($sth->fetch) {
	if ($self->{CZECH_LANGUAGE}) {
	    $content = $self->_lc_and_unac($content);
	    push(@found, $doc_id) if (index($content, $phrase) != -1);
	    _log("content scan for $doc_id, phrase = $phrase\n")
		if $PA > 1;
	} else {
	    push(@found, $doc_id);
	}
    }

    return \@found;
}

sub _fetch_docweights {
    my $self = shift;
    my $all_fields = shift;

    my @fnos;
    if ($all_fields) {
	@fnos = (0 .. $#{$self->{DOC_FIELDS}});
    } else {
	# skip over if we already have hash entry
	foreach my $fno (@{$self->{TERM_FIELD_NOS}}) {
	    unless (ref $self->{W_D}->[$fno]) {
		push @fnos, $fno;
	    } 
	}
    }

    if ($#fnos > -1) {
	my $fnos = join(',', @fnos);

	my $sql = $self->{DB}->fetch_docweights($fnos);

	my $sth = $self->{INDEX_DBH}->prepare($sql);

	$sth->execute || warn $DBI::errstr;

	while (my $row = $sth->fetchrow_arrayref) {
	    $self->{AVG_W_D}->[$row->[0]] = $row->[1];
	    # Ugly, DBD::SQLite doesn't quote \0 when using placeholders
	    if ($self->{DBD_TYPE} eq 'SQLite') {
		my $packed_w_d = $row->[2];
		$packed_w_d =~ s/\\0/\0/g;
		$packed_w_d =~ s/\\\\/\\/g;
		$self->{W_D}->[$row->[0]] = [ unpack('f*', $packed_w_d) ];
	    } else {
		$self->{W_D}->[$row->[0]] = [ unpack('f*', $row->[2]) ];
	    }
	}
    }
}

sub _search_okapi {

    no warnings qw(uninitialized);

    my $self = shift;

    my %score;                # accumulator to hold doc scores

    my $b = 0.75;             # $b, $k1, $k3 are parameters for Okapi
    my $k1 = 1.2;             # BM25 algorithm
    my $k3 = 7;               #
    my $f_qt;                 # frequency of term in query
    my $f_t;                  # Number of documents that contain term
    my $W_d;                  # weight of document, sqrt((1 + log(terms))**2)
    my $avg_W_d;              # average document weight in collection
    my $doc_id;               # document id
    my $f_dt;                 # frequency of term in given doc_id
    my $idf = 0;
    my $fno = 0;

    my $acc_size = 0;         # current number of keys in %score

    # FIXME: use actual document count
    my $N = $self->{MAX_INDEXED_ID};

    $self->_fetch_docweights;

    my $result_max = $self->{RESULT_VECTOR}->Max;
    my $result_min = $self->{RESULT_VECTOR}->Min;

    if ($result_max < 1) {
	if (not @{$self->{STOPLISTED_QUERY}}) {
	    throw_query( error => $ERROR{no_results} );
	}
        else {
	    throw_query( error => $self->_format_stoplisted_error );
	}
    }

    foreach my $fno ( @{$self->{TERM_FIELD_NOS}} ) {
	$avg_W_d = $self->{AVG_W_D}->[$fno];
	foreach my $term (@{$self->{TERMS}->[$fno]}) {
	    $f_t = $self->{F_T}->[$fno]->{$term} ||
		$self->{C}->f_t($fno, $term);
	    $idf =  log(($N - $f_t + 0.5) / ($f_t + 0.5));
	    next if $idf < IDF_MIN_OKAPI; # FIXME: do we want do warn that term was stoplisted?
	    $f_qt = $self->{F_QT}->[$fno]->{$term};     # freq of term in query
	    my $w_qt = (($k3 + 1) * $f_qt) / ($k3 + $f_qt); # query term weight
	    my $term_docs = $self->{TERM_DOCS}->[$fno]->{$term} ||
		$self->{C}->term_docs($fno, $term);
	    score_term_docs_okapi($term_docs, \%score, $self->{RESULT_VECTOR}, ACCUMULATOR_LIMIT, $result_min, $result_max, $idf, $f_t, $self->{W_D}->[$fno], $avg_W_d, $w_qt, $k1, $b);
	}
    }

    unless (scalar keys %score) {
	if (not @{$self->{STOPLISTED_QUERY}}) {
	    throw_query( error => $ERROR{no_results} );
	}
        else {
	    throw_query( error => $self->_format_stoplisted_error );
	}
    }
    return $self->_doc_ids_to_keys(\%score);
}

sub _doc_ids_to_keys {
    my $self = shift;
    my $score = shift;
    my %copy = %$score;
    my @doc_ids = sort { $a <=> $b } keys %$score;
    my $doc_keys = $self->{DB}->fetch_doc_keys(\@doc_ids);
    my %score_by_keys;
    @score_by_keys{@$doc_keys} = @$score{@doc_ids};
    return \%score_by_keys;
}

sub _format_stoplisted_error {
    my $self = shift;
    my $stopped = join(', ', @{$self->{STOPLISTED_QUERY}});
    return qq($ERROR{no_results_stop} $stopped.);
}

######################################################################
#
# _optimize_or_search()
#
#   If query contains large number of OR terms,
#   turn the rarest terms into AND terms to reduce result set size
#   before scoring.
#
#   Algorithm: if there are four or less query terms turn the two
#   least frequent OR terms into AND terms. For five or more query
#   terms, make the three least frequent OR terms into AND terms.
#
#   Does nothing if AND or NOT terms already exist
#

sub _optimize_or_search {
    my $self = shift;
    foreach my $fno ( @{$self->{QUERY_FIELD_NOS}} ) {

	my @clauses = @{$self->{QUERY}->[$fno]};

	my %f_t;
	my @or_clauses;
	my $or_term_count = 0;
	foreach my $clause (@clauses) {
	    return if exists $clause->{CONJ};           # user explicitly asked
	    return if ($clause->{MODIFIER} eq 'NOT'     # for boolean query 
		      || $clause->{MODIFIER} eq 'AND');
	    if ($clause->{TYPE} eq 'TERM'
		|| $clause->{TYPE} eq 'PLURAL'
		|| $clause->{TYPE} eq 'WILD') {

		if ($clause->{MODIFIER} eq 'OR') {
		    $or_term_count++;
		    my $term = $clause->{TERM};
		    $f_t{$term} = $self->{C}->f_t($fno, $term) || 0;
		    push @or_clauses, $clause;
		}
	    } elsif ($clause->{TYPE} eq 'IMPLICITPHRASE'
		     || $clause->{TYPE} eq 'PHRASE') {
		if ($clause->{MODIFIER} eq 'OR') {
		    $clause->{MODIFIER} = 'AND';
		}
	    } else {
		return;
	    }
	}
	return if $or_term_count < 1;

	# sort in order of f_t
	my @f_t_sorted =
	    sort { $f_t{$a->{TERM}} <=> $f_t{$b->{TERM}} } @or_clauses;

	if ($or_term_count >= 1) {
	    $f_t_sorted[0]->{MODIFIER} = 'AND';
	}
	if ($or_term_count >= 2) {
	    $f_t_sorted[1]->{MODIFIER} = 'AND';
	}
	if ($or_term_count > 4) {
	    $f_t_sorted[2]->{MODIFIER} = 'AND';
	}
    }
}

sub _resolve_mask {

    my $self = shift;

    return unless $self->{MASK};

    $self->{RESULT_MASK} = Bit::Vector->new($self->{MAX_INDEXED_ID} + 1);
    $self->{RESULT_MASK}->Fill;

    if ($self->_fetch_mask) {
	$self->{VALID_MASK} = 1;
    }
    if ($self->{MASK}->{and_mask}) {
	foreach my $mask (@{$self->{MASK}->{and_mask}}) {
	    unless (ref $mask) {
		next unless ref $self->{MASK_VECTOR}->{$mask};
		$self->{RESULT_MASK}->Intersection(
		    $self->{RESULT_MASK}, $self->{MASK_VECTOR}->{$mask});
	    } else {
		my $vector = Bit::Vector->new($self->{MAX_INDEXED_ID} + 1);
		$vector->Index_List_Store(@$mask);
		$self->{RESULT_MASK}->Intersection(
		    $self->{RESULT_MASK}, $vector);
	    }
	}
    }
    if ($self->{MASK}->{not_mask}) {
	foreach my $mask (@{$self->{MASK}->{not_mask}}) {
	    unless (ref $mask) {
		next unless ref $self->{MASK_VECTOR}->{$mask};
		$self->{MASK_VECTOR}->{$mask}->Flip;
		$self->{RESULT_MASK}->Intersection(
		    $self->{RESULT_MASK}, $self->{MASK_VECTOR}->{$mask});
	    } else {
		my $vector = Bit::Vector->new($self->{MAX_INDEXED_ID} + 1);
		$vector->Index_List_Store(@$mask);
		$vector->Flip;
		$self->{RESULT_MASK}->Intersection(
		    $self->{RESULT_MASK}, $vector);
	    }
	}
    }
    if ($self->{MASK}->{or_mask}) {
	push @{$self->{MASK}->{or_mask_set}}, $self->{MASK}->{or_mask};
    }
    if ($self->{MASK}->{or_mask_set}) {
	foreach my $mask_set (@{$self->{MASK}->{or_mask_set}}) {
	    my $or_mask_count = 0;
	    my $union_vector = Bit::Vector->new($self->{MAX_INDEXED_ID} + 1);
	    foreach my $mask (@$mask_set) {
		unless (ref $mask) {
		    next unless ref $self->{MASK_VECTOR}->{$mask};
		    $or_mask_count++;
		    $union_vector->Union(
		        $union_vector, $self->{MASK_VECTOR}->{$mask});
		} else {
		    $or_mask_count++;
		    my $vector = Bit::Vector->new($self->{MAX_INDEXED_ID} + 1);
		    $vector->Index_List_Store(@$mask);
		    $union_vector->Union(
		        $union_vector, $self->{MASK_VECTOR}->{$mask});
		}
	    }
	    if ($or_mask_count) {
		$self->{RESULT_MASK}->Intersection(
		    $self->{RESULT_MASK}, $union_vector);
	    }
	}
    }
}

sub _fetch_mask {
    my $self = shift;

    my $sql = $self->{DB}->fetch_mask;
    my $sth = $self->{INDEX_DBH}->prepare($sql);

    my $mask_count = 0;
    my $i = 0;

    foreach my $mask (@{$self->{MASK_FETCH_LIST}}) {
	if (ref ($self->{MASK_VECTOR}->{$mask})) {
	    # We already have one, go ahead
	    $mask_count++;
	    next;
	}

	$sth->execute($mask);

	next if $sth->rows < 1;
	$mask_count += $sth->rows;

	my $docs_vector;
	$sth->bind_col(1, \$docs_vector);
	$sth->fetch;

	$self->{MASK_VECTOR}->{$mask} =
	    Bit::Vector->new_Enum(($self->{MAX_INDEXED_ID} + 1), $docs_vector);

	$i++;

    }
    return $mask_count;
}

# Set everything to lowercase and change accented characters to
# unaccented equivalents
sub _lc_and_unac {
    my $self = shift;
    my $s = shift;
    $s = unac_string($self->{CHARSET}, $s) if DO_UNAC;
    $s = lc($s);
    return $s;
}

sub _docs {
    my $self = shift;
    my $fno = shift;
    my $term = shift;

    local $^W = 0; # turn off uninitialized value warning
    if (@_) {
	$self->{TERM_DOCS_VINT}->[$fno]->{$term} .= pack 'w*', @_;
	$self->{DOCFREQ_T}->[$fno]->{$term}++; 
    } else {
	$self->{C}->term_docs_hashref($fno, $term);
    }
}

sub _positions {
    my $self = shift;
    my $fno = shift;
    my $term = shift;
    if (@_) {
	my $positions = shift;
	$self->{TERM_POS}->[$fno]->{$term} .=
	    pack_vint_delta($positions);
    }
}

sub _commit_docs {
    my $self = shift;

    my $added_ids = shift || $self->{ADDED_IDS};

    my $id_a = $self->max_indexed_id + 1; # old max_indexed_id
    $self->max_indexed_id($added_ids->[-1]);
    $self->all_doc_ids($added_ids);

    my ($sql, $sth);
    my $id_b = $self->{MAX_INDEXED_ID};

    _log("Storing doc weights\n") if $PA;

    $self->_fetch_docweights(1);

    $self->{INDEX_DBH}->begin_work;

    $sth = $self->{INDEX_DBH}->prepare($self->{DB}->update_docweights);

    no warnings qw(uninitialized);
    foreach my $fno ( 0 .. $#{$self->{DOC_FIELDS}} ) {
	my @w_d;
	if ($#{$self->{W_D}->[$fno]} >= 0) {
	    @w_d = @{$self->{W_D}->[$fno]};
	    @w_d[$id_a .. $id_b] =
		@{$self->{NEW_W_D}->[$fno]}[$id_a .. $id_b];
	} else {
	    @w_d = @{$self->{NEW_W_D}->[$fno]};
	}
	my $sum;
	foreach (@w_d) {
	    $sum += $_;
	}
	# FIXME: use actual doc count instead of max_indexed_id
	my $avg_w_d = $sum / $id_b; 
	$w_d[0] = 0 unless defined $w_d[0];
	# FIXME: this takes too much space, use a float compression method
	my $packed_w_d = pack 'f*', @w_d;
	$self->{DB}->update_docweights_execute($sth, $fno, $avg_w_d, $packed_w_d);
	# Set AVG_W_D and W_D cached values to new value, in case same 
	# instance is used for search immediately after adding to index
	$self->{AVG_W_D}->[$fno] = $avg_w_d;
	$self->{W_D}->[$fno] = \@w_d;
    }

    $sth->finish;

    # Delete temporary in-memory structure
    delete($self->{NEW_W_D});

    _log("Committing inverted tables to database\n") if $PA;

    foreach my $fno ( 0 .. $#{$self->{DOC_FIELDS}} ) {

	_log("field$fno ", scalar keys %{$self->{TERM_DOCS_VINT}->[$fno]},
             " distinct terms\n") if $PA;

	my $s_sth;

	# SQLite chokes with "database table is locked" unless s_sth
	# is finished before i_sth->execute
	unless ($self->{DBD_TYPE} eq 'SQLite') {
	    $s_sth = $self->{INDEX_DBH}->prepare(
		         $self->{DB}->inverted_select(
			    $self->{INVERTED_TABLES}->[$fno] ) );
	}
	my $i_sth = $self->{INDEX_DBH}->prepare(
		        $self->{DB}->inverted_replace(
			    $self->{INVERTED_TABLES}->[$fno] ) );

	my $tc = 0;
	while (my ($term, $term_docs_vint) =
	       each %{$self->{TERM_DOCS_VINT}->[$fno]}) {

	    _log("$term\n") if $PA >= 2;
	    if ($PA && $tc > 0) {
		_log("committed $tc terms\n") if $tc % 500 == 0;
	    }

	    my $o_docfreq_t = 0;
	    my $o_term_docs = '';
	    my $o_term_pos = '';

	    $s_sth = $self->{INDEX_DBH}->prepare( $self->{DB}->inverted_select(
				   $self->{INVERTED_TABLES}->[$fno]) )
		if $self->{DBD_TYPE} eq 'SQLite';
	    $s_sth->execute($term);
	    $s_sth->bind_columns(\$o_docfreq_t, \$o_term_docs, \$o_term_pos);
	    $s_sth->fetch;
	    $s_sth->finish if $self->{DBD_TYPE} eq 'SQLite';
	    my $term_docs = pack_term_docs_append_vint($o_term_docs,
						       $term_docs_vint);

	    my $term_pos = $o_term_pos . $self->{TERM_POS}->[$fno]->{$term};

	    $self->{DB}->inverted_replace_execute(
		$i_sth,
	        $term,
		$self->{DOCFREQ_T}->[$fno]->{$term} + $o_docfreq_t,
		$term_docs,
		$term_pos,
	    );

	    delete($self->{TERM_DOCS_VINT}->[$fno]->{$term});
            delete($self->{TERM_POS}->[$fno]->{$term});
	    $tc++;
	}
        $i_sth->finish if $self->{DBD_TYPE} eq 'SQLite';
	_log("committed $tc terms\n") if $PA && $tc > 0;
	# Flush temporary hashes after data is stored
	delete($self->{TERM_DOCS_VINT}->[$fno]);
	delete($self->{TERM_POS}->[$fno]);
	delete($self->{DOCFREQ_T}->[$fno]);
    }

    $self->{INDEX_DBH}->commit;

}

sub _add_to_delete_queue {
    my $self = shift;
    my @ids = @_;
    if (ref $ids[0] eq 'ARRAY') {
	@ids = @{$ids[0]};
    }

    my $delete_queue_enum = $self->{DB}->fetch_delete_queue || "";
    my $delete_queue_vector = Bit::Vector->new_Enum($self->max_indexed_id + 1,
                                  $delete_queue_enum);

    $delete_queue_vector->Index_List_Store(@ids);

    $self->{DB}->update_delete_queue($delete_queue_vector->to_Enum);

}

sub _all_doc_ids_remove {
    my $self = shift;
    my @ids = @_;
    # doc_id bits to unset
    if (ref $ids[0] eq 'ARRAY') {
	@ids = @{$ids[0]};
    }

    unless (ref $self->{ALL_DOCS_VECTOR}) {
	$self->{ALL_DOCS_VECTOR} = Bit::Vector->new_Enum(
               $self->max_indexed_id + 1,
	       $self->_fetch_all_docs_vector
	   );
    }

    if (@ids) {
	$self->{ALL_DOCS_VECTOR}->Index_List_Remove(@ids);
	$self->{INDEX_DBH}->do($self->{DB}->update_all_docs_vector, undef,
			       $self->{ALL_DOCS_VECTOR}->to_Enum);
    }

}

sub all_doc_ids {
    my $self = shift;
    my @ids = @_;

    # doc_id bits to set
    if (ref $ids[0] eq 'ARRAY') {
	@ids = @{$ids[0]};
    }
    no warnings qw(uninitialized);
    unless (ref $self->{ALL_DOCS_VECTOR}) {
	$self->{ALL_DOCS_VECTOR} = Bit::Vector->new_Enum(
            $self->max_indexed_id + 1,
	    $self->_fetch_all_docs_vector
	);
    }

    if (@ids) {
	if ($self->{ALL_DOCS_VECTOR}->Size() < $self->max_indexed_id + 1) {
	    $self->{ALL_DOCS_VECTOR}->Resize($self->max_indexed_id + 1);
	}
	$self->{ALL_DOCS_VECTOR}->Index_List_Store(@ids);
	$self->{INDEX_DBH}->do($self->{DB}->update_all_docs_vector, undef,
			       $self->{ALL_DOCS_VECTOR}->to_Enum);
    }
    else {
	# FIXME: this is probably unnecessary, but older versions
	# had this documented as a public method
	return $self->{ALL_DOCS_VECTOR}->Index_List_Read;
    }
}

sub fetch_all_docs_vector {
    my $self = shift;
    unless (ref $self->{ALL_DOCS_VECTOR}) {
	$self->{ALL_DOCS_VECTOR} = Bit::Vector->new_Enum(
            $self->max_indexed_id + 1,
	    $self->_fetch_all_docs_vector
	);
    }
}

sub _fetch_all_docs_vector {
    my $self = shift;
    my $sql = $self->{DB}->fetch_all_docs_vector;
    return scalar $self->{INDEX_DBH}->selectrow_array($sql);
}


sub _fetch_doc {
    my $self = shift;
    my $id = shift;
    my $field = shift;

    my $sql = $self->{DB}->fetch_doc($field);
    return scalar $self->{DOC_DBH}->selectrow_array($sql, undef, $id);
}

sub _fetch_doc_all_fields {
    my $self = shift;
    my $id = shift;
    my $sql = $self->{DB}->fetch_doc_all_fields();
    my @fields = $self->{DOC_DBH}->selectrow_array($sql, undef, $id);
    my %fields;
    foreach my $i (0 .. $#fields) {
	$fields{$self->{DOC_FIELDS}->[$i]} = $fields[$i];
    }
    return \%fields;
}

sub _terms {
    my $self = shift;
    my $doc = shift;

    # kill tags
    $doc =~ s/<.*?>/ /g;

    # Decode HTML entities
    if ($self->{DECODE_HTML_ENTITIES}) {
	$doc = HTML::Entities::decode($doc);
    }

    $doc = $self->_lc_and_unac($doc);

    # split words on any non-word character or on underscore

    return grep {
	$_ = substr($_, 0, $self->{MAX_WORD_LENGTH});
	$_ =~ /[a-z0-9]+/ && not $self->_stoplisted($_)
    } split(/[^a-zA-Z0-9]+/, $doc);
}

sub _ping_doc {
    my $self = shift;
    my $id = shift;
    my $found_doc = 0;
    my $sql = $self->{DB}->ping_doc;
    ($found_doc) = $self->{DOC_DBH}->selectrow_array($sql, undef, $id);
    return $found_doc;
}

sub _create_tables {
    my $self = shift;
    my ($sql, $sth);

    # mask table

    _log("Dropping mask table ($self->{MASK_TABLE})\n") if $PA;
    $self->{DB}->drop_table($self->{MASK_TABLE});

    $sql = $self->{DB}->create_mask_table;
    _log("Creating mask table ($self->{MASK_TABLE})\n") if $PA;
    $self->{INDEX_DBH}->do($sql);

    # docweights table

    _log("Dropping docweights table ($self->{DOCWEIGHTS_TABLE})\n") if $PA;
    $self->{DB}->drop_table($self->{DOCWEIGHTS_TABLE});

    $sql = $self->{DB}->create_docweights_table;
    _log("Creating docweights table ($self->{DOCWEIGHTS_TABLE})\n") if $PA;
    $self->{INDEX_DBH}->do($sql);

    # docs vector table

    _log("Dropping docs vector table ($self->{ALL_DOCS_VECTOR_TABLE})\n")
	if $PA;
    $self->{DB}->drop_table($self->{ALL_DOCS_VECTOR_TABLE});

    _log("Creating docs vector table ($self->{ALL_DOCS_VECTOR_TABLE})\n")
	if $PA;
    $self->{INDEX_DBH}->do($self->{DB}->create_all_docs_vector_table);

    # delete queue table

    _log("Dropping delete queue table ($self->{DELETE_QUEUE_TABLE})\n")
	if $PA;
    $self->{DB}->drop_table($self->{DELETE_QUEUE_TABLE});

    _log("Creating delete queue table ($self->{DELETE_QUEUE_TABLE})\n")
	if $PA;
    $self->{INDEX_DBH}->do($self->{DB}->create_delete_queue_table);

    # doc key table

    _log("Dropping doc key table ($self->{DOC_KEY_TABLE})\n") if $PA;
    $self->{DB}->drop_doc_key_table();
    _log("Creating doc key table ($self->{DOC_KEY_TABLE})\n") if $PA;
    $self->{INDEX_DBH}->do($self->{DB}->create_doc_key_table);

    # inverted tables

    foreach my $table ( @{$self->{INVERTED_TABLES}} ) {
	_log("Dropping inverted table ($table)\n") if $PA;
	$self->{DB}->drop_table($table);

	$sql = $self->{DB}->create_inverted_table($table);
	_log("Creating inverted table ($table)\n") if $PA;
	$self->{INDEX_DBH}->do($sql);
    }
}

sub _stoplisted {
    my $self = shift;
    my $term = shift;

    if ($self->{STOPLIST} and $self->{STOPLISTED_WORDS}->{$term}) {
	push(@{$self->{STOPLISTED_QUERY}}, $term);
	_log(" stoplisting: $term\n") if $PA > 1;
	return 1;
    } else {
	return 0;
    }
}

sub create_accessors {
    my $fields = shift;
    my $pkg = caller();
    no strict 'refs';
    foreach my $field (@$fields) {
	*{"${pkg}::$field"} = sub {
	    my $self = shift;
	    $self->set({ $field => shift }) if @_;
	    return $self->{$field};
	}
    }
}

sub get {
    my $self = shift;
    return wantarray ? @{$self}{@_} : $self->{$_[0]};
}

sub set {
    my $self = shift;

    throw_gen({ error => 'incorrect number of args for set()' })
	unless @_;

    my ($keys, $values) = @_ == 1 ? ([keys %{$_[0]}], [values %{$_[0]}]) : @_;

    my ($key, $old_value, $new_value, $is_dirty);
    foreach my $i (0 .. $#$keys) {
	$key = $keys->[$i];
	$new_value = $values->[$i];
	$old_value = $self->{uc $key};

	if ((not defined $new_value and not defined $old_value) or
	    (defined $new_value and defined $old_value and
	     $old_value eq $new_value)) {
	    next;
	}
	$is_dirty = 1;
	$self->{uc $key} = $new_value;
    }
    return $self;
}

1;
__END__


=head1 NAME

DBIx::TextIndex - Perl extension for full-text searching in SQL databases

=head1 SYNOPSIS

 use DBIx::TextIndex;

 $index = DBIx::TextIndex->new({
     index_dbh => $index_dbh,
     collection => 'collection_name',
     doc_fields => ['field1', 'field2'],
 });

 $index->initialize();

 $index->add( key1 => { field1 => 'some text', field2 => 'more text' } );

 $results = $index->search({
     field1 => '"a phrase" +and -not or',
     field2 => 'more words',
 });

 foreach my $key
     (sort {$$results{$b} <=> $$results{$a}} keys %$results ) 
 {
     print "Key: $key Score: $$results{$key} \n";
 }

=head1 DESCRIPTION

DBIx::TextIndex was developed for doing full-text searches on BLOB
columns stored in a database.  Almost any database with BLOB and DBI
support should work with minor adjustments to SQL statements in the
module.  MySQL, PostgreSQL, and SQLite are currently supported.

As of version 0.24, data from any source outside of a database can be
indexed by passing the data to the C<add()> method as a string.

=head1 INDEX CREATION

=head2 Preparing an index for use for the first time

To set up a new index, call C<new()>, followed by C<initialize()>.

 $index = DBIx::TextIndex->new({
     index_dbh => $dbh,
     collection => 'my_books',
     doc_fields => [ 'title', 'author', 'text' ],
 });

 $index->initialize();

C<initialize()> should only be called the first time a new index is created.
Calling initialize a second time with the same collection name will delete
and re-create the index.

The C<doc_fields> attribute specifies which fields of a document are contained
in the index.  This decision must be made at initialization -- additional
document fields cannot be added to the index later.

After the index is initialized once, subsequent calls to C<new()> require
only the C<index_dbh> and C<collection> arguments.

 $index = DBIx::TextIndex->new({
     index_dbh => $dbh,
     collection => 'my_books',
 });

=head2 Adding documents to the index

Every document is made up of fields, and has a unique key that is
returned with search results.

 $index->add( book1 => {
                         author => 'Leo Tolstoy',
                         title => 'War and Peace',
                         text => '"Well, Prince, so Genoa and Lucca ...',
                       },

              book2 => {
                         author => 'J.R.R. Tolkien',
                         title => 'The Hobbit',
                         text => 'In a hole in the ground there lived ...',
                       },
             );

With each call to C<add()>, the index is written to tables in the underlying
SQL database.

When adding many documents in a loop, use C<begin_add()> and C<commit_add()>
around the loop.  This will increase indexing performance by 
delaying writes to the SQL database until C<commit_add()> is called.

 $index->begin_add();

 while ( my ($book_id, $author, $title, $text) = fetch_doc() ) {
     $index->add( $book_id => { author => $author,
                                title => $title,
                                text => $text }   );
 }

 $index->commit_add();

=head2 Indexing data in SQL tables

DBIx::TextIndex has additional convenience methods to index data contained
in SQL tables.  Before calling C<initialize()> also set the C<doc_dbh>,
C<doc_table>, and C<doc_id_field> attributes:

 $index = DBIx::TextIndex->new({
     index_dbh => $dbh,
     collection => 'my_books',
     doc_dbh => $doc_dbh,
     doc_table => 'book',
     doc_id_field => 'book_id',
     doc_fields => [ 'title', 'author', 'text' ],
 });

 $index->initialize();

After initialization, subsequent creation of index objects only require
the C<index_dbh>, C<collection>, and C<doc_dbh> arguments:

 $index = DBIx::TextIndex->new({
     index_dbh => $dbh,
     collection => 'my_books',
     doc_dbh => $doc_dbh,
 });

Passing an array of ids to C<add_doc()> indexes the C<doc_fields>
(columns) in C<doc_table> matched using the C<doc_id_field> column.

 $index->add_doc(1, 2, 3);

C<add_doc()> creates SQL statements to retrieve data from the document table
before adding to the index. In the above example, a series of statements like
C<"SELECT title, author, text FROM book WHERE book_id = 1"> would be issued.

If more flexibility is needed, data could be fetched first and passed to the
C<add()> method instead. For example, a multi-table JOIN could be issued
or several columns could be concatenated into a single index field.

=head1 QUERY SYNTAX

FIXME: This section is incomplete.

Searches are case insensitive.

=head2 Boolean Operations

DBIx::TextIndex supports several variations of boolean operators. The
C<AND>, C<OR>, and C<NOT> operators are upper case only.

=over 4

=item OR, ||

 cat OR dog
 cat || dog

=item AND, &&, +

 cat AND dog
 cat && dog
 +cat +dog

=item NOT, !, -

 cat NOT dog
 cat ! dog
 cat -dog

=back

=head2 Grouping With Parentheses

Parentheses may be used in conjunction with other operators to form
complex boolean expressions:

 (cat OR dog) AND goat

 (cat OR dog) AND (goat OR chicken)

=head2 Phrase Searches

Enclose phrases in double quotes:

 "See Spot run"

=head2 Proximity Searches

Use the tilde C<"~"> operator at the end of phrase to find words within
a certain distance.

 "some phrase"~1   - matches only exact "some phrase"
 "some phrase"~2   - matches "some other phrase"
 "some phrase"~10  - matches "some [1..9 words] phrase"

Defaults to C<~1> when omitted, which is a normal phrase search.

The proximity match works from left to right, which means C<"some
phrase"~3> does not match C<"phrase other some"> or C<"phrase some">

=head2 Wildcard Partial-Term Searches

You can use wildcard characters C<"*"> or C<"?"> at the end of or in
the middle of search terms:

C<"*"> matches zero or more characters

 car*	  - "car", "cars", "careful", "cartel", ....
 ca*r     - "car", "career", "caper", "cardiovascular"

C<"?"> matches any single character

  car?    - "care", "cars", "cart"
  d?g     - "dig", "dog", "dug"

C<"+"> at the end matches singular or plural form (naively, by
         appending an 's' to the word)

  car+    - "car", "cars"

By default, at least 1 alphanumeric character must appear before the
first wildcard character.  The option C<min_wildcard_length> can be
changed to require more alphanumeric characters before the first
wildcard.

The option C<max_wildcard_term_expansion> specifies the maximum number
of words a wildcard term can expand to before throwing a query
exception.  The default is 30 words.


=head1 BOOLEAN SEARCH MASKS

DBIx::TextIndex can apply boolean operations on arbitrary lists of
doc ids to search results.

Take this table:

 doc_id  category  doc_full_text
 1       green     full text here ...
 2       green     ...
 3       blue      ...
 4       red       ...
 5       blue      ...
 6       green     ...

Masks that represent doc ids for in each the three categories can
be created:

=head2 C<add_mask()>

 $index->add_mask($mask_name, \@doc_ids);

 $index->add_mask('green_category', [ 1, 2, 6 ]);
 $index->add_mask('blue_category', [ 3, 5 ]);
 $index->add_mask('red_category', [ 4 ]);

The first argument is an arbitrary string, and the second is a
reference to any array of doc ids that the mask name identifies.

Mask operations are passed in a second argument hash reference to
$index->search():

 %query_args = (
     first_field => '+andword -notword orword "phrase words"',
     second_field => ...
     ...
 );

 %args = (
     not_mask => \@not_mask_list,
     and_mask => \@and_mask_list,
     or_mask  => \@or_mask_list,
     or_mask_set => [ \@or_mask_list_1, \@or_mask_list_2, ... ],
 );

 $index->search(\%query_args, \%args);

=over 4

=item not_mask

For each mask in the not_mask list, the intersection of the search query results and all documents not in the mask is calculated.

From our example above, to narrow search results to documents not in
green category:

 $index->search(\%query_args, { not_mask => ['green_category'] });

=item and_mask

For each mask in the and_mask list, the intersection of the search
query results and all documents in the mask is calculated.

This would give return results only in blue category:

 $index->search(\%query_args,
                { and_mask => ['blue_category'] });

Instead of using named masks, lists of doc ids can be passed on
the fly as array references.  This would give the same results as the
previous example:

 my @blue_ids = (3, 5);
 $index->search(\%query_args,
                { and_mask => [ \@blue_ids ] });

=item or_mask_set

With the or_mask_set argument, the union of all the masks in each list
is computed individually, and then the intersection of each union set
with the query results is calculated.

=item or_mask

An or_mask is treated as an or_mask_set with only one list. In
this example, the union of blue_category and red_category is taken,
and then the intersection of that union with the query results is
calculated:

 $index->search(\%query_args,
                { or_mask => [ 'blue_category', 'red_category' ] });

=back

=head2 C<delete_mask()>

 $index->delete_mask($mask_name);

Deletes a single mask from the mask table in the database.


=head1 INTERFACE

=head2 Public Methods

=head3 C<new()>

 $index = DBIx::TextIndex->new(\%args)

Constructor method, accepts args as a hashref.  The first time an index is
created, C<index_dbh>, C<collection>, C<doc_fields> and must be passed.
For subsequent calls to new, only C<index_dbh> and C<collection> are 
required.

To index documents using C<add_doc()>, C<doc_dbh>, C<doc_table>, and
C<doc_id_field> are also required for initialization. C<doc_dbh> is required
each time the index is used to add documents.

Other arguments are optional.

C<new()> accepts these arguments:

=over 8

=item index_dbh

 index_dbh => $index_dbh

DBI connection handle used to store tables for DBIx::TextIndex.
Use a separate database if possible to avoid name collisions
with existing tables.

=item collection

 collection => $collection

A name for the index. Should contain only alpha-numeric characters or
underscores [A-Za-z0-9_]. Limited to 100 characters.

=item doc_dbh

 doc_dbh => $doc_dbh

A DBI connection handle to database containing text documents

=item doc_table

 doc_table => $doc_table

Name of database table containing text documents

=item doc_fields

 doc_fields => \@doc_fields

An arrayref of fields contained in the index.  If using C<add_doc()>,
lists column names to be indexed in C<doc_table>.

=item doc_id_field

 doc_id_field => $doc_id_field

Name of an integer key column in C<doc_table>.  Must be a primary or unique
key.

=item proximity_index

 proximity_index => 1

Enables index structure to support phrase and proximity searches. Default
is on (C<1>), pass C<0> to turn off.

=item errors

 errors => {
     empty_query => "your query was empty",
     quote_count => "phrases must be quoted correctly",
     no_results => "your seach did not produce any results",
     no_results_stop => "no results, these words were stoplisted: ",
     wildcard_length =>
	    "Use at least one letter or number at the beginning " .
	    "of the word before wildcard characters.",
     wildcard_expansion =>
        "The wildcard term you used was too broad, " .
	"please use more characters before or after the wildcard",
 }

This hash reference can be used to override default error messages.

=item charset

 charset => 'iso-8859-1'

Default is 'iso-8859-1'.

Accented characters are converted to ASCII equivalents based on the charset.

Pass 'iso-8859-2' for Czech or other Slavic languages.

Only iso-8859-1 and iso-8859-2 have been tested.

=item stoplist

 stoplist => [ 'en' ]

Activates stoplisting of very common words that are present in almost
every document. Default is to not use stoplisting.  Value of the
parameter is a reference to array of two-letter language codes in
lower case.  Currently only two stoplists exist:

 en - English
 cz - Czech

Stoplisting is usually not recommended because certain queries
containing common words cannot be resolved, such as: "The Who" or "To
be or not to be."  DBIx::TextIndex is optimized well enough that the
performance gains from stoplisting are minimal.

=item max_word_length

 max_word_length => 20

Specifies maximum word length resolution. Defaults to 20 characters.

=item phrase_threshold

 phrase_threshold => 1000

If C<proximity_index> is turned off, and documents were indexed with
C<add_doc()>, and C<doc_dbh> is available, some phrase queries can be
resolved by scanning the original document rows with a LIKE '%phrase%'
query.  The phrase threshold is the maximum number of rows that will
be scanned.

It is recommended that the C<proximity_index> option always be used,
because it is more efficient than scanning rows, and it is not limited
to documents added using C<add_doc()>.

=item decode_html_entities

 decode_html_entities => 1

Decode html entities before indexing documents (e.g. &amp; -> &).
Default is 1.

=item print_activity

 print_activity => 0

Activates STDOUT debugging. Higher value increases verbosity.

=item update_commit_interval

 update_commit_interval => 20000

When indexing a large number of documents using C<add_doc()> or
C<add()> inside a C<begin_add()> / C<commit_add()> block, this setting
will trigger an automatic commit to the database when the number of
added documents exceeds this number.

Setting this higher will increase indexing speed, but also increase
memory usage. In tests, the default setting of 20000 when indexing
10KB documents results in about 500MB of memory used.

=item min_wildcard_length

 min_wildcard_length => 1

Defines the number of characters that must appear at the beginning of
a search term before the first wildcard character appears.  Must be at
least one character.

 d*       - is a valid search if min_wildcard_length = 1

If C<min_wildcard_length> = 3:

 do*      - invalid search
 dog*     - valid search

=item max_wildcard_term_expansion

 max_wildcard_term_expansion => 30

Internally, a wildcard search is expanded into an OR clause: C<car*>
is turned into C<(car OR cars OR careful OR cartel OR ...)>.  If a
search too broad, the wildcard term will expand into a query of
hundreds or thousands of terms. For example, the query containing
C<"a*"> would return any documents that contain a word starting with
"a".

The C<max_wildcard_term_expansion> places a hard limit on the number
of terms in the expansion. An exception is thrown if the limit is
exceeded.
 
=item doc_key_sql_type

 doc_key_sql_type => varchar

SQL datatype to store doc keys, defaults to varchar. If only numeric
keys are required, this could be changed to an integer type for more
compact storage.

=item doc_key_length

 doc_key_length => 200

The maximum length of a doc_key.

=back

After creating a new TextIndex for the first time, and after calling
initialize(), only the index_dbh, doc_dbh, and collection arguments
are needed to create subsequent instances of a TextIndex.

=head3 C<initialize()>

 $index->initialize()

This method creates all the inverted tables for DBIx::TextIndex in the
database specified by index_dbh. This method should be called only
once when creating an index for the first time. It drops all the
inverted tables before creating new ones.

C<initialize()> also stores the C<doc_table>, C<doc_fields>,
C<doc_id_field>, C<char_set>, C<stoplist>, C<error> attributes,
C<proximity_index>, C<max_word_length>, C<phrase_threshold> and
C<min_wildcard_length> preferences in a special table called
"collection," so subsequent calls to C<new()> for a given collection do
not need those arguments.

Calling C<initialize()> will upgrade the collection table created by
earlier versions of DBIx::TextIndex if necessary.

=head3 C<add()>

 $index->add($doc_key, \%doc_fields)

Indexes a document represented by hashref, where the keys of the hash
are field names and the values are strings to be indexed.  When
C<search()> is called, and a hit for that document is scored,
C<$doc_key> will be returned in the search results.

=head3 C<begin_add()>

Before performing a large number of <add()> operations in a loop, call
C<begin_add()> to delay writing to the database until C<commit_add()>
is called. If C<begin_add()> is not called, C<add()> will run in an
"autocommit" mode.

Has no effect if using C<add_doc()> method instead of C<add()>.

The C<update_commit_interval> parameter defines an upper limit on the
number of documents held in memory before being committed to the
database. If the limit is reached, the changes to the index will be
comitted at that point.

=head3 C<commit_add()>

Commits a group of C<add()> operations to the database. It is only
necessary to call this if C<begin_add()> was called first.

=head3 C<add_doc()>

 $index->add_doc(\@doc_ids)

Adds all the C<@docs_ids> matching rows with C<doc_id_field> from
C<doc_table> to the index. Reads from the database handle specified by
C<doc_dbh>.

If C<@doc_ids> references documents that are already indexed, those
documents will be re-indexed.

=head3 C<add_document()>

Deprecated, use C<add_doc()> instead.

=head3 C<remove()>

 $index->remove(\@doc_keys)

C<@doc_keys> can be a list of doc keys originally passed to C<add()>
or the numeric doc ids used for C<add_doc()>.

The disk space used for the removed doc keys is not recovered, so an
index rebuild is recommended after a significant amount of documents
are removed.

=head3 C<remove_document()>

Deprecated, use C<remove()>

=head3 C<remove_doc()>

Deprecated, use C<remove()>

=head3 C<search()>

 $results = $index->search(\%args)

C<search()> returns C<$results>, a hash reference.  The keys of the
hash are doc ids, and the values are the relative scores of the
documents.  If an error occured while searching, search will throw a
DBIx::TextIndex::Exception::Query object.

 eval {
     $results = $index->search({
         first_field => '+andword -notword orword "phrase words"',
         second_field => ...
         ...
     });
 };
 if ($@) {
     if ($@->isa('DBIx::TextIndex::Exception::Query') {
         print "No results: " . $@->error . "\n";
     } else {
         # Something more drastic happened
         $@->rethrow;
     }
 } else {
     print "The score for $doc_id is $results->{$doc_id}\n";
 }

=head3 C<unscored_search()>

 $doc_keys = $index->unscored_search(\%args)

unscored_search() returns $doc_ids, a reference to an array.  Since
the scoring algorithm is skipped, this method is much faster than search().
A DBIx::TextIndex::Exception::Query object will be thrown if the query is
bad or no results are found.

 eval {
     $doc_ids = $index->unscored_search({
         first_field => '+andword -notword orword "phrase words"',
         second_field => ...
     });
 };
 if ($@) {
     if ($@->isa('DBIx::TextIndex::Exception::Query') {
         print "No results: " . $@->error . "\n";
     } else {
         # Something more drastic happened
         $@->rethrow;
     }
 } else {
     print "Here's all the doc ids:\n";
     map { print "$_\n" } @$doc_ids;
 }

=head3 C<indexed()>

 if ($index->indexed($doc_key)) { ... }

Returns a number greater than zero if C<$index> contains C<$doc_key>.
Returns C<0> if C<$doc_key> is not found.

=head3 C<last_indexed_key()>

 $key = $index->last_indexed_key()

Returns the document key last added to the index. Useful for keeping
track of documents added to the index in some sequential order

=head3 C<optimize()>

FIXME: Implementation not complete

=head3 C<delete()>

 $index->delete()

C<delete()> removes the tables associated with a TextIndex from index_dbh.

=head3 C<stat()>

Allows you to obtain some meta information about the index. Accepts one
parameter that specifies what you want to obtain.

 $index->stat('total_words')

Returns a total count of words in the index. This number
may differ from the total count of words in the documents
itself.

=head3 C<upgrade_collection_table()>

 $index->upgrade_collection_table()

Upgrades the collection table to the latest format. Usually does not
need to be called by the programmer, because initialize() handles
upgrades automatically.

=head1 RESULTS HIGHLIGHTING

A module HTML::Highlight can be used either
independently or together with DBIx::TextIndex for this task.

The HTML::Highlight module provides a very nice Google-like
highligting using different colors for different words or phrases and also
can be used to preview a context in which the query words appear in
resulting documents.

The module works together with DBIx::TextIndex using its new method
html_highlight().

Check example script 'html_search.cgi' in the 'examples/' directory of
DBIx::TextIndex distribution or refer to the documentation of HTML::Highlight
for more information.

=head1 AUTHOR

Daniel Koch, dkoch@cpan.org.

=head1 COPYRIGHT

Copyright 1997-2007 by Daniel Koch.
All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, i.e., under the terms of the "Artistic
License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=head1 ACKNOWLEDGEMENTS

Thanks to Jim Blomo, for PostgreSQL patches.

Thanks to the lucy project (http://www.seg.rmit.edu.au/lucy/) for
ideas and code for the Okapi scoring function.

Simon Cozens' Lucene::QueryParser module was adapted to create the
DBIx::TextIndex QueryParser module.

Special thanks to Tomas Styblo, for first version of proximity index,
Czech language support, stoplists, highlighting, document removal and many
other improvements.

Thanks to Ulrich Pfeifer for ideas and code from Man::Index module
in "Information Retrieval, and What pack 'w' Is For" article from
The Perl Journal vol. 2 no. 2.

Thanks to Steffen Beyer for the Bit::Vector module, which
enables fast set operations in this module. Version 5.3 or greater of
Bit::Vector is required by DBIx::TextIndex.

=head1 BUGS

Documentation is not complete.

Please feel free to email me (dkoch@cpan.org) with any questions
or suggestions.

=head1 SEE ALSO

perl(1).

=cut
