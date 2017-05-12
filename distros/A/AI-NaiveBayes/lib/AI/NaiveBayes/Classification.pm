package AI::NaiveBayes::Classification;
$AI::NaiveBayes::Classification::VERSION = '0.04';
use strict;
use warnings;
use 5.010;
use Moose;

has features => (is => 'ro', isa => 'HashRef[HashRef]', required => 1);
has label_sums => (is => 'ro', isa => 'HashRef', required => 1);
has best_category => (is => 'ro', isa => 'Str', lazy_build => 1);

sub _build_best_category {
    my $self = shift;
    my $sc = $self->label_sums;

    my ($best_cat, $best_score) = each %$sc;
    while (my ($key, $val) = each %$sc) {
        ($best_cat, $best_score) = ($key, $val) if $val > $best_score;
    }
    return $best_cat;
}

sub find_predictors{
    my $self = shift;

    my $best_cat = $self->best_category;
    my $features = $self->features;
    my @predictors; 
    for my $feature ( keys %$features  ) {
        for my $cat ( keys %{ $features->{$feature } } ){
            next if $cat eq $best_cat;
            push @predictors, [ $feature, $features->{$feature}{$best_cat} - $features->{$feature}{$cat} ];
        }
    }
    @predictors = sort { abs( $b->[1] ) <=> abs( $a->[1] ) } @predictors;
    return $best_cat, @predictors;
}


__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding UTF-8

=head1 NAME

AI::NaiveBayes::Classification - The result of a bayesian classification

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    my $result = $classifier->classify({bar => 3, blurp => 2});
    # $result is an AI::NaiveBayes::Classification object
    say $result->best_category;
    my $predictors = $result->find_predictors;

=head1 DESCRIPTION

AI::NaiveBayes::Classification represents the result of a bayesian classification,
produced by AI::NaiveBayes classifier.

=head1 METHODS

=over 4

=item C<best_category()>

Returns a string being a label that suits given document the best.

=item C<find_predictors()>

This method returns the C<best_category()>, as well as the list of all the predictors
along with their influence on the best category selected. So the second value
returned is a list of array references, where each one contains a string being a
single feature and a number describing its influence on the result. So the
second part of the result may look like this:

    (
        [ 'activities',  1.2511540632952 ],
        [ 'over',       -1.0269523272981 ],
        [ 'provide',     0.8280157033269 ],
        [ 'natural',     0.7361042359385 ],
        [ 'against',    -0.6923354975173 ],
    )

=back

=head1 SEE ALSO

AI::NaiveBayes (3), AI::Classifier(3)

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

# ABSTRACT: The result of a bayesian classification

