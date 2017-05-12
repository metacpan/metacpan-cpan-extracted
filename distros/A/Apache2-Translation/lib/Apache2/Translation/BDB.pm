package Apache2::Translation::BDB;

use 5.008008;
use strict;

use File::Spec;
use BerkeleyDB;
use Storable ();
use Class::Member::HASH -CLASS_MEMBERS=>qw/bdbenv readonly extra_db
					   _db1 _db2 _txn parent_txn
					   _connected root/;
our @CLASS_MEMBERS;

use Apache2::Translation::_base;
use base 'Apache2::Translation::_base';

use warnings;
no warnings qw(uninitialized);
undef $^W;

our $VERSION = '0.05';

# _db1 maps id=>[block, order, action, id, key, uri]
# _db2 is a secondary index of (key,uri). It is associated with _db1
# extra_db contains the timestamp and the id-sequence

our $last_created_provider;

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

  # then override with named parameters
  foreach my $m (@CLASS_MEMBERS) {
    $I->$m=$o{$m} if( exists $o{$m} );
  }

  unless( ref($I->bdbenv) ) {
    if( defined $I->bdbenv ) {
      die "ERROR: bdbenv must be set to a directory name\n"
	unless( ref($I->bdbenv) or length $I->bdbenv );

      my $dir=$I->bdbenv;
      $dir=File::Spec->catdir( $I->root, $dir )
	if( length $I->root and !File::Spec->file_name_is_absolute($dir) );
      -d $dir or mkdir $dir;
    } else {
      if( $last_created_provider ) {
	$I->bdbenv=$last_created_provider;
      } else {
	die "ERROR: bdbenv must be set to a directory name\n";
      }
    }
  }

  return $last_created_provider=$I;
}

sub connect {
  my ($I)=@_;

  return $I if( $I->_connected );

  my $env=$I->bdbenv;
  if( ref($env) ) {
    if( $I->bdbenv->isa(__PACKAGE__) ) {
      $I->bdbenv->connect;
      $I->bdbenv=$env=$I->bdbenv->bdbenv;
    }
  } else {
    my $dir=$I->bdbenv;
    $dir=File::Spec->catdir( $I->root, $dir )
      if( length $I->root and !File::Spec->file_name_is_absolute($dir) );
    $I->bdbenv=$env=BerkeleyDB::Env->new
      (
       -Home  => $dir,
       -Flags => DB_CREATE| DB_INIT_MPOOL | DB_INIT_LOCK | DB_INIT_TXN |
                 DB_INIT_LOG,
       -LockDetect => DB_LOCK_MINWRITE,
       #-ErrFile=>\*STDERR,
       #-Verbose=>10,
      ) or die "ERROR: Cannot create BDB environment $dir: $BerkeleyDB::Error\n";
  }

  my $txn;
  $txn=$env->txn_begin($I->parent_txn ? $I->parent_txn : undef, 0)
    unless($I->readonly);
  my $name1=ref($I).'-id.db';
  $I->_db1=BerkeleyDB::Btree->new
    (
     -Filename     => $name1,
     -Flags        => ($I->readonly ? DB_RDONLY | DB_AUTO_COMMIT
                                    : DB_CREATE),
     -Env          => $env,
     -Txn          => $txn,
    );
  my $name2=ref($I).'-keyuri.db';
  $I->_db2=BerkeleyDB::Btree->new
    (
     -Filename     => $name2,
     -Flags        => ($I->readonly ? DB_RDONLY | DB_AUTO_COMMIT
                                    : DB_CREATE),
     -Env          => $env,
     -Txn          => $txn,
     -Property     => DB_DUP,
    );
  my $name3=ref($I).'-extra.db';
  $I->extra_db=BerkeleyDB::Btree->new
    (
     -Filename     => $name3,
     -Flags        => ($I->readonly ? DB_RDONLY | DB_AUTO_COMMIT
                                    : DB_CREATE),
     -Env          => $env,
     -Txn          => $txn,
    );

  unless($I->readonly) {
    if( $I->_db1 and $I->_db2 and $I->extra_db ) {
      $txn->txn_commit
	and die "ERROR: Cannot commit DB_CREATE: $BerkeleyDB::Error\n";
    } else {
      $txn->txn_abort;
      die "ERROR: Cannot open database: $BerkeleyDB::Error\n";
    }
  }

  $I->begin($I->parent_txn);
  $I->_db1->associate
    ($I->_db2, sub {
       my ($pkey, $pdata)=@_;
       $_[2]=join( "\t", @{decode($pdata)}[KEY,URI] );
       return 0;
     }) if($I->_db1 and $I->_db2);
  $I->commit;

  $I->_connected=1;

  return $I;
}

