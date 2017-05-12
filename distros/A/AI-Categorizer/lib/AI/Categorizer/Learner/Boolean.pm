package AI::Categorizer::Learner::Boolean;

use strict;
use AI::Categorizer::Learner;
use base qw(AI::Categorizer::Learner);
use Params::Validate qw(:types);
use AI::Categorizer::Util qw(random_elements);

__PACKAGE__->valid_params
  (
   max_instances => {type => SCALAR, default => 0},
   threshold => {type => SCALAR, default => 0.5},
  );

sub create_model {
  my $self = shift;
  my $m = $self->{model} ||= {};
  my $mi = $self->{max_instances};

  foreach my $cat ($self->knowledge_set->categories) {
    my (@p, @n);
    foreach my $doc ($self->knowledge_set->documents) {
      if ($doc->is_in_category($cat)) {
	push @p, $doc;
      } else {
	push @n, $doc;
      }
    }
    if ($mi and @p + @n > $mi) {
      # Get rid of random instances from training set, preserving
      # current positive/negative ratio
      my $ratio = $mi / (@p + @n);
      @p = random_elements(\@p, @p * $ratio);
      @n = random_elements(\@n, @n * $ratio);
      
      warn "Limiting to ". @p ." positives and ". @n ." negatives\n" if $self->verbose;
    }

    warn "Creating model for ", $cat->name, "\n" if $self->verbose;
    $m->{learners}{ $cat->name } = $self->create_boolean_model(\@p, \@n, $cat);
  }
}

sub create_boolean_model;  # Abstract method

sub get_scores {
  my ($self, $doc) = @_;
  my $m = $self->{model};
  my %scores;
  foreach my $cat (keys %{$m->{learners}}) {
    $scores{$cat} = $self->get_boolean_score($doc, $m->{learners}{$cat});
  }
  return (\%scores, $self->{threshold});
}

sub get_boolean_score;  # Abstract method

sub threshold {
  my $self = shift;
  $self->{threshold} = shift if @_;
  return $self->{threshold};
}

sub categories {
  my $self = shift;
  return map AI::Categorizer::Category->by_name( name => $_ ), keys %{ $self->{model}{learners} };
}

1;
__END__

=head1 NAME

AI::Categorizer::Learner::Boolean - Abstract class for boolean categorizers

=head1 SYNOPSIS

 package AI::Categorizer::Learner::SomethingNew;
 use AI::Categorizer::Learner::Boolean;
 @ISA = qw(AI::Categorizer::Learner::Boolean);
 
 sub create_boolean_model {
   my ($self, $positives, $negatives, $category) = @_;
   ...
   return $something_helpful;
 }
 
 sub get_boolean_score {
   my ($self, $document, $something_helpful) = @_;
   ...
   return $score;
 }

=head1 DESCRIPTION

This is an abstract class which turns boolean categorizers
(categorizers based on algorithms that can just provide yes/no
categorization decisions for a single document and single category)
into multi-valued categorizers.  For instance, the decision tree
categorizer C<AI::Categorizer::Learner::DecisionTree> maintains a
decision tree for each category, then uses it to decide whether a
certain document belongs to the given category.

Any class that inherits from this class should implement the following
methods:

=head2 create_boolean_model()

Used during training to create a category-specific model.  The type of
model you create is up to you - it should be returned as a scalar.
Whatever you return will be available to you in the
C<get_boolean_score()> method, so put any information you'll need
during categorization in this scalar.

In addition to C<$self>, this method will be passed three arguments.
The first argument is a reference to an array of B<positive> examples,
i.e. documents that belong to the given category.  The next argument
is a reference to an array of B<negative> examples, i.e. documents
that do I<not> belong to the given category.  The final argument is
the Category object for the given category.

=head2 get_boolean_score()

Used during categorization to assign a score for a single document
relative to a single category.  The score should be between 0 and 1,
with a score greater than 0.5 indicating membership in the category.

In addition to C<$self>, this method will be passed two arguments.
The first argument is the document to be categorized.  The second
argument is the value returned by C<create_boolean_model()> for this
category.

=head1 AUTHOR

Ken Williams, <ken@mathforum.org>

=head1 SEE ALSO

AI::Categorizer

=cut
