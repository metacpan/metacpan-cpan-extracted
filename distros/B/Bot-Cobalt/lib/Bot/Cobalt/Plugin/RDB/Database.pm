package Bot::Cobalt::Plugin::RDB::Database;
$Bot::Cobalt::Plugin::RDB::Database::VERSION = '0.021003';
## Frontend to managing RDB-style Bot::Cobalt::DB instances
## I regret writing this.
##
## We may have a lot of RDBs.
## This plugin tries to make it easy to operate on them discretely
## with a minimum of angst in the frontend app.
##
## If there is no DB in our RDBDir named 'main' it is initialized.
##
## If an error occurs, the first argument returned will be boolean false.
## The error as a simple string is available via the 'Error' method.
## These values are only 'sort-of' human readable; they're holdovers from 
## the previous constant retvals, and typically translated into langset 
## RPLs by Plugin::RDB.
##
## Our RDB interfaces typically take RDB names; we map them to paths and 
## attempt to switch our ->{CURRENT} Bot::Cobalt::DB object appropriately.
##
## The frontend doesn't have to worry about dbopen/dbclose, which works 
## for RDBs because access is almost always a single operation and we 
## can afford to open / lock / access / unlock / close every call.

use v5.10;
use strictures 2;

use Carp;

use Bot::Cobalt::DB;
use Bot::Cobalt::Error;
use Bot::Cobalt::Utils qw/ glob_to_re_str /;

use Bot::Cobalt::Plugin::RDB::SearchCache;

use Path::Tiny;
use List::Util qw/shuffle/;
use Time::HiRes;
use Try::Tiny;

sub new {
  my $self = {};
  my $class = shift;
  bless $self, $class;

  my %opts = @_;
  
  my $core;
  
  if (ref $opts{core}) {
    $core = delete $opts{core};
  } else {
    require Bot::Cobalt::Core;
    $core = Bot::Cobalt::Core->instance;
  }

  $self->{core} = $core;

  my $rdbdir = path(
    delete $opts{RDBDir} || croak "new() needs a RDBDir"
  );

  $self->{RDBDir} = $rdbdir;
  
  $self->{CacheObj} = Bot::Cobalt::Plugin::RDB::SearchCache->new(
    MaxKeys => $opts{CacheKeys} // 30,
  );
  
  $core->log->debug("Using RDBDir $rdbdir");

  
  unless ($rdbdir->exists) {
    $core->log->debug("Did not find RDBDir $rdbdir, attempting mkpath");
    $rdbdir->mkpath;
  }

  unless ($rdbdir->is_dir) {
    confess "Found RDBDir $rdbdir but it is not a directory!";
  }
  
  unless ( $self->dbexists('main') ) {
    $core->log->debug("No main RDB found, creating one");

    try { 
      $self->createdb('main') 
    } catch {
      $core->log->warn("Failed to create 'main' RDB: $_")
    };
  }
  
  return $self
}

sub dbexists {
  my ($self, $rdb) = @_;
  $self->path_from_name($rdb)->exists
}

sub path_from_name {
  my ($self, $rdb) = @_;
  path( $self->{RDBDir} .'/'. $rdb .'.rdb' )
}

sub error {
  my ($self, $error) = @_;
  Bot::Cobalt::Error->new( $error )
}

sub createdb {
  my ($self, $rdb) = @_;
  
  die $self->error("RDB_INVALID_NAME")
    unless $rdb and $rdb =~ /^[A-Za-z0-9]+$/;

  die $self->error("RDB_EXISTS")
    if $self->dbexists($rdb);
  
  my $core = $self->{core};
  $core->log->debug("attempting to create RDB $rdb");
  
  my $path = $self->path_from_name($rdb);

  $self->_rdb_switch($rdb);
  my $db = $self->{CURRENT};

  unless ( ref $db ) {
    $core->log->error("Could not switch to RDB $rdb at $path");
    die $self->error("RDB_DBFAIL")
  }
  
  unless ( $db->dbopen ) {
    $core->log->error("dbopen failure for $rdb in createdb");
    die $self->error("RDB_DBFAIL")
  }
  
  $db->dbclose;
  
  $core->log->info("Created RDB $rdb");
  
  return 1
}

