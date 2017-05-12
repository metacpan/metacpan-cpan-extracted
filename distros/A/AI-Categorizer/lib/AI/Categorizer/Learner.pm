package AI::Categorizer::Learner;

use strict;
use Class::Container;
use AI::Categorizer::Storable;
use base qw(Class::Container AI::Categorizer::Storable);

use Params::Validate qw(:types);
use AI::Categorizer::ObjectSet;

__PACKAGE__->valid_params
  (
   knowledge_set  => { isa => 'AI::Categorizer::KnowledgeSet', optional => 1 },
   verbose => {type => SCALAR, default => 0},
  );

__PACKAGE__->contained_objects
  (
   hypothesis => {
		  class => 'AI::Categorizer::Hypothesis',
		  delayed => 1,
		 },
   experiment => {
		  class => 'AI::Categorizer::Experiment',
		  delayed => 1,
		 },
  );

# Subclasses must override these virtual methods:
sub get_scores;
sub create_model;

# Optional virtual method for on-line learning:
sub add_knowledge;

sub verbose {
  my $self = shift;
  if (@_) {
    $self->{verbose} = shift;
  }
  return $self->{verbose};
}

sub knowledge_set {
  my $self = shift;
  if (@_) {
    $self->{knowledge_set} = shift;
  }
  return $self->{knowledge_set};
}

sub categories {
  my $self = shift;
  return $self->knowledge_set->categories;
}

sub train {
  my ($self, %args) = @_;
  $self->{knowledge_set} = $args{knowledge_set} if $args{knowledge_set};
  die "No knowledge_set provided" unless $self->{knowledge_set};

  $self->{knowledge_set}->finish;
  $self->create_model;    # Creates $self->{model}
  $self->delayed_object_params('hypothesis',
			       all_categories => [map $_->name, $self->categories],
			      );
}

sub prog_bar {
  my ($self, $count) = @_;
  
  return sub { print STDERR '.' } unless eval "use Time::Progress; 1";
  
  my $pb = 'Time::Progress'->new;
  $pb->attr(max => $count);
  my $i = 0;
  return sub {
    $i++;
    return if $i % 25;
    my $string = '';
    if (@_) {
      my $e = shift;
      $string = sprintf " (maF1=%.03f, miF1=%.03f)", $e->macro_F1, $e->micro_F1;
    }
    print STDERR $pb->report("%50b %p ($i/$count)$string\r", $i);
    return $i;
  };
}

sub categorize_collection {
  my ($self, %args) = @_;
  my $c = $args{collection} or die "No collection provided";

  my @all_cats = map $_->name, $self->categories;
  my $experiment = $self->create_delayed_object('experiment', categories => \@all_cats);
  my $pb = $self->verbose ? $self->prog_bar($c->count_documents) : sub {};
  while (my $d = $c->next) {
    my $h = $self->categorize($d);
    $experiment->add_hypothesis($h, [map $_->name, $d->categories]);
    $pb->($experiment);
    if ($self->verbose > 1) {
      printf STDERR ("%s: assigned=(%s) correct=(%s)\n",
		     $d->name,
		     join(', ', $h->categories),
		     join(', ', map $_->name, $d->categories));
    }
  }
  print STDERR "\n" if $self->verbose;

  return $experiment;
}

sub categorize {
  my ($self, $doc) = @_;
  
  my ($scores, $threshold) = $self->get_scores($doc);
  
  if ($self->verbose > 2) {
    warn "scores: @{[ %$scores ]}" if $self->verbose > 3;
    
    foreach my $key (sort {$scores->{$b} <=> $scores->{$a}} keys %$scores) {
      print "$key: $scores->{$key}\n";
    }
  }
  
  return $self->create_delayed_object('hypothesis',
                                      scores => $scores,
                                      threshold => $threshold,
                                      document_name => $doc->name,
                                     );
}
1;

__END__

=head1 NAME

AI::Categorizer::Learner - Abstract Machine Learner Class

=head1 SYNOPSIS

 use AI::Categorizer::Learner::NaiveBayes;  # Or other subclass
 
 # Here $k is an AI::Categorizer::KnowledgeSet object
 
 my $nb = new AI::Categorizer::Learner::NaiveBayes(...parameters...);
 $nb->train(knowledge_set => $k);
 $nb->save_state('filename');
 
 ... time passes ...
 
 $nb = AI::Categorizer::Learner::NaiveBayes->restore_state('filename');
 my $c = new AI::Categorizer::Collection::Files( path => ... );
 while (my $document = $c->next) {
   my $hypothesis = $nb->categorize($document);
   print "Best assigned category: ", $hypothesis->best_category, "\n";
   print "All assigned categories: ", join(', ', $hypothesis->categories), "\n";
 }

=head1 DESCRIPTION

The C<AI::Categorizer::Learner> class is an abstract class that will
never actually be directly used in your code.  Instead, you will use a
subclass like C<AI::Categorizer::Learner::NaiveBayes> which implements
an actual machine learning algorithm.

The general description of the Learner interface is documented here.

=head1 METHODS

=over 4

=item new()

Creates a new Learner and returns it.  Accepts the following
parameters:

=over 4

=item knowledge_set

A Knowledge Set that will be used by default during the C<train()>
method.

=item verbose

If true, the Learner will display some diagnostic output while
training and categorizing documents.

=back

=item train()

=item train(knowledge_set => $k)

Trains the categorizer.  This prepares it for later use in
categorizing documents.  The C<knowledge_set> parameter must provide
an object of the class C<AI::Categorizer::KnowledgeSet> (or a subclass
thereof), populated with lots of documents and categories.  See
L<AI::Categorizer::KnowledgeSet> for the details of how to create such
an object.  If you provided a C<knowledge_set> parameter to C<new()>,
specifying one here will override it.

=item categorize($document)

Returns an C<AI::Categorizer::Hypothesis> object representing the
categorizer's "best guess" about which categories the given document
should be assigned to.  See L<AI::Categorizer::Hypothesis> for more
details on how to use this object.

=item categorize_collection(collection => $collection)

Categorizes every document in a collection and returns an Experiment
object representing the results.  Note that the Experiment does not
contain knowledge of the assigned categories for every document, only
a statistical summary of the results.

=item knowledge_set()

Gets/sets the internal C<knowledge_set> member.  Note that since the
knowledge set may be enormous, some Learners may throw away their
knowledge set after training or after restoring state from a file.

=item $learner-E<gt>save_state($path)

Saves the Learner for later use.  This method is inherited from
C<AI::Categorizer::Storable>.

=item $class-E<gt>restore_state($path)

Returns a Learner saved in a file with C<save_state()>.  This method
is inherited from C<AI::Categorizer::Storable>.

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
