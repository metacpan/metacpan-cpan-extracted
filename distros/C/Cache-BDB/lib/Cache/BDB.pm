package Cache::BDB;

use strict;
use warnings;

use BerkeleyDB;
use Storable;
use File::Path qw(mkpath);

our $VERSION = '0.04';

use constant DEFAULT_DB_TYPE => 'Btree';

#############################
# Construction/Destruction. #
#############################
 
sub new {
    my ($proto, %params) = @_;
    my $class = ref($proto) || $proto;

    die "$class requires Berkeley DB version 3 or greater"
      unless $BerkeleyDB::db_version >= 3;
    
    # can't do anything without at least these params
    die "$class: cache_root not specified" unless($params{cache_root});
    die "$class: namespace not specified" unless($params{namespace});

    my $cache_root = $params{cache_root};
    unless(-d $cache_root) {
      eval {
	mkpath($cache_root, 0, 0777);
      };
      if($@) {
	die "$class: cache_root '$cache_root' unavailable: $@";
      }
    }
 
    my $env = BerkeleyDB::Env->new(
				   -Home => $cache_root,
				   -Flags => 
				   (DB_INIT_CDB | DB_CREATE | DB_INIT_MPOOL),
				   -ErrPrefix => $class,
				   -ErrFile => *STDERR,
				   -SetFlags => 
				   $params{env_lock} ? DB_CDB_ALLDB : 0,
				   -Verbose => 1,
				  ) 
      or die "$class: Unable to create env: $BerkeleyDB::Error";

    my $type = join('::', 'BerkeleyDB', ($params{type} &&
					 ($params{type} eq 'Btree' ||
					  $params{type} eq 'Hash'  ||
					  $params{type} eq 'Recno')) ?
		    $params{type} : DEFAULT_DB_TYPE);

    my $fname =  $params{cache_file} || join('.', $params{namespace}, "db");

    my $db = $type->new(
		      -Env => $env,
		      -Subname => $params{namespace},
		      -Filename => $fname,
		      -Flags => DB_CREATE,
		      # -Pagesize => 8192,
		     );

    # make a second attempt to connect to the db. this should handle
    # the case where a cache was created with one type and connected
    # to again with a different type. should probably just be an
    # error, but just in case ...
    
    unless(defined $db ) {
      $db = BerkeleyDB::Unknown->new(
				     -Env => $env,
				     -Subname => $params{namespace},
				     -Filename => $fname,
				     #-Pagesize => 8192,
				    );
    }
  
    die "$class: Unable to open db: $BerkeleyDB::Error" unless defined $db;
  
    # eventually these should support user defined subs and/or
    # options as well.
    $db->filter_store_value( sub { $_ = Storable::freeze($_) });
    $db->filter_fetch_value( sub { $_ = Storable::thaw($_) });
  
    # sync the db for good measure.
    $db->db_sync();      
        
    my $self = {
		# private stuff
		__env => $env,
		__last_purge_time => time(),
		__type => $type, 
		__db => $db,

		# expiry/purge
		default_expires_in => $params{default_expires_in} || 0,
		auto_purge_interval => $params{auto_purge_interval} || 0,
		auto_purge_on_set => $params{auto_purge_on_set} || 0,
		auto_purge_on_get => $params{auto_purge_on_get} || 0,

		purge_on_init => $params{purge_on_init} || 0,
		purge_on_destroy => $params{purge_on_destroy} || 0,

		clear_on_init => $params{clear_on_init} || 0,
		clear_on_destroy => $params{clear_on_destroy} || 0,

		disable_auto_purge => $params{disable_auto_purge} || 0,

		# file/namespace
		namespace => $params{namespace},
		cache_root => $params{cache_root},

		# options
		disable_compact => $params{disable_compact},

	       };

    bless $self, $class;
    
    $self->clear() if $self->{clear_on_init};
    $self->purge() if $self->{purge_on_init};

    return $self;
}

sub DESTROY {
    my $self = shift;

    $self->clear() if $self->{clear_on_destroy};
    $self->purge() if $self->{purge_on_destroy};

    undef $self->{__db};
    undef $self->{__env};
}

*close = \&DESTROY;

##############################################
# Instance options and expiry configuration. #  
##############################################

sub namespace {
    my $self = shift;
    warn "namespace is read only" if shift;
    return $self->{namespace};
}

sub auto_purge_interval {
    my ($self, $interval) = @_;

    if(defined($interval)) {
	return undef unless $interval =~ /^\d+$/;
	$self->{auto_purge_interval} = $interval;
    }
    return $self->{auto_purge_interval};
}

sub auto_purge_on_set {
    my ($self, $v) = @_;
    if(defined($v)) {
	$self->{auto_purge_on_set} = $v;
    }
    return $self->{auto_purge_on_set};
}

sub auto_purge_on_get {
    my ($self, $v) = @_;
    if(defined($v)) {
	$self->{auto_purge_on_get} = $v;
    }
    return $self->{auto_purge_on_get};
}

#################################################
# Methods for setting and getting cached items. # 
#################################################

