package JAF::DBI::Pg;

use strict;
use base qw( JAF::DBI );

sub last_insert_id {
  shift->{last_insert_id}
}

sub date_format {
  return sprintf "%04d-%02d-%02d", (shift =~ /(\d{1,2}).(\d{1,2}).(\d{4})/)[2,1,0];
}
sub datetime_format {
  return sprintf "%04d-%02d-%02d %02d:%02d:%02d", (shift =~ /(\d{1,2}).(\d{1,2}).(\d{4})\s+(\d{2}).(\d{2}).?(\d{2})?/)[2,1,0,3,4,5];
}

sub insert {
  my ($self, $params, $options) = @_;
  if($self->{key} && !ref $self->{key}) {
    $params->{$self->{key}} = $self->{dbh}->selectrow_array("select nextval('seq_$self->{table}')") unless($params->{$self->{key}});
    $self->{last_insert_id} = $params->{$self->{key}};
  }
  return $self->SUPER::insert($params, $options)
}

sub _record_sql {
  my ($self, $options) = @_;
  
  my @cols = $options && $options->{cols} ? @{$options->{cols}} : @{$self->{cols}};
  foreach my $c(!$self->{key} ? () : ref $self->{key} eq 'ARRAY' ? @{$self->{key}} : ($self->{key})) {
    push @cols, $c unless(grep {$_ eq $c} @cols)
  }
  my $criteria = $options->{criteria};
  
  my $return = "select ".(join ',', @cols)." from $self->{table} ";
  if ($criteria) {
    $return .= " where ".(ref $criteria eq 'ARRAY' ? join ' and ', map {"$_ = ?"} @$criteria : "$criteria = ?");
  }
  if($options->{order_by}) {
    if($options->{order_by} =~ /^(.+)(\+|\-)$/) {
      $return .= " order by $1 ".($2 eq '-' ? 'desc' : 'asc')
    } else {
      $return .= " order by $options->{order_by}"
    }
  }
  $return .= " offset $options->{offset}" if $options->{offset};
  $return .= " limit $options->{limit}" if $options->{limit};
  return $return;
}

1;
