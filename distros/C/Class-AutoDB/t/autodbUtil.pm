package autodbUtil;
# use t::lib;
use strict;
use Carp;
use FindBin;
# sigh. Test::Deep exports reftype, blessed (and much more) so don't import from Scalar::Util
# use Scalar::Util qw(looks_like_number reftype blessed);
use Scalar::Util qw(looks_like_number refaddr);
use List::Util qw(min max);
use List::MoreUtils qw(uniq);
use Data::Rmap ();
use Storable qw(dclone);
use File::Basename qw(fileparse);
use File::Spec;
use Cwd qw(cwd);
use DBI;
use Fcntl;   # For O_RDWR, O_CREAT, etc.
use SDBM_File;
use Test::More;
# Test::Deep doesn't export cmp_details, deep_diag until recent version (0.104)
# so we import them "by hand"
use Test::Deep;
*cmp_details=\&Test::Deep::cmp_details;
*deep_diag=\&Test::Deep::deep_diag;
use TAP::Harness;
# use TAP::Formatter::Console; 
use TAP::Parser::Aggregator;
use Hash::AutoHash::Args;
use Exporter();

our @ISA=qw(Exporter);
our @EXPORT=qw(group groupmap gentle_uniq
	       create_autodb_table autodb dbh testdb $MYSQL_dir $SDBM_dir
	       oid2obj obj2oid all_objects
	       tie_oid %oid %oid2id %id2oid %obj2oid %oid2obj
	       id id_restore id_next next_id
	       reach reach_fetch reach_mark
	       ok_dbtables _ok_dbtables ok_dbcolumns _ok_dbcolumns
	       ok_basetable ok_listtable ok_collection ok_collections
	       _ok_basetable _ok_listtable _ok_collection _ok_collections
	       ok_oldoid ok_oldoids ok_newoid ok_newoids ok_deloid ok_deloids
	       _ok_oldoid _ok_newoid _ok_deloid
	       ok_objcache conjure_oid
	       cmp_thawed _cmp_thawed cmp_details
	       remember_oids
	       test_single 
	       actual_tables actual_counts norm_counts actual_columns
	       report report_pass report_fail called_from
	     );
# TODO: rewrite w/ Hash::AutoHash::MultiValued
# group a list by categories returned by sub.
# has to be declared before use, because of prototype
sub group (&@) {
  my($sub,@list)=@_;
  my %groups;
  for (@list) {
    my $group=&$sub($_);
    my $members=$groups{$group} || ($groups{$group}=[]);
    push(@$members,$_);
  }
  wantarray? %groups: \%groups;
}
# like group, but processes elements that are put on list. 
# sub should return 2 element list: 1st defines group, 2nd maps the value
# has to be declared before use, because of prototype
sub groupmap (&@) {
  my($sub,@list)=@_;
  my %groups;
  for (@list) {
    my($group,$value)=&$sub($_);
    my $members=$groups{$group} || ($groups{$group}=[]);
    push(@$members,$value);
  }
  wantarray? %groups: \%groups;
}
# uniq-ify a list gently, so Oids not fetched.
sub gentle_uniq {
  my(%seen,@uniq);
  for (@_) {
    my $key=ref($_)? refaddr($_): $_;
    push(@uniq,$_) unless $seen{$key};
    $seen{$key}++;
  }
  @uniq;
}

# used in serialize_ok tests. someday in Developer/Serialize tests
sub create_autodb_table {
  my $dbh=DBI->connect("dbi:mysql:database=".testdb(),undef,undef,
		       {AutoCommit=>1, ChopBlanks=>1, PrintError=>0, PrintWarn=>0, Warn=>0,})
    or return $DBI::errstr;
  $dbh->do(qq(DROP TABLE IF EXISTS _AutoDB)) or return $dbh->errstr;
  $dbh->do(qq(CREATE TABLE IF NOT EXISTS
                _AutoDB(oid BIGINT UNSIGNED NOT NULL,
                        object LONGBLOB,
                        PRIMARY KEY (oid))))
      or return $dbh->errstr;
  undef;
}
sub autodb {$Class::AutoDB::GLOBALS->autodb}
sub oid2obj {Class::AutoDB::Serialize->oid2obj(@_)}
sub obj2oid {Class::AutoDB::Serialize->obj2oid(@_)}
sub all_objects {values %{Class::AutoDB::Globals->instance()->oid2obj}}

