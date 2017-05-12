package AI::Categorizer;
$VERSION = '0.09';

use strict;
use Class::Container;
use base qw(Class::Container);
use Params::Validate qw(:types);
use File::Spec;
use AI::Categorizer::Learner;
use AI::Categorizer::Document;
use AI::Categorizer::Category;
use AI::Categorizer::Collection;
use AI::Categorizer::Hypothesis;
use AI::Categorizer::KnowledgeSet;


__PACKAGE__->valid_params
  (
   progress_file => { type => SCALAR, default => 'save' },
   knowledge_set => { isa => 'AI::Categorizer::KnowledgeSet' },
   learner       => { isa => 'AI::Categorizer::Learner' },
   verbose       => { type => BOOLEAN, default => 0 },
   training_set  => { type => SCALAR, optional => 1 },
   test_set      => { type => SCALAR, optional => 1 },
   data_root     => { type => SCALAR, optional => 1 },
  );

__PACKAGE__->contained_objects
  (
   knowledge_set => { class => 'AI::Categorizer::KnowledgeSet' },
   learner       => { class => 'AI::Categorizer::Learner::NaiveBayes' },
   experiment    => { class => 'AI::Categorizer::Experiment',
		      delayed => 1 },
   collection    => { class => 'AI::Categorizer::Collection::Files',
		      delayed => 1 },
  );

sub new {
  my $package = shift;
  my %args = @_;
  my %defaults;
  if (exists $args{data_root}) {
    $defaults{training_set} = File::Spec->catfile($args{data_root}, 'training');
    $defaults{test_set} = File::Spec->catfile($args{data_root}, 'test');
    $defaults{category_file} = File::Spec->catfile($args{data_root}, 'cats.txt');
    delete $args{data_root};
  }

  return $package->SUPER::new(%defaults, %args);
}

#sub dump_parameters {
#  my $p = shift()->SUPER::dump_parameters;
#  delete $p->{stopwords} if $p->{stopword_file};
#  return $p;
#}

sub knowledge_set { shift->{knowledge_set} }
sub learner       { shift->{learner} }

# Combines several methods in one sub
sub run_experiment {
  my $self = shift;
  $self->scan_features;
  $self->read_training_set;
  $self->train;
  $self->evaluate_test_set;
  print $self->stats_table;
}

sub scan_features {
  my $self = shift;
  return unless $self->knowledge_set->scan_first;
  $self->knowledge_set->scan_features( path => $self->{training_set} );
  $self->knowledge_set->save_features( "$self->{progress_file}-01-features" );
}

sub read_training_set {
  my $self = shift;
  $self->knowledge_set->restore_features( "$self->{progress_file}-01-features" )
    if -e "$self->{progress_file}-01-features";
  $self->knowledge_set->read( path => $self->{training_set} );
  $self->_save_progress( '02', 'knowledge_set' );
  return $self->knowledge_set;
}

sub train {
  my $self = shift;
  $self->_load_progress( '02', 'knowledge_set' );
  $self->learner->train( knowledge_set => $self->{knowledge_set} );
  $self->_save_progress( '03', 'learner' );
  return $self->learner;
}

sub evaluate_test_set {
  my $self = shift;
  $self->_load_progress( '03', 'learner' );
  my $c = $self->create_delayed_object('collection', path => $self->{test_set} );
  $self->{experiment} = $self->learner->categorize_collection( collection => $c );
  $self->_save_progress( '04', 'experiment' );
  return $self->{experiment};
}

sub stats_table {
  my $self = shift;
  $self->_load_progress( '04', 'experiment' );
  return $self->{experiment}->stats_table;
}

sub progress_file {
  shift->{progress_file};
}

sub verbose {
  shift->{verbose};
}

sub _save_progress {
  my ($self, $stage, $node) = @_;
  return unless $self->{progress_file};
  my $file = "$self->{progress_file}-$stage-$node";
  warn "Saving to $file\n" if $self->{verbose};
  $self->{$node}->save_state($file);
}

sub _load_progress {
  my ($self, $stage, $node) = @_;
  return unless $self->{progress_file};
  my $file = "$self->{progress_file}-$stage-$node";
  warn "Loading $file\n" if $self->{verbose};
  $self->{$node} = $self->contained_class($node)->restore_state($file);
}

1;
__END__

=head1 NAME

AI::Categorizer - Automatic Text Categorization

