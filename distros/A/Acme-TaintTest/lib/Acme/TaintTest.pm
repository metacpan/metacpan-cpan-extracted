# This is a dummy file for testing purposes

package Acme::TaintTest;
use strict;
use warnings;
# use bytes;
use re 'taint';

require v5.14.0;


our $VERSION = "0.0.6";

our @ISA = qw();

sub Version {
  return $VERSION;
}

1
