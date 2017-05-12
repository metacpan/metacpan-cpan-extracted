package AI::Categorizer::Learner::DecisionTree;
$VERSION = '0.01';

use strict;
use AI::DecisionTree;
use AI::Categorizer::Learner::Boolean;
use base qw(AI::Categorizer::Learner::Boolean);

sub create_model {
  my $self = shift;
  $self->SUPER::create_model;
  $self->{model}{first_tree}->do_purge;
  delete $self->{model}{first_tree};
}

sub create_boolean_model {
  my ($self, $positives, $negatives, $cat) = @_;
  
  my $t = new AI::DecisionTree(noise_mode => 'pick_best', 
			       verbose => $self->verbose);

  my %results;
  for ($positives, $negatives) {
    foreach my $doc (@$_) {
      $results{$doc->name} = $_ eq $positives ? 1 : 0;
    }
  }

  if ($self->{model}{first_tree}) {
    $t->copy_instances(from => $self->{model}{first_tree});
    $t->set_results(\%results);

  } else {
    for ($positives, $negatives) {
      foreach my $doc (@$_) {
	$t->add_instance( attributes => $doc->features->as_boolean_hash,
			  result => $results{$doc->name},
			  name => $doc->name,
			);
      }
    }
    $t->purge(0);
    $self->{model}{first_tree} = $t;
  }

  print STDERR "\nBuilding tree for category '", $cat->name, "'" if $self->verbose;
  $t->train;
  return $t;
}

sub get_scores {
  my ($self, $doc) = @_;
  local $self->{current_doc} = $doc->features->as_boolean_hash;
  return $self->SUPER::get_scores($doc);
}

sub get_boolean_score {
  my ($self, $doc, $t) = @_;
  return $t->get_result( attributes => $self->{current_doc} ) || 0;
}

1;
__END__

=head1 NAME

AI::Categorizer::Learner::DecisionTree - Decision Tree Learner

=head1 SYNOPSIS

  use AI::Categorizer::Learner::DecisionTree;
  
  # Here $k is an AI::Categorizer::KnowledgeSet object
  
  my $l = new AI::Categorizer::Learner::DecisionTree(...parameters...);
  $l->train(knowledge_set => $k);
  $l->save_state('filename');
  
  ... time passes ...
  
  $l = AI::Categorizer::Learner->restore_state('filename');
  while (my $document = ... ) {  # An AI::Categorizer::Document object
    my $hypothesis = $l->categorize($document);
    print "Best assigned category: ", $hypothesis->best_category, "\n";
  }

=head1 DESCRIPTION

This class implements a Decision Tree machine learner, using
C<AI::DecisionTree> to do the internal work.

=head1 METHODS

This class inherits from the C<AI::Categorizer::Learner> class, so all
of its methods are available unless explicitly mentioned here.

=head2 new()

Creates a new DecisionTree Learner and returns it.

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

Ken Williams, ken@mathforum.org

=head1 COPYRIGHT

Copyright 2000-2003 Ken Williams.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

AI::Categorizer(3)

=cut