=head1 SYNOPSIS

 use AI::Categorizer;
 my $c = new AI::Categorizer(...parameters...);
 
 # Run a complete experiment - training on a corpus, testing on a test
 # set, printing a summary of results to STDOUT
 $c->run_experiment;
 
 # Or, run the parts of $c->run_experiment separately
 $c->scan_features;
 $c->read_training_set;
 $c->train;
 $c->evaluate_test_set;
 print $c->stats_table;
 
 # After training, use the Learner for categorization
 my $l = $c->learner;
 while (...) {
   my $d = ...create a document...
   my $hypothesis = $l->categorize($d);  # An AI::Categorizer::Hypothesis object
   print "Assigned categories: ", join ', ', $hypothesis->categories, "\n";
   print "Best category: ", $hypothesis->best_category, "\n";
 }
 
=head1 DESCRIPTION

C<AI::Categorizer> is a framework for automatic text categorization.
It consists of a collection of Perl modules that implement common
categorization tasks, and a set of defined relationships among those
modules.  The various details are flexible - for example, you can
choose what categorization algorithm to use, what features (words or
otherwise) of the documents should be used (or how to automatically
choose these features), what format the documents are in, and so on.

The basic process of using this module will typically involve
obtaining a collection of B<pre-categorized> documents, creating a
"knowledge set" representation of those documents, training a
categorizer on that knowledge set, and saving the trained categorizer
for later use.  There are several ways to carry out this process.  The
top-level C<AI::Categorizer> module provides an umbrella class for
high-level operations, or you may use the interfaces of the individual
classes in the framework.

A simple sample script that reads a training corpus, trains a
categorizer, and tests the categorizer on a test corpus, is
distributed as eg/demo.pl .

Disclaimer: the results of any of the machine learning algorithms are
far from infallible (close to fallible?).  Categorization of documents
is often a difficult task even for humans well-trained in the
particular domain of knowledge, and there are many things a human
would consider that none of these algorithms consider.  These are only
statistical tests - at best they are neat tricks or helpful
assistants, and at worst they are totally unreliable.  If you plan to
use this module for anything really important, human supervision is
essential, both of the categorization process and the final results.

For the usage details, please see the documentation of each individual
module.

=head1 FRAMEWORK COMPONENTS

This section explains the major pieces of the C<AI::Categorizer>
object framework.  We give a conceptual overview, but don't get into
any of the details about interfaces or usage.  See the documentation
for the individual classes for more details.

A diagram of the various classes in the framework can be seen in
C<doc/classes-overview.png>, and a more detailed view of the same
thing can be seen in C<doc/classes.png>.

=head2 Knowledge Sets

A "knowledge set" is defined as a collection of documents, together
with some information on the categories each document belongs to.
Note that this term is somewhat unique to this project - other sources
may call it a "training corpus", or "prior knowledge".  A knowledge
set also contains some information on how documents will be parsed and
how their features (words) will be extracted and turned into
meaningful representations.  In this sense, a knowledge set represents
not only a collection of data, but a particular view on that data.

A knowledge set is encapsulated by the
C<AI::Categorizer::KnowledgeSet> class.  Before you can start playing
with categorizers, you will have to start playing with knowledge sets,
so that the categorizers have some data to train on.  See the
documentation for the C<AI::Categorizer::KnowledgeSet> module for
information on its interface.

=head3 Feature selection

Deciding which features are the most important is a very large part of
the categorization task - you cannot simply consider all the words in
all the documents when training, and all the words in the document
being categorized.  There are two main reasons for this - first, it
would mean that your training and categorizing processes would take
forever and use tons of memory, and second, the significant stuff of
the documents would get lost in the "noise" of the insignificant stuff.

The process of selecting the most important features in the training
set is called "feature selection".  It is managed by the
C<AI::Categorizer::KnowledgeSet> class, and you will find the details
of feature selection processes in that class's documentation.

=head2 Collections

Because documents may be stored in lots of different formats, a
"collection" class has been created as an abstraction of a stored set
of documents, together with a way to iterate through the set and
return Document objects.  A knowledge set contains a single collection
object.  A C<Categorizer> doing a complete test run generally contains
two collections, one for training and one for testing.  A C<Learner>
can mass-categorize a collection.

The C<AI::Categorizer::Collection> class and its subclasses
instantiate the idea of a collection in this sense.

