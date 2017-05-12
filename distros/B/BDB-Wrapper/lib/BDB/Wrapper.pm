package BDB::Wrapper;
use 5.006;
use strict;
use warnings;
use BerkeleyDB;
use Carp;
use File::Spec;
use FileHandle;
use Exporter;
use AutoLoader qw(AUTOLOAD);

our $VERSION = '0.49';
our @ISA = qw(Exporter AutoLoader);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
# From BerkeleyDB.pm 0.43
our @EXPORT = qw(
	DB_AFTER
	DB_AGGRESSIVE
	DB_ALREADY_ABORTED
	DB_APPEND
	DB_APPLY_LOGREG
	DB_APP_INIT
	DB_ARCH_ABS
	DB_ARCH_DATA
	DB_ARCH_LOG
	DB_ARCH_REMOVE
	DB_ASSOC_CREATE
	DB_ASSOC_IMMUTABLE_KEY
	DB_AUTO_COMMIT
	DB_BEFORE
	DB_BTREE
	DB_BTREEMAGIC
	DB_BTREEOLDVER
	DB_BTREEVERSION
	DB_BUFFER_SMALL
	DB_CACHED_COUNTS
	DB_CDB_ALLDB
	DB_CHECKPOINT
	DB_CHKSUM
	DB_CHKSUM_SHA1
	DB_CKP_INTERNAL
	DB_CLIENT
	DB_CL_WRITER
	DB_COMMIT
	DB_COMPACT_FLAGS
	DB_CONSUME
	DB_CONSUME_WAIT
	DB_CREATE
	DB_CURLSN
	DB_CURRENT
	DB_CURSOR_BULK
	DB_CURSOR_TRANSIENT
	DB_CXX_NO_EXCEPTIONS
	DB_DATABASE_LOCK
	DB_DATABASE_LOCKING
	DB_DEGREE_2
	DB_DELETED
	DB_DELIMITER
	DB_DIRECT
	DB_DIRECT_DB
	DB_DIRECT_LOG
	DB_DIRTY_READ
	DB_DONOTINDEX
	DB_DSYNC_DB
	DB_DSYNC_LOG
	DB_DUP
	DB_DUPCURSOR
	DB_DUPSORT
	DB_DURABLE_UNKNOWN
	DB_EID_BROADCAST
	DB_EID_INVALID
	DB_ENCRYPT
	DB_ENCRYPT_AES
	DB_ENV_APPINIT
	DB_ENV_AUTO_COMMIT
	DB_ENV_CDB
	DB_ENV_CDB_ALLDB
	DB_ENV_CREATE
	DB_ENV_DATABASE_LOCKING
	DB_ENV_DBLOCAL
	DB_ENV_DIRECT_DB
	DB_ENV_DIRECT_LOG
	DB_ENV_DSYNC_DB
	DB_ENV_DSYNC_LOG
	DB_ENV_FAILCHK
	DB_ENV_FATAL
	DB_ENV_HOTBACKUP
	DB_ENV_LOCKDOWN
	DB_ENV_LOCKING
	DB_ENV_LOGGING
	DB_ENV_LOG_AUTOREMOVE
	DB_ENV_LOG_INMEMORY
	DB_ENV_MULTIVERSION
	DB_ENV_NOLOCKING
	DB_ENV_NOMMAP
	DB_ENV_NOPANIC
	DB_ENV_NO_OUTPUT_SET
	DB_ENV_OPEN_CALLED
	DB_ENV_OVERWRITE
	DB_ENV_PRIVATE
	DB_ENV_RECOVER_FATAL
	DB_ENV_REF_COUNTED
	DB_ENV_REGION_INIT
	DB_ENV_REP_CLIENT
	DB_ENV_REP_LOGSONLY
	DB_ENV_REP_MASTER
	DB_ENV_RPCCLIENT
	DB_ENV_RPCCLIENT_GIVEN
	DB_ENV_STANDALONE
	DB_ENV_SYSTEM_MEM
	DB_ENV_THREAD
	DB_ENV_TIME_NOTGRANTED
	DB_ENV_TXN
	DB_ENV_TXN_NOSYNC
	DB_ENV_TXN_NOT_DURABLE
	DB_ENV_TXN_NOWAIT
	DB_ENV_TXN_SNAPSHOT
	DB_ENV_TXN_WRITE_NOSYNC
	DB_ENV_USER_ALLOC
	DB_ENV_YIELDCPU
	DB_EVENT_NOT_HANDLED
	DB_EVENT_NO_SUCH_EVENT
	DB_EVENT_PANIC
	DB_EVENT_REG_ALIVE
	DB_EVENT_REG_PANIC
	DB_EVENT_REP_CLIENT
	DB_EVENT_REP_DUPMASTER
	DB_EVENT_REP_ELECTED
	DB_EVENT_REP_ELECTION_FAILED
	DB_EVENT_REP_JOIN_FAILURE
	DB_EVENT_REP_MASTER
	DB_EVENT_REP_MASTER_FAILURE
	DB_EVENT_REP_NEWMASTER
	DB_EVENT_REP_PERM_FAILED
	DB_EVENT_REP_STARTUPDONE
	DB_EVENT_WRITE_FAILED
	DB_EXCL
	DB_EXTENT
	DB_FAILCHK
	DB_FAST_STAT
	DB_FCNTL_LOCKING
	DB_FILEOPEN
	DB_FILE_ID_LEN
	DB_FIRST
	DB_FIXEDLEN
	DB_FLUSH
	DB_FORCE
	DB_FORCESYNC
	DB_FOREIGN_ABORT
	DB_FOREIGN_CASCADE
	DB_FOREIGN_CONFLICT
	DB_FOREIGN_NULLIFY
	DB_FREELIST_ONLY
	DB_FREE_SPACE
	DB_GETREC
	DB_GET_BOTH
	DB_GET_BOTHC
	DB_GET_BOTH_LTE
	DB_GET_BOTH_RANGE
	DB_GET_RECNO
	DB_GID_SIZE
	DB_HANDLE_LOCK
	DB_HASH
	DB_HASHMAGIC
	DB_HASHOLDVER
	DB_HASHVERSION
	DB_HOTBACKUP_IN_PROGRESS
	DB_IGNORE_LEASE
	DB_IMMUTABLE_KEY
	DB_INCOMPLETE
	DB_INIT_CDB
	DB_INIT_LOCK
	DB_INIT_LOG
	DB_INIT_MPOOL
	DB_INIT_REP
	DB_INIT_TXN
	DB_INORDER
	DB_JAVA_CALLBACK
	DB_JOINENV
	DB_JOIN_ITEM
	DB_JOIN_NOSORT
	DB_KEYEMPTY
	DB_KEYEXIST
	DB_KEYFIRST
	DB_KEYLAST
	DB_LAST
	DB_LOCKDOWN
	DB_LOCKMAGIC
	DB_LOCKVERSION
	DB_LOCK_ABORT
	DB_LOCK_CHECK
	DB_LOCK_CONFLICT
	DB_LOCK_DEADLOCK
	DB_LOCK_DEFAULT
	DB_LOCK_DUMP
	DB_LOCK_EXPIRE
	DB_LOCK_FREE_LOCKER
	DB_LOCK_GET
	DB_LOCK_GET_TIMEOUT
	DB_LOCK_INHERIT
	DB_LOCK_MAXLOCKS
	DB_LOCK_MAXWRITE
	DB_LOCK_MINLOCKS
	DB_LOCK_MINWRITE
	DB_LOCK_NORUN
	DB_LOCK_NOTEXIST
	DB_LOCK_NOTGRANTED
	DB_LOCK_NOTHELD
	DB_LOCK_NOWAIT
	DB_LOCK_OLDEST
	DB_LOCK_PUT
	DB_LOCK_PUT_ALL
	DB_LOCK_PUT_OBJ
	DB_LOCK_PUT_READ
	DB_LOCK_RANDOM
	DB_LOCK_RECORD
	DB_LOCK_REMOVE
	DB_LOCK_RIW_N
	DB_LOCK_RW_N
	DB_LOCK_SET_TIMEOUT
	DB_LOCK_SWITCH
	DB_LOCK_TIMEOUT
	DB_LOCK_TRADE
	DB_LOCK_UPGRADE
	DB_LOCK_UPGRADE_WRITE
	DB_LOCK_YOUNGEST
	DB_LOGCHKSUM
	DB_LOGC_BUF_SIZE
	DB_LOGFILEID_INVALID
	DB_LOGMAGIC
	DB_LOGOLDVER
	DB_LOGVERSION
	DB_LOGVERSION_LATCHING
	DB_LOG_AUTOREMOVE
	DB_LOG_AUTO_REMOVE
	DB_LOG_BUFFER_FULL
	DB_LOG_CHKPNT
	DB_LOG_COMMIT
	DB_LOG_DIRECT
	DB_LOG_DISK
	DB_LOG_DSYNC
	DB_LOG_INMEMORY
	DB_LOG_IN_MEMORY
	DB_LOG_LOCKED
	DB_LOG_NOCOPY
	DB_LOG_NOT_DURABLE
	DB_LOG_NO_DATA
	DB_LOG_PERM
	DB_LOG_RESEND
	DB_LOG_SILENT_ERR
	DB_LOG_VERIFY_BAD
	DB_LOG_VERIFY_CAF
	DB_LOG_VERIFY_DBFILE
	DB_LOG_VERIFY_ERR
	DB_LOG_VERIFY_FORWARD
	DB_LOG_VERIFY_INTERR
	DB_LOG_VERIFY_PARTIAL
	DB_LOG_VERIFY_VERBOSE
	DB_LOG_VERIFY_WARNING
	DB_LOG_WRNOSYNC
	DB_LOG_ZERO
	DB_MAX_PAGES
	DB_MAX_RECORDS
	DB_MPOOL_CLEAN
	DB_MPOOL_CREATE
	DB_MPOOL_DIRTY
	DB_MPOOL_DISCARD
	DB_MPOOL_EDIT
	DB_MPOOL_EXTENT
	DB_MPOOL_FREE
	DB_MPOOL_LAST
	DB_MPOOL_NEW
	DB_MPOOL_NEW_GROUP
	DB_MPOOL_NOFILE
	DB_MPOOL_NOLOCK
	DB_MPOOL_PRIVATE
	DB_MPOOL_TRY
	DB_MPOOL_UNLINK
	DB_MULTIPLE
	DB_MULTIPLE_KEY
	DB_MULTIVERSION
	DB_MUTEXDEBUG
	DB_MUTEXLOCKS
	DB_MUTEX_ALLOCATED
	DB_MUTEX_LOCKED
	DB_MUTEX_LOGICAL_LOCK
	DB_MUTEX_PROCESS_ONLY
	DB_MUTEX_SELF_BLOCK
	DB_MUTEX_SHARED
	DB_MUTEX_THREAD
	DB_NEEDSPLIT
	DB_NEXT
	DB_NEXT_DUP
	DB_NEXT_NODUP
	DB_NOCOPY
	DB_NODUPDATA
	DB_NOERROR
	DB_NOLOCKING
	DB_NOMMAP
	DB_NOORDERCHK
	DB_NOOVERWRITE
	DB_NOPANIC
	DB_NORECURSE
	DB_NOSERVER
	DB_NOSERVER_HOME
	DB_NOSERVER_ID
	DB_NOSYNC
	DB_NOTFOUND
	DB_NO_AUTO_COMMIT
	DB_ODDFILESIZE
	DB_OK_BTREE
	DB_OK_HASH
	DB_OK_QUEUE
	DB_OK_RECNO
	DB_OLD_VERSION
	DB_OPEN_CALLED
	DB_OPFLAGS_MASK
	DB_ORDERCHKONLY
	DB_OVERWRITE
	DB_OVERWRITE_DUP
	DB_PAD
	DB_PAGEYIELD
	DB_PAGE_LOCK
	DB_PAGE_NOTFOUND
	DB_PANIC_ENVIRONMENT
	DB_PERMANENT
	DB_POSITION
	DB_POSITIONI
	DB_PREV
	DB_PREV_DUP
	DB_PREV_NODUP
	DB_PRINTABLE
	DB_PRIORITY_DEFAULT
	DB_PRIORITY_HIGH
	DB_PRIORITY_LOW
	DB_PRIORITY_UNCHANGED
	DB_PRIORITY_VERY_HIGH
	DB_PRIORITY_VERY_LOW
	DB_PRIVATE
	DB_PR_HEADERS
	DB_PR_PAGE
	DB_PR_RECOVERYTEST
	DB_QAMMAGIC
	DB_QAMOLDVER
	DB_QAMVERSION
	DB_QUEUE
	DB_RDONLY
	DB_RDWRMASTER
	DB_READ_COMMITTED
	DB_READ_UNCOMMITTED
	DB_RECNO
	DB_RECNUM
	DB_RECORDCOUNT
	DB_RECORD_LOCK
	DB_RECOVER
	DB_RECOVER_FATAL
	DB_REGION_ANON
	DB_REGION_INIT
	DB_REGION_MAGIC
	DB_REGION_NAME
	DB_REGISTER
	DB_REGISTERED
	DB_RENAMEMAGIC
	DB_RENUMBER
	DB_REPFLAGS_MASK
	DB_REPMGR_ACKS_ALL
	DB_REPMGR_ACKS_ALL_AVAILABLE
	DB_REPMGR_ACKS_ALL_PEERS
	DB_REPMGR_ACKS_NONE
	DB_REPMGR_ACKS_ONE
	DB_REPMGR_ACKS_ONE_PEER
	DB_REPMGR_ACKS_QUORUM
	DB_REPMGR_CONF_2SITE_STRICT
	DB_REPMGR_CONF_ELECTIONS
	DB_REPMGR_CONNECTED
	DB_REPMGR_DISCONNECTED
	DB_REPMGR_ISPEER
	DB_REPMGR_PEER
	DB_REP_ACK_TIMEOUT
	DB_REP_ANYWHERE
	DB_REP_BULKOVF
	DB_REP_CHECKPOINT_DELAY
	DB_REP_CLIENT
	DB_REP_CONF_AUTOINIT
	DB_REP_CONF_BULK
	DB_REP_CONF_DELAYCLIENT
	DB_REP_CONF_INMEM
	DB_REP_CONF_LEASE
	DB_REP_CONF_NOAUTOINIT
	DB_REP_CONF_NOWAIT
	DB_REP_CONNECTION_RETRY
	DB_REP_CREATE
	DB_REP_DEFAULT_PRIORITY
	DB_REP_DUPMASTER
	DB_REP_EGENCHG
	DB_REP_ELECTION
	DB_REP_ELECTION_RETRY
	DB_REP_ELECTION_TIMEOUT
	DB_REP_FULL_ELECTION
	DB_REP_FULL_ELECTION_TIMEOUT
	DB_REP_HANDLE_DEAD
	DB_REP_HEARTBEAT_MONITOR
	DB_REP_HEARTBEAT_SEND
	DB_REP_HOLDELECTION
	DB_REP_IGNORE
	DB_REP_ISPERM
	DB_REP_JOIN_FAILURE
	DB_REP_LEASE_EXPIRED
	DB_REP_LEASE_TIMEOUT
	DB_REP_LOCKOUT
	DB_REP_LOGREADY
	DB_REP_LOGSONLY
	DB_REP_MASTER
	DB_REP_NEWMASTER
	DB_REP_NEWSITE
	DB_REP_NOBUFFER
	DB_REP_NOTPERM
	DB_REP_OUTDATED
	DB_REP_PAGEDONE
	DB_REP_PAGELOCKED
	DB_REP_PERMANENT
	DB_REP_REREQUEST
	DB_REP_STARTUPDONE
	DB_REP_UNAVAIL
	DB_REVSPLITOFF
	DB_RMW
	DB_RPCCLIENT
	DB_RPC_SERVERPROG
	DB_RPC_SERVERVERS
	DB_RUNRECOVERY
	DB_SALVAGE
	DB_SA_SKIPFIRSTKEY
	DB_SA_UNKNOWNKEY
	DB_SECONDARY_BAD
	DB_SEQUENCE_OLDVER
	DB_SEQUENCE_VERSION
	DB_SEQUENTIAL
	DB_SEQ_DEC
	DB_SEQ_INC
	DB_SEQ_RANGE_SET
	DB_SEQ_WRAP
	DB_SEQ_WRAPPED
	DB_SET
	DB_SET_LOCK_TIMEOUT
	DB_SET_LTE
	DB_SET_RANGE
	DB_SET_RECNO
	DB_SET_REG_TIMEOUT
	DB_SET_TXN_NOW
	DB_SET_TXN_TIMEOUT
	DB_SHALLOW_DUP
	DB_SNAPSHOT
	DB_SPARE_FLAG
	DB_STAT_ALL
	DB_STAT_CLEAR
	DB_STAT_LOCK_CONF
	DB_STAT_LOCK_LOCKERS
	DB_STAT_LOCK_OBJECTS
	DB_STAT_LOCK_PARAMS
	DB_STAT_MEMP_HASH
	DB_STAT_MEMP_NOERROR
	DB_STAT_NOERROR
	DB_STAT_SUBSYSTEM
	DB_ST_DUPOK
	DB_ST_DUPSET
	DB_ST_DUPSORT
	DB_ST_IS_RECNO
	DB_ST_OVFL_LEAF
	DB_ST_RECNUM
	DB_ST_RELEN
	DB_ST_TOPLEVEL
	DB_SURPRISE_KID
	DB_SWAPBYTES
	DB_SYSTEM_MEM
	DB_TEMPORARY
	DB_TEST_ELECTINIT
	DB_TEST_ELECTSEND
	DB_TEST_ELECTVOTE1
	DB_TEST_ELECTVOTE2
	DB_TEST_ELECTWAIT1
	DB_TEST_ELECTWAIT2
	DB_TEST_POSTDESTROY
	DB_TEST_POSTLOG
	DB_TEST_POSTLOGMETA
	DB_TEST_POSTOPEN
	DB_TEST_POSTRENAME
	DB_TEST_POSTSYNC
	DB_TEST_PREDESTROY
	DB_TEST_PREOPEN
	DB_TEST_PRERENAME
	DB_TEST_RECYCLE
	DB_TEST_SUBDB_LOCKS
	DB_THREAD
	DB_THREADID_STRLEN
	DB_TIMEOUT
	DB_TIME_NOTGRANTED
	DB_TRUNCATE
	DB_TXNMAGIC
	DB_TXNVERSION
	DB_TXN_ABORT
	DB_TXN_APPLY
	DB_TXN_BACKWARD_ROLL
	DB_TXN_BULK
	DB_TXN_CKP
	DB_TXN_FAMILY
	DB_TXN_FORWARD_ROLL
	DB_TXN_LOCK
	DB_TXN_LOCK_2PL
	DB_TXN_LOCK_MASK
	DB_TXN_LOCK_OPTIMIST
	DB_TXN_LOCK_OPTIMISTIC
	DB_TXN_LOG_MASK
	DB_TXN_LOG_REDO
	DB_TXN_LOG_UNDO
	DB_TXN_LOG_UNDOREDO
	DB_TXN_LOG_VERIFY
	DB_TXN_NOSYNC
	DB_TXN_NOT_DURABLE
	DB_TXN_NOWAIT
	DB_TXN_OPENFILES
	DB_TXN_POPENFILES
	DB_TXN_PRINT
	DB_TXN_REDO
	DB_TXN_SNAPSHOT
	DB_TXN_SYNC
	DB_TXN_TOKEN_SIZE
	DB_TXN_UNDO
	DB_TXN_WAIT
	DB_TXN_WRITE_NOSYNC
	DB_UNKNOWN
	DB_UNREF
	DB_UPDATE_SECONDARY
	DB_UPGRADE
	DB_USERCOPY_GETDATA
	DB_USERCOPY_SETDATA
	DB_USE_ENVIRON
	DB_USE_ENVIRON_ROOT
	DB_VERB_CHKPOINT
	DB_VERB_DEADLOCK
	DB_VERB_FILEOPS
	DB_VERB_FILEOPS_ALL
	DB_VERB_RECOVERY
	DB_VERB_REGISTER
	DB_VERB_REPLICATION
	DB_VERB_REPMGR_CONNFAIL
	DB_VERB_REPMGR_MISC
	DB_VERB_REP_ELECT
	DB_VERB_REP_LEASE
	DB_VERB_REP_MISC
	DB_VERB_REP_MSGS
	DB_VERB_REP_SYNC
	DB_VERB_REP_SYSTEM
	DB_VERB_REP_TEST
	DB_VERB_WAITSFOR
	DB_VERIFY
	DB_VERIFY_BAD
	DB_VERIFY_FATAL
	DB_VERIFY_PARTITION
	DB_VERSION_FAMILY
	DB_VERSION_FULL_STRING
	DB_VERSION_MAJOR
	DB_VERSION_MINOR
	DB_VERSION_MISMATCH
	DB_VERSION_PATCH
	DB_VERSION_RELEASE
	DB_VERSION_STRING
	DB_VRFY_FLAGMASK
	DB_WRITECURSOR
	DB_WRITELOCK
	DB_WRITEOPEN
	DB_WRNOSYNC
	DB_XA_CREATE
	DB_XIDDATASIZE
	DB_YIELDCPU
	DB_debug_FLAG
	DB_user_BEGIN
	LOGREC_ARG
	LOGREC_DATA
	LOGREC_DB
	LOGREC_DBOP
	LOGREC_DBT
	LOGREC_Done
	LOGREC_HDR
	LOGREC_LOCKS
	LOGREC_OP
	LOGREC_PGDBT
	LOGREC_PGDDBT
	LOGREC_PGLIST
	LOGREC_POINTER
	LOGREC_TIME
	);


