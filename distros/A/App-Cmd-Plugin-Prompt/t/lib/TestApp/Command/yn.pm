use strict;
use warnings;
package TestApp::Command::yn;
use TestApp -command;

sub run {
  my ($self) = @_;

  my $yn = prompt_yn('just pick y or n', { default => 1 });
  printf "you picked: %s\n", ($yn ? 'yes' : 'no');
};

1;
