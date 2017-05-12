package AI::NaiveBayes::Learner;
$AI::NaiveBayes::Learner::VERSION = '0.04';
use strict;
use warnings;
use 5.010;

use List::Util qw( min sum );
use Moose;
use AI::NaiveBayes;

has attributes => (is => 'ro', isa => 'HashRef', default => sub { {} }, clearer => '_clear_attrs');
has labels     => (is => 'ro', isa => 'HashRef', default => sub { {} }, clearer => '_clear_labels');
has examples  => (is => 'ro', isa => 'Int',     default => 0, clearer => '_clear_examples');

has features_kept => (is => 'ro', predicate => 'limit_features');

has classifier_class => ( is => 'ro', isa => 'Str', default => 'AI::NaiveBayes' );

sub add_example {
    my ($self, %params) = @_;
    for ('attributes', 'labels') {
        die "Missing required '$_' parameter" unless exists $params{$_};
    }

    $self->{examples}++;

    my $attributes = $params{attributes};
    my $labels     = $params{labels};

    add_hash($self->attributes(), $attributes);

    my $our_labels = $self->labels;
    foreach my $label ( @$labels ) {
        $our_labels->{$label}{count}++;
        $our_labels->{$label}{attributes} //= {};
        add_hash($our_labels->{$label}{attributes}, $attributes);
    }
}

sub classifier {
    my $self = shift;

    my $examples    = $self->examples;
    my $labels       = $self->labels;
    my $vocab_size   = keys %{ $self->attributes };
    my $model;
    $model->{attributes} = $self->attributes;


    # Calculate the log-probabilities for each category
    foreach my $label (keys %$labels) {
        $model->{prior_probs}{$label} = log($labels->{$label}{count} / $examples);

        # Count the number of tokens in this cat
        my $label_tokens = sum( values %{ $labels->{$label}{attributes} } );

        # Compute a smoothing term so P(word|cat)==0 can be avoided
        $model->{smoother}{$label} = -log($label_tokens + $vocab_size);

        # P(attr|label) = $count/$label_tokens                         (simple)
        # P(attr|label) = ($count + 1)/($label_tokens + $vocab_size)   (with smoothing)
        # log P(attr|label) = log($count + 1) - log($label_tokens + $vocab_size)

        my $denominator = log($label_tokens + $vocab_size);

        while (my ($attribute, $count) = each %{ $labels->{$label}{attributes} }) {
            $model->{probs}{$label}{$attribute} = log($count + 1) - $denominator;
        }

        if ($self->limit_features) {
            my %old  = %{$model->{probs}{$label}};
            my @features = sort { abs($old{$a}) <=> abs($old{$b}) } keys(%old);
            my $limit = min($self->features_kept, 0+@features);
            if ($limit < 1) {
                $limit = int($limit * keys(%old));
            }
            my @top = @features[0..$limit-1];
            my %kept = map { $_ => $old{$_} } @top;
            $model->{probs}{$label} = \%kept;
        }
    }
    my $classifier_class = $self->classifier_class;
    return $classifier_class->new( model => $model );
}

sub add_hash {
    my ($first, $second) = @_;
    $first //= {};
    foreach my $k (keys %$second) {
        $first->{$k} //= 0;
        $first->{$k} += $second->{$k};
    }
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding UTF-8

=head1 NAME

AI::NaiveBayes::Learner - Build AI::NaiveBayes classifier from a set of training examples.

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    my $learner = AI::NaiveBayes::Learner->new(features_kept => 0.5);
    $learner->add_example(
        attributes => { sheep => 1, very => 1, valuable => 1, farming => 1 },
        labels => ['farming'] 
    );

    my $classifier = $learner->classifier;

=head1 DESCRIPTION

This is a trainer of AI::NaiveBayes classifiers.  It saves information passed
by the C<add_example> method from
training data into internal structures and then constructs a classifier when
the C<classifier> method is called.

=head1 ATTRIBUTES

=over 4

=item C<features_kept>

Indicates how many features should remain after calculating probabilities. By
default all of them will be kept. For C<features_kept> > 1, C<features_kept> of
features will be preserved. For values lower than 1, a specified fraction of 
features will be kept (e.g. top 20% of features for C<features_kept> = 0.2).

The rest of the attributes is for class' internal usage, and thus not
documented.

=item C<classifier_class>

The class of the classifier to be created.  By default it is
C<AI::NaiveBayes>

=back

=head1 METHODS

=over 4

=item C<add_example( attributes => HASHREF, labels => LIST )>

Saves the information from a training example into internal data structures.
C<attributes> should be of the form of 
    { feature1 => weight1, feature2 => weight2, ... }
C<labels> should be a list of strings denoting one or more classes to which the example belongs.

=item C<classifier()>

    Creates an AI::NaiveBayes classifier based on the data accumulated before.

=back

=head1 UTILITY SUBS

=over 4

=item C<add_hash>

=back

=head1 BASED ON

Much of the code and description is from L<Algorithm::NaiveBayes>.

=head1 AUTHORS

=over 4

=item *

Zbigniew Lukasiak <zlukasiak@opera.com>

=item *

Tadeusz Sośnierz <tsosnierz@opera.com>

=item *

Ken Williams <ken@mathforum.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Opera Software ASA.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Build AI::NaiveBayes classifier from a set of training examples.