# NG 13-10-31: testdb created in 000.reqs and name stored in t/testdb
our $testdb;
sub testdb {
  unless($testdb) {
    my $file=File::Spec->catfile(qw(t testdb));
    open(TESTDB,"< $file") or do {
      my $diag=<<DIAG
BAD NEWS: Unable to open file $file which contains test database name: $!
Tests cannot proceed
DIAG
      ;
      BAIL_OUT($diag);
    };
    $testdb=<TESTDB>;
    chomp $testdb;
    close TESTDB;
  }
  $testdb
}
# CAUTION: $SDBM_dir. $MYSQL_dir duplicated in Build.PL
our $SDBM_dir=File::Spec->catdir(cwd(),qw(t SDBM));
our $MYSQL_dir=File::Spec->catdir(cwd(),qw(t MYSQL));
sub dbh {my $autodb=autodb; $autodb? $autodb->dbh: _dbh()}
our $MYSQL_dbh;

# NG 13-10-23: changed connect to use $ENV{USER} instead of undef. should be equivalent, but...
sub _dbh {
  $MYSQL_dbh or do {
    my $testdb=testdb;
    $MYSQL_dbh=DBI->connect
    ("dbi:mysql:database=$testdb",$ENV{USER},undef,
     {AutoCommit=>1, ChopBlanks=>1, PrintError=>0, PrintWarn=>0, Warn=>0,});
  };
}
# hashes below are exported.
# %oid,%oid2id,%id2oid are persistent and refer to db objects
# %obj2oid,%oid2obj are non-persistent and refer to in-memory objects
our(%oid,%oid2id,%id2oid,%obj2oid,%oid2obj);

our $SDBM_errstr;
sub _tie_sdbm (\%$;$) {		# eg, tie_sdbm(%oid,'oid','create')
  my($hash,$filebase,$create)=@_;
  return undef if !$create && tied %$hash; # short circuit if already tied
  my $file=File::Spec->catfile($SDBM_dir,$filebase);
  my $flags=$create? (O_TRUNC|O_CREAT|O_RDWR): O_RDWR;
  my $tie=tie(%$hash, 'SDBM_File', $file, $flags, 0666);
  $SDBM_errstr=$tie? undef:('Cannot '.($create? 'create': 'open')." SDBM file $file: $!");
}
sub tie_oid {
  my $create=shift;
  _tie_sdbm(%oid,'oid',$create) and confess $SDBM_errstr;
  _tie_sdbm(%oid2id,'oid2id',$create) and confess $SDBM_errstr;
  _tie_sdbm(%id2oid,'id2oid',$create) and confess $SDBM_errstr;
  undef;
}

our $ID;
use File::Spec::Functions qw(splitdir abs2rel);
sub init_id {
  $ID=0;
  for (splitdir(abs2rel($0))) {
    $ID=1000*$ID+(/\.(\d+)\./)[0];
  }
  $ID*=1000;
}
sub id {defined $ID? $ID: ($ID=init_id)}
sub id_restore {tie_oid(); $ID=1+max(keys %id2oid)}
sub id_next {my $id=id(); $ID++; $id} # like $id++
sub next_id {my $id=id(); ++$ID}	    # like ++$id

# return objects reachable from one or more starting points.
# adapted from Data::Rmap docs
sub reach {
  my @reach=uniq(Data::Rmap::rmap_ref {Scalar::Util::blessed($_) ? $_ : ();} @_);
  wantarray? @reach: \@reach;
}
# fetch objects reachable from one or more starting points. 
# uses stringify ("$_") to do the work
# adapted from Data::Rmap docs
sub reach_fetch {
  my @reach=uniq(Data::Rmap::rmap_ref {"$_" if UNIVERSAL::isa($_,'Class::AutoDB::Oid'); $_;} @_);
  wantarray? @reach: \@reach;
}

