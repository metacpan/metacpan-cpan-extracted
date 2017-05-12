package AI::Categorizer::KnowledgeSet;

use strict;
use Class::Container;
use AI::Categorizer::Storable;
use base qw(Class::Container AI::Categorizer::Storable);

use Params::Validate qw(:types);
use AI::Categorizer::ObjectSet;
use AI::Categorizer::Document;
use AI::Categorizer::Category;
use AI::Categorizer::FeatureVector;
use AI::Categorizer::Util;
use Carp qw(croak);

__PACKAGE__->valid_params
  (
   categories => {
		  type => ARRAYREF,
		  default => [],
		  callbacks => { 'all are Category objects' => 
				 sub { ! grep !UNIVERSAL::isa($_, 'AI::Categorizer::Category'),
					 @{$_[0]} },
			       },
		 },
   documents  => {
		  type => ARRAYREF,
		  default => [],
		  callbacks => { 'all are Document objects' => 
				 sub { ! grep !UNIVERSAL::isa($_, 'AI::Categorizer::Document'),
					 @{$_[0]} },
			       },
		 },
   scan_first => {
		  type => BOOLEAN,
		  default => 1,
		 },
   feature_selector => {
			isa => 'AI::Categorizer::FeatureSelector',
		       },
   tfidf_weighting  => {
			type => SCALAR,
			optional => 1,
		       },
   term_weighting  => {
		       type => SCALAR,
		       default => 'x',
		      },
   collection_weighting => {
			    type => SCALAR,
			    default => 'x',
			   },
   normalize_weighting => {
			   type => SCALAR,
			   default => 'x',
			  },
   verbose => {
	       type => SCALAR,
	       default => 0,
	      },
  );

__PACKAGE__->contained_objects
  (
   document => { delayed => 1,
		 class => 'AI::Categorizer::Document' },
   category => { delayed => 1,
		 class => 'AI::Categorizer::Category' },
   collection => { delayed => 1,
		   class => 'AI::Categorizer::Collection::Files' },
   features => { delayed => 1,
		 class => 'AI::Categorizer::FeatureVector' },
   feature_selector => 'AI::Categorizer::FeatureSelector::DocFrequency',
  );

sub new {
  my ($pkg, %args) = @_;
  
  # Shortcuts
  if ($args{tfidf_weighting}) {
    @args{'term_weighting', 'collection_weighting', 'normalize_weighting'} = split '', $args{tfidf_weighting};
    delete $args{tfidf_weighting};
  }

  my $self = $pkg->SUPER::new(%args);

  # Convert to AI::Categorizer::ObjectSet sets
  $self->{categories} = new AI::Categorizer::ObjectSet( @{$self->{categories}} );
  $self->{documents}  = new AI::Categorizer::ObjectSet( @{$self->{documents}}  );

  if ($self->{load}) {
    my $args = ref($self->{load}) ? $self->{load} : { path => $self->{load} };
    $self->load(%$args);
    delete $self->{load};
  }
  return $self;
}

sub features {
  my $self = shift;

  if (@_) {
    $self->{features} = shift;
    $self->trim_doc_features if $self->{features};
  }
  return $self->{features} if $self->{features};

  # Create a feature vector encompassing the whole set of documents
  my $v = $self->create_delayed_object('features');
  foreach my $document ($self->documents) {
    $v->add( $document->features );
  }
  return $self->{features} = $v;
}

sub categories {
  my $c = $_[0]->{categories};
  return wantarray ? $c->members : $c->size;
}

sub documents {
  my $d = $_[0]->{documents};
  return wantarray ? $d->members : $d->size;
}

sub document {
  my ($self, $name) = @_;
  return $self->{documents}->retrieve($name);
}

sub feature_selector { $_[0]->{feature_selector} }
sub scan_first       { $_[0]->{scan_first} }

sub verbose {
  my $self = shift;
  $self->{verbose} = shift if @_;
  return $self->{verbose};
}

