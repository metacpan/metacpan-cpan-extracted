package AI::NaiveBayes;

use strict;
use warnings;
use 5.010;
use AI::NaiveBayes::Classification;
use AI::NaiveBayes::Learner;
use Moose;
use MooseX::Storage;

use List::Util qw(max);

with Storage(format => 'Storable', io => 'File');

has model   => (is => 'ro', isa => 'HashRef[HashRef]', required => 1);

sub train {
    my $self = shift;
    my $learner = AI::NaiveBayes::Learner->new();
    for my $example ( @_ ){
        $learner->add_example( %$example );
    }
    return $learner->classifier;
}


sub classify {
    my ($self, $newattrs) = @_;
    $newattrs or die "Missing parameter for classify()";

    my $m = $self->model;

    # Note that we're using the log(prob) here.  That's why we add instead of multiply.

    my %scores = %{$m->{prior_probs}};
    my %features;
    while (my ($feature, $value) = each %$newattrs) {
        next unless exists $m->{attributes}{$feature};  # Ignore totally unseen features
        while (my ($label, $attributes) = each %{$m->{probs}}) {
            my $score = ($attributes->{$feature} || $m->{smoother}{$label})*$value;  # P($feature|$label)**$value
            $scores{$label} += $score;
            $features{$feature}{$label} = $score;
        }
    }

    rescale(\%scores);

    return AI::NaiveBayes::Classification->new( label_sums => \%scores, features => \%features );
}

sub rescale {
    my ($scores) = @_;

    # Scale everything back to a reasonable area in logspace (near zero), un-loggify, and normalize
    my $total = 0;
    my $max = max(values %$scores);
    foreach (values %$scores) {
        $_ = exp($_ - $max);
        $total += $_**2;
    }
    $total = sqrt($total);
    foreach (values %$scores) {
        $_ /= $total;
    }
}


__PACKAGE__->meta->make_immutable;

1;
__END__


# ABSTRACT: A Bayesian classifier

=encoding utf8

=head1 SYNOPSIS

    # AI::NaiveBayes objects are created by AI::NaiveBayes::Learner
    # but for quick start you can use the 'train' class method
    # that is a shortcut using default AI::NaiveBayes::Learner settings

    my $classifier = AI::NaiveBayes->train( 
        {
            attributes => {
                sheep => 1, very => 1,  valuable => 1, farming => 1
            },
            labels => ['farming']
        },
        {
            attributes => {
                vampires => 1, cannot => 1, see => 1, their => 1,
                images => 1, mirrors => 1
            },
            labels => ['vampire']
        },
    );

    # Classify a feature vector
    my $result = $classifier->classify({bar => 3, blurp => 2});
    
    # $result is now a AI::NaiveBayes::Classification object
    
    my $best_category = $result->best_category;
    
=head1 DESCRIPTION

This module implements the classic "Naive Bayes" machine learning
algorithm.  This is a low level class that accepts only pre-computed feature-vectors
as input, see L<AI::Classifier::Text> for a text classifier that uses
this class.  

Creation of C<AI::NaiveBayes> classifier object out of training
data is done by L<AI::NaiveBayes::Learner>. For quick start 
you can use the limited C<train> class method that trains the 
classifier in a default way.

The classifier object is immutable.

It is a well-studied probabilistic algorithm often used in
automatic text categorization.  Compared to other algorithms (kNN,
SVM, Decision Trees), it's pretty fast and reasonably competitive in
the quality of its results.

A paper by Fabrizio Sebastiani provides a really good introduction to
text categorization:
L<http://faure.iei.pi.cnr.it/~fabrizio/Publications/ACMCS02.pdf>

=head1 METHODS

=over 4

=item new( model => $model )

Internal. See L<AI::NaiveBayes::Learner> to learn how to create a C<AI::NaiveBayes>
classifier from training data.

=item train( LIST of HASHREFS )

Shortcut for creating a trained classifier using L<AI::NaiveBayes::Learner> default
settings. 
Arguments are passed to the C<add_example> method of the L<AI::NaiveBayes::Learner>
object one by one.

=item classify( HASHREF )

Classifies a feature-vector of the form:

    { feature1 => weight1, feature2 => weight2, ... }
    
The result is a C<AI::NaiveBayes::Classification> object.

=item rescale

Internal

=back

=head1 ATTRIBUTES 

=over 4

=item model

Internal

=back

=head1 THEORY

Bayes' Theorem is a way of inverting a conditional probability. It
states:

    P(y|x) P(x)
        P(x|y) = -------------
    P(y)

The notation C<P(x|y)> means "the probability of C<x> given C<y>."  See also
L<"http://mathforum.org/dr.math/problems/battisfore.03.22.99.html">
for a simple but complete example of Bayes' Theorem.

In this case, we want to know the probability of a given category given a
certain string of words in a document, so we have:

    P(words | cat) P(cat)
        P(cat | words) = --------------------
    P(words)

We have applied Bayes' Theorem because C<P(cat | words)> is a difficult
quantity to compute directly, but C<P(words | cat)> and C<P(cat)> are accessible
(see below).

The greater the expression above, the greater the probability that the given
document belongs to the given category.  So we want to find the maximum
value.  We write this as

    P(words | cat) P(cat)
        Best category =   ArgMax      -----------------------
    cat in cats          P(words)


Since C<P(words)> doesn't change over the range of categories, we can get rid
of it.  That's good, because we didn't want to have to compute these values
anyway.  So our new formula is:

    Best category =   ArgMax      P(words | cat) P(cat)
        cat in cats

Finally, we note that if C<w1, w2, ... wn> are the words in the document,
then this expression is equivalent to:

    Best category =   ArgMax      P(w1|cat)*P(w2|cat)*...*P(wn|cat)*P(cat)
        cat in cats

That's the formula I use in my document categorization code.  The last
step is the only non-rigorous one in the derivation, and this is the
"naive" part of the Naive Bayes technique.  It assumes that the
probability of each word appearing in a document is unaffected by the
presence or absence of each other word in the document.  We assume
this even though we know this isn't true: for example, the word
"iodized" is far more likely to appear in a document that contains the
word "salt" than it is to appear in a document that contains the word
"subroutine".  Luckily, as it turns out, making this assumption even
when it isn't true may have little effect on our results, as the
following paper by Pedro Domingos argues:
L<"http://www.cs.washington.edu/homes/pedrod/mlj97.ps.gz">

=head1 SEE ALSO

Algorithm::NaiveBayes (3), AI::Classifier::Text(3) 

=head1 BASED ON

Much of the code and description is from L<Algorithm::NaiveBayes>.

=cut
