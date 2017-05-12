package Class::AutoDB::BaseTable;

use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Class::AutoClass;
use Text::Abbrev;
use Class::AutoDB::Table;
@ISA = qw(Class::AutoDB::Table);

@AUTO_ATTRIBUTES=qw();
@OTHER_ATTRIBUTES=qw();
Class::AutoClass::declare(__PACKAGE__);

# NG 09-03-19: commented out _init_self -- stub not needed
# sub _init_self {
#   my($self,$class,$args)=@_;
#   return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
# }
# TODO: this is re-used in Database.pm.  find a single place for this.
# TODO: this is re-used in Table.pm.  Reimplement as method
my %TYPES=(string  =>'longtext',
	   integer =>'int',
	   float   =>'double',
	   object  =>'bigint unsigned',);
my @TYPES=keys %TYPES;
my %TYPES_ABBREV=abbrev @TYPES;

sub put {
  my($self,$oid,$key_values)=@_;
  my %keys=$self->keys;
  my $dbh=$self->dbh;
  my $name=$self->name;
  my @columns=('oid');
  my @values=($oid);
  while(my($key,$type)=each %keys) {
    my $value=$key_values->{$key};
    # NG 09-12-17: line below causes 0's to be stored as NULLs. breaks queries
    #              selecting on 0. scary this wasn't caught earlier!
    # next unless $value;
    push(@columns,$key);
    push(@values,$dbh->quote($value,$TYPES{$type}));
  }
  my $columns='('.join(',',@columns).')';
  my $values='values('. join(',',@values).')';
  my $sql="REPLACE $name $columns $values";
  wantarray? ($sql): [$sql];
}
# NG 10-09-06: added 'del' method
sub del {
  my($self,$oid)=@_;
  my $dbh=$self->dbh;
  my $name=$self->name;
  my $sql="DELETE FROM $name WHERE oid=$oid";
  wantarray? ($sql): [$sql];
}
sub create {
  my($self)=@_;
  my $name=$self->name;
  my $keys=$self->keys;
  my $index = defined $self->index ? $self->index : 1; # indexing is default
  my @columns=('oid bigint unsigned not null, primary key (oid)');
  while(my($key,$type)=each %$keys) {
    my $sql_type=$TYPES{$TYPES_ABBREV{$type}} or
      $self->throw("Invalid data type for key $key: $type. Should be one of: ".join(' ',@TYPES));
    if($index) {
      $index=$sql_type ne 'longtext'? "index($key)": "index($key(255))";
      push(@columns,"$key $sql_type,$index");     
    } else {
      push(@columns,"$key $sql_type");
    }
  }
  my $sql=@columns? "create table $name \(".join(',',@columns)."\)": '';
  wantarray? ($sql): [$sql];
}
sub alter {
  my($self)=@_;
  my $name=$self->name;
  my $keys=$self->keys;
  my $index = defined $self->index ? $self->index : 1; # indexing is default
  my @columns;
  while(my($key,$type)=each %$keys) {
    my $sql_type=$TYPES{$TYPES_ABBREV{$type}} or
      $self->throw("Invalid data type for key $key: $type. Should be one of: ".join(' ',@TYPES));
    if($index) {
      $index=$sql_type ne 'longtext'? "index($key)": "index($key(255))";
      push(@columns,"add $key $sql_type,add $index");     
    } else {
      push(@columns,"add $key $sql_type");
    }
  }
  my $sql=@columns? "alter table $name ".join(',',@columns): '';
  wantarray? ($sql): [$sql];
}

1;
