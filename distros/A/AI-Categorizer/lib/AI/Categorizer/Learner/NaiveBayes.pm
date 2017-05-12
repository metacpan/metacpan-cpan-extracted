package AI::Categorizer::Learner::NaiveBayes;

use strict;
use AI::Categorizer::Learner;
use base qw(AI::Categorizer::Learner);
use Params::Validate qw(:types);
use Algorithm::NaiveBayes;

__PACKAGE__->valid_params
  (
   threshold => {type => SCALAR, default => 0.3},
  );

sub create_model {
  my $self = shift;
  my $m = $self->{model} = Algorithm::NaiveBayes->new;

  foreach my $d ($self->knowledge_set->documents) {
    $m->add_instance(attributes => $d->features->as_hash,
		     label      => [ map $_->name, $d->categories ]);
  }
  $m->train;
}

sub get_scores {
  my ($self, $newdoc) = @_;

  return ($self->{model}->predict( attributes => $newdoc->features->as_hash ),
	  $self->{threshold});
}

sub threshold {
  my $self = shift;
  $self->{threshold} = shift if @_;
  return $self->{threshold};
}

sub save_state {
  my $self = shift;
  local $self->{knowledge_set};  # Don't need the knowledge_set to categorize
  $self->SUPER::save_state(@_);
}

sub categories {
  my $self = shift;
  return map AI::Categorizer::Category->by_name( name => $_ ), $self->{model}->labels;
}

1;

__END__

=head1 NAME

AI::Categorizer::Learner::NaiveBayes - Naive Bayes Algorithm For AI::Categorizer

=head1 SYNOPSIS

  use AI::Categorizer::Learner::NaiveBayes;
  
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

This is an implementation of the Naive Bayes decision-making
algorithm, applied to the task of document categorization (as defined
by the AI::Categorizer module).  See L<AI::Categorizer> for a complete
description of the interface.

This module is now a wrapper around the stand-alone
C<Algorithm::NaiveBayes> module.  I moved the discussion of Bayes'
Theorem into that module's documentation.

=head1 METHODS

This class inherits from the C<AI::Categorizer::Learner> class, so all
of its methods are available unless explicitly mentioned here.

=head2 new()

Creates a new Naive Bayes Learner and returns it.  In addition to the
parameters accepted by the C<AI::Categorizer::Learner> class, the
Naive Bayes subclass accepts the following parameters:

=over 4

=item * threshold

Sets the score threshold for category membership.  The default is
currently 0.3.  Set the threshold lower to assign more categories per
document, set it higher to assign fewer.  This can be an effective way
to trade of between precision and recall.

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

=head1 CALCULATIONS

The various probabilities used in the above calculations are found
directly from the training documents.  For instance, if there are 5000
total tokens (words) in the "sports" training documents and 200 of
them are the word "curling", then C<P(curling|sports) = 200/5000 =
0.04> .  If there are 10,000 total tokens in the training corpus and
5,000 of them are in documents belonging to the category "sports",
then C<P(sports)> = 5,000/10,000 = 0.5> .

Because the probabilities involved are often very small and we
multiply many of them together, the result is often a tiny tiny
number.  This could pose problems of floating-point underflow, so
instead of working with the actual probabilities we work with the
logarithms of the probabilities.  This also speeds up various
calculations in the C<categorize()> method.

=head1 TO DO

More work on the confidence scores - right now the winning category
tends to dominate the scores overwhelmingly, when the scores should
probably be more evenly distributed.

=head1 AUTHOR

Ken Williams, ken@forum.swarthmore.edu

=head1 COPYRIGHT

Copyright 2000-2003 Ken Williams.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

AI::Categorizer(3), Algorithm::NaiveBayes(3)

"A re-examination of text categorization methods" by Yiming Yang
L<http://www.cs.cmu.edu/~yiming/publications.html>

"On the Optimality of the Simple Bayesian Classifier under Zero-One
Loss" by Pedro Domingos
L<"http://www.cs.washington.edu/homes/pedrod/mlj97.ps.gz">

A simple but complete example of Bayes' Theorem from Dr. Math
L<"http://www.mathforum.com/dr.math/problems/battisfore.03.22.99.html">

=cut
