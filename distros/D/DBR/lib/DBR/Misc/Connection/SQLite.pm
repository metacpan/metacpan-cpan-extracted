package DBR::Misc::Connection::SQLite;

use strict;
use base 'DBR::Misc::Connection';

sub required_config_fields {   [ qw(dbfile) ]   };

sub getSequenceValue{
      my $self = shift;
      my $call = shift;

      my ($insert_id)  = $self->{dbh}->func('last_insert_rowid');
      return $insert_id;

}

1;