# mark objects reachable from a starting point w/ traversal order. result contains no duplicates
# copies the structure and returns the copy, 
# since it modifies the objects it encounters -- that's the whole point!!
our $MARK;
sub reach_mark {
  my $start=[@_];
  my $copy=dclone($start);
  $MARK=0;
  _reach_mark($copy);
  wantarray? @$copy: $copy;
}
# sub reach_mark {
#   my $start=shift;
#   my $copy=dclone($start);
#   $MARK=0;
#   _reach_mark($copy);
#   $copy;
# }
sub _reach_mark {
  my $start=shift;
  Data::Rmap::rmap_ref 
      {
	if (Scalar::Util::blessed($_) && 'HASH' eq Scalar::Util::reftype($_)) {
	  $_->{__MARK__}=$MARK++ unless exists $_->{__MARK__};
	}
        return $_} $start;
}
# check tables that exist in database
sub ok_dbtables {
  my($tables,$label)=@_;
  my($package,$file,$line)=caller; # for fails
  my $ok=_ok_dbtables($tables,$label,$file,$line);
  report_pass($ok,$label);
}
sub _ok_dbtables {
  my($correct,$label,$file,$line)=@_;
  my $actual=dbh->selectcol_arrayref(qq(SHOW TABLES)) || [];
  my($ok,$details)=cmp_details($actual,set(@$correct));
  report_fail($ok,$label,$file,$line,$details);
}
# check columns that exist in database. $table2columns is HASH of column=>[columns]
sub ok_dbcolumns {
  my($table2columns,$label)=@_;
  my($package,$file,$line)=caller; # for fails
  my $ok=_ok_dbcolumns($table2columns,$label,$file,$line);
  report_pass($ok,$label);
}
sub _ok_dbcolumns {
  my($table2columns,$label,$file,$line)=@_;
  my($ok,$details);
  while(my($table,$correct)=each %$table2columns) {
    my $actual=actual_columns($table);
    my($ok,$details)=cmp_details($actual,set(@$correct));
    report_fail($ok,$label,$file,$line,$details) or return 0;
  }
  return 1;
}
# check object's row in base table
sub ok_basetable {
  my($object,$label,$table,@keys)=@_;
  my($package,$file,$line)=caller; # for fails
  my $ok=_ok_basetable($object,$label,$table,$file,$line,@keys);
  report_pass($ok,$label);
}
sub _ok_basetable {
  my($object,$label,$table,$file,$line,@keys)=@_;
  my $oid=autodb->oid($object);
  my($actual,$correct);
  if (@keys) {
    my $keys=join(', ',@keys);
    # expect one row. result will be ARRAY of ARRAY of columns
    $actual=dbh->selectall_arrayref(qq(SELECT $keys FROM $table WHERE oid=$oid));
    # remember to convert objects to oid in $correct
    #  my $correct=[[$object->get(@keys)]];
    # my $correct=[[map {ref($_) && UNIVERSAL::isa($_,'Class::AutoDB::Object')? autodb->oid($_): $_}
    $correct=[[map {autodb->oid($_) || $_} $object->get(@keys)]];
  } else {			# empty collection, so just make sure oid is present
    ($actual)=dbh->selectrow_array(qq(SELECT COUNT(oid) FROM $table WHERE oid=$oid));
    $correct=1;
  }
  my($ok,$details)=cmp_details($actual,$correct);
  report_fail($ok,$label,$file,$line,$details);
}
# check object's rows in list table
sub ok_listtable {
  my($object,$label,$basetable,$listkey)=@_;
  my($package,$file,$line)=caller; # for fails
  my $ok=_ok_listtable($object,$label,$basetable,$file,$line,$listkey);
  report_pass($ok,$label);
}
sub _ok_listtable {
  my($object,$label,$basetable,$file,$line,$listkey)=@_;
  my $oid=autodb->oid($object);
  my $table=$basetable.'_'.$listkey;
  # expect 0 or more rows. result will be ARRAY of values
  my $actual=dbh->selectcol_arrayref(qq(SELECT $listkey FROM $table WHERE oid=$oid));
  # remember NOT to convert non-objects to oids in @correct
  # my @correct=map {autodb->oid($_)} @{$object->$listkey};
  # my @correct=map {ref($_) && UNIVERSAL::isa($_,'Class::AutoDB::Object')? autodb->oid($_): $_}
  my @correct=map {autodb->oid($_) || $_} @{$object->$listkey || []};
  my($ok,$details)=cmp_details($actual,bag(@correct));
  report_fail($ok,$label,$file,$line,$details);
}