=head1 NAME

  BDB::Wrapper
  Wrapper module for BerkeleyDB.pm for easy usage of it.
  This will make it easy to use BerkeleyDB.pm.
  You can protect bdb file from the concurrent access and you can use BerkeleyDB.pm with less difficulty.
  This module is used on http://sakuhindb.com/ and is developed based on the requirement.

  Attention: If you use this module for the specified Berkeley DB file,
  please use this module for all access to the bdb.
  By it, you can control lock and strasaction of bdb files.
  BDB_HOMEs are created under /tmp/bdb_home in default option.

  Japanese: http://sakuhindb.com/pj/6_B4C9CDFDBFCDA4B5A4F3/13/list.html
  English: http://en.sakuhindb.com/pe/Administrator/19/list.html

=cut

=head1 Example of basic usage

=cut

=pod

  #!/usr/bin/perl -w
  package test_bdb;
  use strict;
  use BDB::Wrapper;
  my $pro=new test_bdb;
  $pro->run();
  sub new(){
    my $self={};
    return bless $self;
  }

  sub run(){
    my $self=shift;
    $self->init_vars();
    $self->demo();
  }

  sub init_vars(){
    my $self=shift;
    $self->{'bdb'}='/tmp/test.bdb';
    $self->{'bdbw'}=new BDB::Wrapper;
  }

  sub demo(){
    my $self=shift;
    if(my $dbh=$self->{'bdbw'}->create_write_dbh($self->{'bdb'})){
      ###############
      # This is not must job but it will help to avoid unexpected result caused by unexpected process killing
      my $lock=$dbh->cds_lock();
      local $SIG{'INT'};
      local $SIG{'TERM'};
      local $SIG{'QUIT'};
      $SIG{'INT'}=$SIG{'TERM'}=$SIG{'QUIT'}=sub {$lock->cds_unlock();$dbh->db_close();};
      ###########
      if($dbh && $dbh->db_put('name', 'value')==0){
      }
      else{
        $lock->cds_unlock();
        $dbh->db_close() if $dbh;
        die 'Failed to put to '.$self->{'bdb'};
      }
      $lock->cds_unlock();
      $dbh->db_close() if $dbh;
    }

    if(my $dbh=$self->{'bdbw'}->create_read_dbh($self->{'bdb'})){
      my $value;
      if($dbh->db_get('name', $value)==0){
        print 'Name='.$name.' value='.$value."\n";
      }
      $dbh->db_close();
    }
  }

