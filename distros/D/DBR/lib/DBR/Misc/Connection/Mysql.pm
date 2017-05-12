package DBR::Misc::Connection::Mysql;

use strict;
use base 'DBR::Misc::Connection';


sub getSequenceValue{
      my $self = shift;
      my $call = shift;

      my ($insert_id)  = $self->{dbh}->selectrow_array('select last_insert_id()');
      return $insert_id;

}

sub can_trust_execute_rowcount{ 1 } # NOTE: This should be variable when mysql_use_result is implemented

1;