# check object in collection
sub ok_collection {
  my($object,$label,$base,$basekeys,$listkeys)=@_;
  my($package,$file,$line)=caller; # for fails
  my $ok=_ok_collection($object,$label,$base,$basekeys,$listkeys,$file,$line);
  report_pass($ok,$label);
}
# check multiple objects in multiple collections
# $colls is HASH of collection=>[[basekeys],[listkeys]]
sub ok_collections {
  my($objects,$label,$colls)=@_;
  my($package,$file,$line)=caller; # for fails
  my $ok=1;
  for(my $i=0; $i<@$objects; $i++) {
    my $object=$objects->[$i];
    while(my($coll,$keylists)=each %$colls) {
      my($basekeys,$listkeys)=@$keylists;
      $ok&&=_ok_collection($object,"$label: object $i $coll",
			   $coll,$basekeys,$listkeys,$file,$line);
    }
  }
  report_pass($ok,$label);
}
sub _ok_collection {
  my($object,$label,$base,$basekeys,$listkeys,$file,$line)=@_;
  _ok_basetable($object,"$label: base table",$base,$file,$line,@$basekeys) or return 0;
  for my $listkey (@$listkeys) {
    _ok_listtable($object,"$label: $listkey list table",$base,$file,$line,$listkey) or return 0;
  }
  1;
}

# check that object's oid looks okay and is old
# @tables no longer used since loop that checks oids vs. tables commented out
sub ok_oldoid {
  my($object,$label)=@_;
  my($package,$file,$line)=caller; # for fails
  my $ok=_ok_oldoid($object,$label,$file,$line);
  report_pass($ok,$label);
}
# check that objects' oids look okay and are old
# @tables no longer used since loop that checks oids vs. tables commented out
sub ok_oldoids {
  my($objects,$label)=@_;
  my($package,$file,$line)=caller; # for fails
  my $ok=1;
  for(my $i=0; $i<@$objects; $i++) {
    $ok&&=_ok_oldoid($objects->[$i],"$label object $i",$file,$line);
  }
  report_pass($ok,$label);
}
# @tables no longer used since loop that checks oids vs. tables commented out
sub _ok_oldoid {
  my($obj,$label,$file,$line)=@_;
  tie_oid;
  my $oid=autodb->oid($obj);
  report_fail($oid>1,"$label: oid looks good",$file,$line) or return 0;
  # first check in-memory state maintained by test
  report_fail(exists $oid2obj{$oid}? $oid2obj{$oid}==$obj: 1,
	      "$label: oid-to-object unique",$file,$line) or return 0;
  report_fail(exists $obj2oid{refaddr $obj}? $obj2oid{refaddr $obj}==$oid: 1,
	      "$label: object-to-oid unique",$file,$line) or return 0;
  # update in-memory state maintained by test
  $oid2obj{$oid}=$obj;
  $obj2oid{refaddr $obj}=$oid;
  # next check real object cache (similar to ok_objcache)
  report_fail(oid2obj($oid)==$obj,"$label: cache entry for oid $oid",$file,$line) or return 0;
  # NG 10-09-10: test below fails when putting deleted objects.  d'oh...
  # NG 10-09-11: changed calling program so uncommented test below
  report_fail
    (ref $obj ne 'Class::AutoDB::OidDeleted',
     "$label: ref for oid $oid looks extant (not OidDeleted)",$file,$line) or return 0;
  # third check against database maintained by test
  report_fail($oid{$oid},"$label: in oid SDBM file",$file,$line) or return 0;
  if (UNIVERSAL::can($obj,'id')) {
    my $id=$obj->id;
    report_fail($oid2id{$oid}==$id,"$label: in oid2id SDBM file",$file,$line) or return 0;
    report_fail($id2oid{$id}==$oid,"$label: in id2oid SDBM file",$file,$line) or return 0;
  }
  # last but not least check against real database 
  #   just _AutoDB here. collections tested in ok_collections
  # NG 10-09-09: added NOT NULL to support deleted objects
  my($count)=dbh->selectrow_array
    (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid=$oid AND object IS NOT NULL));
  report_fail($count==1,"$label: $oid has count $count in _AutoDB table",$file,$line) or return 0;
}

