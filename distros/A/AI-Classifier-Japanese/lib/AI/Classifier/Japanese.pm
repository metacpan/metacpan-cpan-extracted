package AI::Classifier::Japanese;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

use Mouse;
use Text::MeCab;
use Algorithm::NaiveBayes;

my $nb = Algorithm::NaiveBayes->new;

sub add_training_text {
  my ($self, $text, $category) = @_;

  my $words_freq_ref = &_convert_text_to_bow($text);
  $nb->add_instance(
    attributes => $words_freq_ref,
    label      => $category
  );
}

sub train {
  $nb->train;
}

sub labels {
  $nb->labels;
}

sub predict {
  my ($self, $text) = @_;

  my $words_freq_ref = &_convert_text_to_bow($text);
  my $result_ref = $nb->predict(
    attributes => $words_freq_ref
  );
}

sub _convert_text_to_bow {
  my $text = shift;

  my $words_ref = &_parse_text($text);
  my $words_freq_ref = {};
  foreach (@$words_ref) {
    $words_freq_ref->{$_}++;
  }
  return $words_freq_ref;
}

sub _parse_text {
  my $text = shift;

  my $mecab = Text::MeCab->new();
  my $node = $mecab->parse($text);
  my $words_ref = [];

  while ($node) {
    if (&_is_keyword($node->posid)) {
      push @$words_ref, $node->surface;
    }
    $node = $node->next;
  }
  return $words_ref;
}

sub save_state {
  my ($self, $path) = @_;
  $nb->save_state($path);
}

sub restore_state {
  my ($self, $path) = @_;
  $nb = Algorithm::NaiveBayes->restore_state($path);
}

sub _is_keyword {
  my $posid = shift;

  return &_is_noun($posid) || &_is_verb($posid) || &_is_adj($posid);
}

# See: http://mecab.googlecode.com/svn/trunk/mecab/doc/posid.html
sub _is_interjection {
  return $_[0] == 2;
}
sub _is_adj {
  return 10 <= $_[0] && $_[0] < 13;
}
sub _is_aux {
  return $_[0] == 25;
}
sub _is_conjunction {
  return $_[0] == 26;
}
sub _is_particls {
  return 27 <= $_[0] && $_[0] < 31;
}
sub _is_verb {
  return 31 <= $_[0] && $_[0] < 34;
}
sub _is_noun {
  return 36 <= $_[0] && $_[0] < 68;
}
sub _is_prenominal_adj {
  return $_[0] == 68;
}

__PACKAGE__->meta->make_immutable();

1;
__END__

=encoding utf-8

=head1 NAME

AI::Classifier::Japanese - the combination wrapper of Algorithm::NaiveBayes and
Text::MeCab.

=head1 SYNOPSIS

    use AI::Classifier::Japanese;

    # Create new instance
    my $classifier = AI::Classifier::Japanese->new();

    # Add training text
    $classifier->add_training_text("たのしい．楽しい！", 'positive');
    $classifier->add_training_text("つらい．辛い！", 'negative');

    # Train
    $classifier->train;

    # Test
    my $result_ref = $classifier->predict("たのしい");
    print $result_ref->{'positive'}; # => Confidence value

=head1 DESCRIPTION

AI::Classifier::Japanese is a Japanese-text category classifier module using Naive Bayes and MeCab.
This module is based on Algorithm::NaiveBayes.
Only noun, verb and adjective are currently supported.

=head1 METHODS

=over

=item C<< my $classifier = AI::Classifier::Japanese->new(); >>

Create new instance of AI::Classifier::Japanese.

=item C<< $classifier->add_training_text($text, $category); >>

Add training text.

=item C<< $classifier->train; >>

Train.

=item C<< my $result_ref = $classifier->predict($text); >>

Test and returns a predicted result hash reference which has a confidence value for each category.

=item C<< $classifier->save_state($params_path); >>

Save parameters.

=item C<< $classifier->restore_state($params_path); >>

Restore parameters from a file.

=item C<< my @labels = $classifier->labels; >>

Get category labels as an array reference.

=back

=head1 LICENSE

Copyright (C) Shinichi Goto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Shinichi Goto E<lt>shingtgt @ GMAIL COME<gt>

=cut