=head2 Documents

Each document is represented by an C<AI::Categorizer::Document>
object, or an object of one of its subclasses.  Each document class
contains methods for turning a bunch of data into a Feature Vector.
Each document also has a method to report which categories it belongs
to.

=head2 Categories

Each category is represented by an C<AI::Categorizer::Category>
object.  Its main purpose is to keep track of which documents belong
to it, though you can also examine statistical properties of an entire
category, such as obtaining a Feature Vector representing an
amalgamation of all the documents that belong to it.

=head2 Machine Learning Algorithms

There are lots of different ways to make the inductive leap from the
training documents to unseen documents.  The Machine Learning
community has studied many algorithms for this purpose.  To allow
flexibility in choosing and configuring categorization algorithms,
each such algorithm is a subclass of C<AI::Categorizer::Learner>.
There are currently four categorizers included in the distribution:

=over 4

=item AI::Categorizer::Learner::NaiveBayes

A pure-perl implementation of a Naive Bayes classifier.  No
dependencies on external modules or other resources.  Naive Bayes is
usually very fast to train and fast to make categorization decisions,
but isn't always the most accurate categorizer.

=item AI::Categorizer::Learner::SVM

An interface to Corey Spencer's C<Algorithm::SVM>, which implements a
Support Vector Machine classifier.  SVMs can take a while to train
(though in certain conditions there are optimizations to make them
quite fast), but are pretty quick to categorize.  They often have very
good accuracy.

=item AI::Categorizer::Learner::DecisionTree

An interface to C<AI::DecisionTree>, which implements a Decision Tree
classifier.  Decision Trees generally take longer to train than Naive
Bayes or SVM classifiers, but they are also quite fast when
categorizing.  Decision Trees have the advantage that you can
scrutinize the structures of trained decision trees to see how
decisions are being made.

=item AI::Categorizer::Learner::Weka

An interface to version 2 of the Weka Knowledge Analysis system that
lets you use any of the machine learners it defines.  This gives you
access to lots and lots of machine learning algorithms in use by
machine learning researches.  The main drawback is that Weka tends to
be quite slow and use a lot of memory, and the current interface
between Weka and C<AI::Categorizer> is a bit clumsy.

=back

Other machine learning methods that may be implemented soonish include
Neural Networks, k-Nearest-Neighbor, and/or a mixture-of-experts
combiner for ensemble learning.  No timetable for their creation has
yet been set.

Please see the documentation of these individual modules for more
details on their guts and quirks.  See the C<AI::Categorizer::Learner>
documentation for a description of the general categorizer interface.

If you wish to create your own classifier, you should inherit from
C<AI::Categorizer::Learner> or C<AI::Categorizer::Learner::Boolean>,
which are abstract classes that manage some of the work for you.

=head2 Feature Vectors

Most categorization algorithms don't deal directly with documents'
data, they instead deal with a I<vector representation> of a
document's I<features>.  The features may be any properties of the
document that seem helpful for determining its category, but they are usually
some version of the "most important" words in the document.  A list of
features and their weights in each document is encapsulated by the
C<AI::Categorizer::FeatureVector> class.  You may think of this class
as roughly analogous to a Perl hash, where the keys are the names of
features and the values are their weights.

=head2 Hypotheses

The result of asking a categorizer to categorize a previously unseen
document is called a hypothesis, because it is some kind of
"statistical guess" of what categories this document should be
assigned to.  Since you may be interested in any of several pieces of
information about the hypothesis (for instance, which categories were
assigned, which category was the single most likely category, the
scores assigned to each category, etc.), the hypothesis is returned as
an object of the C<AI::Categorizer::Hypothesis> class, and you can use
its object methods to get information about the hypothesis.  See its
class documentation for the details.

=head2 Experiments

The C<AI::Categorizer::Experiment> class helps you organize the
results of categorization experiments.  As you get lots of
categorization results (Hypotheses) back from the Learner, you can
feed these results to the Experiment class, along with the correct
answers.  When all results have been collected, you can get a report
on accuracy, precision, recall, F1, and so on, with both
micro-averaging and macro-averaging over categories.  We use the
C<Statistics::Contingency> module from CPAN to manage the
calculations. See the docs for C<AI::Categorizer::Experiment> for more
details.

=head1 METHODS

=over 4

=item new()

