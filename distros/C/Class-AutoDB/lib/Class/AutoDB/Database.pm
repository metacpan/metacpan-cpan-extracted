package Class::AutoDB::Database;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use DBI;
use Class::AutoClass;
use Hash::AutoHash::Args;
use Class::AutoDB::Registry;
use Class::AutoDB::Cursor;
use Text::Abbrev;
@ISA = qw(Class::AutoClass);

# Mixin for Class::AutoDB. Handles database operations

@AUTO_ATTRIBUTES=qw(object_table
		   _exists);
@OTHER_ATTRIBUTES=qw();
%SYNONYMS=();
%DEFAULTS=(object_table=>'_AutoDB');
Class::AutoClass::declare(__PACKAGE__);

my $GLOBALS=Class::AutoDB::Globals->instance();

# TODO: this is copied from Table.pm.  find a single place for this.
my %TYPES=(string  =>'longtext',
	   integer =>'int',
	   float   =>'double',
	   object  =>'bigint unsigned',);
my @TYPES=keys %TYPES;
my %TYPES_ABBREV=abbrev @TYPES;

# TODO: deal with free-form queries
sub find {
  my $self=shift;
  my $query=$self->parse_query(@_);
  my $cursor=new Class::AutoDB::Cursor(-query=>$query,-dbh=>$self->dbh);
  $cursor;
}
sub get {
  my $self=shift;
  my $cursor=$self->find(@_);
  $cursor->get;
}
sub count {
  my $self=shift;
  my $query=$self->parse_query(@_);
  my $cursor=new Class::AutoDB::Cursor(-query=>$query,-dbh=>$self->dbh);
  $cursor->count;
}
# NG 10-09-15: moved some code around to handle empty query and raw SQL
sub parse_query {
  my $self=shift;
  my $args=new Hash::AutoHash::Args(@_);
  # NG 09-12-19: $autodb needed to remove $value->oid below
  my $autodb=$GLOBALS->autodb;
  my $dbh=$self->dbh;
  my $object_table=$self->object_table;
  my @from=($object_table);	# always need_AutoDB
  # NG 10-09-13: added 'IS NOT NULL' to handle deleted objects
  my @where=qq($object_table.object IS NOT NULL);
  # NG 10-09-15: added support for raw SQL
  my $sql=$args->sql;
  delete $args->{sql};        # so 'sql' will not be confused with a search key!
  push(@where,"$object_table.oid IN ($sql)") if $sql;
  my $limit;			# may be set in 'then' below
  if (%$args) {
    my $name=$args->collection;
    delete $args->{collection};	# so 'collection' will not be confused with a search key!
    my $query=$args->query? $args->query: $args;
    my $collection=$self->registry->collection($name) || $self->throw("Unknown collection $name");
    my $keys=$collection->keys;
    # NG 09-12-18: rewrote to avoid duplicates when selecting from list
    #              and to omit base table when keys are all lists
    my(@base_where,@list_selects);
    while(my($key,$value)=each %$query) {	# create SQL condition for each search key
      if ($key eq '_limit_') { # reserved keyword
	$limit = $value;
	next;
      }
      my $type=$keys->{$key} || $self->throw("Unknown key $key for collection $name");
      if (($type eq 'object' || $type eq 'list(object)') && defined $value) {
	# NG 09-12-19: $value->oid crashes on nonpersistent things. 
	#              change also needed for cleanup of user-object namespace
	# $value=$value->oid;
	# $value=Class::AutoDB::Serialize::obj2oid($value)
	# NG 09-12-22: handle repeated search terms for list(object)
	if ('ARRAY' eq ref $value) {
	  $value=[map {Class::AutoDB::Serialize::obj2oid($_)} @$value];
	} else {
	  $value=Class::AutoDB::Serialize::obj2oid($value)
	}
      }
      my($db_type,$list_type,$table);
      if ($type=~/^list/) {
	# legal to have repeated search terms for list
	my @values='ARRAY' eq ref $value? @$value: ($value);
	($list_type)=$type=~/^list\s*\(\s*(.*)\s*\)/;
	$db_type=$TYPES{$list_type};
        for my $value (@values) {
	  $table=$name."_$key";	# list keys are stored in separate tables
	  my $list_select=qq(SELECT $table.oid FROM $table WHERE ); 
	  if (defined $value) {
	    $value=$dbh->quote($value,$db_type);
	    $list_select.="$table.$key=$value";
	  } else {
	    $list_select.="$table.$key IS NULL";
	  }
	  push(@list_selects,$list_select);
	}
      } else {			# scalar keys are stored in base table
	# illegal to have repeated search terms for base
	$self->throw("scalar search key $key repeated") if 'ARRAY' eq ref $value;
	$db_type=$TYPES{$type};
	if (defined $value) {
	  $value=$dbh->quote($value,$db_type);
	  push(@base_where,"$name.$key=$value");
	} else {
	  push(@base_where,"$name.$key IS NULL");
	}
      }
    }
    if (@base_where || !@list_selects) { 
      # we do base query via regular join. include join if query would otherwise be empty
      push(@base_where,qq($name.oid=$object_table.oid));
      push(@from,$name); 
    } 
    # NG 10-09-13: added 'IS NOT NULL' to handle deleted objects
    # my @where=(@base_where,map {qq($object_table.oid IN ($_))} @list_selects);
    # my @where=(qq($object_table.object IS NOT NULL),
    push(@where,@base_where,map {qq($object_table.oid IN ($_))} @list_selects);
  } else {			        # empty query
    push(@where,"$object_table.oid>1"); # get all user objects but skip registry
  }
  my $from=join(',',@from);
  my $where=join(' AND ',@where);
  #   my (@where,$limit);
  #   my %tables=($name=>$name);	# always include base table
  #   while(my($key,$value)=each %$query) {	# create SQL condition for each search key
  #     if ($key eq '_limit_') { # reserved keyword
  #       $limit = $value;
  #       next;
  #     }
  #     my $type=$keys->{$key} || $self->throw("Unknown key $key for collection $name");
  #     my($db_type,$list_type,$table);
  #     if ($type=~/^list/) {
  #       ($list_type)=$type=~/^list\s*\(\s*(.*)\s*\)/;
  #       $db_type=$TYPES{$list_type};
  #       $table=$name."_$key";	# list keys are stored in separate tables
  #       $tables{$table}=$table;
  #     } else {
  #       $db_type=$TYPES{$type};
  #       $table=$name;		# scalar keys are stored in base table
  #     }
  #     if (($type eq 'object' || $type eq 'list(object)') && defined $value) {
  #       $value=$value->oid;
  #     }
  #     $value=$dbh->quote($value,$db_type);
  #     push(@where,"$table.$key=$value");
  #   }
  #   for my $table (keys %tables) { # create join conditions for each table
  #     push(@where,"$table.oid=$object_table.oid");
  #   }
  #   my $from=join(',',$object_table,keys %tables);
  #   my $where=join(' AND ',@where);
  # overwrite query
  my $query = " FROM $from WHERE $where";
  # NG 10-09-15: rewrote for style
  # if ($limit) {
  #   $query .= ' LIMIT ';
  #   $query .= $limit;
  # }
  $query.=" LIMIT $limit" if defined $limit;
  $query;
}
sub create {
  my($self,$index_flag)=@_;
  $self->throw("Cannot create database unless connected") unless $self->is_connected;
  my $registry=$self->registry;
  my $dbh=$self->dbh;
  my @sql;
  my $object_table=$self->object_table;
  # drop & recreate object table
  # NG 10-09-17: added DROP VIEW
  push(@sql,(qq(DROP TABLE IF EXISTS $object_table),
	     qq(DROP VIEW IF EXISTS $object_table),
	     qq(CREATE TABLE $object_table (oid BIGINT UNSIGNED NOT NULL,
					    object LONGBLOB,
					    PRIMARY KEY (oid)))));
  push(@sql,$registry->schema('create', $index_flag)); # create collections (drops tables first)
  $self->do_sql(@sql);		          # do it!
  # NG 11-01-07: line below equates saved & current registry versions, making it impossible
  #     to do diffs on runtime schema changes
  #   my 1st attempt to fix was to just comment it out, reasoning it was unnecessary, 
  #     since 'alter' (below) doesn't do it, and  caller invokes $registry->merge later 
  #     which merges contents of schemas
  #   this was wrong. caller invokes $registry->get earlier which sets saved schema to
  #     value stored in database (d'oh -- it's called 'saved' schema after all:) 
  #     having saved schema in hand is necessary if we want to delete existing collections
  #     as part of create process -- dunno why we don't do this. maybe later
  #   2nd try: careful deep copy current to saved
  # $registry->saved($registry->current);	  # current version is now the real one
  $registry->saved($registry->current->copy);     # current version is now the real one
  $registry->put;		          # store registry
  $self->_exists(1);
}
sub drop {
  my($self)=@_;
  $self->throw("Cannot drop database unless connected") unless $self->is_connected;
  my $registry=$self->registry;
  my $object_table=$self->object_table;
  my @sql;
  push(@sql,$registry->schema('drop'));	  # drop collections
  # drop & recreate object table
  # NG 10-09-17: added DROP VIEW
  push(@sql,(qq(DROP TABLE IF EXISTS $object_table),
	     qq(DROP VIEW IF EXISTS $object_table),
	     qq(CREATE TABLE $object_table (oid BIGINT UNSIGNED NOT NULL,
					    object LONGBLOB,
					    PRIMARY KEY (oid)))));
  $self->do_sql(@sql);		
  $registry=new Class::AutoDB::Registry; # reset registry
  $self->registry($registry);
  $registry->autodb($self);	# set autodb here so Registry::new won't attempt 'get'
  $registry->put;		# store registry
  $self->_exists(1);
}
sub alter {
  my($self)=@_;
  $self->throw("Cannot alter database unless connected") unless $self->is_connected;
  my $registry=$self->registry;
  my $object_table=$self->object_table;
  my @sql;
  push(@sql,$registry->schema('alter'));  # alter collections
  # NG 10-09-17: added DROP VIEW
  push(@sql,			          # create object table if necessary
       qq(DROP VIEW IF EXISTS $object_table),
       qq(CREATE TABLE IF NOT EXISTS $object_table (oid BIGINT UNSIGNED NOT NULL,
						    object LONGBLOB,
						    PRIMARY KEY (oid))));
  $self->do_sql(@sql);
  $registry->put;		          # store registry
  $self->_exists(1);
}
# NG 09-11-20: strengthened 'exists' to make sure registry exists in _AutoDB
sub exists {
  my $self=shift;
  return $self->_exists if defined $self->_exists;
  return undef unless $self->is_connected;
  my $dbh=$self->dbh;
  my $object_table=$self->object_table;
  my $registry_oid=Class::AutoDB::Registry->oid;
#   my $tables=$dbh->selectall_arrayref(qq(show tables));
#   my $exists=grep {$object_table eq $_->[0]} @$tables;
# NG 09-11-20: select below will fail if _AutoDB does not exist. this is okay because
#              connect method (in Connect) turns PrintError off
  my($exists)=$dbh->selectrow_array(qq(select count(*) from _AutoDB where oid=$registry_oid));
  $self->_exists($exists||0);
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
