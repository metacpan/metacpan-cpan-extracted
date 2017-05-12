package JAF::DBI;

use strict;
use DBI ();
use Data::Dumper 'Dumper';

sub new {
  my ($class, $self) = @_;
  return undef unless $self->{parent};
  bless $self, $class;
  $self->_init();
  return $self;
}

sub _init {
  my $self = shift;

  $self->{insert_message} = "Record's inserted";
  $self->{update_message} = "Record's updated";
  $self->{delete_message} = "Record's deleted";
}

sub error { shift()->{parent}->error(@_) }
sub message { shift()->{parent}->message(@_) }

sub fixup { { Columns => {} } }

sub _insert_sql {
  my ($self, $options) = @_;
  
  my $cols = $options->{cols} || $self->{cols};
  
  return "insert into $self->{table} (".(join ',', @{$cols}).") values (".(join ',', map {'?'} @{$cols}).")";
}

sub insert { 
  my ($self, $params, $options) = @_;
  
  my @cols = $options && $options->{cols} ? @{$options->{cols}} : @{$self->{cols}};
  @cols = grep {exists $params->{$_}} @cols;
  my $sql = $options->{sql} || $self->_insert_sql({%$options, cols => \@cols});

  if ($options->{debug}) {
    warn Dumper { sql => $sql, params => $params, options => $options };
  }

  my $return = $self->{dbh}->do($sql, undef, map {$params->{$_}} @cols);
  $return ? $self->message(defined $options->{message} ? $options->{message} : $self->{insert_message}) : $self->error($self->{dbh}->errstr());
  return $return;
}

sub _update_sql {
  my ($self, $options) = @_;
  
  my $cols = $options->{cols} || $self->{cols};
  my $criteria = $options->{criteria} || $self->{key};
  
  return "update $self->{table} set ".(join ',', map {"$_ = ?"} @$cols)." where ".(ref $criteria eq 'ARRAY' ? join ' and ', map {"$_ = ?"} @$criteria : "$criteria = ?");
}

sub update { 
  my ($self, $params, $options) = @_;
  
  $options->{criteria} ||= $self->{key};

  my @cols = $options && $options->{cols} ? @{$options->{cols}} : @{$self->{cols}};
  @cols = grep {exists $params->{$_} && (!ref $self->{key} || $self->{key} ne $_)} @cols;
  my $sql = $options->{sql} || $self->_update_sql({%$options, cols => \@cols});

  my $return = $self->{dbh}->do($sql, undef, (map {$params->{$_}} @cols), ref ($options->{criteria}) eq 'ARRAY' ? map {$params->{$_}} @{$options->{criteria}} : $params->{$options->{criteria}});
  $return ? $self->message(defined $options->{message} ? $options->{message} : $self->{update_message}) : $self->error($self->{dbh}->errstr());
  return $return;
}

sub _delete_sql {
  my ($self, $options) = @_;
  
  my $criteria = $options->{criteria} || $self->{key};
  
  return "delete from $self->{table} where ".(ref $criteria eq 'ARRAY' ? join ' and ', map {"$_ = ?"} @$criteria : "$criteria = ?");
}

sub delete { 
  my ($self, $params, $options) = @_;

  $options->{criteria} ||= $self->{key};
  my $sql = $options->{sql} || $self->_delete_sql($options);

  if ($options->{debug}) {
    warn Dumper { sql => $sql, params => $params, options => $options };
  }

  my $return = $self->{dbh}->do($sql, undef, ref ($options->{criteria}) eq 'ARRAY' ? map {$params->{$_}} @{$options->{criteria}} : $params->{$options->{criteria}});
  $return ? $self->message(defined $options->{message} ? $options->{message} : $self->{delete_message}) : $self->error($self->{dbh}->errstr());
  return $return;
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
  $return .= " limit $options->{limit}" if $options->{limit};
  return $return;
}

sub record { 
  my ($self, $params, $options) = @_;

  $options->{cols} ||= $self->{cols};
  $options->{criteria} ||= $self->{key};
  my $sql = $options->{sql} || $self->_record_sql($options);

  $self->{dbh}->selectrow_hashref($sql, undef, ref ($options->{criteria}) eq 'ARRAY' ? map {$params->{$_}} @{$options->{criteria}} : $params->{$options->{criteria}});
}

sub records { 
  my ($self, $params, $options) = @_;

  $options->{cols} ||= $self->{cols};
  my $sql = $options->{sql} || $self->_record_sql($options);

  my $return = $self->{dbh}->selectall_arrayref($sql, $self->fixup, exists $options->{criteria} ? ref ($options->{criteria}) eq 'ARRAY' ? map {$params->{$_}} @{$options->{criteria}} : $params->{$options->{criteria}} : ());

  return @$return ? $return : undef;
}

sub count {
  my ($self, $params, $options) = @_;
  $options->{sql} = "select count(*) from $self->{table}";
  my @crit = !$options->{criteria} ? () : ref $options->{criteria} eq 'ARRAY' ? @{$options->{criteria}} : ($options->{criteria});
  $options->{sql} .= " where ".join(' and ', map {"$_ = ?"} @crit) if(@crit);
  $self->{dbh}->selectrow_array($options->{sql}, undef, map {$params->{$_}} @crit)
}

1;