=cut

=head1 Example of using transaction

=cut

=pod

  # Transaction Usage
  #!/usr/bin/perl -w
  package bdb_write;
  use strict;
  use BDB::Wrapper;

  my $pro = new bdb_write;
  $pro->run();
  sub new(){
    my $self={};
    return bless $self;
  }

  sub run(){
    my $self=shift;
    $self->{'bdbw'}=new BDB::Wrapper;
    # If you want to create bdb_home with transaction log under /home/txn_data/bdb_home/$BDBFILENAME/
    my ($dbh, $env)=$self->{'bdbw'}->create_write_dbh({'bdb'=>'/tmp/bdb_write.bdb', 'txn'=>1});
    my $txn = $env->txn_begin(undef, DB_TXN_NOWAIT);
  
    my $cnt=0;
    for($i=0;$i<1000;$i++){
      $dbh->db_put($i, $i*rand());
      $cnt=$i;
      if($cnt && $cnt%100==0){
        $txn->txn_commit();
        $txn = $env->txn_begin(undef, DB_TXN_NOWAIT);
      }
    }

    $txn->txn_commit();
    $env->txn_checkpoint(1,1,0);
    $dbh->db_close();
    chmod 0666, '/tmp/bdb_write.bdb';
    print "Content-type:text/html\n\n";
    print $cnt."\n";
  }

