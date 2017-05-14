package Acme::Text::Shorten::ForTwitter::Plugin::Texting;

use strict;
use warnings;

sub modify_base_rules {
  my $pkg = shift;
  my $base = shift;

  $base->{texting} = sub {
    my $text = shift;

    my %textisms = (
      "your" => "ur",
      "you're" => "ur",
      "you are" => "ur",
      "why" => "y",
      "you" => "u",
      "what" => "wut",
      
    );

    for my $c (reverse sort { length $a <=> length $b } keys %textisms) {
      $$text =~ s/(\b)$c(\b)/$textisms{$c}/g;
    }
  };

  return;
}

1;
__END__

=head1 NAME

Acme::Text::Shorten::ForTwitter::Plugin::Texting - Common texting atrocities

=head1 DESCRIPTION

Adds shorteners for things like:

  "you" => "u",
  "why" => "u",

etc...

=head1 AUTHOR

Matthew Horsfall (alh) - <wolfsage@gmail.com>

=cut