sub trim_doc_features {
  my ($self) = @_;
  
  foreach my $doc ($self->documents) {
    $doc->features( $doc->features->intersection($self->features) );
  }
}


sub prog_bar {
  my ($self, $collection) = @_;

  return sub {} unless $self->verbose;
  return sub { print STDERR '.' } unless eval "use Time::Progress; 1";

  my $count = $collection->can('count_documents') ? $collection->count_documents : 0;
  
  my $pb = 'Time::Progress'->new;
  $pb->attr(max => $count);
  my $i = 0;
  return sub {
    $i++;
    return if $i % 25;
    print STDERR $pb->report("%50b %p ($i/$count)\r", $i);
  };
}

# A little utility method for several other methods like scan_stats(),
# load(), read(), etc.
sub _make_collection {
  my ($self, $args) = @_;
  return $args->{collection} || $self->create_delayed_object('collection', %$args);
}

sub scan_stats {
  # Should determine:
  #  - number of documents
  #  - number of categories
  #  - avg. number of categories per document (whole corpus)
  #  - avg. number of tokens per document (whole corpus)
  #  - avg. number of types per document (whole corpus)
  #  - number of documents, tokens, & types for each category
  #  - "category skew index" (% variance?) by num. documents, tokens, and types

  my ($self, %args) = @_;
  my $collection = $self->_make_collection(\%args);
  my $pb = $self->prog_bar($collection);

  my %stats;


  while (my $doc = $collection->next) {
    $pb->();
    $stats{category_count_with_duplicates} += $doc->categories;

    my ($sum, $length) = ($doc->features->sum, $doc->features->length);
    $stats{document_count}++;
    $stats{token_count} += $sum;
    $stats{type_count}  += $length;
    
    foreach my $cat ($doc->categories) {
#warn $doc->name, ": ", $cat->name, "\n";
      $stats{categories}{$cat->name}{document_count}++;
      $stats{categories}{$cat->name}{token_count} += $sum;
      $stats{categories}{$cat->name}{type_count}  += $length;
    }
  }
  print "\n" if $self->verbose;

  my @cats = keys %{ $stats{categories} };

  $stats{category_count}          = @cats;
  $stats{categories_per_document} = $stats{category_count_with_duplicates} / $stats{document_count};
  $stats{tokens_per_document}     = $stats{token_count} / $stats{document_count};
  $stats{types_per_document}      = $stats{type_count}  / $stats{document_count};

  foreach my $thing ('type', 'token', 'document') {
    $stats{"${thing}s_per_category"} = AI::Categorizer::Util::average
      ( map { $stats{categories}{$_}{"${thing}_count"} } @cats );

    next unless @cats;

    # Compute the skews
    my $ssum;
    foreach my $cat (@cats) {
      $ssum += ($stats{categories}{$cat}{"${thing}_count"} - $stats{"${thing}s_per_category"}) ** 2;
    }
    $stats{"${thing}_skew_by_category"} = sqrt($ssum/@cats) / $stats{"${thing}s_per_category"};
  }

  return \%stats;
}

sub load {
  my ($self, %args) = @_;
  my $c = $self->_make_collection(\%args);

  if ($self->{features_kept}) {
    # Read the whole thing in, then reduce
    $self->read( collection => $c );
    $self->select_features;

  } elsif ($self->{scan_first}) {
    # Figure out the feature set first, then read data in
    $self->scan_features( collection => $c );
    $c->rewind;
    $self->read( collection => $c );

  } else {
    # Don't do any feature reduction, just read the data
    $self->read( collection => $c );
  }
}

sub read {
  my ($self, %args) = @_;
  my $collection = $self->_make_collection(\%args);
  my $pb = $self->prog_bar($collection);
  
  while (my $doc = $collection->next) {
    $pb->();
    $self->add_document($doc);
  }
  print "\n" if $self->verbose;
}

sub finish {
  my $self = shift;
  return if $self->{finished}++;
  $self->weigh_features;
}