*encode=\&Storable::nfreeze;
*decode=\&Storable::thaw;

*start=\&connect;
sub stop {}
sub can_notes {1}

sub fetch {
  my ($I, $key, $uri, $with_notes)=@_;

  $key.="\t".$uri;
  my (@l, $v, $c, $stat);
  $c=$I->_db2->db_cursor;
  if( $with_notes ) {
    for( $stat=$c->c_get($key, $v, DB_SET);
	 $stat==0;
	 $stat=$c->c_get($key, $v, DB_NEXT_DUP) ) {
      push @l, [@{decode($v)}[BLOCK,ORDER,ACTION,ID,NOTE]];
    }
  } else {
    for( $stat=$c->c_get($key, $v, DB_SET);
	 $stat==0;
	 $stat=$c->c_get($key, $v, DB_NEXT_DUP) ) {
      push @l, [@{decode($v)}[BLOCK,ORDER,ACTION,ID]];
    }
  }
  return sort {$a->[BLOCK] <=> $b->[BLOCK] or $a->[ORDER] <=> $b->[ORDER]} @l;
}

sub list_keys {
  my $I=$_[0];

  my (%h, $k, $v, $c, $stat);
  $c=$I->_db2->db_cursor;
  for( $stat=$c->c_get($k, $v, DB_FIRST);
       $stat==0;
       $stat=$c->c_get($k, $v, DB_NEXT_NODUP) ) {
    undef $h{(split /\t/, $k)[0]};
  }

  return map {[$_]} sort keys %h;
}

sub list_keys_and_uris {
  my ($I,$key)=@_;
  $key='' unless( defined $key );

  my (@l, $k, $v, $c, $stat);
  $c=$I->_db2->db_cursor;

  for( $stat=$c->c_get($k, $v, DB_FIRST);
       $stat==0;
       $stat=$c->c_get($k, $v, DB_NEXT_NODUP) ) {
    my @v=split /\t/, $k;
    push @l, [@v] if( !length($key) or $key eq $v[0] );
  }
  return sort {$a->[0] cmp $b->[0] or $a->[1] cmp $b->[1]} @l;
}

sub begin {
  my ($I)=@_;

  $I->_txn=$I->bdbenv->txn_begin
    ( $I->parent_txn ? $I->parent_txn : undef, DB_TXN_NOSYNC );
  die "ERROR: Cannot create transaction: $BerkeleyDB::Error\n"
    unless( defined $I->_txn );
  $I->_txn->Txn($I->_db1, $I->_db2, $I->extra_db);
}

sub commit {
  my ($I)=@_;

  my $rc=!$I->_txn->txn_commit;
  undef $I->_txn;
  $I->bdbenv->txn_checkpoint(0,0);
  return $rc;
}

sub rollback {
  my ($I)=@_;

  return unless( $I->_txn );
  my $rc=!$I->_txn->txn_abort;
  undef $I->_txn;
  return $rc;
}

sub update {
  my $I=shift;
  my $old=shift;
  my $new=shift;

  my ($v, $c, $stat, $rc);
  $c=$I->_db1->db_cursor;

  if( ($rc=$c->c_get($old->[oID], $v, DB_SET))==0 ) {
    my $el=decode($v);
    if( $el->[BLOCK]==$old->[oBLOCK] and $el->[ORDER]==$old->[oORDER] ) {
      @{$el}[BLOCK,ORDER,ACTION,KEY,URI,NOTE]=
	@{$new}[nBLOCK,nORDER,nACTION,nKEY,nURI,nNOTE];
      $rc=$c->c_put($old->[oID],
		    encode($el),
		    DB_CURRENT);
      die "__RETRY__\n" if( $rc==DB_LOCK_DEADLOCK );
      return $rc==0 ? 1 : 0;
    }
  } elsif( $rc==DB_LOCK_DEADLOCK ) {
    die "__RETRY__\n" if( $rc==DB_LOCK_DEADLOCK );
  }
  return "0 but true";
}

