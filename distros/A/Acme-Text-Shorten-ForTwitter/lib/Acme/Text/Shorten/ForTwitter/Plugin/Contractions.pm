package Acme::Text::Shorten::ForTwitter::Plugin::Contractions;

use strict;
use warnings;

sub modify_base_rules {
  my $pkg = shift;
  my $base = shift;

  $base->{contractions} = sub {
    my $text = shift;

    my %contractions = (
      "am not"         => "ain't",
      "are not"        => "aren't",
      "cannot"         => "can't",
      "can not"        => "can't",
      "could have"     => "could've",
      "could not have" => "couldn't've",
      "did not"        => "didn't",
      "does not"       => "doesn't",
      "do not"         => "don't",
      "had not"        => "hadn't",
      "had not have"   => "hadn't've",
      "has not"        => "hasn't",
      "have not"       => "haven't",
      "he had"         => "he'd",
      "he would"       => "he'd",
      "he shall"       => "he'll",
      "he will"        => "he'll",
      "he has"         => "he's",
      "he is"          => "he's",
      "how did"        => "how'd",
      "how would"      => "how'd",
      "how will"       => "how'l",
      "how has"        => "how's",
      "how is"         => "how's",
      "how does"       => "how's",
      "I had"          => "I'd",
      "I would have"   => "I'd've",
      "I shall"        => "I'll",
      "I will"         => "I'll",
      "I am"           => "I'm",
      "I have"         => "I've",
      "it had"         => "it'd",
      "it would"       => "it'd",
      "it would have"  => "it'd've",
      "it shall"       => "it'll",
      "it will"        => "it'll",
      "it has"         => "it's",
      "it is"          => "it's",
      "let us"         => "let's",
      "madam"          => "ma'am",
      "might not"      => "mightn't",
      "might not have" => "mightn't've",
      "might have"     => "might've",
      "must not"       => "mustn't",
      "need not"       => "needn't",
      "not have"       => "not've",
      "of the clock"   => "o'clock",
      "ought not"      => "oughtn't",
      "how is that"    => "'ow's'at",
      "shall not"      => "shan't",
      "she had"        => "she'd",
      "she would"      => "she'd",
      "she shall"      => "she'll",
      "she will"       => "she'll",
      "she has"        => "she's",
      "she is"         => "she's",
      "should have"    => "should've",
      "should not"     => "shouldn't",
      "should not have" => "shouldn't've",
      "that will"       => "that'll",
      "that has"        => "that's",
      "that is"         => "that's",
      "there had"       => "there'd",
      "there would"     => "there'd",
      "there would have" => "there'd've",
      "there are"        => "there're",
      "there has"        => "there's",
      "there is"         => "there's",
      "they had"         => "they'd",
      "they have"        => "they'd",
      "they would have"  => "they'd've",
      "they will"        => "they'll",
      "they shall"       => "they'll",
      "they are"         => "they're",
      "they have"        => "they've",
      "was not"          => "wasn't",
      "we had"           => "we'd",
      "we would"         => "we'd",
      "we would have"    => "we'd've",
      "we will"          => "we'll",
      "we are"           => "we're",
      "we have"          => "we've",
      "were not"         => "weren't",
      "what shall"       => "what'll",
      "what will"        => "what'll",
      "what are"         => "what're",
      "what has"         => "what's",
      "what is"          => "what's",
      "what does"        => "what's",
      "what did"         => "what'd",
      "what have"        => "what've",
      "when has"         => "when's",
      "when is"          => "when's",
      "where did"        => "where'd",
      "where has"        => "where's",
      "where is"         => "where's",
      "where have"       => "where've",
      "who would"        => "who'd",
      "who had"          => "who'd",
      "who would have"   => "who'd've",
      "who shall"        => "who'll",
      "who will"         => "who'll",
      "who are"          => "who're",
      "who has"          => "who's",
      "who is"           => "who's",
      "who have"         => "who've",
      "why will"         => "why'll",
      "why are"          => "why're",
      "why has"          => "why's",
      "why is"           => "why's",
      "will not"         => "won't",
      "would have"       => "would've",
      "would not"        => "wouldn't",
      "would not have"   => "wouldn't've",
      "you all"          => "y'all",
      "you all should have" => "y'all'd've",
      "you all could have"  => "y'all'd've",
      "you all would have"  => "y'all'd've",
      "you had"             => "you'd",
      "you would"           => "you'd",
      "you shall"           => "you'll",
      "you will"            => "you'll",
      "you are"             => "you're",
      "you have"            => "you've",
    );

    for my $c (reverse sort { length $a <=> length $b } keys %contractions) {
      $$text =~ s/(\b)$c(\b)/$contractions{$c}/g;
    }
  };

  return;
}

1;
__END__

=head1 NAME

Acme::Text::Shorten::ForTwitter::Plugin::Contractions - Common English contractions

=head1 DESCRIPTION

Adds shorteners for things like:

  "I am" -> "I'm",
  "I would have"   => "I'd've",

etc...

=head1 AUTHOR

Matthew Horsfall (alh) - <wolfsage@gmail.com>

=cut