sub weigh_features {
  # This could be made more efficient by figuring out an execution
  # plan in advance

  my $self = shift;
  
  if ( $self->{term_weighting} =~ /^(t|x)$/ ) {
    # Nothing to do
  } elsif ( $self->{term_weighting} eq 'l' ) {
    foreach my $doc ($self->documents) {
      my $f = $doc->features->as_hash;
      $_ = 1 + log($_) foreach values %$f;
    }
  } elsif ( $self->{term_weighting} eq 'n' ) {
    foreach my $doc ($self->documents) {
      my $f = $doc->features->as_hash;
      my $max_tf = AI::Categorizer::Util::max values %$f;
      $_ = 0.5 + 0.5 * $_ / $max_tf foreach values %$f;
    }
  } elsif ( $self->{term_weighting} eq 'b' ) {
    foreach my $doc ($self->documents) {
      my $f = $doc->features->as_hash;
      $_ = $_ ? 1 : 0 foreach values %$f;
    }
  } else {
    die "term_weighting must be one of 'x', 't', 'l', 'b', or 'n'";
  }
  
  if ($self->{collection_weighting} eq 'x') {
    # Nothing to do
  } elsif ($self->{collection_weighting} =~ /^(f|p)$/) {
    my $subtrahend = ($1 eq 'f' ? 0 : 1);
    my $num_docs = $self->documents;
    $self->document_frequency('foo');  # Initialize
    foreach my $doc ($self->documents) {
      my $f = $doc->features->as_hash;
      $f->{$_} *= log($num_docs / $self->{doc_freq_vector}{$_} - $subtrahend) foreach keys %$f;
    }
  } else {
    die "collection_weighting must be one of 'x', 'f', or 'p'";
  }

  if ( $self->{normalize_weighting} eq 'x' ) {
    # Nothing to do
  } elsif ( $self->{normalize_weighting} eq 'c' ) {
    $_->features->normalize foreach $self->documents;
  } else {
    die "normalize_weighting must be one of 'x' or 'c'";
  }
}

sub document_frequency {
  my ($self, $term) = @_;
  
  unless (exists $self->{doc_freq_vector}) {
    die "No corpus has been scanned for features" unless $self->documents;

    my $doc_freq = $self->create_delayed_object('features', features => {});
    foreach my $doc ($self->documents) {
      $doc_freq->add( $doc->features->as_boolean_hash );
    }
    $self->{doc_freq_vector} = $doc_freq->as_hash;
  }
  
  return exists $self->{doc_freq_vector}{$term} ? $self->{doc_freq_vector}{$term} : 0;
}

sub scan_features {
  my ($self, %args) = @_;
  my $c = $self->_make_collection(\%args);

  my $pb = $self->prog_bar($c);
  my $ranked_features = $self->{feature_selector}->scan_features( collection => $c, prog_bar => $pb );

  $self->delayed_object_params('document', use_features => $ranked_features);
  $self->delayed_object_params('collection', use_features => $ranked_features);
  return $ranked_features;
}

sub select_features {
  my $self = shift;
  
  my $f = $self->feature_selector->select_features(knowledge_set => $self);
  $self->features($f);
}

sub partition {
  my ($self, @sizes) = @_;
  my $num_docs = my @docs = $self->documents;
  my @groups;

  while (@sizes > 1) {
    my $size = int ($num_docs * shift @sizes);
    push @groups, [];
    for (0..$size) {
      push @{ $groups[-1] }, splice @docs, rand(@docs), 1;
    }
  }
  push @groups, \@docs;

  return map { ref($self)->new( documents => $_ ) } @groups;
}

sub make_document {
  my ($self, %args) = @_;
  my $cats = delete $args{categories};
  my @cats = map { $self->call_method('category', 'by_name', name => $_) } @$cats;
  my $d = $self->create_delayed_object('document', %args, categories => \@cats);
  $self->add_document($d);
}

sub add_document {
  my ($self, $doc) = @_;

  foreach ($doc->categories) {
    $_->add_document($doc);
  }
  $self->{documents}->insert($doc);
  $self->{categories}->insert($doc->categories);
}