sub set {
    my ($self, $key, $value, $ttl) = @_;

    return 0 unless ($key && $value);

    my $db = $self->{__db};
    my $rv;

    my $now = time();

    if($self->{auto_purge_on_set}) {
       my $interval = $self->{auto_purge_interval};    
       if($now > ($self->{__last_purge_time} + $interval)) {
	 $self->purge();
	 $self->{__last_purge_time} = $now;
       }
     }
    
    $ttl ||= $self->{default_expires_in};
    my $expires = ($ttl) ? $now + $ttl : 0;
    
    my $data = {__expires => $expires,
		__set_time => $now, 
		__last_access_time => $now,
		__version => $Cache::BDB::VERSION,
		__data => $value};

    $rv = $db->db_put($key, $data);

    return $rv ? 0 : 1;
}

sub add {
  my ($self, $key, $value, $ttl) = @_;

  return $self->get($key) ? 0 : $self->set($key, $value, $ttl);
}

sub replace {
  my ($self, $key, $value, $ttl) = @_;

  return $self->get($key) ? $self->set($key, $value, $ttl) : 0;
}

sub get {
    my ($self, $key) = @_;

    return undef unless $key;
    my $db = $self->{__db};
    my $t = time();

    my $data;

    if($self->{auto_purge_on_get}) {
      my $interval = $self->{auto_purge_interval};
      if($t > ($self->{__last_purge_time} + $interval)) {
	$self->purge();
	$self->{__last_purge_time} = $t;
      }
    }
    
    my $rv = $db->db_get($key, $data);
    return undef if $rv == DB_NOTFOUND;
    return undef unless $data->{__data};

    if($self->__is_expired($data, $t)) {
      $self->remove($key) unless $self->{disable_auto_purge};
      return undef;
    } 
    # this is pretty slow, leaving it out for now. if i start supporting
    # access time related stuff i'll need to work on it.
    #      $self->_update_access_time($key, $data, $t); 
    
    return $data->{__data};
}

sub get_bulk {
    my $self = shift;
    my $t = time();
    my $count = 0;
    
    my $db = $self->{__db};
    my $cursor = $db->db_cursor();
    
    my %ret;
    my ($k, $v) = ('','');

    while($cursor->c_get($k, $v, DB_NEXT) == 0) {
      my $d = $self->get($k);
      $ret{$k} = $d if $d;
    }
    $cursor->c_close();

    return \%ret;
}

sub _update_access_time {
    my ($self, $key, $data, $t)  = @_;
    
    my $db = $self->{__db};
    $t ||= time();
    $data->{__last_access_time} = $t;

    my $rv = $db->db_put($key, $data);
    
    return $rv;
}

###########################
# Cache meta information. #
###########################

sub count {
    my $self = shift;
    my $total = 0;

    my $db = $self->{__db};
    my $stats = $db->db_stat;
    my $type = $db->type;

    $total =  ($type == DB_HASH) ? 
      $stats->{hash_ndata} : $stats->{bt_ndata};

    return $total;
}

sub size {
    my $self = shift;
    
    my $db = $self->{__db};

    eval { require Devel::Size };
    if($@) {
      warn "size() currently requires Devel::Size";
      return 0;
    }
    else {
      import Devel::Size qw(total_size);
    }
    
    my ($k, $v) = ('','');
    my $size = 0;

    my $cursor = $self->{__db}->db_cursor();
    while($cursor->c_get($k, $v, DB_NEXT) == 0) {
	$size += total_size($v->{__data});
    }

    $cursor->c_close();
    return $size;
}

##############################################
# Methods for removing items from the cache. #
##############################################

sub remove {
    my ($self, $key) = @_;

    my $rv;
    my $v = '';
    my $db = $self->{__db};
    $rv = $db->db_del($key);

    warn "compaction failed!" if $self->_compact();

    return $rv ? 0 : 1;
}

*delete = \&remove;  

sub clear {
    my $self = shift;
    my $rv;

    my $count = 0;
    my $db = $self->{__db};
    $rv = $db->truncate($count);

    warn "compaction failed!" if $self->_compact();

    return $count;
}

sub purge {
    my $self = shift;
    my $t = time();
    my $count = 0;
    
    my $db = $self->{__db};
    my $cursor = $db->db_cursor(DB_WRITECURSOR);

    my ($k, $v) = ('','');
    while($cursor->c_get($k, $v, DB_NEXT) == 0) {
      if($self->__is_expired($v, $t)) {
	$cursor->c_del();
	$count++;
      }
    }
    $cursor->c_close();

    warn "compaction failed!" if $self->_compact();

    return $count;
}

sub __is_expired {
    my ($self, $data, $t) = @_;
    $t ||= time();

    return 1 if($data->{__expires} && $data->{__expires} < $t);
    return 0;
}

sub is_expired {
    my ($self, $key) = @_;

    my $data;
    my $t = time();
    return 0 unless $key;
    my $db = $self->{__db};
    my $rv = $db->db_get($key, $data);

    return 0 unless $data;
    return $self->__is_expired($data, $t);
}

sub _compact {
  my $self = shift;

  my $rv = 0; # assume success, if compact isn't available pretend its cool
  my $db = $self->{__db};
  if($db->can('compact') && 
     $db->type == DB_BTREE && 
     !$self->{disable_compact}) {
    $rv = $db->compact(undef, undef, undef, DB_FREE_SPACE, undef);
  }
  return $rv;
}

1;
