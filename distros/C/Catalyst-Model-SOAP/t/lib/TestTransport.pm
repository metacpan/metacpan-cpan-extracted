package TestTransport;

use strict;
use warnings;
use base qw(XML::Compile::Transport);

sub new {
  my ($class, $code) = @_;
  return bless \$code, $class;
}

sub compileClient {
  ${shift()};
}

1;