sub save_features {
  my ($self, $file) = @_;
  
  my $f = ($self->{features} || { $self->delayed_object_params('document') }->{use_features})
    or croak "No features to save";
  
  open my($fh), "> $file" or croak "Can't create $file: $!";
  my $h = $f->as_hash;
  print $fh "# Total: ", $f->length, "\n";
  
  foreach my $k (sort {$h->{$b} <=> $h->{$a}} keys %$h) {
    print $fh "$k\t$h->{$k}\n";
  }
  close $fh;
}

sub restore_features {
  my ($self, $file, $n) = @_;
  
  open my($fh), "< $file" or croak "Can't open $file: $!";

  my %hash;
  while (<$fh>) {
    next if /^#/;
    /^(.*)\t([\d.]+)$/ or croak "Malformed line: $_";
    $hash{$1} = $2;
    last if defined $n and $. >= $n;
  }
  my $features = $self->create_delayed_object('features', features => \%hash);
  
  $self->delayed_object_params('document',   use_features => $features);
  $self->delayed_object_params('collection', use_features => $features);
}

1;

__END__

=head1 NAME

AI::Categorizer::KnowledgeSet - Encapsulates set of documents

=head1 SYNOPSIS

 use AI::Categorizer::KnowledgeSet;
 my $k = new AI::Categorizer::KnowledgeSet(...parameters...);
 my $nb = new AI::Categorizer::Learner::NaiveBayes(...parameters...);
 $nb->train(knowledge_set => $k);

=head1 DESCRIPTION

The KnowledgeSet class that provides an interface to a set of
documents, a set of categories, and a mapping between the two.  Many
parameters for controlling the processing of documents are managed by
the KnowledgeSet class.

=head1 METHODS

=over 4

=item new()

Creates a new KnowledgeSet and returns it.  Accepts the following
parameters:

=over 4

=item load

If a C<load> parameter is present, the C<load()> method will be
invoked immediately.  If the C<load> parameter is a string, it will be
passed as the C<path> parameter to C<load()>.  If the C<load>
parameter is a hash reference, it will represent all the parameters to
pass to C<load()>.

=item categories

An optional reference to an array of Category objects representing the
complete set of categories in a KnowledgeSet.  If used, the
C<documents> parameter should also be specified.

=item documents

An optional reference to an array of Document objects representing the
complete set of documents in a KnowledgeSet.  If used, the
C<categories> parameter should also be specified.

=item features_kept

A number indicating how many features (words) should be considered
when training the Learner or categorizing new documents.  May be
specified as a positive integer (e.g. 2000) indicating the absolute
number of features to be kept, or as a decimal between 0 and 1
(e.g. 0.2) indicating the fraction of the total number of features to
be kept, or as 0 to indicate that no feature selection should be done
and that the entire set of features should be used.  The default is
0.2.

=item feature_selection

A string indicating the type of feature selection that should be
performed.  Currently the only option is also the default option:
C<document_frequency>.

=item tfidf_weighting

Specifies how document word counts should be converted to vector
values.  Uses the three-character specification strings from Salton &
Buckley's paper "Term-weighting approaches in automatic text
retrieval".  The three characters indicate the three factors that will
be multiplied for each feature to find the final vector value for that
feature.  The default weighting is C<xxx>.

The first character specifies the "term frequency" component, which
can take the following values:

=over 4

=item b

Binary weighting - 1 for terms present in a document, 0 for terms absent.

=item t

Raw term frequency - equal to the number of times a feature occurs in
the document.

=item x

A synonym for 't'.

=item n

Normalized term frequency - 0.5 + 0.5 * t/max(t).  This is the same as
the 't' specification, but with term frequency normalized to lie
between 0.5 and 1.

=back

The second character specifies the "collection frequency" component, which
can take the following values:

=over 4

=item f

Inverse document frequency - multiply term C<t>'s value by C<log(N/n)>,
where C<N> is the total number of documents in the collection, and
C<n> is the number of documents in which term C<t> is found.

=item p