sub deldb {
  my ($self, $rdb) = @_;
  confess "No RDB specified" unless defined $rdb;

  my $core = $self->{core};

  die $self->error("RDB_INVALID_NAME")
    unless $rdb and $rdb =~ /^[A-Za-z0-9]+$/;

  die $self->error("RDB_NOSUCH")
    unless $self->dbexists($rdb);
  
  $self->_rdb_switch($rdb);
  my $db = $self->{CURRENT};

  unless ( ref $db ) {
    $core->log->error("deldb failure; cannot switch to $rdb");
    die $self->error("RDB_DBFAIL")
  }
  
  unless ( $db->dbopen ) {
    $core->log->error("dbopen failure for $rdb in deldb");
    $core->log->error("Refusing to unlink, admin should investigate.");
    die $self->error("RDB_DBFAIL")
  }

  $db->dbclose;

  $self->{CURRENT} = undef;

  undef $db;

  my $cache = $self->{CacheObj};
  $cache->invalidate($rdb);

  my $path = $self->path_from_name($rdb);
  unless ( unlink $path ) {
    $core->log->error("Cannot unlink RDB $rdb at $path: $!");
    die $self->error("RDB_FILEFAILURE")
  }
    
  $core->log->info("Deleted RDB $rdb");
  
  return 1
}

sub del {
  my ($self, $rdb, $key) = @_;
  confess "No RDB specified" unless defined $rdb;

  my $core = $self->{core};

  die $self->error("RDB_INVALID_NAME")
    unless $rdb and $rdb =~ /^[A-Za-z0-9]+$/;
  
  die $self->error("RDB_NOSUCH")
    unless $self->dbexists($rdb);
  
  $self->_rdb_switch($rdb);
  my $db = $self->{CURRENT};
  
  unless ( ref $db ) {
    $core->log->error("del failure; cannot switch to $rdb");
    die $self->error("RDB_DBFAIL")
  }
  
  unless ( $db->dbopen ) {
    $core->log->error("dbopen failure for $rdb in del");
    die $self->error("RDB_DBFAIL")
  }
  
  unless ( $db->get($key) ) {
    $db->dbclose;
    
    $core->log->debug("no such item: $key in $rdb");
    
    die $self->error("RDB_NOSUCH_ITEM")
  }
  
  unless ( $db->del($key) ) {
    $db->dbclose;

    $core->log->warn("failure in db->del for $key in $rdb");

    die $self->error("RDB_DBFAIL")
  }
  
  my $cache = $self->{CacheObj};
  $cache->invalidate($rdb);
  
  $db->dbclose;
  return 1
}

sub get {
  my ($self, $rdb, $key) = @_;
  confess "No RDB specified" unless defined $rdb;

  my $core = $self->{core};

  die $self->error("RDB_INVALID_NAME")
    unless $rdb and $rdb =~ /^[A-Za-z0-9]+$/;

  die $self->error("RDB_NOSUCH")
    unless $self->dbexists($rdb);
  
  $self->_rdb_switch($rdb);
  my $db = $self->{CURRENT};
  
  unless ( ref $db ) {
    $core->log->error("get failure; cannot switch to $rdb");
    die $self->error("RDB_DBFAIL")
  }
  
  unless ( $db->dbopen(ro => 1) ) {
    $core->log->error("dbopen failure for $rdb in get");
    die $self->error("RDB_DBFAIL")
  }
  
  my $value = $db->get($key);
  unless ( defined $value ) {
    $db->dbclose;
    die $self->error("RDB_NOSUCH_ITEM")
  }
  
  $db->dbclose;
  
  return $value
}

sub get_keys {
  my ($self, $rdb) = @_;
  confess "No RDB specified" unless defined $rdb;

  die $self->error("RDB_INVALID_NAME")
    unless $rdb and $rdb =~ /^[A-Za-z0-9]+$/;

  die $self->error("RDB_NOSUCH") 
    unless $self->dbexists($rdb);

  my $core = $self->{core};
  
  $self->_rdb_switch($rdb);
  my $db = $self->{CURRENT};

  unless ( ref $db ) {
    $core->log->error("get_keys failure; cannot switch to $rdb");
    die $self->error("RDB_DBFAIL")
  }
  
  unless ( $db->dbopen(ro => 1) ) {
    $core->log->error("dbopen failure for $rdb in get_keys");
    die $self->error("RDB_DBFAIL")
  }
  
  my @dbkeys = $db->dbkeys;
  $db->dbclose;

  return wantarray ? @dbkeys : scalar(@dbkeys)
}

sub put {
  my ($self, $rdb, $ref) = @_;

  confess "put() needs a RDB name and a reference" 
    unless defined $rdb and defined $ref;
  
  die $self->error("RDB_INVALID_NAME")
    unless $rdb and $rdb =~ /^[A-Za-z0-9]+$/;

  die $self->error("RDB_NOSUCH")
    unless $self->dbexists($rdb);
  
  my $core = $self->{core};
  
  $self->_rdb_switch($rdb);
  my $db = $self->{CURRENT};

  unless ( ref $db ) {
    $core->log->error("put failure; cannot switch to $rdb");
    die $self->error("RDB_DBFAIL")
  }
  
  unless ( $db->dbopen ) {
    $core->log->error("dbopen failure for $rdb in put");
    die $self->error("RDB_DBFAIL")
  }
  
  my $newkey = $self->_gen_unique_key;
  
  unless ( $db->put($newkey, $ref) ) {
    $db->dbclose;
    die $self->error("RDB_DBFAIL")
  }

  $db->dbclose;
  
  my $cache = $self->{CacheObj};
  $cache->invalidate($rdb);

  return $newkey
}