=cut

=head1 methods

=head2 new

  Creates an object of BDB::Wrapper
  
  If you set {'ram'=>1}, you can use /dev/shm/bdb_home for storing locking file for BDB instead of /tmp/bdb_home/.
  1 is default value.
  
  If you set {'no_lock'=>1}, the control of concurrent access will not be used. So the lock files are also not created.
  0 is default value.
  
  If you set {'cache'=>$CACHE_SIZE}, you can allocate cache memory of the specified bytes for using bdb files.
  The value can be overwritten by the cache value of create_write_dbh
  undef is default value.
  
  If you set {'wait'=>wait_seconds}, you can specify the seconds in which dead lock will be removed.
  22 is default value.
  
  If you set {'transaction'=>transaction_root_dir}, all dbh object will be created in transaction mode unless you don\'t specify transaction root dir in each method.
  0 is default value.

=cut

sub new(){
  my $self={};
  my $class=shift;
  my $op_ref=shift;
  $self->{'lock_root'}='/tmp';
  $self->{'no_lock'}=0;
  $self->{'Flags'}='';
  $self->{'wait'}= 22;
  $self->{'default_txn_dir'}='/tmp/txn_data';
  while(my ($key, $value)=each %{$op_ref}){
    if($key eq 'ram'){
      if($value){
        $self->{'lock_root'}='/dev/shm';
      }
    }
    elsif($key eq 'cache'){
      $self->{'Cachesize'}=$value if(defined($value));
    }
    elsif($key eq 'Cachesize'){
      $self->{'Cachesize'}=$value if(defined($value));
    }
    elsif($key eq 'no_lock'){
      if($value){
        $self->{'no_lock'}++;
      }
    }
    elsif($key eq 'wait'){
      $self->{'wait'}=$value;
    }
    elsif($key eq 'transaction'){
      $self->{'transaction'}=$value;
      if($self->{'transaction'} && $self->{'transaction'}!~ m!^/.!){
	  $self->{'transaction'} = $self->{'default_txn_dir'};
      }
      if($self->{'transaction'}){
        $self->{'lock_root'}=$self->{'transaction'};
      }
    }
    elsif($key eq 'txn'){
      $self->{'transaction'}=$value;
      if($self->{'transaction'} && $self->{'transaction'}!~ m!^/.!){
	  $self->{'transaction'} = $self->{'default_txn_dir'};
      }
      if($self->{'transaction'}){
        $self->{'lock_root'}=$self->{'transaction'};
      }
    }
    else{
      my $error='Invalid option: key='.$key;
      if($value){
        $error.=', value='.$value;
      }
      Carp::croak($error);
    }
  }
  return bless $self;
}