# check that object's oid looks okay and is new
sub ok_newoid {
  my($object,$label,@tables)=@_;
  my($package,$file,$line)=caller; # for fails
  my $ok=_ok_newoid($object,$label,$file,$line,@tables);
  report_pass($ok,$label);
}
# check that objects' oids look okay and are new
sub ok_newoids {
  my($objects,$label,@tables)=@_;
  my($package,$file,$line)=caller; # for fails
  my $ok=1;
  for(my $i=0; $i<@$objects; $i++) {
    $ok&&=_ok_newoid($objects->[$i],"$label object $i",$file,$line,@tables);
  }
  report_pass($ok,$label);
}
sub _ok_newoid {
  my($obj,$label,$file,$line,@tables)=@_;
  tie_oid;
  my $oid=autodb->oid($obj);
  report_fail($oid>1,"$label: oid looks good",$file,$line) or return 0;
  # first check in-memory state maintained by test
  report_fail(exists $oid2obj{$oid}? $oid2obj{$oid}==$obj: 1,
	      "$label: oid-to-object unique",$file,$line) or return 0;
  report_fail(exists $obj2oid{refaddr $obj}? $obj2oid{refaddr $obj}==$oid: 1,
	      "$label: object-to-oid unique",$file,$line) or return 0;
  # update in-memory state maintained by test
  $oid2obj{$oid}=$obj;
  $obj2oid{refaddr $obj}=$oid;
  # next check real object cache (similar to ok_objcache)
  report_fail(oid2obj($oid)==$obj,"$label: cache entry for oid $oid",$file,$line) or return 0;
  report_fail
    (ref($obj) ne 'Class::AutoDB::OidDeleted',
     "$label: ref for oid $oid looks extant (not OidDeleted)",$file,$line) or return 0;
  # third check against database maintained by test
  report_fail(!$oid{$oid},"$label: not in SDBM file",$file,$line) or return 0;
  if (UNIVERSAL::can($obj,'id')) {
    my $id=$obj->id;
    report_fail(!$oid2id{$oid},"$label: in oid2id SDBM file",$file,$line) or return 0;
    # line below generates spurious errors when tests rerun
    # report_fail(!$id2oid{$id},"$label: in id2oid SDBM file",$file,$line) or return 0;
  }
  # last but not least check against real database 
  push(@tables,'_AutoDB') unless grep {$_ eq '_AutoDB'} @tables;
  for my $table (@tables) {
    my($count)=dbh->selectrow_array(qq(SELECT COUNT(oid) FROM $table WHERE oid=$oid));
    report_fail(!$count,"$label: not in $table table",$file,$line) or return 0;
  }
  1;
}

