package Data::Range::Compare::Stream::Iterator::File::Temp;

use strict;
use warnings;
use File::Temp qw/ :seekable /;

sub get_temp {
  my ($self,%args)=@_;
  %args=(UNLINK=>0,%args);
  $args{DIR}=$self->{tmpdir} if defined($self->{tmpdir});

  File::Temp->new(%args);
}

1;