1;
__END__

=head2 create_env

  Creates Environment for BerkeleyDB

  create_env({'bdb'=>$bdb,
    'no_lock='>0(default) or 1,
    'cache'=>undef(default) or integer,
    'error_log_file'=>undef or $error_log_file,
    'transaction'=> 0==undef or 1 or $transaction_root_dir
    });

  no_lock and cache will overwrite the value specified in new but used only in this env

=cut

sub create_env(){
  my $self=shift;
  my $op=shift;
  my $bdb=File::Spec->rel2abs($op->{'bdb'}) || return;
  my $no_lock=$op->{'no_lock'} || $self->{'no_lock'} || 0;
  my $transaction=undef;
  $self->{'error_log_file'}=$op->{'errore_log_file'};
  if(exists($op->{'transaction'})){
    $transaction=$op->{'transaction'};
  }
  elsif(exists($op->{'txn'})){
    $transaction=$op->{'txn'};
  }
  else{
    $transaction=$self->{'transaction'};
  }
  if($transaction && $transaction!~ m!^/.!){
    $transaction = $self->{'default_txn_dir'};
  }
  my $cache=$op->{'cache'} || $self->{'Cachesize'} || undef;
  my $env;
  my $Flags;
  if($transaction){
    if($transaction=~ m!^/.!){
      $Flags=DB_INIT_LOCK |DB_INIT_LOG | DB_INIT_TXN | DB_CREATE | DB_INIT_MPOOL;
    }
    else{
      croak("transaction parameter must be valid directory name.");
    }
  }
  elsif($no_lock){
    $Flags=DB_CREATE | DB_INIT_MPOOL;
  }
  else{
    $Flags=DB_INIT_CDB | DB_CREATE | DB_INIT_MPOOL;
  }
  my $lock_flag;
  my $home_dir=$self->get_bdb_home({'bdb'=>$bdb, 'transaction'=>$transaction});
  $home_dir=~ s!\.[^/\.\s]+$!!;
  unless(-d $home_dir){
    $self->rmkdir($home_dir);
  }
  
  $lock_flag=DB_LOCK_OLDEST unless($no_lock);
  if($cache){
    $env = new BerkeleyDB::Env {
      -Cachesize => $cache,
      -Flags => $Flags,
      -Home  => $home_dir,
      -LockDetect => $lock_flag,
      -Mode => 0666, 
      -ErrFile => $self->{'error_log_file'}
      };
  }
  else{
    $env = new BerkeleyDB::Env {
      -Flags => $Flags,
      -Home  => $home_dir,
      -LockDetect => $lock_flag,
      -Mode => 0666, 
      -ErrFile => $self->{'error_log_file'}
      };
  }
  # DB_CREATE is necessary for ccdb
  # Home is necessary for locking
  return $env;
}
# { DB_DATA_DIR => "/home/databases",                          DB_LOG_DIR  => "/home/logs",                          DB_TMP_DIR  => "/home/tmp"


=head2 create_dbh

  Not recommened method. Please use create_read_dbh() or create_write_dbh().
  Creates database handler for BerkeleyDB
  This will be obsolete due to too much simplicity, so please don\'t use.

=cut

sub create_dbh(){
  my $self=shift;
  my $bdb=File::Spec->rel2abs(shift);
  my $op=shift;
  return $self->create_write_dbh($bdb,$op);
}

=head2 create_hash_ref

  Not recommended method. Please use create_write_dbh().
  Creates database handler for BerkeleyDB
  This will be obsolete due to too much simplicity, so please don\'t use.

=cut

sub create_hash_ref(){
  my $self=shift;
  my $bdb=File::Spec->rel2abs(shift);
  my $op=shift;
  return $self->create_write_hash_ref($bdb, $op);
}

=head2 create_write_dbh

  This returns database handler for writing or ($database_handler, $env) depeinding on the request.

  $self->create_write_dbh({'bdb'=>$bdb,
    'cache'=>undef(default) or integer,
    'hash'=>0 or 1,
    'dont_try'=>0 or 1,
    'no_lock'=>0(default) or 1,
    'sort_code_ref'=>$sort_code_reference,
    'sort' or 'sort_num'=>0 or 1,
    'transaction'=> 0==undef or $transaction_root_dir,
    'reverse_cmp'=>0 or 1,
    'reverse' or 'reverse_num'=>0 or 1
    });

  In the default mode, BDB file will be created as Btree;

  If you set 'hash' 1, Hash BDB will be created.

  If you set 'dont_try' 1, this module won\'t try to unlock BDB if it detects the situation in which deadlock may be occuring.

  If you set sort_code_ref some code reference, you can set subroutine for sorting for Btree.

  If you set sort or sort_num 1, you can use sub {$_[0] <=> $_[1]} for sort_code_ref.

  If you set reverse or reverse_num 1, you can use sub {$_[1] <=> $_[0]} for sort_code_ref.

  If you set reverse_cmp 1, you can use sub {$_[1] cmp $_[0]} for sort_code_ref.

  If you set transaction for storing transaction log, transaction will be used and ($bdb_handler, $transaction_handler) will be returned.

=cut