sub random {
  my ($self, $rdb) = @_;
  confess "No RDB specified" unless defined $rdb;
  
  die $self->error("RDB_INVALID_NAME")
    unless $rdb and $rdb =~ /^[A-Za-z0-9]+$/;

  die $self->error("RDB_NOSUCH")
    unless $self->dbexists($rdb);

  my $core = $self->{core};
  
  $self->_rdb_switch($rdb);
  my $db = $self->{CURRENT};

  unless ( ref $db ) {
    $core->log->error("random failure; cannot switch to $rdb");
    die $self->error("RDB_DBFAIL")
  }
  
  unless ( $db->dbopen(ro => 1) ) {
    $core->log->error("dbopen failure for $rdb in random");
    die $self->error("RDB_DBFAIL")
  }
  
  my @dbkeys = $db->dbkeys;
  unless (@dbkeys) {
    $db->dbclose;
    die $self->error("RDB_NOSUCH_ITEM")
  }
  
  my $randkey = $dbkeys[rand @dbkeys];
  my $ref = $db->get($randkey);

  unless (ref $ref) {
    $db->dbclose;
    $core->log->error("Broken DB? item $randkey in $rdb not a ref");
    die $self->error("RDB_DBFAIL");
  }
  $db->dbclose;
  
  return $ref
}

sub search {
  my ($self, $rdb, $glob, $wantone) = @_;
  confess "search() needs a RDB name and a glob" 
    unless defined $rdb and defined $glob;

  die $self->error("RDB_INVALID_NAME")
    unless $rdb and $rdb =~ /^[A-Za-z0-9]+$/;

  die $self->error("RDB_NOSUCH")
    unless $self->dbexists($rdb);

  my $core = $self->{core};
  
  $self->_rdb_switch($rdb);
  my $db = $self->{CURRENT};

  unless ( ref $db ) {
    $core->log->error("search failure; cannot switch to $rdb");
    die $self->error("RDB_DBFAIL")
  }
  
  ## hit search cache first
  my $cache = $self->{CacheObj};
  my @matches = $cache->fetch($rdb, $glob);
  if (@matches) {
    if ($wantone) {
      return (shuffle @matches)[-1]
    } else {
      return wantarray ? @matches : [ @matches ]
    }
  }

  my $re = glob_to_re_str($glob);
  $re = qr/$re/i;

  unless ( $db->dbopen(ro => 1) ) {
    $core->log->error("dbopen failure for $rdb in search");
    die $self->error("RDB_DBFAIL")
  }
  
  my @dbkeys = $db->dbkeys;
  for my $dbkey (shuffle @dbkeys) {
    my $ref = $db->get($dbkey) // next;
    my $str = ref $ref eq 'HASH' ? $ref->{String} : $ref->[0] ;

    if ($str =~ $re) {
      if ($wantone) {
        ## plugin only cares about one match, short-circuit
        $db->dbclose;
        return $dbkey
      } else {
        push(@matches, $dbkey);
      }
    }

  }
  
  $db->dbclose;

  ## WANTONE but we didn't find any, return undef
  return undef if $wantone;
  
  ## push back to cache
  $cache->cache($rdb, $glob, [ @matches ] );
  
  return wantarray ? @matches : [ @matches ]
}


sub cache_check {
  my ($self, $rdb, $glob) = @_;
  my $cache = $self->{CacheObj};
  
  my @matches = $cache->fetch($rdb, $glob);
  return @matches
}

sub cache_push {
  my ($self, $rdb, $glob, $ref) = @_;
  my $cache = $self->{CacheObj};
  
  $cache->cache($rdb, $glob, $ref);
}

sub _gen_unique_key {
  my ($self) = @_;

  my $db = $self->{CURRENT} 
           || croak "_gen_unique_key called but no db to check";

  my @v = ( 'a' .. 'f', 0 .. 9 );
  my $newkey = join '', map { $v[rand @v] } 1 .. 4;
  $newkey .= $v[rand @v] while exists $db->Tied->{$newkey};

  ## regen 0000 keys:
  $newkey =~ /^0+$/ ? $self->_gen_unique_key : $newkey
}

sub _rdb_switch {
  my ($self, $rdb) = @_;
  
  undef $self->{CURRENT};
  
  my $core = $self->{core};
  my $path = $self->path_from_name($rdb);
  unless ($path) {
    $core->log->error("_rdb_switch failed; no path for $rdb");
    return
  }
  
  $self->{CURRENT} = Bot::Cobalt::DB->new(
    File => $path,
  );
}

1;
__END__
