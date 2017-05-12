package AI::Categorizer::FeatureSelector;

use strict;
use Class::Container;
use base qw(Class::Container);

use Params::Validate qw(:types);
use AI::Categorizer::FeatureVector;
use AI::Categorizer::Util;
use Carp qw(croak);

__PACKAGE__->valid_params
  (
   features_kept => {
		     type => SCALAR,
		     default => 0.2,
		    },
   verbose => {
	       type => SCALAR,
	       default => 0,
	      },
  );

sub verbose {
  my $self = shift;
  $self->{verbose} = shift if @_;
  return $self->{verbose};
}

sub reduce_features {
  # Takes a feature vector whose weights are "feature scores", and
  # chops to the highest n features.  n is specified by the
  # 'features_kept' parameter.  If it's zero, all features are kept.
  # If it's between 0 and 1, we multiply by the present number of
  # features.  If it's greater than 1, we treat it as the number of
  # features to use.

  my ($self, $f, %args) = @_;
  my $kept = defined $args{features_kept} ? $args{features_kept} : $self->{features_kept};
  return $f unless $kept;

  my $num_kept = ($kept < 1 ? 
		  $f->length * $kept :
		  $kept);

  print "Trimming features - # features = " . $f->length . "\n" if $self->verbose;
  
  # This is algorithmic overkill, but the sort seems fast enough.  Will revisit later.
  my $features = $f->as_hash;
  my @new_features = (sort {$features->{$b} <=> $features->{$a}} keys %$features)
                      [0 .. $num_kept-1];

  my $result = $f->intersection( \@new_features );
  print "Finished trimming features - # features = " . $result->length . "\n" if $self->verbose;
  return $result;
}

# Abstract methods
sub rank_features;
sub scan_features;

sub select_features {
  my ($self, %args) = @_;
  
  die "No knowledge_set parameter provided to select_features()"
    unless $args{knowledge_set};

  my $f = $self->rank_features( knowledge_set => $args{knowledge_set} );
  return $self->reduce_features( $f, features_kept => $args{features_kept} );
}


1;

__END__

=head1 NAME

AI::Categorizer::FeatureSelector - Abstract Feature Selection class

=head1 SYNOPSIS

 ...

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