# check that object's oid looks okay and is deleted
sub ok_deloid {
  my($object,$label,@tables)=@_;
  my($package,$file,$line)=caller; # for fails
  my $ok=_ok_deloid($object,$label,$file,$line,@tables);
  report_pass($ok,$label);
}
# check that objects' oids look okay and are deleted
sub ok_deloids {
  my($objects,$label,@tables)=@_;
  my($package,$file,$line)=caller; # for fails
  my $ok=1;
  for(my $i=0; $i<@$objects; $i++) {
    $ok&&=_ok_deloid($objects->[$i],"$label object $i",$file,$line,@tables);
  }
  report_pass($ok,$label);
}
sub _ok_deloid {
  my($obj,$label,$file,$line,@tables)=@_;
  tie_oid;
  my $oid=autodb->oid($obj);
  report_fail($oid>1,"$label: oid looks good",$file,$line) or return 0;
  # first check in-memory state maintained by test
  report_fail(exists $oid2obj{$oid}? $oid2obj{$oid}==$obj: 1,
	      "$label: oid-to-object unique",$file,$line) or return 0;
  report_fail(exists $obj2oid{refaddr $obj}? $obj2oid{refaddr $obj}==$oid: 1,
	      "$label: object-to-oid unique",$file,$line) or return 0;
  # update in-memory state maintained by test
  $oid2obj{$oid}=$obj;
  $obj2oid{refaddr $obj}=$oid;
  # next check real object cache (similar to ok_objcache)
  report_fail(oid2obj($oid)==$obj,"$label: cache entry for oid $oid",$file,$line) or return 0;
  report_fail
    (ref($obj) eq 'Class::AutoDB::OidDeleted',
     "$label: ref for oid $oid looks deleted (is OidDeleted)",$file,$line) or return 0;
  # third check against database maintained by test
  # NG 10-09-10: tests fail when deleting old objects. kinda silly anyway since
  #              just testing the test...
  # report_fail(!$oid{$oid},"$label: not in SDBM file",$file,$line) or return 0;
    if (UNIVERSAL::can($obj,'id')) {
      my $id=$obj->id;
      report_fail(!$oid2id{$oid},"$label: in oid2id SDBM file",$file,$line) or return 0;
      # line below generates spurious errors when tests rerun
      # report_fail(!$id2oid{$id},"$label: in id2oid SDBM file",$file,$line) or return 0;
    }
  # last but not least check against real database
  # _AutoDB is special because deleted objects exist but are NULL
  my($count)=dbh->selectrow_array
    (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid=$oid AND object IS NULL));
  report_fail
    ($count==1,
     "$label: $oid deleted (exists but is NULL) in _AutoDB table",$file,$line) or return 0;
  for my $table (@tables) {
    next if $table eq '_AutoDB';
    my($count)=dbh->selectrow_array(qq(SELECT COUNT(oid) FROM $table WHERE oid=$oid));
    report_fail(!$count,"$label: not in $table table",$file,$line) or return 0;
  }
  1;
}


