package AI::Categorizer::Learner::Guesser;

use strict;
use AI::Categorizer::Learner;
use base qw(AI::Categorizer::Learner);

sub create_model {
  my $self = shift;
  my $k = $self->knowledge_set;
  my $num_docs = $k->documents;
  
  foreach my $cat ($k->categories) {
    next unless $cat->documents;
    $self->{model}{$cat->name} = $cat->documents / $num_docs;
  }
}

sub get_scores {
  my ($self, $newdoc) = @_;
  
  my %scores;
  while (my ($cat, $prob) = each %{$self->{model}}) {
    $scores{$cat} = 0.5 + $prob - rand();
  }
  
  return (\%scores, 0.5);
}

1;

__END__

=head1 NAME

AI::Categorizer::Learner::Guesser - Simple guessing based on class probabilities

=head1 SYNOPSIS

  use AI::Categorizer::Learner::Guesser;
  
  # Here $k is an AI::Categorizer::KnowledgeSet object
  
  my $l = new AI::Categorizer::Learner::Guesser;
  $l->train(knowledge_set => $k);
  $l->save_state('filename');
  
  ... time passes ...
  
  $l = AI::Categorizer::Learner->restore_state('filename');
  my $c = new AI::Categorizer::Collection::Files( path => ... );
  while (my $document = $c->next) {
    my $hypothesis = $l->categorize($document);
    print "Best assigned category: ", $hypothesis->best_category, "\n";
    print "All assigned categories: ", join(', ', $hypothesis->categories), "\n";
  }

=head1 DESCRIPTION

This implements a simple category guesser that makes assignments based
solely on the prior probabilities of categories.  For instance, if 5%
of the training documents belong to a certain category, then the
probability of any test document being assigned to that category is
0.05.  This can be useful for providing baseline scores to compare
with other more sophisticated algorithms.

See L<AI::Categorizer> for a complete description of the interface.

=head1 METHODS

This class inherits from the C<AI::Categorizer::Learner> class, so all
of its methods are available.

=head1 AUTHOR

Ken Williams (C<< <ken@mathforum.org> >>)

=head1 COPYRIGHT

Copyright 2000-2003 Ken Williams.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

AI::Categorizer(3)

=cut