Creates a new Categorizer object and returns it.  Accepts lots of
parameters controlling behavior.  In addition to the parameters listed
here, you may pass any parameter accepted by any class that we create
internally (the KnowledgeSet, Learner, Experiment, or Collection
classes), or any class that I<they> create.  This is managed by the
C<Class::Container> module, so see
L<its documentation|Class::Container> for the details of how this
works.

The specific parameters accepted here are:

=over 4

=item progress_file

A string that indicates a place where objects will be saved during
several of the methods of this class.  The default value is the string
C<save>, which means files like C<save-01-knowledge_set> will get
created.  The exact names of these files may change in future
releases, since they're just used internally to resume where we last
left off.

=item verbose

If true, a few status messages will be printed during execution.

=item training_set

Specifies the C<path> parameter that will be fed to the KnowledgeSet's
C<scan_features()> and C<read()> methods during our C<scan_features()>
and C<read_training_set()> methods.

=item test_set

Specifies the C<path> parameter that will be used when creating a
Collection during the C<evaluate_test_set()> method.

=item data_root

A shortcut for setting the C<training_set>, C<test_set>, and
C<category_file> parameters separately.  Sets C<training_set> to
C<$data_root/training>, C<test_set> to C<$data_root/test>, and
C<category_file> (used by some of the Collection classes) to
C<$data_root/cats.txt>.

=back

=item learner()

Returns the Learner object associated with this Categorizer.  Before
C<train()>, the Learner will of course not be trained yet.

=item knowledge_set()

Returns the KnowledgeSet object associated with this Categorizer.  If
C<read_training_set()> has not yet been called, the KnowledgeSet will
not yet be populated with any training data.

=item run_experiment()

Runs a complete experiment on the training and testing data, reporting
the results on C<STDOUT>.  Internally, this is just a shortcut for
calling the C<scan_features()>, C<read_training_set()>, C<train()>,
and C<evaluate_test_set()> methods, then printing the value of the
C<stats_table()> method.

=item scan_features()

Scans the Collection specified in the C<test_set> parameter to
determine the set of features (words) that will be considered when
training the Learner.  Internally, this calls the C<scan_features()>
method of the KnowledgeSet, then saves a list of the KnowledgeSet's
features for later use.

This step is not strictly necessary, but it can dramatically reduce
memory requirements if you scan for features before reading the entire
corpus into memory.

=item read_training_set()

Populates the KnowledgeSet with the data specified in the C<test_set>
parameter.  Internally, this calls the C<read()> method of the
KnowledgeSet.  Returns the KnowledgeSet.  Also saves the KnowledgeSet
object for later use.

=item train()

Calls the Learner's C<train()> method, passing it the KnowledgeSet
created during C<read_training_set()>.  Returns the Learner object.
Also saves the Learner object for later use.

=item evaluate_test_set()

Creates a Collection based on the value of the C<test_set> parameter,
and calls the Learner's C<categorize_collection()> method using this
Collection.  Returns the resultant Experiment object.  Also saves the
Experiment object for later use in the C<stats_table()> method.

=item stats_table()

Returns the value of the Experiment's (as created by
C<evaluate_test_set()>) C<stats_table()> method.  This is a string
that shows various statistics about the
accuracy/precision/recall/F1/etc. of the assignments made during
testing.

=back

=head1 HISTORY

This module is a revised and redesigned version of the previous
C<AI::Categorize> module by the same author.  Note the added 'r' in
the new name.  The older module has a different interface, and no
attempt at backward compatibility has been made - that's why I changed
the name.

You can have both C<AI::Categorize> and C<AI::Categorizer> installed
at the same time on the same machine, if you want.  They don't know
about each other or use conflicting namespaces.

=head1 AUTHOR

Ken Williams <ken@mathforum.org>

Discussion about this module can be directed to the perl-AI list at
<perl-ai@perl.org>.  For more info about the list, see
http://lists.perl.org/showlist.cgi?name=perl-ai

=head1 REFERENCES

An excellent introduction to the academic field of Text Categorization
is Fabrizio Sebastiani's "Machine Learning in Automated Text
Categorization": ACM Computing Surveys, Vol. 34, No. 1, March 2002,
pp. 1-47.

=head1 COPYRIGHT

Copyright 2000-2003 Ken Williams.  All rights reserved.

This distribution is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.  These terms apply to
every file in the distribution - if you have questions, please contact
the author.

=cut
