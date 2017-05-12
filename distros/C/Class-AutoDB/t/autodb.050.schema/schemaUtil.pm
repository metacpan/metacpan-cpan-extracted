package schemaUtil;
use t::lib;
use strict;
use List::MoreUtils qw(uniq);
use DBI;
use Test::More;
use Test::Deep;
use autodbUtil;
use Exporter();
our @ISA=qw(Exporter);
our @EXPORT=(@autodbUtil::EXPORT,
	     qw($class2colls $class2transients $coll2keys label %test_args
		correct_tables correct_columns
		alter_class alter_coll alter_class_colls expand_coll
		drop_all
	      ));

# class2colls for all classes in schema tests
our $class2colls=
  {Person=>[qw(Person HasName)],
   Place=>[qw(Place HasName)],
   Thing=>[],
   Expand=>[qw(Person Expand)],
   NewColl=>[qw(NewColl)],
   NewExpand=>[qw(Expand NewColl)],
  };

# coll2keys for all collections in schema tests
our $coll2keys=
  {Person=>[[qw(id name sex)],[qw(friends)]],
   Place=>[[qw(id name country)],[]],
   HasName=>[[qw(id name)],[]],
   Expand=>[[qw(id name)],[]],
   NewColl=>[[qw(id name)],[]],
  };

# class2transients for all collections in schema tests
our $class2transients={};

# label sub for all graph 'TestObject' tests
sub label {
  my $test=shift;
  my $object=$test->current_object;
#  $object->id.' '.$object->name if $object;
  (UNIVERSAL::can($object,'name')? $object->name:
   (UNIVERSAL::can($object,'desc')? $object->desc:
    (UNIVERSAL::can($object,'id')? $object->id: '')));
}

our %test_args=(class2colls=>$class2colls,class2transients=>$class2transients,
		coll2keys=>$coll2keys,label=>\&label);
################################################################################
our($autodb,$dbh);

# return correct tables for a list of classes. adapted from autodbTestObject
sub correct_tables {
  my @classes=@_;
  my @correct_tables=qw(_AutoDB);
  for my $class (@classes) {
    my $colls=$class2colls->{$class};
    for my $coll (@$colls) {
      my $pair=$coll2keys->{$coll};
      my @tables=($coll,map {$coll.'_'.$_} @{$pair->[1]});
      push(@correct_tables,@tables);
    }
  }
  @correct_tables=uniq(@correct_tables);
  wantarray? @correct_tables: \@correct_tables;
}
# return correct columns for a list of classes. adapted from autodbTestObject
# result is hash of table=>[columns]
sub correct_columns {
  my @classes=@_;
  my %correct_columns=(_AutoDB=>[qw(oid object)]);
  for my $class (@classes) {
    my $colls=$class2colls->{$class};
    for my $coll (@$colls) {
      my $pair=$coll2keys->{$coll};
      $correct_columns{$coll}=['oid',@{$pair->[0]}]; # base keys
      map {$correct_columns{$coll.'_'.$_}=['oid',$_]} @{$pair->[1]};
    }}
  wantarray? %correct_columns: \%correct_columns;
}

# change class2colls for class
sub alter_class {
  my($class,$new_colls)=@_;
  $class2colls->{$class}=$new_colls;
}
# change coll2keys for collection
sub alter_coll {
  my($coll,$new_keylists)=@_;
  $coll2keys->{$coll}=$new_keylists;
}
# expand coll2keys for collection
sub expand_coll {
  my($coll,$expand_basekeys,$expand_listkeys)=@_;
  my($basekeys,$listkeys)=@{$coll2keys->{$coll}};
  push(@$basekeys,@$expand_basekeys) if $expand_basekeys;
  push(@$listkeys,@$expand_listkeys) if $expand_listkeys;
}
# change class2colls, coll2keys for class
sub alter_class_colls {
  my($class,$new_colls,$new_coll2keys)=@_;
  $class2colls->{$class}=$new_colls;
  while(my($coll,$keylists)=each %$new_coll2keys) {
    $coll2keys->{$coll}=$keylists;
  }
}
# drop all tables to start clean
sub drop_all {
  my $label=@_? shift: 'drop all';
  my $tables=dbh->selectcol_arrayref(qq(SHOW TABLES)); #  return ARRAY ref of table names
  # NG 10-09-15: added DROP VIEW. changed SQL syntax to do all tables in one go
  # my @sql=map {qq(DROP TABLE IF EXISTS $_)} @$tables;
  $tables=join(',',@$tables);
  my @sql=(qq(DROP TABLE IF EXISTS $tables),qq(DROP VIEW IF EXISTS $tables));
  do_sql(@sql);
  # make sure it worked
  my($package,$file,$line)=caller; # for fails
  _ok_dbtables([],$label,$file,$line);
} 

sub do_sql {
  for my $sql (@_) {
    dbh->do($sql);
  }}

1;
