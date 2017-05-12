package Audio::DB::Util::Warnings;

use strict;

sub print_warning {
  my ($self,$msg,$counter) = @_;
  print STDERR $msg . ": $counter";
  print STDERR -t STDOUT && !$ENV{EMACS} ? "\r" : "\n";
}


1;
