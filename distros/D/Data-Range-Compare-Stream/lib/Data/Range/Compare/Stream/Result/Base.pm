package Data::Range::Compare::Stream::Result::Base;

use strict;
use warnings;
use overload
  'bool'=>\&boolean,
  '""'=>\&to_string,
  Fallback=>1;

sub to_string { join ' - ',@{$_[0]}[0,1] }

sub new {
  my ($class,@args)=@_;
  bless [@args],$class;
}

sub get_common { $_[0] }


sub boolean { 1 }

1;
