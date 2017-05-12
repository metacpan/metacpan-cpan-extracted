package Alzabo::Display::SWF::Text;

use strict;
use warnings;

use SWF::Text;
our $VERSION = '0.01';
sub new {
  my $pkg = shift;
  my $t = new SWF::Text;
  $t->setFont($_[1]);
  $t->setColor(@_[2..4]);
  $t->setHeight(12);
  $t->addString($_[0]);
  return $t;
}

1;

