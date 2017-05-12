package Data::Range::Compare::Stream::Iterator::Consolidate::Result;

use strict;
use warnings;
use overload '""'=>\&to_string,fallback=>1;

use constant COMMON_RANGE=>0;
use constant START_RANGE=>1;
use constant END_RANGE=>2;
use constant IS_MISSING=>3;
use constant IS_GENERATED=>4;

use base qw(Data::Range::Compare::Stream::Result::Base);

sub get_common { $_[0]->[COMMON_RANGE] }
sub get_common_range { $_[0]->[COMMON_RANGE] }
sub get_start { $_[0]->[START_RANGE] }
sub get_start_range { $_[0]->[START_RANGE] }
sub get_end { $_[0]->[END_RANGE] }
sub get_end_range { $_[0]->[END_RANGE] }
sub is_missing { $_[0]->[$_[0]->IS_MISSING] }
sub is_generated { $_[0]->[$_[0]->IS_GENERATED] }


sub to_string {
  my ($self)=@_;
  sprintf 'Commoon Range: [%s] Starting range: [%s] Ending Range: [%s]',$self->get_common,$self->get_start,$self->get_end
}


1;