Probabilistic inverse document frequency - multiply term C<t>'s value
by C<log((N-n)/n)> (same variable meanings as above).

=item x

No change - multiply by 1.

=back


The third character specifies the "normalization" component, which
can take the following values:

=over 4

=item c

Apply cosine normalization - multiply by 1/length(document_vector).

=item x

No change - multiply by 1.

=back

The three components may alternatively be specified by the
C<term_weighting>, C<collection_weighting>, and C<normalize_weighting>
parameters respectively.

=item verbose

If set to a true value, some status/debugging information will be
output on C<STDOUT>.

=back


=item categories()

In a list context returns a list of all Category objects in this
KnowledgeSet.  In a scalar context returns the number of such objects.

=item documents()

In a list context returns a list of all Document objects in this
KnowledgeSet.  In a scalar context returns the number of such objects.

=item document()

Given a document name, returns the Document object with that name, or
C<undef> if no such Document object exists in this KnowledgeSet.

=item features()

Returns a FeatureSet object which represents the features of all the
documents in this KnowledgeSet.

=item verbose()

Returns the C<verbose> parameter of this KnowledgeSet, or sets it with
an optional argument.

=item scan_stats()

Scans all the documents of a Collection and returns a hash reference
containing several statistics about the Collection.  (XXX need to describe stats)

=item scan_features()

This method scans through a Collection object and determines the
"best" features (words) to use when loading the documents and training
the Learner.  This process is known as "feature selection", and it's a
very important part of categorization.

The Collection object should be specified as a C<collection> parameter,
or by giving the arguments to pass to the Collection's C<new()> method.

The process of feature selection is governed by the
C<feature_selection> and C<features_kept> parameters given to the
KnowledgeSet's C<new()> method.

This method returns the features as a FeatureVector whose values are
the "quality" of each feature, by whatever measure the
C<feature_selection> parameter specifies.  Normally you won't need to
use the return value, because this FeatureVector will become the
C<use_features> parameter of any Document objects created by this
KnowledgeSet.

=item save_features()

Given the name of a file, this method writes the features (as
determined by the C<scan_features> method) to the file.

=item restore_features()

Given the name of a file written by C<save_features>, loads the
features from that file and passes them as the C<use_features>
parameter for any Document objects created in the future by this
KnowledgeSet.

=item read()

Iterates through a Collection of documents and adds them to the
KnowledgeSet.  The Collection can be specified using a C<collection>
parameter - otherwise, specify the arguments to pass to the C<new()>
method of the Collection class.

=item load()

This method can do feature selection and load a Collection in one step
(though it currently uses two steps internally).  

=item add_document()

Given a Document object as an argument, this method will add it and
any categories it belongs to to the KnowledgeSet.

=item make_document()

This method will create a Document object with the given data and then
call C<add_document()> to add it to the KnowledgeSet.  A C<categories>
parameter should specify an array reference containing a list of
categories I<by name>.  These are the categories that the document
belongs to.  Any other parameters will be passed to the Document
class's C<new()> method.

=item finish()

This method will be called prior to training the Learner.  Its purpose
is to perform any operations (such as feature vector weighting) that
may require examination of the entire KnowledgeSet.

=item weigh_features()

This method will be called during C<finish()> to adjust the weights of
the features according to the C<tfidf_weighting> parameter.

=item document_frequency()

Given a single feature (word) as an argument, this method will return
the number of documents in the KnowledgeSet that contain that feature.

=item partition()

Divides the KnowledgeSet into several subsets.  This may be useful for
performing cross-validation.  The relative sizes of the subsets should
be passed as arguments.  For example, to split the KnowledgeSet into
four KnowledgeSets of equal size, pass the arguments .25, .25, .25
(the final size is 1 minus the sum of the other sizes).  The
partitions will be returned as a list.

=back

=head1 AUTHOR

Ken Williams, ken@mathforum.org

=head1 COPYRIGHT

Copyright 2000-2003 Ken Williams.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

AI::Categorizer(3)

=cut