sub create_write_dbh(){
  my $self=shift;
  my $bdb=shift;
  my $op='';
  if($bdb && ref($bdb) eq 'HASH'){
    $op=$bdb;
    $bdb=$op->{'bdb'};
  }
  else{
    $op=shift;
    $op->{'bdb'}=$bdb;
  }
  
  $op->{'bdb'}=File::Spec->rel2abs($op->{'bdb'});

  my $transaction = undef;
  my $hash=0;
  my $dont_try=0;
  my $sort_code_ref=undef;
  if(ref($op) eq 'HASH'){
    $hash=$op->{'hash'} || 0;
    $dont_try=$op->{'dont_try'} || 0;
    if(exists($op->{'transaction'})){
      $transaction = $op->{'transaction'};
    }
    elsif(exists($op->{'txn'})){
      $transaction = $op->{'txn'};
    }
    else{
      $transaction = $self->{'transaction'};
    }
    if($transaction && $transaction!~ m!^/.!){
      $transaction = $self->{'default_txn_dir'};
    }
    if($op->{'reverse'} || $op->{'reverse_num'}){
      $sort_code_ref=sub {$_[1] <=> $_[0]};
    }
    elsif($op->{'reverse_cmp'}){
      $sort_code_ref=sub {$_[1] cmp $_[0]};
    }
    elsif($op->{'sort'} || $op->{'sort_num'}){
      $sort_code_ref=sub {$_[0] <=> $_[1]};
    }
    else{
      $sort_code_ref=$op->{'sort_code_ref'};
    }
  }
  else{
    $hash=$op || 0;
    $dont_try=shift || 0;
    $sort_code_ref=shift;
  }
  my $env;
  
  if($op->{'no_env'}){
    $env=undef;
  }
  else{
    $env=$self->create_env({'bdb'=>$op->{'bdb'}, 'cache'=>$op->{'cache'}, 'no_lock'=>$op->{'no_lock'}, 'transaction'=>$transaction});
  }
  
  my $bdb_dir=$op->{'bdb'};
  $bdb_dir=~ s!/[^/]+$!!;
  
  my $dbh;
  
  if($no_lock){
    $self->rmkdir($bdb_dir);
    if($hash){
      $dbh =new BerkeleyDB::Hash {
        -Filename => $op->{'bdb'},
        -Flags => DB_CREATE,
        -Mode => 0666,
        -Env => $env
        };
    }
    else{
      $dbh =new BerkeleyDB::Btree {
        -Filename => $op->{'bdb'},
        -Flags => DB_CREATE,
        -Mode => 0666,
        -Env => $env,
        -Compare => $sort_code_ref
        };
    }
  }
  else{
    $SIG{ALRM} = sub { die "timeout"};
    eval{
      alarm($self->{'wait'});
      $self->rmkdir($bdb_dir);
      if($hash){
        $dbh =new BerkeleyDB::Hash {
          -Filename => $op->{'bdb'},
          -Flags => DB_CREATE,
          -Mode => 0666,
          -Env => $env
          };
      }
      else{
        $dbh =new BerkeleyDB::Btree {
          -Filename => $op->{'bdb'},
          -Flags => DB_CREATE,
          -Mode => 0666,
          -Env => $env,
          -Compare => $sort_code_ref
          };
      }
      alarm(0);
    };

    unless($dont_try){
      if($@){
        if($@ =~ /timeout/){
          $op->{'dont_try'}=1;
          $dont_try=1;
          my $home_dir=$self->get_bdb_home({'bdb'=>$bdb, 'transaction'=>$transaction});
          system('rm -rf '.$home_dir) if ($home_dir=~ m!^(?:/tmp|/dev/shm)! && -d $home_dir);
          if(ref($op) eq 'HASH'){
            $op->{'dont_try'}=1;
            return $self->create_write_dbh($op);
          }
          else{
            return $self->create_write_dbh($bdb, $dont_try, $sort_code_ref);
          }
        }
        else{
          alarm(0);
        }
      }
    }
  }
  
  if(!$dbh){
    {
      local $|=0;
      print "Content-type:text/html\n\nFailed to create write dbh for ";
      print $op->{'bdb'}.'<br />'."\n";
      print "Please inform this error to this site's administrator.";
      exit;
    }
  }
  else{
    if(wantarray){
      return ($dbh, $env);
    }
    else{
      return $dbh;
    }
  }
}


=head2 create_read_dbh

  This returns database handler for reading or ($database_handler, $env) depeinding on the request.

  $self->create_read_dbh({
    'bdb'=>$bdb,
    'hash'=>0 or 1,
    'dont_try'=>0 or 1,
    'sort_code_ref'=>$sort_code_reference,
    'sort' or 'sort_num'=>0 or 1,
    'reverse_cmp'=>0 or 1,
    'reverse' or 'reverse_num'=>0 or 1,
    'transaction'=> 0==undef or 1 or $transaction_root_dir
    });

  In the default mode, BDB file will be created as Btree;

  If you set 'hash' 1, Hash BDB will be created.

  If you set 'dont_try' 1, this module won\'t try to unlock BDB if it detects the situation in which deadlock may be occuring.

  If you set sort_code_ref some code reference, you can set subroutine for sorting for Btree.

  If you set sort or sort_num 1, you can use sub {$_[0] <=> $_[1]} for sort_code_ref.

  If you set reverse or reverse_num 1, you can use sub {$_[1] <=> $_[0]} for sort_code_ref.

  If you set reverse_cmp 1, you can use sub {$_[1] cmp $_[0]} for sort_code_ref.

  If you set transaction 1, you will user /tmp/txn_data for the storage of transaction.
=cut

sub create_read_dbh(){
  my $self=shift;
  my $bdb=shift;
  my $op='';
  my $transaction=undef;
  if($bdb && ref($bdb) eq 'HASH'){
    $op=$bdb;
    $bdb=$op->{'bdb'};
  }
  else{
    $op=shift;
    $op->{'bdb'}=$bdb;
  }
  $op->{'bdb'}=File::Spec->rel2abs($op->{'bdb'});
  
  my $hash=0;
  my $dont_try=0;
  my $sort_code_ref=undef;
  if(ref($op) eq 'HASH'){
      if(exists($op->{'transaction'})){
	  $transaction=$op->{'transaction'};
      }
      elsif(exists($op->{'txn'})){
	  $transaction=$op->{'txn'};
      }
      elsif($self->{'transaction'}){
	  $transaction=$self->{'transaction'};
      }
      
    if($transaction && $transaction!~ m!^/.!){
       $transaction=$self->{'default_txn_dir'};
 #  croak("transaction parameter must be valid directory name.");
    }
    
    $hash=$op->{'hash'} || 0;
    $dont_try=$op->{'dont_try'} || 0;
    if($op->{'reverse'} || $op->{'reverse_num'}){
      $sort_code_ref=sub {$_[1] <=> $_[0]};
    }
    elsif($op->{'reverse_cmp'}){
      $sort_code_ref=sub {$_[1] cmp $_[0]};
    }
    elsif($op->{'sort'} || $op->{'sort_num'}){
      $sort_code_ref=sub {$_[0] <=> $_[1]};
    }
    elsif($op->{'sort_code_ref'}){
      $sort_code_ref=$op->{'sort_code_ref'};
    }
  }
  else{
    $hash=$op || 0;
    $dont_try=shift || 0;
    $sort_code_ref=shift;
  }
  
  my $env='';
  if($op->{'use_env'} || $transaction){
    $env=$self->create_env({'bdb'=>$op->{'bdb'}, 'cache'=>$op->{'cache'}, 'no_lock'=>$op->{'no_lock'}, 'transaction'=>$transaction});
  }
  else{
    $env=undef;
  }
  
  my $dbh;
  local $SIG{ALRM} = sub { die "timeout"};
  eval{
    alarm($self->{'wait'});
    if($hash){
      $dbh =new BerkeleyDB::Hash {
        -Env=>$env,
        -Filename => $op->{'bdb'},
        -Flags    => DB_RDONLY
        };
    }
    else{
      $dbh =new BerkeleyDB::Btree {
        -Env=>$env,
        -Filename => $op->{'bdb'},
        -Flags    => DB_RDONLY,
        -Compare => $sort_code_ref
        };
    }
    alarm(0);
  };

  unless($dont_try){
    if($@){
      if($@ =~ /timeout/){
        $op->{'dont_try'}=1;
        $dont_try=1;
        $self->clear_bdb_home({'bdb'=>$op->{'bdb'}, 'transaction'=>$transaction});
        if(ref($op) eq 'HASH'){
          return $self->create_read_dbh($op->{'bdb'}, $op);
        }
        else{
          return $self->create_read_dbh($op->{'bdb'}, $hash, $dont_try, $sort_code_ref);
        }
      }
      else{
        alarm(0);
      }
    }
  }
    
  if(!$dbh){
    return;
  }
  else{
    if(wantarray){
      return ($dbh, $env);
    }
    else{
      return $dbh;
    }
  }
}