sub insert {
  my ($I, $new)=@_;

  # fetch a new id
  my ($k, $v, $c, $id, $rc);
  $c=$I->extra_db->db_cursor;
  if( ($rc=$c->c_get($k='id_seq', $v, DB_SET))==0 ) {
    $rc=$c->c_put( $k, $id=$v+1, DB_CURRENT );
  } else {
    die "__RETRY__\n" if( $rc==DB_LOCK_DEADLOCK );
    $rc=$I->extra_db->db_put( $k, $id=1 );
  }
  die "__RETRY__\n" if( $rc==DB_LOCK_DEADLOCK );

  my $el=[];
  @{$el}[BLOCK,ORDER,ACTION,KEY,URI,NOTE,ID]=
    (@{$new}[nBLOCK,nORDER,nACTION,nKEY,nURI,nNOTE], $id);

  $rc=$I->_db1->db_put( $id, encode($el) );
  die "__RETRY__\n" if( $rc==DB_LOCK_DEADLOCK );
  return $rc==0 ? 1 : 0;
}

sub delete {
  my ($I, $old)=@_;

  my ($v, $c, $stat, $rc);
  $c=$I->_db1->db_cursor;

  if( ($rc=$c->c_get($old->[oID], $v, DB_SET))==0 ) {
    my $el=decode($v);
    if( $el->[BLOCK]==$old->[oBLOCK] and $el->[ORDER]==$old->[oORDER] ) {
      $rc=$c->c_del;
      die "__RETRY__\n" if( $rc==DB_LOCK_DEADLOCK );
      return $rc==0 ? 1 : 0;
    }
  } elsif( $rc==DB_LOCK_DEADLOCK ) {
    die "__RETRY__\n";
  }
  return "0 but true";
}

sub clear {
  my ($I)=@_;

  my ($k, $v, $c, $stat, $count, $rc);

  $count=0;
  $c=$I->_db1->db_cursor;
  while( ($rc=$c->c_get($k, $v, DB_NEXT))==0 ) {
    $rc=$c->c_del;
    die "__RETRY__\n" if( $rc==DB_LOCK_DEADLOCK );
    $count+=($rc==0 ? 1 : 0);
  }
  die "__RETRY__\n" if( $rc==DB_LOCK_DEADLOCK );
  die "__RETRY__\n" if( $I->extra_db->db_del("\ttmstmp")==DB_LOCK_DEADLOCK );

  return $count;
}

sub iterator {
  my $c=$_[0]->_db2->db_cursor;
  my @blocklist;

  return sub {
    unless( @blocklist ) {
      my ($key, $k, $v, $rc);
      if( ($rc=$c->c_get($key, $v, DB_NEXT))==0 ) {
	my $new=[];
	@{$new}[nBLOCK,nORDER,nACTION,nKEY,nURI,nNOTE,nID]=
	  @{decode($v)}[BLOCK,ORDER,ACTION,KEY,URI,NOTE,ID];
	push @blocklist, $new;
	while( ($rc=$c->c_get($k=$key, $v, DB_NEXT_DUP))==0 ) {
	  $new=[];
	  @{$new}[nBLOCK,nORDER,nACTION,nKEY,nURI,nNOTE,nID]=
	    @{decode($v)}[BLOCK,ORDER,ACTION,KEY,URI,NOTE,ID];
	  push @blocklist, $new;
	}
	@blocklist=sort {$a->[nBLOCK]<=>$b->[nBLOCK] or
			 $a->[nORDER]<=>$b->[nORDER]} @blocklist;
      } elsif( $rc==DB_LOCK_DEADLOCK ) {
	die "__RETRY__\n";
      } else {
	undef $c;
	return;
      }
    }
    return shift @blocklist;
  };
}

sub extra {
  my ($I, $k, $v)=@_;

  my ($res);
  die "__RETRY__\n" if( $I->extra_db->db_get($k, $res)==DB_LOCK_DEADLOCK );
  if( @_>2 ) {
    die "__RETRY__\n" if( $I->extra_db->db_put($k, $v)==DB_LOCK_DEADLOCK );
  }

  return $res;
}

sub timestamp {
  my ($I, $stamp)=@_;

  no warnings qw(numeric);
  return $I->extra( "\ttmstmp", $stamp )+0;
}

1;
__END__
