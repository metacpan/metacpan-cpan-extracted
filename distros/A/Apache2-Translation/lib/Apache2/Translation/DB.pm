package Apache2::Translation::DB;

use 5.008008;
use strict;
use warnings;
no warnings qw(uninitialized);

use DBI;
use Class::Member::HASH -CLASS_MEMBERS=>qw/database user password table
					   key uri block order action notes
					   cachesize cachetbl cachecol
					   singleton id is_initialized
					   seqtbl seqnamecol seqvalcol
					   idseqname dbinit
					   _existing_keys
					   _cache _cache_version _dbh/;
our @CLASS_MEMBERS;

our $VERSION = '0.07';

sub new {
  my $parent=shift;
  my $class=ref($parent) || $parent;
  my $I=bless {}=>$class;
  my $x=0;
  my %o=map {($x=!$x) ? lc($_) : $_} @_;

  if( ref($parent) ) {         # inherit first
    foreach my $m (@CLASS_MEMBERS) {
      $I->$m=$parent->$m;
    }
  }

  $I->cachesize=1000;
  $I->singleton=0;

  # then override with named parameters
  foreach my $m (@CLASS_MEMBERS) {
    $I->$m=$o{$m} if( exists $o{$m} );
  }

  $I->_existing_keys={};
  $I->_cache={};
  if( $I->cachesize=~/^\d/ ) {
    eval "use Tie::Cache::LRU";
    die "$@" if $@;
    tie %{$I->_cache}, 'Tie::Cache::LRU', $I->cachesize;
  }

  return $I;
}

sub connect {
  my $I=shift;

  my $dbh=$I->_dbh=DBI->connect( $I->database, $I->user, $I->password,
				{
				 AutoCommit=>1,
				 PrintError=>0,
				 RaiseError=>1,
				} );
  $dbh->do($I->dbinit) if( length $I->dbinit );
  return $dbh;
}

sub start {
  my $I=shift;
  unless( $I->_dbh and eval {$I->start_common} ) {
    $I->_dbh->disconnect if( $I->_dbh );
    $I->connect;
    $I->start_common;
  }
}

sub stop {
  my $I=shift;
  undef $I->_dbh if( !$I->singleton and
		     ($I->_dbh->isa( 'Apache::DBI::Cache::db' ) or
		      $I->_dbh->isa( 'Apache::DBI::db' )) );
}

sub start_common {
  my $I=shift;

  my ($cache_tbl,$cache_col)=map {$I->$_} qw/cachetbl cachecol/;

  my $sql=<<"SQL";
SELECT MAX($cache_col)
FROM $cache_tbl
SQL

  my $stmt=$I->_dbh->prepare_cached( $sql );
  $stmt->execute;
  my $cache_version=$stmt->fetchall_arrayref->[0]->[0];

  unless( $cache_version eq $I->_cache_version ) {
    %{$I->_cache}=();
    $I->_cache_version=$cache_version;

    my ($tbl, $key, $uri)=map {$I->$_} qw/table key uri/;
    $sql=<<"SQL";
SELECT DISTINCT $key, $uri FROM $tbl
SQL

    $stmt=$I->_dbh->prepare_cached( $sql );
    $stmt->execute;
    $I->_existing_keys=+{map {("$_->[0]\0$_->[1]"=>1)}
			 @{$stmt->fetchall_arrayref}};
  }

  return 1;
}

sub fetch {
  my $I=shift;
  my ($key, $uri, $with_notes)=@_;

  my $ref;
  my ($id_col, $notes_col)=($I->id, $I->notes);
  if( $with_notes and length $notes_col and length $id_col ) {
    my ($table_name,$key_col,$uri_col,$block_col,$order_col,$action_col)=
      map {$I->$_} qw/table key uri block order action/;

    my $sql=<<"SQL";
SELECT $block_col, $order_col, $action_col, $id_col, $notes_col
FROM $table_name
WHERE $key_col=?
  AND $uri_col=?
ORDER BY $block_col ASC, $order_col ASC
SQL

    my $stmt=$I->_dbh->prepare_cached( $sql );
    $stmt->execute( $key, $uri );
    $ref=$stmt->fetchall_arrayref;
    map {defined $_->[4] ? 1 : ($_->[4]='')} @{$ref};
  } else {
    my $k="$key\0$uri";
    return unless( exists $I->_existing_keys->{$k} );

    $ref=$I->_cache->{$k};
    unless( defined $ref ) {
      my ($table_name,$key_col,$uri_col,$block_col,$order_col,$action_col)=
	map {$I->$_} qw/table key uri block order action/;

      my $sql=<<"SQL";
SELECT $block_col, $order_col, $action_col@{[length $id_col ? ", $id_col" : ""]}
FROM $table_name
WHERE $key_col=?
  AND $uri_col=?
ORDER BY $block_col ASC, $order_col ASC
SQL

      my $stmt=$I->_dbh->prepare_cached( $sql );
      $stmt->execute( $key, $uri );
      $ref=$stmt->fetchall_arrayref;

      $I->_cache->{"$key\0$uri"}=$ref;
    }
  }
  return @{$ref};
}

