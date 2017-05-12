package Class::AutoDB::Cursor;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use DBI;
use Class::AutoClass;
# use Hash::AutoHash::Args;
@ISA = qw(Class::AutoClass);

# Cursor for AutoDB queries

@AUTO_ATTRIBUTES=qw(query dbh select_sth count_sth is_started object_table);
@OTHER_ATTRIBUTES=qw();
%SYNONYMS=();
%DEFAULTS=(object_table=>'_AutoDB',is_started=>0);
Class::AutoClass::declare(__PACKAGE__);

# NG 09-03-19: commented out _init_self -- stub not needed
# sub _init_self {
#   my($self,$class,$args)=@_;
#   return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
# }
sub get {
  my($self,$n)=@_;
  $self->reset unless $self->is_started;
  my($dbh,$sth)=($self->dbh,$self->select_sth);
  my $rows=$sth->fetchall_arrayref(undef,$n) || 
    $self->throw("Database error in fetch for query\n".$self->select_sql."\n".$dbh->errstr);
  my @objects;
  for my $row (@$rows) {
    my($oid,$freeze)=@$row;
    my $object=Class::AutoDB::Serialize::thaw($oid,$freeze);
    # NG 10-09-13: skip deleted objects
    next if 'Class::AutoDB::OidDeleted' eq ref $object;
    push(@objects,$object);
  }
  wantarray? @objects: \@objects;
}
#*get_all=\&get;

sub get_next {
  my($self)=@_;
  $self->reset unless $self->is_started;
  my($dbh,$sth)=($self->dbh,$self->select_sth);
  return undef unless $sth && $sth->{Active};
  # NG 10-09-13: added outer loop to skip deleted objects
  while(1) {
    my($oid,$freeze)=$sth->fetchrow_array;
    # NG 10-09-13: changed test to support deleted objects ($freeze undef)
    # if (!$freeze) {		# either end of results or error
    if (!defined $oid) {		# either end of results or error
      return undef unless $dbh->err;	# end of results
      $self->throw("Database error in fetch for query\n".$self->select_sql."\n".$dbh->errstr);
    } else {
      my $object=Class::AutoDB::Serialize::thaw($oid,$freeze);
      # NG 10-09-13: skip deleted objects
      return $object unless 'Class::AutoDB::OidDeleted' eq ref $object;
    }
  }
}
sub count {
  my($self)=@_;
  my($sql,$dbh,$sth)=($self->count_sql,$self->dbh,$self->count_sth);
  if ($sql && $dbh && !$sth) {
    $sth=$dbh->prepare($sql) || 
      $self->throw("Database error in prepare for query\n$sql\n".$dbh->errstr);
    $sth->execute || $self->throw("Database error in exectue for query\n$sql\n".$dbh->errstr);
    $self->count_sth($sth);
  } elsif ($sql && $sth) {
    $sth->execute || $self->throw("Database error in exectue for query\n$sql\n".$dbh->errstr);
  }
  # NG 09-12-14: was throwing error when count==0! scary this wasn't caught sooner
  #  my($count)=$sth->fetchrow_array || 
  #    $self->throw("Database error in fetch for query\n$sql\n".$dbh->errstr);
  my($count)=$sth->fetchrow_array || 
    ($dbh->err && $self->throw("Database error in fetch for query\n$sql\n".$dbh->errstr));
  $count || 0;
}
sub select_sql {
  my($self)=@_;
  my($object_table,$query)=($self->object_table,$self->query);
  my $sql="SELECT $object_table.oid,$object_table.object $query";
  $sql;
}
sub count_sql {
  my($self)=@_;
  my($object_table,$query)=($self->object_table,$self->query);
  my $sql="SELECT COUNT($object_table.oid) $query";
  $sql;
}
sub reset {
  my($self)=@_;
  my($sql,$dbh,$sth)=($self->select_sql,$self->dbh,$self->select_sth);
  if ($sql && $dbh && !$sth) {
    $sth=$dbh->prepare($sql) || 
      $self->throw("Database error in prepare for query\n$sql\n".$dbh->errstr);
    $sth->execute || $self->throw("Database error in exectue for query\n$sql\n".$dbh->errstr);
    $self->select_sth($sth);
  } elsif ($sql && $sth) {
    $sth->execute || $self->throw("Database error in exectue for query\n$sql\n".$dbh->errstr);
  }
  $self->is_started(1);
}

# TODO: decide on has_more -- requires a look ahead buffer -- not a big deal, but do we need it?

# TODO: implement find - conjoins existing SQL with new query
sub find {
}
sub do_sql {
  my $self=shift;
  my @sql=_flatten(@_);
  $self->throw("Cannot run SQL unless connected") unless $self->is_connected;
  my $dbh=$self->dbh;
  for my $sql (@sql) {
    next unless $sql;
    $dbh->do($sql);
    $self->throw("SQL error: ".$dbh->errstr) if $dbh->err;
  }
}
sub _flatten {map {'ARRAY' eq ref $_? @$_: $_} @_;}

1;
