package JAF::DBI::mysql;

use strict;
use base qw( JAF::DBI );

sub last_insert_id { $_[0]->{dbh}->{mysql_insertid} }

sub date_format {
  return sprintf "%04d-%02d-%02d", (shift =~ /(\d{1,2}).(\d{1,2}).(\d{4})/)[2,1,0];
}
sub datetime_format {
  return sprintf "%04d-%02d-%02d %02d:%02d:%02d", (shift =~ /(\d{1,2}).(\d{1,2}).(\d{4})\s+(\d{2}).(\d{2}).?(\d{2})?/)[2,1,0,3,4,5];
}

sub _replace_sql {
  my ($self, $options) = @_;
  my $cols = $options->{cols} || $self->{cols};
  return "replace into $self->{table} (".(join ',', @{$cols}).") values (".(join ',', map {'?'} @{$cols}).")";
}

sub replace { 
  my ($self, $params, $options) = @_;
  
  my @cols = $options && $options->{cols} ? @{$options->{cols}} : @{$self->{cols}};
  @cols = grep {exists $params->{$_}} @cols;
  my $sql = $options->{sql} || $self->_replace_sql({%$options, cols => \@cols});

  my $return = $self->{dbh}->do($sql, undef, map {$params->{$_}} @cols);
  $return ? $self->message(defined $options->{message} ? $options->{message} : $self->{insert_message}) : $self->error($self->{dbh}->errstr());
  return $return;
}

1;
