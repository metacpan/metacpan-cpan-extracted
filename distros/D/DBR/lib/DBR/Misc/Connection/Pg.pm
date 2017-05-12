package DBR::Util::Connection::Pg;

use strict;
use base 'DBR::Util::Connection';

sub getSequenceValue{
      my $self = shift;
      my $call = shift;

      my ($last_id)  = $self->{dbh}->selectrow_array('select lastval()');
      return $last_id;

}

1;
