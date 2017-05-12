package CLIDTest::More;

use strict;
use warnings;
use base qw( CLI::Dispatch );

my %alias = ( S => 'Simple', Args => 'WithArgs', Options => 'WithOptions' );

sub convert_command {
  my $command = shift->SUPER::convert_command(@_);
  return $alias{$command} ? $alias{$command} : $command;
}

1;