# check entries in object cache, esp for Oid and OidDeleted objects
# do it carefully to avoid inadvertent fetches! 
#   I messed this up first couple of times.
#   NEVER test $obj. always test ref $obj !!!
# cache entry cab be specified by reference (ie, obj), oid as number, or both in either order
# $entry_type can be 
#   undef           entry should not exist
#   object          entry should hold real object
#   Oid, OidDeleted obvious
sub ok_objcache {
  my($obj,$oid);
  ref $_[0]? $obj=shift: ($oid=shift); # 1st arg can be $obj or $oid
				       # 2nd arg can be the other one or neither
  !ref $obj && ref $_[0]? $obj=shift: (!$oid && $_[0]=~/^\d+$/? $oid=shift: undef);
  my($entry_type,$class,$label,$file,$line,$no_report_pass)=@_;
  
  # set whichever of obj and oid not already set. if both set, check consistency
  if (ref $obj && $oid) {
    report_fail(oid2obj($oid)==$obj && obj2oid($obj)==$oid,
		'object and oid do not match in ok_objcache',$file,$line);
  } elsif (ref $obj) {
    $oid=obj2oid($obj);
  } elsif ($oid) {
    $obj=oid2obj($oid);
  } else {
    confess "Invalid arguments: at least one of \$obj or \$oid must be specified";
  }

  my $ok=1;
  if (!defined $entry_type) {	# expect obj to be undef
    $ok&&=report_fail
      (!defined $obj,"$label. cache entry should not exist",$file,$line);
  } else {
    my $ref=ref $obj;
    if ($entry_type=~/^obj/i) {
      $ok&&=report_fail
	($ref eq $class,"$label: cache entry has wrong class: got $ref, expected $class",
	 $file,$line);
    } else {			# Oid or OidDeleted
      confess "Ilegal entry_type $entry_type" unless $entry_type=~/oid$|deleted$/i;
      my $correct_ref=$entry_type=~/oid$/i? 'Class::AutoDB::Oid': 'Class::AutoDB::OidDeleted';
      $ok&&=report_fail
	($ref eq $correct_ref,
	 "$label. cache entry has wrong class: got $ref, expected $correct_ref",$file,$line);
      my $oid_class=$obj->{_CLASS};
      my $oid_oid=$obj->{_OID};
      $ok&&=report_fail
	($oid_oid==$oid,
	 "$label. $entry_type contains wrong oid: got $oid_oid, expected $oid",$file,$line);
      # Oid must have class. optional for OidDeleted
      if ($entry_type=~/oid$/i || (defined $class && exists $obj->{_CLASS})) { 
	$ok&&=report_fail
	  ($oid_class eq $class,
	   "$label. $entry_type contains wrong class: got $oid_class, expected $class",
	   $file,$line);
      }
      # check for extraneous keys.
      my @oid_keys=keys %$obj;
      my $bad_keys=join(',',grep !/_CLASS|_OID/,@oid_keys);
      $ok&&=report_fail(!$bad_keys,
			"$label. $entry_type contains extraneous keys: $bad_keys",$file,$line);
    }
  }
  !$no_report_pass? report_pass($ok,$label): $ok;
}
# conjure up Oid entries in object cache. returns entry in case anyone wants it (which they do :)
use Class::AutoDB::Oid;
use Class::AutoDB::OidDeleted;
sub conjure_oid {
  my($oid,$entry_type,$class)=@_;
  confess "Ilegal entry_type $entry_type" unless $entry_type=~/oid$|deleted$/i;
  my $obj={_OID=>$oid};
  $obj->{_CLASS}=$class if defined $class;
  bless $obj,$entry_type=~/oid$/i? 'Class::AutoDB::Oid': 'Class::AutoDB::OidDeleted';
  oid2obj($oid,$obj);
  obj2oid($obj,$oid);
  $obj;
}