=head2 create_write_hash_ref

  Not recommended method. Please use create_write_dbh() instead of this method.
  This will creates hash for writing.

  $self->create_write_hash_ref({'bdb'=>$bdb,
    'hash'=>0 or 1,
    'dont_try'=>0 or 1,
    'sort_code_ref'=>$sort_code_reference,
    'sort' or 'sort_num'=>0 or 1,
    'reverse_cmp'=>0 or 1,
    'reverse' or 'reverse_num'=>0 or 1
    });

  In the default mode, BDB file will be created as Btree.

  If you set 'hash' 1, Hash BDB will be created.

  If you set 'dont_try' 1, this module won\'t try to unlock BDB if it detects the situation in which deadlock may be occuring.

  If you set sort_code_ref some code reference, you can set subroutine for sorting for Btree.

  If you set sort or sort_num 1, you can use sub {$_[0] <=> $_[1]} for sort_code_ref.

  If you set reverse or reverse_num 1, you can use sub {$_[1] <=> $_[0]} for sort_code_ref.

  If you set reverse_cmp 1, you can use sub {$_[1] cmp $_[0]} for sort_code_ref.

=cut

sub create_write_hash_ref(){
  my $self=shift;
  my $bdb=shift;
  my $op='';
  if($bdb && ref($bdb) eq 'HASH'){
    $op=$bdb;
    $bdb=$op->{'bdb'};
  }
  else{
    $op=shift;
  }
  $bdb=File::Spec->rel2abs($bdb);
  
  my $hash=0;
  my $dont_try=0;
  my $sort_code_ref=undef;
  if(ref($op) eq 'HASH'){
    $hash=$op->{'hash'} || 0;
    $dont_try=$op->{'dont_try'} || 0;
    if($op->{'reverse'} || $op->{'reverse_num'}){
      $sort_code_ref=sub {$_[1] <=> $_[0]};
    }
    elsif($op->{'reverse_cmp'}){
      $sort_code_ref=sub {$_[1] cmp $_[0]};
    }
    elsif($op->{'sort'} || $op->{'sort_num'}){
      $sort_code_ref=sub {$_[0] <=> $_[1]};
    }
    else{
      $sort_code_ref=$op->{'sort_code_ref'};
    }
  }
  else{
    $hash=$op || 0;
    $dont_try=shift || 0;
    $sort_code_ref=shift;
  }
  my $type='BerkeleyDB::Btree';
  if($hash){
    $type='BerkeleyDB::Hash';
  }
  my $env;
  if($self->{'op'}->{'no_env'}){
    $env=undef;
  }
  else{
    $env=$self->create_env({'bdb'=>$bdb});
  }

  my $transaction = undef;
  if(exists($op->{'transaction'})){
    $transaction = $op->{'transaction'};
  }
  elsif(exists($op->{'txn'})){
    $transaction = $op->{'txn'};
  }
  else{
    $transaction = $self->{'transaction'};
  }

  if($transaction && $transaction!~ m!^/.!){
    $transaction = $self->{'default_txn_dir'};
  }
  
  my $bdb_dir=$bdb;
  $bdb_dir=~ s!/[^/]+$!!;
  local $SIG{ALRM} = sub { die "timeout"};
  my %hash;
  eval{
    alarm($self->{'wait'});
    $self->rmkdir($bdb_dir);
    if($sort_code_ref && !$hash){
      tie %hash, $type,
      -Env=>$env,
      -Filename => $bdb,
      -Mode => 0666,
      -Flags    => DB_CREATE,
      -Compare => $sort_code_ref;
    }
    else{
      tie %hash, $type,
      -Env=>$env,
      -Filename => $bdb,
      -Mode => 0666,
      -Flags    => DB_CREATE;
    }
    alarm(0);
  };
  
  unless($dont_try){
    if($@){
      if($@ =~ /timeout/){
        $op->{'dont_try'}=1;
        $dont_try=1;
        my $home_dir=$self->get_bdb_home({'bdb'=>$bdb, 'transaction'=>$transaction});
        system('rm -rf '.$home_dir) if ($home_dir=~ m!^(?:/tmp|/dev/shm)!);
        if(ref($op) eq 'HASH'){
          return $self->create_write_hash_ref($bdb, $op);
        }
        else{
          return $self->create_write_hash_ref($bdb, $hash, $dont_try, $sort_code_ref);
        }
      }
      else{
        alarm(0);
      }
    }
  }
  return \%hash;
}

=head2 create_read_hash_ref

  Not recommended method. Please use create_read_dbh and cursor().
  This will creates database handler for reading.

  $self->create_read_hash_ref({
    'bdb'=>$bdb,
    'hash'=>0 or 1,
    'dont_try'=>0 or 1,
    'sort_code_ref'=>$sort_code_reference,
    'sort' or 'sort_num'=>0 or 1,
    'reverse_cmp'=>0 or 1,
    'reverse' or 'reverse_num'=>0 or 1
    });

  In the default mode, BDB file will be created as Btree.

  If you set 'hash' 1, Hash BDB will be created.

  If you set 'dont_try' 1, this module won\'t try to unlock BDB if it detects the situation in which deadlock may be occuring.

  If you set sort_code_ref some code reference, you can set subroutine for sorting for Btree.

  If you set sort or sort_num 1, you can use sub {$_[0] <=> $_[1]} for sort_code_ref.

  If you set reverse or reverse_num 1, you can use sub {$_[1] <=> $_[0]} for sort_code_ref.

  If you set reverse_cmp 1, you can use sub {$_[1] cmp $_[0]} for sort_code_ref.

  If you set use_env 1, you can use environment for this method.

=cut

