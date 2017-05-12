package Class::AutoDB::Collection;

use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS);
use strict;
use Class::AutoClass;
use Class::AutoDB::Table;
use Class::AutoDB::BaseTable;
use Class::AutoDB::ListTable;
@ISA = qw(Class::AutoClass); # AutoClass must be first!!

BEGIN {
  @AUTO_ATTRIBUTES=qw(name
		      _keys _tables _cmp_data);
  @OTHER_ATTRIBUTES=qw(keys register);
  %SYNONYMS=();
  Class::AutoClass::declare(__PACKAGE__);
}
# NG 09-03-19: commented out _init_self -- stub not needed
# sub _init_self {
#   my($self,$class,$args)=@_;
#   return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
# }
sub register {
  my($self,$new_keys)=@_;
  my $keys=$self->keys or $self->keys({});
  while(my($key,$type)=each %$new_keys) {
    $type=lc $type;
    $keys->{$key}=$type, next unless defined $keys->{$key};
    $self->throw("Inconsistent registrations for search key $key: types are ".$keys->{$key}." and $type") unless $keys->{$key} eq $type;
  }
  $self->_keys($keys);
  $self->_tables(undef);	# clear computed value so it'll be recomputed next time 
}
sub keys {
  my $self=shift;
  my $result= @_? $self->_keys($_[0]): $self->_keys;
  $result or $result={};
  wantarray? %$result: $result;
}
sub merge {
  my($self,$diff)=@_;
  my $keys=$self->keys || {};
  my $new_keys=$diff->new_keys;
  @$keys{keys %$new_keys}=values %$new_keys;
  $self->keys($keys);
  $self->_tables(undef);	# clear computed value so it'll be recomputed next time 
}
sub put {
  my($self,$object)=@_;
  # instantiate values of search keys
  my %key_values;
  my %keys=$self->keys;
  while(my($key,$type)=each %keys) {
    my $method=UNIVERSAL::can($object,$key);
    next unless $method;
    my $value=$object->$method;
    if ($type eq 'object' && defined $value) {
      # NG 09-12-19: $value->oid crashes on nonpersistent things. 
      #              change also needed for cleanup of user-object namespace
      # $value=$value->oid;
      $value=Class::AutoDB::Serialize::obj2oid($value)
    } elsif ($type eq 'list(object)' && defined $value) {
      # NG 05-08-22: $value points to the list in the _REAL_ object
      #   Orginal code clobbered this list
      #   Fixed code creates new empty list and copies oids there
      my $oids=[];
      # NG 09-12-19: $_->oid crashes on nonpersistent things. 
      #              change also needed for cleanup of user-object namespace
      # @$oids=map {$_->oid} @$value;
      @$oids=map {Class::AutoDB::Serialize::obj2oid($_)} @$value;
      $value=$oids;
    }
    $key_values{$key}=$value;
  }
  # generate SQL to store object in each table
  # NG 09-12-19: $object->oid. crashes on nonpersistent things. 
  #              change also needed for cleanup of user-object namespace
  # my $oid=$object->oid;
  my $oid=Class::AutoDB::Serialize::obj2oid($object);
  my @sql=map {$_->put($oid,\%key_values)} $self->tables;
  wantarray? @sql: \@sql;
}
# NG 10-09-06: added 'del' method
sub del {
  my($self,$object)=@_;
  # generate SQL to delete object from each table
  my $oid=Class::AutoDB::Serialize::obj2oid($object);
  my @sql=map {$_->del($oid)} $self->tables;
  wantarray? @sql: \@sql;
}
sub create {
  my($self,$index_flag)=@_;
  my @sql=map {$_->drop} $self->tables;	# drop tables if they exist
  push(@sql,map {$_->index($index_flag); $_->create} $self->tables);
  wantarray? @sql: \@sql;
}
sub drop {
  my($self)=@_;
  my @sql=map {$_->drop} $self->tables;
  wantarray? @sql: \@sql;
}
 
sub alter {
  my($self,$diff)=@_;
  my @sql;
  my $new_keys=$diff->new_keys;
  my $name=$self->name;
  # Split new keys to be added into scalar vs. list
  my($scalar_keys,$list_keys);
  while(my($key,$type)=each %$new_keys) {
    _is_list_type($type)? $list_keys->{$key}=$type: $scalar_keys->{$key}=$type;
  }
  # New scalar keys have to be added to base table
  # Create a Table object to hold these new keys.
  # Just for programming convenience -- this is not a real table
  my $base_table=new Class::AutoDB::BaseTable (-name=>$name,-keys=>$scalar_keys);
  push(@sql,$base_table->schema('alter'));
  # New list keys have to generate new tables
  while(my($key,$type)=each %$list_keys) {
    my($inner_type)=$type=~/^list\s*\(\s*(.*?)\s*\)/;
    my $list_table=new Class::AutoDB::ListTable (-name=>$name.'_'.$key,
						-keys=>{$key=>$inner_type});
    push(@sql,$list_table->drop);   # drop table if exists
    push(@sql,$list_table->create); # create table
  }
  $self->_tables(undef);	# clear computed value so it'll be recomputed next time 
  wantarray? @sql: \@sql;
}
sub tables {
  my $self=shift;
  return $self->_tables(@_) if @_;
  unless (defined $self->_tables) {
    my $name=$self->name;
    # Collection has one 'base' table for scalar keys and one 'list' table per list key
    #
    # Start by splitting keys into scalar vs. list
    my $keys=$self->keys;
    my($scalar_keys,$list_keys)=({},{});
    while(my($key,$type)=each %$keys) {
      _is_list_type($type)? $list_keys->{$key}=$type: $scalar_keys->{$key}=$type;
    }
    my $base_table=new Class::AutoDB::BaseTable(-name=>$name,-keys=>$scalar_keys);
    my $tables=[$base_table];
    while(my($key,$type)=each %$list_keys) {
      my($inner_type)=$type=~/^list\s*\(\s*(.*?)\s*\)/;
      my $list_table=new Class::AutoDB::ListTable (-name=>$name.'_'.$key,
						  -keys=>{$key=>$inner_type});
      push(@$tables,$list_table);
    }
    $self->_tables($tables);
  }
  wantarray? @{$self->_tables}: $self->_tables;
}
sub tidy {
  my $self=shift;
  $self->_tables(undef);
}

sub _is_list_type {$_[0]=~/^list\s*\(/;}
sub _flatten {map {'ARRAY' eq ref $_? @$_: $_} @_;}
  
1;
