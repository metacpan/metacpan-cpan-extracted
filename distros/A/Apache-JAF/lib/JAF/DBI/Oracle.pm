package JAF::DBI::Oracle;

use strict;
use base qw( JAF::DBI );

sub _init {
  my $self = shift;
  $self->SUPER::_init();
  $self->{scheme} = $self->{parent}{scheme};
}

sub last_insert_id {
  shift->{last_insert_id}
}

sub _insert_sql {
  my ($self, $options) = @_;
  my $cols = $options->{cols} || $self->{cols};
  return "insert into ".($options->{scheme} || $self->{scheme}).".$self->{table} (".(join ',', @$cols).") values (".(join ',', map {'?'} @$cols).")";
}

sub insert {
  my ($self, $params, $options) = @_;
  if($self->{key} && !ref $self->{key}) {
    $params->{$self->{key}} = $self->{dbh}->selectrow_array("select ".($options->{scheme} || $self->{scheme}).".seq_$self->{table}.nextval from dual") unless($params->{$self->{key}});
    $self->{last_insert_id} = $params->{$self->{key}};
  }
  return $self->SUPER::insert($params, $options)
}

sub _update_sql {
  my ($self, $options) = @_;
  my $cols = $options->{cols} || $self->{cols};
  my $criteria = exists $options->{criteria} ? $options->{criteria} : $self->{key};
  return "update ".($options->{scheme} || $self->{scheme}).".$self->{table} set ".(join ',', map {"$_ = ?"} @$cols).($criteria ? " where ".(ref $criteria eq 'ARRAY' ? join ' and ', map {"$_ = ?"} @$criteria : "$criteria = ?") : '');
}

sub _delete_sql {
  my ($self, $options) = @_;
  my $criteria = exists $options->{criteria} ? $options->{criteria} : $self->{key};
  return "delete from ".($options->{scheme} || $self->{scheme}).".$self->{table}".($criteria ? " where ".(ref $criteria eq 'ARRAY' ? join ' and ', map {"$_ = ?"} @$criteria : "$criteria = ?") : '');
}

sub _record_sql {
  my ($self, $options) = @_;
  my @cols = $options && $options->{cols} ? @{$options->{cols}} : @{$self->{cols}};
  foreach my $c(!$self->{key} ? () : ref $self->{key} eq 'ARRAY' ? @{$self->{key}} : ($self->{key})) {
    push @cols, $c unless(grep {$_ eq $c} @cols)
  }
  my $criteria = $options->{criteria};
  my $return = "select ".(join ',', @cols)." from ".($options->{scheme} || $self->{scheme}).".$self->{table} ";
  $return .= " where ".(ref $criteria eq 'ARRAY' ? join ' and ', map {"$_ = ?"} @$criteria : "$criteria = ?") if($criteria);
  if($options->{order_by}) {
    if($options->{order_by} =~ /^(.+)(\+|\-)$/) {
      $return .= " order by $1 ".($2 eq '-' ? 'desc' : 'asc')
    } else {
      $return .= " order by $options->{order_by}"
    }
  }
  if($options->{limit} =~ /^\d+$/) {
    $return = "select * from ($return) where rownum<=?"
  } elsif($options->{limit} =~ /\d+,\s?\d+/) {
    $return = "select ".(join ',', @cols)." from (select ".(join ',', @cols,'rownum rn')." from ($return)) where rn>=? and rn<=?"
  }
  return $return;
}

sub records { 
  my ($self, $params, $options) = @_;
  $options->{cols} ||= $self->{cols};
  my $sql = $options->{sql} || $self->_record_sql($options);
  $options->{criteria} = [$options->{criteria} || ()] if(ref $options->{criteria} ne 'ARRAY');
  if($options->{limit} =~ /^(\d+)$/) {
    $params->{limit_end} = $1;
    push @{$options->{criteria}}, 'limit_end'
  } elsif($options->{limit} =~ /(\d+),\s?(\d+)/) {
    $params->{limit_start} = $1;
    $params->{limit_end} = $1 + $2 - 1;
    push @{$options->{criteria}}, 'limit_start', 'limit_end'
  }
  my $return = $self->{dbh}->selectall_arrayref($sql, $self->fixup, map {$params->{$_}} @{$options->{criteria}});
  return @$return ? $return : undef;
}

sub count {
  my ($self, $params, $options) = @_;
  $options->{sql} = "select count(*) from ".($options->{scheme} || $self->{scheme}).".$self->{table}";
  my @crit = !$options->{criteria} ? () : ref $options->{criteria} eq 'ARRAY' ? @{$options->{criteria}} : ($options->{criteria});
  $options->{sql} .= " where ".join(' and ', map {"$_ = ?"} @crit) if(@crit);
  $self->{dbh}->selectrow_array($options->{sql}, undef, map {$params->{$_}} @crit)
}



1;