sub create_read_hash_ref(){
  my $self=shift;
  my $bdb=shift;
  my $op='';
  if($bdb && ref($bdb) eq 'HASH'){
    $op=$bdb;
    $bdb=$op->{'bdb'};
  }
  else{
    $op=shift;
  }
  $bdb=File::Spec->rel2abs($bdb);
  
  my $hash=0;
  my $dont_try=0;
  my $sort_code_ref=undef;
  if(ref($op) eq 'HASH'){
    $hash=$op->{'hash'} || 0;
    $dont_try=$op->{'dont_try'} || 0;
    if($op->{'reverse'} || $op->{'reverse_num'}){
      $sort_code_ref=sub {$_[1] <=> $_[0]};
    }
    elsif($op->{'reverse_cmp'}){
      $sort_code_ref=sub {$_[1] cmp $_[0]};
    }
    elsif($op->{'sort'} || $op->{'sort_num'}){
      $sort_code_ref=sub {$_[0] <=> $_[1]};
    }
    else{
      $sort_code_ref=$op->{'sort_code_ref'};
    }
  }
  else{
    # Obsolete
    $hash=$op || 0;
    $dont_try=shift || 0;
    $sort_code_ref=shift;
  }
  my $type='BerkeleyDB::Btree';
  if($hash){
    $type='BerkeleyDB::Hash';
  }
  
  my $env='';
  if($op->{'use_env'}){
    $env=$self->create_env({'bdb'=>$bdb});
  }
  else{
    $env=undef;
  }
  
  my %hash;
  local $SIG{ALRM} = sub { die "timeout"};
  eval{
    alarm($self->{'wait'});
    if($sort_code_ref && !$hash){
      tie %hash, $type,
      -Env=>$env,
      -Filename => $bdb,
      -Flags    => DB_RDONLY,
      -Compare => $sort_code_ref;
    }
    else{
      tie %hash, $type,
      -Env=>$env,
      -Filename => $bdb,
      -Flags    => DB_RDONLY;
    }
    alarm(0);
  };
  
  unless($dont_try){
    if($@){
      if($@ =~ /timeout/){
        $op->{'dont_try'}=1;
        $dont_try=1;
        my $home_dir=$self->get_bdb_home({'bdb'=>$bdb, 'transaction'=>$transaction});
        system('rm -rf '.$home_dir) if($home_dir=~ m!^(?:/tmp|/dev/shm)!);
        if(ref($op) eq 'HASH'){
          return $self->create_read_hash_ref($bdb, $op);
        }
        else{
          return $self->create_read_hash_ref($bdb, $hash, $dont_try, $sort_code_ref);
        }
      }
      else{
        alarm(0);
      }
    }
  }
  return \%hash;
}

=head2 rmkdir

  Code from CGI::Accessup.
  This creates the specified directory recursively.

  rmkdir($dir);

=cut
sub rmkdir(){
  my $self=shift;
  my $path=shift;
  my $force=shift;
  if($path){
    $path=~ s!^\s+|\s+$!!gs;
    if($path=~ m![^/\.]!){
      my $target='';
      if($path=~ s!^([\./]+)!!){
        $target=$1;
      }
      while($path=~ s!^([^/]+)/?!!){
        $target.=$1;
        if($force && -f $target){
          unlink $target;
        }
        unless(-d $target){
          mkdir($target,0777) || Carp::carp("Failed to create ".$target);
          # for avoiding umask to mkdir
          chmod 0777, $target || Carp::carp("Failed to chmod ".$target);;
        }
        $target.='/';
      }
      return 1;
    }
  }
  return 0;
}


=head2 get_bdb_home

  This will return bdb_home.
  You may need the information for recovery and so on.

  get bdb_home({
    'bdb'=>$bdb,
    'transaction'=>$transaction
    });

  OR

  get_bdb_home($bdb);

=cut

sub get_bdb_home(){
  my $self=shift;
  my $op=shift;
  my $bdb='';
  my $transaction=undef;
  my $lock_root=$self->{'lock_root'};
  if($op && ref($op) eq 'HASH'){
    $bdb=$op->{'bdb'} || return;
    if(exists($op->{'transaction'})){
      $transaction=$op->{'transaction'};
    }
    elsif(exists($op->{'txn'})){
      $transaction=$op->{'txn'};
    }
    else{
      $transaction=$self->{'transaction'};
    }
  }
  else{
    $bdb=File::Spec->rel2abs($op) || return;
    $transaction=$self->{'transaction'};
  }
  if($transaction && $transaction!~ m!^/.!){
    $transaction = $self->{'default_txn_dir'};
  }
  if($transaction){
    $lock_root=$transaction;
  }
  $bdb=~ s!\.bdb$!!i;
  return $lock_root.'/bdb_home'.$bdb;
}


=head2 clear_bdb_home

  This will clear bdb_home.

  clear_bdb_home({
    'bdb'=>$bdb,
    'transaction' => 0==undef or $transaction_root_dir
    });

  OR

  clear_bdb_home($bdb);

=cut

sub clear_bdb_home(){
  my $self=shift;
  my $op=shift;
  my $bdb='';
  my $transaction=undef;
  my $lock_root=$self->{'lock_root'};
  if($op && ref($op) eq 'HASH'){
    $bdb=$op->{'bdb'} || return;
    if(exists($op->{'transaction'})){
      $transaction=$op->{'transaction'};
    }
    elsif(exists($op->{'txn'})){
      $transaction=$op->{'txn'};
    }
    else{
      $transaction=$self->{'transaction'};
    }

    if($transaction && $transaction!~ m!^/.!){
      $transaction = $self->{'default_txn_dir'};
#      croak("transaction parameter must be valid directory name.");
    }
    if($transaction){
      $lock_root=$transaction;
    }
  }
  else{
    $bdb=File::Spec->rel2abs($op) || return;
  }
  $bdb=~ s!\.bdb$!!i;
  my $dir=$lock_root.'/bdb_home'.$bdb;
  my $dh;
  opendir($dh, $dir);
  if($dh){
    while (my $file = readdir $dh){
      if(-f $dir.'/'.$file){
        unlink $dir.'/'.$file;
      }
    }
    closedir $dh;
    rmdir $dir;
  }
}

=head2 record_error

  This will record error message to /tmp/bdb_error.log if you don\'t specify error_log_file

  record_error({
    'msg'=>$error_message,
    'error_log_file'=>$error_log_file
    });

  OR

  record_error($error_msg)

=cut

sub record_error(){
  my $self=shift;
  my $op=shift || return;
  my $msg='';
  my $error_log_file='';
  
  if($op && ref($op) eq 'HASH'){
    $msg=$op->{'msg'};
    $error_log_file=$op->{'error_log_file'};
  }
  else{
    $msg=$op;
  }
  if(!$error_log_file){
    if($self->{'error_log_file'}){
      $error_log_file=$self->{'error_log_file'};
    }
    else{
      $error_log_file='/tmp/bdb_error.log';
    }
  }
  if(my $fh=new FileHandle('>> '.$error_log_file)){
    my ($in_sec,$in_min,$in_hour,$in_mday,$in_mon,$in_year,$in_wday)=localtime(CORE::time());
    $in_mon++;
    $in_year+=1900;
    $in_mon='0'.$in_mon if($in_mon<10);
    $in_mday='0'.$in_mday if($in_mday<10);
    $in_hour='0'.$in_hour if($in_hour<10);
    $in_min='0'.$in_min if($in_min<10);
    $in_sec='0'.$in_sec if($in_sec<10);
    print $fh $in_year.'/'.$in_mon.'/'.$in_mday.' '.$in_hour.':'.$in_min.':'.$in_sec."\t".$msg."\n";
    $fh->close();
  }
}