# TODO: use is all thawed tests!
# $actual_objects. array of lots of object. 
# $correct_thawed. subset of $actual_objects expected to be thawed
sub cmp_thawed {
  my($actual_objects,$correct_thawed,$label)=@_;
 my($package,$file,$line)=caller; # for fails
  my $ok=_cmp_thawed($actual_objects,$correct_thawed,$label,$file,$line);
  report_pass($ok,$label);
}
sub _cmp_thawed {
  my($actual_objects,$correct_thawed,$label,$file,$line)=@_;
  my @actual_thawed=grep {'Class::AutoDB::Oid' ne ref $_} @$actual_objects;
  # unthawed objects are fragile and esily thawed. do the cmp this way to avoid thawing
  my @actual_refs=
    uniq map {ref($_).'='.Scalar::Util::reftype($_).sprintf('(%0x)',Scalar::Util::refaddr($_))}
      @actual_thawed;
  my @correct_refs=
    uniq map {ref($_).'='.Scalar::Util::reftype($_).sprintf('(%0x)',Scalar::Util::refaddr($_))}
      @$correct_thawed;
  @actual_refs=sort @actual_refs;
  @correct_refs=sort @correct_refs;
  
  my($ok,$details)=cmp_details(\@actual_refs,\@correct_refs);
  report_fail($ok,$label,$file,$line,$details);
}
# remember a list of oids or all oids for later tests
sub remember_oids {
  tie_oid;
  my @objs=@_? @_: all_objects;
  my @oids=grep {$_>1} map {autodb->oid($_)} @objs;
  @oid{@oids}=@oids;
  # get id-able oids and corresponding ids
  my @oids=grep {$_>1} map {autodb->oid($_)} grep {UNIVERSAL::can($_,'id')} @objs;
  my @ids=map {autodb->oid($_)>1? $_->id: ()} grep {UNIVERSAL::can($_,'id')} @objs;
  @oid2id{@oids}=@ids;
  @id2oid{@ids}=@oids;
}
# return those tables (from a given list) that are actually in database
sub actual_tables {
  my @correct=@_;
  my $tables=dbh->selectcol_arrayref(qq(SHOW TABLES));
  my @actual;
  for my $table (@$tables) {
    push(@actual,$table) if grep {$table eq $_} @correct;
  }
  @actual;
}
# return hash of counts for given list of tables
sub actual_counts {
  my @tables=@_;
  my %counts;
  for my $table (@tables) {
    # NG 10-09-09: added _AutoDB special case to handle deleted objects
    my $sql=qq(SELECT COUNT(oid) FROM $table);
    $sql.=' WHERE object IS NOT NULL' if $table eq '_AutoDB';
    # my($count)=dbh->selectrow_array(qq(SELECT COUNT(oid) FROM $table));
    my($count)=dbh->selectrow_array($sql);
    $counts{$table}=$count||0; # convert undef to 0 (usually nonexistent table)
  }
  wantarray? %counts: \%counts;
}
# remove elements with non-true counts
sub norm_counts {
  my %counts=(@_==1 && ref $_[0])? %{$_[0]}: @_;
  map {$counts{$_} or delete $counts{$_}} keys %counts;
  wantarray? %counts: \%counts;
}
# return columns that are actually in a database table
sub actual_columns {
  my($table)=@_;
  my $columns=dbh->selectcol_arrayref(qq(SHOW COLUMNS FROM $table)) || [];
  wantarray? @$columns: $columns;
}
# test one object. presently used in autodb.099.docs/docs.03x series
require autodbTestObject;	# 'require' instead of 'use' to avoid circular 'uses'
our $TEST_OBJECT;
sub test_single {
  my($class,@colls)=@_;
  @colls or @colls=qw(Person);
  my %all_coll2basekeys=(Person=>[qw(name sex id)],PersonStrings=>[qw(name sex id)],
			 HasName=>[qw(name)]);
  my %coll2basekeys=map {$_=>$all_coll2basekeys{$_}} @colls;
#   my $new_args=
#     sub {my($test)=@_; name=>$test->class,sex=>($main::ID%2? 'M': 'F'),id=>$main::ID++};
  my $new_args=
    sub {my($test)=@_; name=>$test->class,sex=>(id()%2? 'M': 'F'),id=>id_next()};
  my $test_object=$TEST_OBJECT || 
    ($TEST_OBJECT=new autodbTestObject
     (new_args=>$new_args,correct_diffs=>1,
      label=>sub {my $test=shift; my $obj=$test->current_object; $obj && $obj->name;},
     ));
  $test_object->test_put(class=>$class,correct_colls=>\@colls,coll2basekeys=>\%coll2basekeys);
  $test_object->last_object;
}

sub report {
  my($ok,$label,$file,$line,$details)=@_;
  pass($label), return if $ok;
  fail($label);
  ($file,$line)=called_from($file,$line);
  diag("from $file line $line") if defined $file;
  if (defined $details) {
    diag(deep_diag($details)) if ref $details;
    diag($details) unless ref $details;
  }
  return 0;
}

sub report_pass {
  my($ok,$label)=@_;
  pass($label) if $ok;
  $ok;
}
sub report_fail {
  my($ok,$label,$file,$line,$details)=@_;
  return 1 if $ok;
  fail($label);
  ($file,$line)=called_from($file,$line);
  diag("from $file line $line") if defined $file;
  if (defined $details) {
    diag(deep_diag($details)) if ref $details;
    diag($details) unless ref $details;
  }
  return 0;
}
# set $file,$line if not already set
sub called_from {
  return @_ if $_[0];
  my($package,$file,$line);
  my $i=0;
  while (($package,$file,$line)=caller($i++)) {
    last if 'main' eq $package;
  }
  ($file,$line);
}
1;
