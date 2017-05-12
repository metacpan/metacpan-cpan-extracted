package AI::Categorizer::Hypothesis;

use strict;

use Class::Container;
use base qw(Class::Container);
use Params::Validate qw(:types);

__PACKAGE__->valid_params
  (
   all_categories => {type => ARRAYREF},
   scores => {type => HASHREF},
   threshold => {type => SCALAR},
   document_name => {type => SCALAR, optional => 1},
  );

sub all_categories { @{$_[0]->{all_categories}} }
sub document_name  { $_[0]->{document_name} }
sub threshold      { $_[0]->{threshold} }

sub best_category {
  my ($self) = @_;
  my $sc = $self->{scores};
  return unless %$sc;

  my ($best_cat, $best_score) = each %$sc;
  while (my ($key, $val) = each %$sc) {
    ($best_cat, $best_score) = ($key, $val) if $val > $best_score;
  }
  return $best_cat;
}

sub in_category {
  my ($self, $cat) = @_;
  return '' unless exists $self->{scores}{$cat};
  return $self->{scores}{$cat} > $self->{threshold};
}

sub categories {
  my $self = shift;
  return @{$self->{cats}} if $self->{cats};
  $self->{cats} = [sort {$self->{scores}{$b} <=> $self->{scores}{$a}}
                   grep {$self->{scores}{$_} >= $self->{threshold}}
                   keys %{$self->{scores}}];
  return @{$self->{cats}};
}

sub scores {
  my $self = shift;
  return @{$self->{scores}}{@_};
}

1;

__END__

=head1 NAME

AI::Categorizer::Hypothesis - Embodies a set of category assignments

=head1 SYNOPSIS

 use AI::Categorizer::Hypothesis;
 
 # Hypotheses are usually created by the Learner's categorize() method.
 # (assume here that $learner and $document have been created elsewhere)
 my $h = $learner->categorize($document);
 
 print "Assigned categories: ", join ', ', $h->categories, "\n";
 print "Best category: ", $h->best_category, "\n";
 print "Assigned scores: ", join ', ', $h->scores( $h->categories ), "\n";
 print "Chosen from: ", join ', ', $h->all_categories, "\n";
 print +($h->in_category('geometry') ? '' : 'not '), "assigned to geometry\n";

=head1 DESCRIPTION

A Hypothesis embodies a set of category assignments that a categorizer
makes about a single document.  Because one may be interested in
knowing different kinds of things about the assignments (for instance,
what categories were assigned, which category had the highest score,
whether a particular category was assigned), we provide a simple class
to help facilitate these scenarios.

=head1 METHODS

=over 4

=item new(%parameters)

Returns a new Hypothesis object.  Generally a user of
C<AI::Categorize> doesn't create a Hypothesis object directly - they
are returned by the Learner's C<categorize()> method.  However, if you
wish to create a Hypothesis directly (maybe passing it some fake data
for testing purposes) you may do so using the C<new()> method.

The following parameters are accepted when creating a new Hypothesis:

=over 4

=item all_categories

A required parameter which gives the set of all categories that could
possibly be assigned to.  The categories should be specified as a
reference to an array of category names (as strings).

=item scores

A hash reference indicating the assignment score for each category.
Any score higher than the C<threshold> will be considered to be
assigned.

=item threshold

A number controlling which categories should be assigned - any
category whose score is greater than or equal to C<threshold> will be
assigned, any category whose score is lower than C<threshold> will not
be assigned.

=item document_name

An optional string parameter indicating the name of the document about
which this hypothesis was made.

=back


=item categories()

Returns an ordered list of the categories the document was placed in,
with best matches first.  Categories are returned by their string names.

=item best_category()

Returns the name of the category with the highest score in this
hypothesis.  Bear in mind that this category may not actually be
assigned if no categories' scores exceed the threshold.

=item in_category($name)

Returns true or false depending on whether the document was placed in
the given category.

=item scores(@names)

Returns a list of result scores for the given categories.  Since the
interface is still changing, and since different Learners implement
scoring in different ways, not very much can officially be said
about the scores, except that a good score is higher than a bad
score.  Individual Learners will have their own procedures for
determining scores, so you cannot compare one Learner's score with
another Learner's - for instance, one Learner might always give scores
between 0 and 1, and another Learner might always return scores less
than 0.  You often cannot compare scores from a single Learner on two
different categorization tasks either.

=item all_categories()

Returns the list of category names specified with the
C<all_categories> constructor parameter.

=item document_name()

Returns the value of the C<document_name> parameter specified as a
constructor parameter, or C<undef> if none was specified.

=back

=head1 AUTHOR

Ken Williams <ken@mathforum.org>

=head1 COPYRIGHT

This distribution is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.  These terms apply to
every file in the distribution - if you have questions, please contact
the author.

=cut
