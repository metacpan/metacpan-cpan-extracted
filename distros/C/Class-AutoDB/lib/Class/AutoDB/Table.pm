package Class::AutoDB::Table;

use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Class::AutoClass;
use Class::AutoDB::Globals;
use Text::Abbrev;
@ISA = qw(Class::AutoClass); # AutoClass must be first!!

@AUTO_ATTRIBUTES=qw(name _keys index);
@OTHER_ATTRIBUTES=qw(keys);
%DEFAULTS=(keys=>{});
Class::AutoClass::declare(__PACKAGE__);

# NG 09-03-19: commented out _init_self -- stub not needed
# sub _init_self {
#   my($self,$class,$args)=@_;
#   return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
# }
sub keys {
  my $self=shift;
  my $result= @_? $self->_keys($_[0]): $self->_keys;
  wantarray? %$result: $result;
}
my @WHATS=qw(create drop alter);
my %WHATS=abbrev @WHATS;
# TODO: this is re-used in Database.pm.  find a single place for this.
my %TYPES=(string  =>'longtext',
	   integer =>'int',
	   float   =>'double',
	   object  =>'bigint unsigned',);
my @TYPES=keys %TYPES;
my %TYPES_ABBREV=abbrev @TYPES;

my $GLOBALS=Class::AutoDB::Globals->instance();
sub autodb {
  my $self=shift;
  $GLOBALS->autodb(@_);
}
sub dbh {$_[0]->autodb->dbh;}

sub schema {
  my($self,$what)=@_;
  $what or $what='create';
  $what=$WHATS{lc($what)} || $self->throw("Invalid \$what for schema: $what. Should be one of: @WHATS");
  return $self->create if $what eq 'create';
  return $self->drop if $what eq 'drop';
  return $self->alter if $what eq 'alter';
}
# sub create -- implemented in subclasses
# sub alter -- implemented in subclasses
sub drop {
  my($self)=@_;
  my $name=$self->name;
  # NG 10-09-15: added DROP VIEW 
  # my $sql="drop table if exists $name";
  # wantarray? ($sql): [$sql];
  my @sql=(qq(DROP TABLE IF EXISTS $name),qq(DROP VIEW IF EXISTS $name));
  wantarray? @sql: \@sql;
}
# NG 09-12-27: quick hack to let abbreviated types match in CollectionDiff
# TODO: TYPE and type checking duplicated in many modules. fix this!
sub equiv_types {
  my $self_or_class=shift;
  my($type0,$type1)=@_;
  my $list0=$type0=~/^list/;
  my $list1=$type1=~/^list/;
  if ($list0 && $list1) {	  # both are list types. get inner types
    ($type0)=$type0=~/^list\s*\(\s*(.*?)\s*\)/;
    ($type1)=$type1=~/^list\s*\(\s*(.*?)\s*\)/;
  } else {
    return 0 if $list0 || $list1; # only one is list type, so not equiv
  }
  return $TYPES_ABBREV{$type0} eq $TYPES_ABBREV{$type1};
}

1;
