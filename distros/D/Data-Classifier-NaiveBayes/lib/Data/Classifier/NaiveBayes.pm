package Data::Classifier::NaiveBayes;
use Moose;
use MooseX::Types::LoadableClass qw(LoadableClass);
use List::Util qw(reduce sum);
use 5.008008;

has categories => (
    is => 'rw',
    default => sub { {} });

# Need to implement
has thresholds => (
    is => 'rw',
    default => sub { {} });

has tokenizer => (
    is => 'rw',
    lazy_build => 1);

has tokenizer_class => (
    is => 'ro',
    isa => LoadableClass,
    default => 'Data::Classifier::NaiveBayes::Tokenizer',
    coerce => 1);

has words => (
    is => 'rw',
    default => sub { {} });

sub _build_tokenizer { $_[0]->tokenizer_class->new }

sub _cat_count {
    my ($self, $category) = @_;
    $self->categories->{$category};
}

sub _cat_scores {
    my ($self, $text) = @_;

    my $probs = {};

    for my $cat (keys %{$self->categories}) {
        $probs->{$cat} = $self->_text_prop($cat, $text);
    }

    return sort { $a->[1] <=> $b->[1] } map { [$_, $probs->{$_} ] } keys %{$probs};
}

sub _doc_prob {
    my ($self, $text, $cat) = @_;

    return reduce { $a * $b } @{$self->tokenizer->words($text, sub{
        my $word = shift;
        return $self->_word_weighted_average($word, $cat);
    })};
}

sub _inc_cat {
    my ($self, $cat) = @_;
    $self->categories->{$cat} ||= 0;
    $self->categories->{$cat} += 1;
}

sub _inc_word {
    my ($self, $word, $cat) = @_;
    $self->words->{$word} ||= {};
    $self->words->{$word}->{$cat} ||= 0;
    $self->words->{$word}->{$cat} += 1;
}

sub _text_prop {
    my ($self, $cat, $text) = @_;
    my $cat_prob = ($self->_cat_count($cat) / $self->_total_count);
    my $doc_prob = $self->_doc_prob($text, $cat);
    return $cat_prob * $doc_prob;
}

sub _total_count {
    my ($self) = @_;
    return sum values %{$self->categories};
}

sub _word_count {
    my ($self, $word, $category) = @_;
    return 0.0 unless $self->words->{$word} && $self->words->{$word}->{$category};
    return sprintf("%.2f", $self->words->{$word}->{$category});
}

sub _word_prob {
    my ($self, $word, $cat ) = @_;
    return 0.0 if $self->_cat_count($cat) == 0;
    return sprintf("%.2f", $self->_word_count($word, $cat) / $self->_cat_count($cat));
}

sub _word_weighted_average {
    my ($self, $word, $cat ) = @_;
  
    my $weight = 1.0;
    my $assumed_prob = 0.5;

    # calculate current probability
    my $basic_prob = $self->_word_prob($word, $cat);

    # count the number of times this word has appeared in all
    # categories
    my $totals = sum map { $self->_word_count($word, $_) } keys %{$self->categories};
  
    # the final weighted average
    return ($weight * $assumed_prob + $totals * $basic_prob) / ($weight + $totals);
}

sub classify {
    my ($self, $text, $default) = @_;

    my $max_prob = 0.0;
    my $best = undef;

    my @scores = $self->_cat_scores($text);

    for my $score ( @scores) {
        my ( $cat, $prob ) = @{$score};
        if ( $prob > $max_prob ) {
            $max_prob = $prob;
            $best = $cat;
        }
    }

    return $default unless $best;
    my $threshold = $self->thresholds->{$best} || 1.0;

    for my $score ( @scores ) {
        my ( $cat, $prob ) = @{$score};

        next if $cat eq $best;
        return $default if $prob * $threshold > $max_prob;
    }

    return $best;
}

sub train {
    my ( $self, $cat, $string ) = @_;
    $self->tokenizer->words($string, sub{
        $self->_inc_word(shift, $cat);    
    });
    $self->_inc_cat($cat);
}

1;
=head1 NAME

Data::Classifier::NaiveBayes

=head1 SYNOPSIS

    my $classifier = Data::Classifier::NaiveBayes->new;

    $classifier->train('token', "Some text to train with");
    print $classifier->classify("Some text to find a match");

=head1 DESCRIPTION

This a Naive Bayes classifer. The code for this project is largely and
shamelessly based off of the work done by alexandru's stuff-classifier 
originally written in Ruby.

    https://github.com/alexandru/stuff-classifier

The code was ported over to Perl and L<Moose>. 

For more information please see the following:

    http://bionicspirit.com/blog/2012/02/09/howto-build-naive-bayes-classifier.html


=head1 ATTRIBUTES

=head2 tokenizer

An access to L<Data::Classifier::NaiveBayes::Tokenizer>.

=head2 tokenizer_class

A string to the tokenizer class name.

=head2 words($hash_ref)

A key value pair of word counts by categories

=head2 categories($hash_ref)

A key value pair of catogory counts.

=head1 METHODS

=head2 classify($phrase)

This will return the highest probable category associated with the phrase.

=head2 train($category, $phrase)

This will perform a word count and associate words with a category to later be
classified.

=head1 SEE ALSO

L<Moose> 

=head1 AUTHOR

Logan Bell, C<< <logie@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012, Logan Bell

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