sub can_notes {length $_[0]->notes;}

sub list_keys {
  my $I=shift;

  my ($table_name,$key_col)=map {$I->$_} qw/table key/;
  my $stmt;
  my $sql=<<"SQL";
SELECT DISTINCT $key_col
FROM $table_name
ORDER BY $key_col ASC
SQL

  $stmt=$I->_dbh->prepare_cached( $sql );
  $stmt->execute;
  return @{$stmt->fetchall_arrayref||[]};
}

sub list_keys_and_uris {
  my $I=shift;

  my ($table_name,$key_col,$uri_col)=map {$I->$_} qw/table key uri/;
  my ($sql, $stmt, @args);
  if( @_ and length $_[0] ) {
    $sql=<<"SQL";
SELECT DISTINCT $key_col, $uri_col
FROM $table_name
WHERE $key_col=?
ORDER BY $key_col ASC, $uri_col ASC
SQL
    push @args, $_[0];
  } else {
    $sql=<<"SQL";
SELECT DISTINCT $key_col, $uri_col
FROM $table_name
ORDER BY $key_col ASC, $uri_col ASC
SQL
  }
  $stmt=$I->_dbh->prepare_cached( $sql );
  $stmt->execute( @args );
  return @{$stmt->fetchall_arrayref||[]};
}

sub begin {
  my $I=shift;
  $I->_dbh->begin_work;
}

sub commit {
  my $I=shift;

  my ($table_name,$col_name)=map {$I->$_} qw/cachetbl cachecol/;
  my $stmt;
  my $sql=<<"SQL";
UPDATE $table_name
SET $col_name=$col_name+1
SQL

  $stmt=$I->_dbh->prepare_cached( $sql );
  $stmt->execute;
  $stmt->finish;

  $I->_dbh->commit;
}

sub rollback {
  my $I=shift;
  $I->_dbh->rollback;
}

sub update {
  my $I=shift;
  my $old=shift;
  my $new=shift;

  my ($table_name,$key_col,$uri_col,$block_col,$order_col,$action_col,
      $id_col, $notes_col)=
	map {$I->$_} qw/table key uri block order action id notes/;
  my ($stmt, $sql);

  if( length $notes_col ) {
    $sql=<<"SQL";
UPDATE $table_name
SET $key_col=?,
    $uri_col=?,
    $block_col=?,
    $order_col=?,
    $action_col=?,
    $notes_col=?
WHERE $key_col=?
  AND $uri_col=?
  AND $block_col=?
  AND $order_col=?
  AND $id_col=?
SQL

    $stmt=$I->_dbh->prepare_cached( $sql );
    my $rc=$stmt->execute( @{$new}[0..5], @{$old}[0..4] );
    $stmt->finish;
    return $rc;
  } else {
    $sql=<<"SQL";
UPDATE $table_name
SET $key_col=?,
    $uri_col=?,
    $block_col=?,
    $order_col=?,
    $action_col=?
WHERE $key_col=?
  AND $uri_col=?
  AND $block_col=?
  AND $order_col=?
  AND $id_col=?
SQL

    $stmt=$I->_dbh->prepare_cached( $sql );
    my $rc=$stmt->execute( @{$new}[0..4], @{$old}[0..4] );
    $stmt->finish;
    return $rc;
  }
}

