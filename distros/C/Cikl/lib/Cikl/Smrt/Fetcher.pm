package Cikl::Smrt::Fetcher;

use strict;
use warnings;
use Mouse;

has 'feedurl' => (
  is => 'ro',
  isa => 'URI',
  required => 1
);

sub schemes { 
  my $class = shift;
  die("$class has not implemented the schemes() method!");
}

sub fetch {
  my $class = shift;
  my $feedparser_config = shift;
  die("$class has not implemented the schemes() method!");
}

1;



