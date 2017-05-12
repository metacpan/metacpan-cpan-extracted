use strict;
use warnings;
package TestApp::Command::any;
use TestApp -command;

sub run {
  my ($self) = @_;

  prompt_any_key;
  print "thanks for pressing a key\n";
};

1;
