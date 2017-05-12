use strict;
use warnings;
package TestApp::Command::str;
use TestApp -command;

sub run {
  my ($self) = @_;

  my $str = prompt_str('please enter a string');
  printf "you entered: <%s>\n", $str;
};

1;
