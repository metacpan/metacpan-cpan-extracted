package AI::Categorizer::Learner::KNN;

use strict;
use AI::Categorizer::Learner;
use base qw(AI::Categorizer::Learner);
use Params::Validate qw(:types);

__PACKAGE__->valid_params
  (
   threshold => {type => SCALAR, default => 0.4},
   k_value => {type => SCALAR, default => 20},
   knn_weighting => {type => SCALAR, default => 'score'},
   max_instances => {type => SCALAR, default => 0},
  );

sub create_model {
  my $self = shift;
  foreach my $doc ($self->knowledge_set->documents) {
    $doc->features->normalize;
  }
  $self->knowledge_set->features;  # Initialize
}

sub threshold {
  my $self = shift;
  $self->{threshold} = shift if @_;
  return $self->{threshold};
}

sub categorize_collection {
  my $self = shift;
  
  my $f_class = $self->knowledge_set->contained_class('features');
  if ($f_class->can('all_features')) {
    $f_class->all_features([$self->knowledge_set->features->names]);
  }
  $self->SUPER::categorize_collection(@_);
}

sub get_scores {
  my ($self, $newdoc) = @_;
  my $currentDocName = $newdoc->name;
  #print "classifying $currentDocName\n";

  my $features = $newdoc->features->intersection($self->knowledge_set->features)->normalize;
  my $q = AI::Categorizer::Learner::KNN::Queue->new(size => $self->{k_value});

  my @docset;
  if ($self->{max_instances}) {
    # Use (approximately) max_instances documents, chosen randomly from corpus
    my $probability = $self->{max_instances} / $self->knowledge_set->documents;
    @docset = grep {rand() < $probability} $self->knowledge_set->documents;
  } else {
    # Use the whole corpus
    @docset = $self->knowledge_set->documents;
  }
  
  foreach my $doc (@docset) {
    my $score = $doc->features->dot( $features );
    warn "Score for ", $doc->name, " (", ($doc->categories)[0]->name, "): $score" if $self->verbose > 1;
    $q->add($doc, $score);
  }
  
  my %scores = map {+$_->name, 0} $self->categories;
  foreach my $e (@{$q->entries}) {
    foreach my $cat ($e->{thing}->categories) {
      $scores{$cat->name} += ($self->{knn_weighting} eq 'score' ? $e->{score} : 1); #increment cat score
    }
  }
  
  $_ /= $self->{k_value} foreach values %scores;
  
  return (\%scores, $self->{threshold});
}

###################################################################
package AI::Categorizer::Learner::KNN::Queue;

sub new {
  my ($pkg, %args) = @_;
  return bless {
		size => $args{size},
		entries => [],
	       }, $pkg;
}

sub add {
  my ($self, $thing, $score) = @_;

  # scores may be (0.2, 0.4, 0.4, 0.8) - ascending

  return unless (@{$self->{entries}} < $self->{size}       # Queue not filled
		 or $score > $self->{entries}[0]{score});  # Found a better entry
  
  my $i;
  if (!@{$self->{entries}}) {
    $i = 0;
  } elsif ($score > $self->{entries}[-1]{score}) {
    $i = @{$self->{entries}};
  } else {
    for ($i = 0; $i < @{$self->{entries}}; $i++) {
      last if $score < $self->{entries}[$i]{score};
    }
  }
  splice @{$self->{entries}}, $i, 0, { thing => $thing, score => $score};
  shift @{$self->{entries}} if @{$self->{entries}} > $self->{size};
}

sub entries {
  return shift->{entries};
}

1;

__END__

=head1 NAME

AI::Categorizer::Learner::KNN - K Nearest Neighbour Algorithm For AI::Categorizer

=head1 SYNOPSIS

  use AI::Categorizer::Learner::KNN;
  
  # Here $k is an AI::Categorizer::KnowledgeSet object
  
  my $nb = new AI::Categorizer::Learner::KNN(...parameters...);
  $nb->train(knowledge_set => $k);
  $nb->save_state('filename');
  
  ... time passes ...
  
  $l = AI::Categorizer::Learner->restore_state('filename');
  my $c = new AI::Categorizer::Collection::Files( path => ... );
  while (my $document = $c->next) {
    my $hypothesis = $l->categorize($document);
    print "Best assigned category: ", $hypothesis->best_category, "\n";
    print "All assigned categories: ", join(', ', $hypothesis->categories), "\n";
  }

=head1 DESCRIPTION

This is an implementation of the k-Nearest-Neighbor decision-making
algorithm, applied to the task of document categorization (as defined
by the AI::Categorizer module).  See L<AI::Categorizer> for a complete
description of the interface.

=head1 METHODS

This class inherits from the C<AI::Categorizer::Learner> class, so all
of its methods are available unless explicitly mentioned here.

=head2 new()

Creates a new KNN Learner and returns it.  In addition to the
parameters accepted by the C<AI::Categorizer::Learner> class, the
KNN subclass accepts the following parameters:

=over 4

=item threshold

Sets the score threshold for category membership.  The default is
currently 0.1.  Set the threshold lower to assign more categories per
document, set it higher to assign fewer.  This can be an effective way
to trade of between precision and recall.

=item k_value

Sets the C<k> value (as in k-Nearest-Neighbor) to the given integer.
This indicates how many of each document's nearest neighbors should be
considered when assigning categories.  The default is 5.

=back

=head2 threshold()

Returns the current threshold value.  With an optional numeric
argument, you may set the threshold.

=head2 train(knowledge_set => $k)

Trains the categorizer.  This prepares it for later use in
categorizing documents.  The C<knowledge_set> parameter must provide
an object of the class C<AI::Categorizer::KnowledgeSet> (or a subclass
thereof), populated with lots of documents and categories.  See
L<AI::Categorizer::KnowledgeSet> for the details of how to create such
an object.

=head2 categorize($document)

Returns an C<AI::Categorizer::Hypothesis> object representing the
categorizer's "best guess" about which categories the given document
should be assigned to.  See L<AI::Categorizer::Hypothesis> for more
details on how to use this object.

=head2 save_state($path)

Saves the categorizer for later use.  This method is inherited from
C<AI::Categorizer::Storable>.

=head1 AUTHOR

Originally written by David Bell (C<< <dave@student.usyd.edu.au> >>),
October 2002.

Added to AI::Categorizer November 2002, modified, and maintained by
Ken Williams (C<< <ken@mathforum.org> >>).

=head1 COPYRIGHT

Copyright 2000-2003 Ken Williams.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

AI::Categorizer(3)

"A re-examination of text categorization methods" by Yiming Yang
L<http://www.cs.cmu.edu/~yiming/publications.html>

=cut
