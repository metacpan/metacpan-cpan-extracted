package Data::Range::Compare::Stream::Iterator::Consolidate::FileAsc;

use strict;
use warnings;
use base qw(Data::Range::Compare::Stream::Iterator::File);
use Data::Range::Compare::Stream;
use Data::Range::Compare::Stream::Iterator::Consolidate::Result;

use constant RESULT_FROM=>'Data::Range::Compare::Stream::Iterator::Consolidate::Result';

sub get_next {
  my ($self)=@_;
  my $range=$self->SUPER::get_next;

  return $self->RESULT_FROM->new($range,$range,$range);
}

1;