sub insert {
  my $I=shift;
  my $new=shift;

  my ($table_name,$key_col,$uri_col,$block_col,$order_col,$action_col,
      $id_col, $notes_col)=
	map {$I->$_} qw/table key uri block order action id notes/;
  my ($stmt, $sql);

  my $st=$I->seqtbl;
  if( length $st ) {
    my $sn=$I->seqnamecol;
    my $sv=$I->seqvalcol;
    my $ms=$I->idseqname;

    $stmt=$I->_dbh->prepare_cached( "SELECT $sv FROM $st WHERE $sn = ?" );
    $stmt->execute($ms);
    my ($newid)=@{$stmt->fetchall_arrayref};
    die "ERROR: $st table not set up: missing row with $sn=$ms\n"
      unless( ref $newid eq 'ARRAY' );
    $newid=$newid->[0];

    $stmt=$I->_dbh->prepare_cached( "UPDATE $st SET $sv=$sv+1 WHERE $sn = ?" );
    $stmt->execute($ms);
    $stmt->finish;

    if( length $notes_col ) {
      $sql=<<"SQL";
INSERT INTO $table_name ($key_col,
                         $uri_col,
                         $block_col,
                         $order_col,
                         $action_col,
                         $notes_col,
                         $id_col)
VALUES (?, ?, ?, ?, ?, ?, ?)
SQL

      $stmt=$I->_dbh->prepare_cached( $sql );
      my $rc=$stmt->execute( @{$new}[0..5], $newid );
      $stmt->finish;
      return $rc;
    } else {
      $sql=<<"SQL";
INSERT INTO $table_name ($key_col,
                         $uri_col,
                         $block_col,
                         $order_col,
                         $action_col, $id_col)
VALUES (?, ?, ?, ?, ?, ?)
SQL

      $stmt=$I->_dbh->prepare_cached( $sql );
      my $rc=$stmt->execute( @{$new}[0..4], $newid );
      $stmt->finish;
      return $rc;
    }
  } else {
    if( length $notes_col ) {
      $sql=<<"SQL";
INSERT INTO $table_name ($key_col,
                         $uri_col,
                         $block_col,
                         $order_col,
                         $action_col,
                         $notes_col)
VALUES (?, ?, ?, ?, ?, ?)
SQL

      $stmt=$I->_dbh->prepare_cached( $sql );
      my $rc=$stmt->execute( @{$new}[0..5] );
      $stmt->finish;
      return $rc;
    } else {
      $sql=<<"SQL";
INSERT INTO $table_name ($key_col,
                         $uri_col,
                         $block_col,
                         $order_col,
                         $action_col)
VALUES (?, ?, ?, ?, ?)
SQL

      $stmt=$I->_dbh->prepare_cached( $sql );
      my $rc=$stmt->execute( @{$new}[0..4] );
      $stmt->finish;
      return $rc;
    }
  }
}

sub delete {
  my $I=shift;
  my $old=shift;

  my ($table_name,$key_col,$uri_col,$block_col,$order_col,$action_col,
      $id_col)= map {$I->$_} qw/table key uri block order action id/;
  my $stmt;
  my $sql=<<"SQL";
DELETE FROM $table_name
WHERE $key_col=?
  AND $uri_col=?
  AND $block_col=?
  AND $order_col=?
  AND $id_col=?
SQL

  $stmt=$I->_dbh->prepare_cached( $sql );
  my $rc=$stmt->execute( @{$old} );
  $stmt->finish;
  return $rc;
}

sub clear {
  my ($I)=@_;

  my $table_name=$I->table;
  my $stmt;
  my $sql=<<"SQL";
DELETE FROM $table_name
SQL

  $stmt=$I->_dbh->prepare_cached( $sql );
  my $rc=$stmt->execute;
  $stmt->finish;
  return $rc;
}

sub iterator {
  my ($I)=@_;

  my ($table_name,$key_col,$uri_col,$block_col,$order_col,$action_col,
      $notes_col,$id_col)=
    map {$I->$_} qw/table key uri block order action notes id/;

  $notes_col="''" unless( length $notes_col );
  $id_col="''" unless( length $id_col );
  my $sql=<<"SQL";
SELECT $key_col, $uri_col, $block_col, $order_col, $action_col,
       $notes_col, $id_col
FROM $table_name
ORDER BY $key_col, $uri_col, $block_col ASC, $order_col ASC
SQL

  my $stmt=$I->_dbh->prepare_cached( $sql );
  $stmt->execute;

  return sub {
    my $el;
    if( $el=$stmt->fetchrow_arrayref ) {
      return $el;
    } else {
      undef $stmt;
      return;
    }
  };
}

sub DESTROY {
  my $I=shift;
  if( defined $I->_dbh ) {
    %{$I->_dbh->{CachedKids}}=();
    $I->_dbh->disconnect;
    undef $I->_dbh;
  }
}

1;
__END__
