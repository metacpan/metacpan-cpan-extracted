package Ace;

use strict;
use Carp qw(croak carp cluck);
use Scalar::Util 'weaken';

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $Error $DEBUG_LEVEL);

use Data::Dumper;
use AutoLoader 'AUTOLOAD';
require Exporter;
use overload 
  '""'  => 'asString',
  'cmp' => 'cmp';

@ISA = qw(Exporter);

# Items to export into callers namespace by default.
@EXPORT = qw(STATUS_WAITING STATUS_PENDING STATUS_ERROR);

# Optional exports
@EXPORT_OK = qw(rearrange ACE_PARSE);
$VERSION = '1.92';

use constant STATUS_WAITING => 0;
use constant STATUS_PENDING => 1;
use constant STATUS_ERROR   => -1;
use constant ACE_PARSE      => 3;

use constant DEFAULT_PORT   => 200005;  # rpc server
use constant DEFAULT_SOCKET => 2005;    # socket server

require Ace::Iterator;
require Ace::Object;
eval qq{use Ace::Freesubs};  # XS file, may not be available

# Map database names to objects (to fix file-caching issue)
my %NAME2DB;

# internal cache of objects
my %MEMORY_CACHE;

my %DEFAULT_CACHE_PARAMETERS = (
				default_expires_in  => '1 day',
				auto_purge_interval => '12 hours',
				);

# Preloaded methods go here.
$Error = '';

# Pseudonyms and deprecated methods.
*list      = \&fetch;
*Ace::ERR  = *Error;

# now completely deprecated and gone
# *find_many = \&fetch_many;
# *models    = \&classes;

sub connect {
  my $class = shift;
  my ($host,$port,$user,$pass,$path,$program,
      $objclass,$timeout,$query_timeout,$database,
      $server_type,$url,$u,$p,$cache,$other);

  # one-argument single "URL" form
  if (@_ == 1) {
    return $class->connect(-url=>shift);
  }

  # multi-argument (traditional) form
  ($host,$port,$user,$pass,
   $path,$objclass,$timeout,$query_timeout,$url,$cache,$other) = 
     rearrange(['HOST','PORT','USER','PASS',
		'PATH',['CLASS','CLASSMAPPER'],'TIMEOUT',
		'QUERY_TIMEOUT','URL','CACHE'],@_);

  ($host,$port,$u,$pass,$p,$server_type) = $class->process_url($url) 
    or croak "Usage:  Ace->connect(-host=>\$host,-port=>\$port [,-path=>\$path]\n"
      if defined $url;

  if ($path) { # local database
    $server_type = 'Ace::Local';
  } else { # either RPC or socket server
    $host      ||= 'localhost';
    $user      ||= $u || '';
    $path      ||= $p || '';
    $port        ||= $server_type eq 'Ace::SocketServer' ? DEFAULT_SOCKET : DEFAULT_PORT;
    $query_timeout = 120 unless defined $query_timeout;
    $server_type ||= 'Ace::SocketServer' if $port <  100000;
    $server_type ||= 'Ace::RPC'          if $port >= 100000;
  }

  # we've normalized parameters, so do the actual connect
  eval "require $server_type" || croak "Module $server_type not loaded: $@";
  if ($path) {
    $database = $server_type->connect(-path=>$path,%$other);
  } else {
    $database = $server_type->connect($host,$port,$query_timeout,$user,$pass,%$other);
  }

  unless ($database) {
    $Ace::Error ||= "Couldn't open database";
    return;
  }

  my $contents = {
		  'database'=> $database,
		  'host'   => $host,
		  'port'   => $port,
		  'path'   => $path,
		  'class'  => $objclass || 'Ace::Object',
		  'timeout' => $query_timeout,
		  'user'    => $user,
		  'pass'    => $pass,
		  'other'  => $other,
		  'date_style' => 'java',
		  'auto_save' => 0,
		 };

  my $self = bless $contents,ref($class)||$class;

  $self->_create_cache($cache) if $cache;
  $self->name2db("$self",$self);
  return $self;
}

sub reopen {
  my $self = shift;
  return 1 if $self->ping;
  my $class = ref($self->{database});
  my $database;
  if ($self->{path}) {
    $database = $class->connect(-path=>$self->{path},%{$self->other});
  } else {
    $database = $class->connect($self->{host},$self->{port}, $self->{timeout},
				$self->{user},$self->{pass},%{$self->{other}});
  }
  unless ($database) {
    $Ace::Error = "Couldn't open database";
    return;
  }
  $self->{database} = $database;
  1;
}

sub class {
  my $self = shift;
  my $d = $self->{class};
  $self->{class} = shift if @_;
  $d;
}

sub class_for {
  my $self = shift;
  my ($class,$id) = @_;
  my $selected_class;

  if (my $selector = $self->class) {
    if (ref $selector eq 'HASH') {
      $selected_class = $selector->{$class} || $selector->{'_DEFAULT_'};
    }
    elsif ($selector->can('class_for')) {
      $selected_class = $selector->class_for($class,$id,$self);
    }
    elsif (!ref $selector) {
      $selected_class = $selector;
    }
    else {
      croak "$selector is neither a scalar, nor a HASH, nor an object that supports the class_for() method";  
    }
  }

  $selected_class ||= 'Ace::Object';

  eval "require $selected_class; 1;" || croak $@
    unless $selected_class->can('new');

  $selected_class;
}

sub process_url {
  my $class = shift;
  my $url = shift;
  my ($host,$port,$user,$pass,$path,$server_type) = ('','','','','','');

  if ($url) {  # look for host:port
    local $_ = $url;
    if (m!^rpcace://([^:]+):(\d+)$!) {  # rpcace://localhost:200005
      ($host,$port) = ($1,$2);
      $server_type = 'Ace::RPC';
    } elsif (m!^sace://([\w:]+)\@([^:]+):(\d+)$!) { # sace://user@localhost:2005
      ($user,$host,$port) = ($1,$2,$3);
      $server_type = 'Ace::SocketServer';
    } elsif (m!^sace://([^:]+):(\d+)$!) { # sace://localhost:2005
      ($host,$port) = ($1,$2);
      $server_type = 'Ace::SocketServer';
    } elsif (m!^tace:(/.+)$!) {           # tace:/path/to/database
      $path = $1;
      $server_type = 'Ace::Local';
    } elsif (m!^(/.+)$!) {                # /path/to/database
      $path = $1;
      $server_type = 'Ace::Local';
    } else {
      return;
    }
  }

  if ($user =~ /:/) {
    ($user,$pass) = split /:/,$user;
  }

  return ($host,$port,$user,$pass,$path,$server_type);  

}

# Return the low-level Ace::AceDB object
sub db {
  return $_[0]->{'database'};
}

# Fetch a model from the database.
# Since there are limited numbers of models, we cache
# the results internally.
sub model {
  my $self = shift;
  require Ace::Model;
  my $model       = shift;
  my $break_cycle = shift;  # for breaking cycles when following #includes
  my $key = join(':',$self,'MODEL',$model);
  $self->{'models'}{$model} ||= eval{$self->cache->get($key)};
  unless ($self->{models}{$model}) {
    $self->{models}{$model} =
      Ace::Model->new($self->raw_query("model \"$model\""),$self,$break_cycle);
    eval {$self->cache->set($key=>$self->{models}{$model})};
  }
  return $self->{'models'}{$model};
}

# cached get
# pass "1" for fill to get a full fill
# pass any other true value to get a tag fill
sub get {
  my $self = shift;
  my ($class,$name,$fill) = @_;

  # look in caches first
  my $obj = $self->memory_cache_fetch($class=>$name) 
    || $self->file_cache_fetch($class=>$name);
  return $obj if $obj;

  # _acedb_get() does the caching
  $obj = $self->_acedb_get($class,$name,$fill) or return;
  $obj;
}

sub _acedb_get {
  my $self = shift;
  my ($class,$name,$filltag) = @_;
  return unless $self->count($class,$name) >= 1;

  #return $self->{class}->new($class,$name,$self,1) unless $filltag;
  return ($self->_list)[0] unless $filltag;

  if (defined $filltag && $filltag eq '1') {  # full fill
    return $self->_fetch();
  } else {
    return $self->_fetch(undef,undef,$filltag);
  }
}


#### CACHE AND CARRY CODE ####
# Be very careful here.  The key used for the memory cache is in the format
# db:class:name, but the key used for the file cache is in the format class:name.
# The difference is that the filecache has a built-in namespace but the memory
# cache doesn't.
sub memory_cache_fetch {
  my $self = shift;
  my ($class,$name) = @_;
  my $key = join ":",$self,$class,$name;
  return unless defined $MEMORY_CACHE{$key};
  carp "memory_cache hit on $class:$name"
    if Ace->debug;
  return $MEMORY_CACHE{$key};
}

sub memory_cache_store {
  my $self = shift;
  croak "Usage: memory_cache_store(\$obj)" unless @_ == 1;
  my $obj = shift;
  my $key = join ':',$obj->db,$obj->class,$obj->name;
  return if exists $MEMORY_CACHE{$key};
  carp "memory_cache store on ",$obj->class,":",$obj->name if Ace->debug;
  weaken($MEMORY_CACHE{$key} = $obj);
}

sub memory_cache_clear {
    my $self = shift;
    %MEMORY_CACHE = ();
}

sub memory_cache_delete {
  my $package = shift;
  my $obj = shift or croak "Usage: memory_cache_delete(\$obj)";
  my $key = join ':',$obj->db,$obj->class,$obj->name;
  delete $MEMORY_CACHE{$key};
}

# Call as:
# $ace->file_cache_fetch($class=>$id)
sub file_cache_fetch {
  my $self = shift;
  my ($class,$name) = @_;
  my $key = join ':',$class,$name;
  my $cache = $self->cache or return;
  my $obj   = $cache->get($key);
  if ($obj && !exists $obj->{'.root'}) {  # consistency checks
    require Data::Dumper;
    warn "CACHE BUG! Discarding inconsistent object $obj\n";
    warn Data::Dumper->Dump([$obj],['obj']);
    $cache->remove($key);
    return;
  }
  warn "cache ",$obj?'hit':'miss'," on '$key'\n" if Ace->debug;
  $self->memory_cache_store($obj) if $obj;
  $obj;
}

# call as
# $ace->file_cache_store($obj);
sub file_cache_store {
  my $self = shift;
  my $obj  = shift;

  return unless $obj->name;

  my $key = join ':',$obj->class,$obj->name;
  my $cache = $self->cache or return;

  warn "caching $key obj=",overload::StrVal($obj),"\n" if Ace->debug;
  if ($key eq ':') {  # something badly wrong
    cluck "NULL OBJECT";
  }
  $cache->set($key,$obj);
}

sub file_cache_delete {
  my $self = shift;
  my $obj = shift;
  my $key = join ':',$obj->class,$obj->name;
  my $cache = $self->cache or return;

  carp "deleting $key obj=",overload::StrVal($obj),"\n" if Ace->debug;
  $cache->remove($key,$obj);
}

#### END: CACHE AND CARRY CODE ####


# Fetch one or a group of objects from the database
sub fetch {
  my $self = shift;
  my ($class,$pattern,$count,$offset,$query,$filled,$total,$filltag) =  
    rearrange(['CLASS',['NAME','PATTERN'],'COUNT','OFFSET','QUERY',
	       ['FILL','FILLED'],'TOTAL','FILLTAG'],@_);

  if (defined $class
      && defined $pattern
      && $pattern !~ /[\?\*]/
#      && !wantarray
     )  {
    return $self->get($class,$pattern,$filled);
  }

  $offset += 0;
  $pattern ||= '*';
  $pattern = Ace->freeprotect($pattern);
  if (defined $query) {
    $query = "query $query" unless $query=~/^query\s/;
  } elsif (defined $class) {
    $query = qq{find $class $pattern};
  } else {
    croak "must call fetch() with the -class or -query arguments";
  }


  my $r = $self->raw_query($query);

  my ($cnt) = $r =~ /Found (\d+) objects/m;
  $$total = $cnt if defined $total;

  # Scalar context and a pattern match operation.  Return the
  # object count without bothering to fetch the objects
  return $cnt if !wantarray and $pattern =~ /(?:[^\\]|^)[*?]/;

  my(@h);
  if ($filltag) {
    @h = $self->_fetch($count,$offset,$filltag);
  } else {
    @h = $filled ? $self->_fetch($count,$offset) : $self->_list($count,$offset);
  }

  return wantarray ? @h : $h[0];
}

sub cache    { 
  my $self = shift;
  my $d    = $self->{filecache};
  $self->{filecache} = shift if @_;
  $d;
}

sub _create_cache {
  my $self   = shift;
  my $params = shift;
  $params    = {} if $params and !ref $params;

  return unless eval {require Cache::SizeAwareFileCache};  # not installed

  (my $namespace = "$self") =~ s!/!_!g;
  my %cache_params = (
		      namespace    => $namespace,
		      %DEFAULT_CACHE_PARAMETERS,
		      %$params,
		     );
  my $cache_obj = Cache::SizeAwareFileCache->new(\%cache_params);
  $self->cache($cache_obj);
}

# class method
sub name2db {
  shift;
  my $name = shift;
  return unless defined $name;
  my $d = $NAME2DB{$name};
  # weaken($NAME2DB{$name} = shift) if @_;
  $NAME2DB{$name} = shift if @_;
  $d;
}

# make a new object using indicated class and name pattern
sub new {
  my $self = shift;
  my ($class,$pattern) = rearrange([['CLASS'],['NAME','PATTERN']],@_);
  croak "You must provide -class and -pattern arguments" 
    unless $class && $pattern;
  # escape % signs in the string
  $pattern = Ace->freeprotect($pattern);
  $pattern =~ s/(?<!\\)%/\\%/g;
  my $r = $self->raw_query("new $class $pattern");
  if (defined($r) and $r=~/write access/im) {  # this keeps changing
    $Ace::Error = "Write access denied";
    return;
  }

  unless ($r =~ /($class)\s+\"([^\"]+)\"$/im) {
    $Ace::Error = $r;
    return;
  }
  $self->fetch($1 => $2);
}

# perform an AQL query
sub aql {
  my $self = shift;
  my $query = shift;
  my $db = $self->db;
  my $r = $self->raw_query("aql -j $query");
  if ($r =~ /(AQL error.*)/) {
    $self->error($1);
    return;
  }
  my @r;
  foreach (split "\n",$r) {
    next if m!^//!;
    next if m!^\0!;
    my ($class,$id) = Ace->split($_);
    my @objects = map { $self->class_for($class,$id)->new(Ace->split($_),$self,1)} split "\t";
    push @r,\@objects;
  }
  return @r;
}

# Return the contents of a keyset.  Pattern matches are allowed, in which case
# the keysets will be merged.
sub keyset {
  my $self = shift;
  my $pattern = shift;
  $self->raw_query (qq{find keyset "$pattern"});
  $self->raw_query (qq{follow});
  return $self->_list;
}


#########################################################
# These functions are for low-level (non OO) access only.
# This is for low-level access only.
sub show {
    my ($self,$class,$pattern,$tag) = @_;
    $Ace::Error = '';
    return unless $self->count($class,$pattern);

    # if we get here, then we've got some data to return.
    my @result;
    my $ts = $self->{'timestamps'} ? '-T' : '';
    $self->{database}->query("show -j $ts $tag");
    my $result = $self->read_object;
    unless ($result =~ /(\d+) object dumped/m) {
	$Ace::Error = 'Unexpected close during show';
	return;
    }
    return grep (!m!^//!,split("\n\n",$result));
}

sub read_object {
    my $self = shift;
    return unless $self->{database};
    my $result;
    while ($self->{database}->status == STATUS_PENDING()) {
      my $data = $self->{database}->read();
#      $data =~ s/\0//g;  # get rid of nulls in the buffer
      $result .= $data if defined $data;
    }
    return $result;
}

# do a query, and return the result immediately
sub raw_query {
  my ($self,$query,$no_alert,$parse) = @_;
  $self->_alert_iterators unless $no_alert;
  $self->{database}->query($query, $parse ? ACE_PARSE : () );
  return $self->read_object;
}

# return the last error
sub error {
  my $class = shift;
  $Ace::Error = shift() if defined($_[0]);
  $Ace::Error=~s/\0//g;  # get rid of nulls
  return $Ace::Error;
}

# close the database
sub close {
  my $self = shift;
  $self->raw_query('save') if $self->auto_save;
  foreach (keys %{$self->{iterators}}) {
    $self->_unregister_iterator($_);
  }
  delete $self->{database};
}

sub DESTROY { 
  my $self = shift;
  return if caller() =~ /^Cache\:\:/;
  warn "$self->DESTROY at ", join ' ',caller() if Ace->debug;
  $self->close;
}


#####################################################################
###################### private routines #############################
sub rearrange {
    my($order,@param) = @_;
    return unless @param;
    my %param;

    if (ref $param[0] eq 'HASH') {
      %param = %{$param[0]};
    } else {
      return @param unless (defined($param[0]) && substr($param[0],0,1) eq '-');

      my $i;
      for ($i=0;$i<@param;$i+=2) {
        $param[$i]=~s/^\-//;     # get rid of initial - if present
        $param[$i]=~tr/a-z/A-Z/; # parameters are upper case
      }

      %param = @param;                # convert into associative array
    }

    my(@return_array);

    local($^W) = 0;
    my($key)='';
    foreach $key (@$order) {
        my($value);
        if (ref($key) eq 'ARRAY') {
            foreach (@$key) {
                last if defined($value);
                $value = $param{$_};
                delete $param{$_};
            }
        } else {
            $value = $param{$key};
            delete $param{$key};
        }
        push(@return_array,$value);
    }
    push (@return_array,\%param) if %param;
    return @return_array;
}

# do a query, but don't return the result
sub _query {
  my ($self,@query) = @_;
  $self->_alert_iterators;
  $self->{'database'}->query("@query");
}

# return a portion of the active list
sub _list {
  my $self = shift;
  my ($count,$offset) = @_;
  my (@result);
  my $query = 'list -j';
  $query .= " -b $offset" if defined $offset;
  $query .= " -c $count"  if defined $count;
  my $result = $self->raw_query($query);
  $result =~ s/\0//g;  # get rid of &$#&@( nulls
  foreach (split("\n",$result)) {
    my ($class,$name) = Ace->split($_);
    next unless $class and $name;
    my $obj = $self->memory_cache_fetch($class,$name);
    $obj  ||= $self->file_cache_fetch($class,$name);
    unless ($obj) {
      $obj = $self->class_for($class,$name)->new($class,$name,$self,1);
      $self->memory_cache_store($obj);
      $self->file_cache_store($obj);
    }
    push @result,$obj;
  }
  return @result;
}

# return a portion of the active list
sub _fetch {
  my $self = shift;
  my ($count,$start,$tag) = @_;
  my (@result);
  $tag = '' unless defined $tag;
  my $query = "show -j $tag";
  $query .= ' -T' if $self->{timestamps};
  $query .= " -b $start"  if defined $start;
  $query .= " -c $count"  if defined $count;
  $self->{database}->query($query);
  while (my @objects = $self->_fetch_chunk) {
    push (@result,@objects);
  }
  # copy tag into a portion of the tree
  if ($tag) {
    for my $tree (@result) {
      my $obj = $self->class_for($tree->class,$tree->name)->new($tree->class,$tree->name,$self,1);
      $obj->_attach_subtree($tag=>$tree);
      $tree = $obj;
    }
  }
  # now recache 'em
  for (@result) {
    if (my $obj = $self->memory_cache_store($_)) {
      %$obj = %$_ unless $obj->filled;  # contents copy -- replace partial object with full object
      $_ = $obj;
    } else {
      $self->memory_cache_store($_);
    }
  }
  return wantarray ? @result : $result[0];
}

sub _fetch_chunk {
  my $self = shift;
  return unless $self->{database}->status == STATUS_PENDING();
  my $result = $self->{database}->read();
  $result =~ s/\0//g;  # get rid of &$#&@!! nulls
  my @chunks = split("\n\n",$result);
  my @result;
  foreach (@chunks) {
    next if m!^//!;
    next unless /\S/;  # occasional empty lines
    my ($class,$id) = Ace->split($_); # /^\?([^?]+)\?([^?]+)\?/m;
    push(@result,$self->class_for($class,$id)->newFromText($_,$self));
  }
  return @result;
}

sub _alert_iterators {
  my $self = shift;
  foreach (keys %{$self->{iterators}}) {
    $self->{iterators}{$_}->invalidate if $self->{iterators}{$_};
  }
  undef $self->{active_list};
}

sub asString {
  my $self = shift;
  return "tace://$self->{path}" if $self->{'path'};
  my $server = $self->db && $self->db->isa('Ace::SocketServer') ? 'sace' : 'rpcace';
  return "$server://$self->{host}:$self->{port}" if $self->{'host'};
  return ref $self;
}

sub cmp {
  my ($self,$arg,$reversed) = @_;
  my $cmp;
  if (ref($arg) and $arg->isa('Ace')) {
    $cmp = $self->asString cmp $arg->asString;
  } else {
    $cmp = $self->asString cmp $arg;
  }
  return $reversed ? -$cmp : $cmp;
}


# Count the objects matching pattern without fetching them.
sub count {
  my $self = shift;
  my ($class,$pattern,$query) = rearrange(['CLASS',
					   ['NAME','PATTERN'],
					   'QUERY'],@_);
  $Ace::Error = '';

  # A special case occurs when we have already fetched this
  # object and it is already on the active list.  In this
  # case, we do not need to recount.
  $query   = '' unless defined $query;
  $pattern = '' unless defined $pattern;
  $class   = '' unless defined $class;

  my $active_tag = "$class$pattern$query";
  if (defined $self->{'active_list'} &&
      defined ($self->{'active_list'}->{$active_tag})) {
    return $self->{'active_list'}->{$active_tag};
  }

  if ($query) {
    $query = "query $query" unless $query=~/^query\s/;
  } else {
    $pattern =~ tr/\n//d;
    $pattern ||= '*';
    $pattern = Ace->freeprotect($pattern);
    $query = "find $class $pattern";
  }
  my $result = $self->raw_query($query);
#  unless ($result =~ /Found (\d+) objects/m) {
  unless ($result =~ /(\d+) Active Objects/m) {
    $Ace::Error = 'Unexpected close during find';
    return;
  }
  return $self->{'active_list'}->{$active_tag} = $1;
}

1;

__END__

=head1 NAME

Ace - Object-Oriented Access to ACEDB Databases

=head1 SYNOPSIS

    use Ace;
    # open a remote database connection
    $db = Ace->connect(-host => 'beta.crbm.cnrs-mop.fr',
                       -port => 20000100);

    # open a local database connection
    $local = Ace->connect(-path=>'~acedb/my_ace');

    # simple queries
    $sequence  = $db->fetch(Sequence => 'D12345');
    $count     = $db->count(Sequence => 'D*');
    @sequences = $db->fetch(Sequence => 'D*');
    $i         = $db->fetch_many(Sequence=>'*');  # fetch a cursor
    while ($obj = $i->next) {
       print $obj->asTable;
    }

    # complex queries
    $query = <<END;
    find Annotation Ready_for_submission ; follow gene ; 
    follow derived_sequence ; >DNA
    END
    @ready_dnas= $db->fetch(-query=>$query);

    $ready = $db->fetch_many(-query=>$query);
    while ($obj = $ready->next) {
        # do something with obj
    }

    # database cut and paste
    $sequence = $db->fetch(Sequence => 'D12345');
    $local_db->put($sequence);
    @sequences = $db->fetch(Sequence => 'D*');
    $local_db->put(@sequences);

    # Get errors
    print Ace->error;
    print $db->error;

=head1 DESCRIPTION

AcePerl provides an interface to the ACEDB object-oriented database.
Both read and write access is provided, and ACE objects are returned
as similarly-structured Perl objects.  Multiple databases can be
opened simultaneously.

You will interact with several Perl classes: I<Ace>, I<Ace::Object>,
I<Ace::Iterator>, I<Ace::Model>.  I<Ace> is the database accessor, and
can be used to open both remote Ace databases (running aceserver or
gifaceserver), and local ones.

I<Ace::Object> is the superclass for all objects returned from the
database.  I<Ace> and I<Ace::Object> are linked: if you retrieve an
Ace::Object from a particular database, it will store a reference to
the database and use it to fetch any subobjects contained within it.
You may make changes to the I<Ace::Object> and have those changes
written into the database.  You may also create I<Ace::Object>s from
scratch and store them in the database.

I<Ace::Iterator> is a utility class that acts as a database cursor for
long-running ACEDB queries.  I<Ace::Model> provides object-oriented
access to ACEDB's schema.

Internally, I<Ace> uses the I<Ace::Local> class for access to local
databases and I<Ace::AceDB> for access to remote databases.
Ordinarily you will not need to interact directly with either of these
classes.

=head1 CREATING NEW DATABASE CONNECTIONS

=head2 connect() -- multiple argument form

    # remote database
    $db = Ace->connect(-host  =>  'beta.crbm.cnrs-mop.fr',
                       -port  =>  20000100);

    # local (non-server) database
    $db = Ace->connect(-path  =>  '/usr/local/acedb);

Use Ace::connect() to establish a connection to a networked or local
AceDB database.  To establish a connection to an AceDB server, use the
B<-host> and/or B<-port> arguments.  For a local server, use the
B<-port> argument.  The database must be up and running on the
indicated host and port prior to connecting to an AceDB server.  The
full syntax is as follows:

    $db = Ace->connect(-host  =>  $host,
                       -port  =>  $port,
		       -path  =>  $database_path,
		       -program     => $local_connection_program
                       -classmapper =>  $object_class,
		       -timeout     => $timeout,
		       -query_timeout => $query_timeout
		       -cache        => {cache parameters},
		      );

The connect() method uses a named argument calling style, and
recognizes the following arguments:

=over 4

=item B<-host>, B<-port>

These arguments point to the host and port of an AceDB server.
AcePerl will use its internal compiled code to establish a connection
to the server unless explicitly overridden with the B<-program>
argument.

=item B<-path>

This argument indicates the path of an AceDB directory on the local
system.  It should point to the directory that contains the I<wspec>
subdirectory.  User name interpolations (~acedb) are OK.

=item B<-user>

Name of user to log in as (when using socket server B<only>).  If not
provided, will attempt an anonymous login.

=item B<-pass>

Password to log in with (when using socket server).

=item B<-url>

An Acedb URL that combines the server type, host, port, user and
password in a single string.  See the connect() method's "single
argument form" description.

=item B<-cache>

AcePerl can use the Cache::SizeAwareFileCache module to cache objects
to disk. This can result in dramatically increased performance in
environments such as web servers in which the same Acedb objects are
frequently reused.  To activate this mechanism, the
Cache::SizeAwareFileCache module must be installed, and you must pass
the -cache argument during the connect() call.

The value of -cache is a hash reference containing the arguments to be
passed to Cache::SizeAwareFileCache.  For example:

   -cache => {
              cache_root         => '/usr/tmp/acedb',
              cache_depth        => 4,
              default_expires_in => '1 hour'
              }

If not otherwise specified, the following cache parameters are assumed:

       Parameter               Default Value
       ---------               -------------
       namespace               Server URL (e.g. sace://localhost:2005)
       cache_root              /tmp/FileCache (dependent on system temp directory)
       default_expires_in      1 day
       auto_purge_interval     12 hours

By default, the cache is not size limited (the "max_size" property is
set to $NO_MAX_SIZE).  To adjust the size you may consider calling the
Ace object's cache() method to retrieve the physical cache and then
calling the cache object's limit_size($max_size) method from time to
time.  See L<Cache::SizeAwareFileCache> for more details.

=item B<-program>

By default AcePerl will use its internal compiled code calls to
establish a connection to Ace servers, and will launch a I<tace>
subprocess to communicate with local Ace databases.  The B<-program>
argument allows you to customize this behavior by forcing AcePerl to
use a local program to communicate with the database.  This argument
should point to an executable on your system.  You may use either a
complete path or a bare command name, in which case the PATH
environment variable will be consulted.  For example, you could force
AcePerl to use the I<aceclient> program to connect to the remote host
by connecting this way:

  $db = Ace->connect(-host => 'beta.crbm.cnrs-mop.fr',
                     -port => 20000100,
                     -program=>'aceclient');

=item B<-classmapper>

The optional B<-classmapper> argument (alias B<-class>) points to the
class you would like to return from database queries.  It is provided
for your use if you subclass Ace::Object.  For example, if you have
created a subclass of Ace::Object called Ace::Object::Graphics, you
can have the database return this subclass by default by connecting
this way:

  $db = Ace->connect(-host => 'beta.crbm.cnrs-mop.fr',
                     -port => 20000100,
	             -class=>'Ace::Object::Graphics');

The value of B<-class> can be a hash reference consisting of AceDB
class names as keys and Perl class names as values.  If a class name
does not exist in the hash, a key named _DEFAULT_ will be looked for.
If that does not exist, then Ace will default to Ace::Object.

The value of B<-class> can also be an object or a classname that
implements a class_for() method.  This method will receive three
arguments containing the AceDB class name, object ID and database
handle.  It should return a string indicating the perl class to
create.

=item B<-timeout>

If no response from the server is received within $timeout seconds,
the call will return an undefined value.  Internally timeout sets an
alarm and temporarily intercepts the ALRM signal.  You should be aware
of this if you use ALRM for your own purposes.

NOTE: this feature is temporarily disabled (as of version 1.40)
because it is generating unpredictable results when used with
Apache/mod_perl.

=item B<-query_timeout>

If any query takes longer than $query_timeout seconds, will return an
undefined value.  This value can only be set at connect time, and cannot
be changed once set.

=back

If arguments are omitted, they will default to the following values:

    -host          localhost
    -port          200005;
    -path          no default
    -program       tace
    -class         Ace::Object
    -timeout       25
    -query_timeout 120

If you prefer to use a more Smalltalk-like message-passing syntax, you
can open a connection this way too:

  $db = connect Ace -host=>'beta.crbm.cnrs-mop.fr',-port=>20000100;

The return value is an Ace handle to use to access the database, or
undef if the connection fails.  If the connection fails, an error
message can be retrieved by calling Ace->error.

You may check the status of a connection at any time with ping().  It
will return a true value if the database is still connected.  Note
that Ace will timeout clients that have been inactive for any length
of time.  Long-running clients should attempt to reestablish their 
connection if ping() returns false.

    $db->ping() || die "not connected";

You may perform low-level calls using the Ace client C API by calling
db().  This fetches an Ace::AceDB object.  See THE LOW LEVEL C API for
details on using this object.
 
    $low_level = $db->db();

=head2 connect() -- single argument form

  $db = Ace->connect('sace://stein.cshl.org:1880')

Ace->connect() also accepts a single argument form using a URL-type
syntax.  The general syntax is:

   protocol://hostname:port/path

The I<:port> and I</path> parts are protocol-dependent as described
above.

Protocols:

=over 4

=item sace://hostname:port

Connect to a socket server at the indicated hostname and port.  Example:

   sace://stein.cshl.org:1880

If not provided, the port defaults to 2005.

=item rpcace://hostname:port

Connect to an RPC server at the indicated hostname and RPC service number.  Example:

  rpcace://stein.cshl.org:400000

If not provided, the port defaults to 200005

=item tace:/path/to/database

Open up the local database at F</path/to/database> using tace.  Example:

  tace:/~acedb/elegans

=item /path/to/database

Same as the previous.

=back

=head2 close() Method

You can explicitly close a database by calling its close() method:

   $db->close();

This is not ordinarily necessary because the database will be
automatically close when it -- and all objects retrieved from it -- go
out of scope.

=head2 reopen() Method

The ACeDB socket server can time out.  The reopen() method will ping
the server and if it is not answering will reopen the connection.  If
the database is live (or could be resurrected), this method returns
true.

=head1 RETRIEVING ACEDB OBJECTS

Once you have established a connection and have an Ace databaes
handle, several methods can be used to query the ACE database to
retrieve objects.  You can then explore the objects, retrieve specific
fields from them, or update them using the I<Ace::Object> methods.
Please see L<Ace::Object>.

=head2 fetch() method

    $count   = $db->fetch($class,$name_pattern);
    $object  = $db->fetch($class,$name);
    @objects = $db->fetch($class,$name_pattern,[$count,$offset]);
    @objects = $db->fetch(-name=>$name_pattern,
                          -class=>$class
			  -count=>$count,
			  -offset=>$offset,
                          -fill=>$fill,
			  -filltag=>$tag,
	                  -total=>\$total);
    @objects = $db->fetch(-query=>$query);

Ace::fetch() retrieves objects from the database based on their class
and name.  You may retrieve a single object by requesting its name, or
a group of objects by fetching a name I<pattern>.  A pattern contains
one or more wildcard characters, where "*" stands for zero or more
characters, and "?" stands for any single character.

This method behaves differently depending on whether it is called in a
scalar or a list context, and whether it is asked to search for a name
pattern or a simple name.

When called with a class and a simple name, it returns the object
referenced by that time, or undef, if no such object exists.  In an
array context, it will return an empty list.

When called with a class and a name pattern in a list context, fetch()
returns the list of objects that match the name.  When called with a
pattern in a scalar context, fetch() returns the I<number> of objects
that match without actually retrieving them from the database.  Thus,
it is similar to count().

In the examples below, the first line of code will fetch the Sequence
object whose database ID is I<D12345>.  The second line will retrieve
all objects matching the pattern I<D1234*>.  The third line will
return the count of objects that match the same pattern.

   $object =  $db->fetch(Sequence => 'D12345');
   @objects = $db->fetch(Sequence => 'D1234*');
   $cnt =     $db->fetch(Sequence =>'D1234*');

A variety of communications and database errors may occur while
processing the request.  When this happens, undef or an empty list
will be returned, and a string describing the error can be retrieved
by calling Ace->error.

When retrieving database objects, it is possible to retrieve a
"filled" or an "unfilled" object.  A filled object contains the entire
contents of the object, including all tags and subtags.  In the case
of certain Sequence objects, this may be a significant amount of data.
Unfilled objects consist just of the object name.  They are filled in
from the database a little bit at a time as tags are requested.  By
default, fetch() returns the unfilled object.  This is usually a
performance win, but if you know in advance that you will be needing
the full contents of the retrieved object (for example, to display
them in a tree browser) it can be more efficient to fetch them in
filled mode. You do this by calling fetch() with the argument of
B<-fill> set to a true value.

The B<-filltag> argument, if provided, asks the database to fill in
the subtree anchored at the indicated tag.  This will improve
performance for frequently-accessed subtrees.  For example:

   @objects = $db->fetch(-name    => 'D123*',
                         -class   => 'Sequence',
                         -filltag => 'Visible');

This will fetch all Sequences named D123* and fill in their Visible
trees in a single operation.

Other arguments in the named parameter calling form are B<-count>, to
retrieve a certain maximum number of objects, and B<-offset>, to
retrieve objects beginning at the indicated offset into the list.  If
you want to limit the number of objects returned, but wish to learn
how many objects might have been retrieved, pass a reference to a
scalar variable in the B<-total> argument.  This will return the
object count.  This example shows how to fetch 100 Sequence
objects, starting at Sequence number 500:

  @some_sequences = $db->fetch('Sequence','*',100,500);

The next example uses the named argument form to fetch 100 Sequence
objects starting at Sequence number 500, and leave the total number of
Sequences in $total:

  @some_sequences = $db->fetch(-class  => 'Sequence',
	                       -count  => 100,
	                       -offset => 500,
	                       -total  => \$total);

Notice that if you leave out the B<-name> argument the "*" wildcard is 
assumed.

You may also pass an arbitrary Ace query string with the B<-query>
argument.  This will supersede any name and class you provide.
Example: 

  @ready_dnas= $db->fetch(-query=>
      'find Annotation Ready_for_submission ; follow gene ; 
       follow derived_sequence ; >DNA');

If your request is likely to retrieve very many objects, fetch() many
consume a lot of memory, even if B<-fill> is false.  Consider using
B<fetch_many()> instead (see below).  Also see the get() method, which
is equivalent to the simple two-argument form of fetch().

=item get() method

   $object = $db->get($class,$name [,$fill]);

The get() method will return one and only one AceDB object
identified by its class and name.  The optional $fill argument can be
used to control how much data is retrieved from the database. If $fill
is absent or undefined, then the method will return a lightweight
"stub" object that is filled with information as requested in a lazy
fashion. If $fill is the number "1" then the retrieved object contains
all the relevant information contained within the database.  Any other
true value of $fill will be treated as a tag name: the returned object
will be prefilled with the subtree to the right of that tag.

Examples:

   # return lightweight stub for Author object "Sulston JE."
   $author = $db->get(Author=>'Sulston JE');

   # return heavyweight object
   $author = $db->get(Author=>'Sulston JE',1);

   # return object containing the Address subtree
   $author = $db->get(Author=>'Sulston JE','Address');

The get() method is equivalent to this form of the fetch()
method:

   $object = $db->fetch($class=>$name);

=head2 aql() method

    $count   = $db->aql($aql_query);
    @objects = $db->aql($aql_query);

Ace::aql() will perform an AQL query on the database.  In a scalar
context it returns the number of rows returned.  In an array context
it returns a list of rows.  Each row is an anonymous array containing
the columns returned by the query as an Ace::Object.

If an AQL error is encountered, will return undef or an empty list and
set Ace->error to the error message.

Note that this routine is not optimized -- there is no iterator
defined.  All results are returned synchronously, leading to large
memory consumption for certain queries.

=head2 put() method

   $cnt = $db->put($obj1,$obj2,$obj3);

This method will put the list of objects into the database,
overwriting like-named objects if they are already there.  This can
be used to copy an object from one database to another, provided that
the models are compatible.

The method returns the count of objects successfully written into the
database.  In case of an error, processing will stop at the last
object successfully written and an error message will be placed in
Ace->error();

=head2 parse() method

  $object = $db->parse('data to parse');

This will parse the Ace tags contained within the "data to parse"
string, convert it into an object in the databse, and return the
resulting Ace::Object.  In case of a parse error, the undefined value
will be returned and a (hopefully informative) description of the
error will be returned by Ace->error().

For example:

  $author = $db->parse(<<END);
  Author : "Glimitz JR"
  Full_name "Jonathan R. Glimitz"
  Mail	"128 Boylston Street"
  Mail	"Boston, MA"
  Mail	"USA"
  Laboratory GM
  END

This method can also be used to parse several objects, but only the
last object successfully parsed will be returned.

=head2 parse_longtext() method

  $object = $db->parse($title,$text);

This will parse the long text (which may contain carriage returns and
other funny characters) and place it into the database with the given
title.  In case of a parse error, the undefined value will be returned
and a (hopefully informative) description of the error will be
returned by Ace->error(); otherwise, a LongText object will be returned.

For example:

  $author = $db->parse_longtext('A Novel Inhibitory Domain',<<END);
  We have discovered a novel inhibitory domain that inhibits
  many classes of proteases, including metallothioproteins.
  This inhibitory domain appears in three different gene families studied
  to date...
  END

=head2 parse_file() method

  @objects = $db->parse_file('/path/to/file');
  @objects = $db->parse_file('/path/to/file',1);

This will call parse() to parse each of the objects found in the
indicated .ace file, returning the list of objects successfully loaded
into the database.

By default, parsing will stop at the first object that causes a parse
error.  If you wish to forge on after an error, pass a true value as
the second argument to this method.

Any parse error messages are accumulated in Ace->error().

=head2 new() method

  $object = $db->new($class => $name);

This method creates a new object in the database of type $class and
name $name.  If successful, it returns the newly-created object.
Otherwise it returns undef and sets $db->error().

$name may contain sprintf()-style patterns.  If one of the patterns is
%d (or a variant), Acedb uses a class-specific unique numbering to return
a unique name.  For example:

  $paper = $db->new(Paper => 'wgb%06d');

The object is created in the database atomically.  There is no chance to rollback as there is
in Ace::Object's object editing methods.

See also the Ace::Object->add() and replace() methods.

=head2 list() method

    @objects = $db->list(class,pattern,[count,offset]);
    @objects = $db->list(-class=>$class,
                         -name=>$name_pattern,
                         -count=>$count,
                         -offset=>$offset);

This is a deprecated method.  Use fetch() instead.

=head2 count() method

    $count = $db->count($class,$pattern);
    $count = $db->count(-query=>$query);

This function queries the database for a list of objects matching the
specified class and pattern, and returns the object count.  For large
sets of objects this is much more time and memory effective than
fetching the entire list.

The class and name pattern are the same as the list() method above.

You may also provide a B<-query> argument to instead specify an
arbitrary ACE query such as "find Author COUNT Paper > 80".  See
find() below.

=head2 find() method

    @objects = $db->find($query_string);
    @objects = $db->find(-query => $query_string,
                         -offset=> $offset,
                         -count => $count
                         -fill  => $fill);

This allows you to pass arbitrary Ace query strings to the server and
retrieve all objects that are returned as a result.  For example, this
code fragment retrieves all papers written by Jean and Danielle
Thierry-Mieg.

    @papers = $db->find('author IS "Thierry-Mieg *" ; >Paper');

You can find the full query syntax reference guide plus multiple
examples at http://probe.nalusda.gov:8000/acedocs/index.html#query.

In the named parameter calling form, B<-count>, B<-offset>, and
B<-fill> have the same meanings as in B<fetch()>.

=head2 fetch_many() method

    $obj = $db->fetch_many($class,$pattern);

    $obj = $db->fetch_many(-class=>$class,
                           -name =>$pattern,
                           -fill =>$filled,
                           -chunksize=>$chunksize);

    $obj = $db->fetch_many(-query=>$query);

If you expect to retrieve many objects, you can fetch an iterator
across the data set.  This is friendly both in terms of network
bandwidth and memory consumption.  It is simple to use:

    $i = $db->fetch_many(Sequence,'*');  # all sequences!!!!
    while ($obj = $i->next) {
       print $obj->asTable;
    }

The iterator will return undef when it has finished iterating, and
cannot be used again.  You can have multiple iterators open at once
and they will operate independently of each other.

Like B<fetch()>, B<fetch_many()> takes an optional B<-fill> (or
B<-filled>) argument which retrieves the entire object rather than
just its name.  This is efficient on a network with high latency if 
you expect to be touching many parts of the object (rather than
just retrieving the value of a few tags).

B<fetch_many()> retrieves objects from the database in groups of a
certain maximum size, 40 by default.  This can be tuned using the
optional B<-chunksize> argument.  Chunksize is only a hint to the
database.  It may return fewer objects per transaction, particularly
if the objects are large.

You may provide raw Ace query string with the B<-query> argument.  If
present the B<-name> and B<-class> arguments will be ignored.

=head2 find_many() method

This is an alias for fetch_many().  It is now deprecated.

=head2 keyset() method

    @objects = $db->keyset($keyset_name);

This method returns all objects in a named keyset.  Wildcard
characters are accepted, in which case all keysets that match the
pattern will be retrieved and merged into a single list of unique
objects.

=head2 grep() method

    @objects = $db->grep($grep_string);
    $count   = $db->grep($grep_string);
    @objects = $db->grep(-pattern => $grep_string,
                         -offset=> $offset,
                         -count => $count,
                         -fill  => $fill,
                         -filltag => $filltag,
			 -total => \$total,
                         -long  => 1,
			);

This performs a "grep" on the database, returning all object names or
text that contain the indicated grep pattern.  In a scalar context
this call will return the number of matching objects.  In an array
context, the list of matching objects are retrieved.  There is also a
named-parameter form of the call, which allows you to specify the
number of objects to retrieve, the offset from the beginning of the
list to retrieve from, whether the retrieved objects should be filled
initially.  You can use B<-total> to discover the total number of
objects that match, while only retrieving a portion of the list.

By default, grep uses a fast search that only examines class names and
lexiques.  By providing a true value to the B<-long> parameter, you
can search inside LongText and other places that are not usually
touched on, at the expense of much more CPU time.

Due to "not listable" objects that may match during grep, the list of
objects one can retrieve may not always match the count.

=head2 model() method

  $model = $db->model('Author');

This will return an I<Ace::Model> object corresponding to the
indicated class.

=head2 new() method

   $obj = $db->new($class,$name);
   $obj = $db->new(-class=>$class,
                   -name=>$name);

Create a new object in the database with the indicated class and name
and return a pointer to it.  Will return undef if the object already
exists in the database.  The object isn't actually written into the database
until you call Ace::Object::commit().

=head2 raw_query() method

    $r = $db->raw_query('Model');

Send a command to the database and return its unprocessed output.
This method is necessary to gain access to features that are not yet
implemented in this module, such as model browsing and complex
queries.

=head2 classes() method

   @classes = $db->classes();
   @all_classes = $db->classes(1);

This method returns a list of all the object classes known to the
server.  In a list context it returns an array of class names.  In a
scalar context, it the number of classes defined in the database.

Ordinarily I<classes()> will return only those classes that are
exposed to the user interface for browsing, the so-called "visible"
classes.  Pass a true argument to the call to retrieve non-visible
classes as well.

=head2 class_count() method

   %classes = $db->class_count()

This returns a hash in which the keys are the class names and the
values are the total number of objects in that class.  All classes
are returned, including invisible ones.  Use this method if you need
to count all classes simultaneously.  If you only want to count one
or two classes, it may be more efficient to call I<count($class_name)>
instead.

This method transiently uses a lot of memory.  It should not be used
with Ace 4.5 servers, as they contain a memory leak in the counting
routine.

=head2 status() method

    %status = $db->status;
    $status = $db->status;

Returns various bits of status information from the server.  In an
array context, returns a hash of hashes.  In a scalar context, returns a
reference to a hash of hashes.  Keys and subkeys are as follows

   code
           program     name of acedb binary
           version     version of acedb binary
           build       build date of acedb binary in format Jan 25 2003 16:21:24

   database
           title       name of the database
           version     version of the database
           dbformat    database format version number
           directory   directory in which the database is stored
           session     session number
           user        user under which server is running
           write       whether the server has write access
           address     global address - not known if this is useful

   resources
           classes     number of classes defined
           keys        number of keys defined
           memory      amount of memory used by acedb objects (bytes)

For example, to get the program version:

   my $version = $db->status->{code}{version};

=head2 title() method

    my $title = $db->title

Returns the version of the current database, equivalent
to $db->status->{database}{title};

=head2 version() method

    my $version = $db->version;

Returns the version of the current database, equivalent 
to $db->status->{database}{version};

=head2 date_style() method

  $style = $db->date_style();
  $style = $db->date_style('ace');
  $style = $db->date_style('java');

For historical reasons, AceDB can display dates using either of two
different formats.  The first format, which I call "ace" style, puts
the year first, as in "1997-10-01".  The second format, which I call
"java" style, puts the day first, as in "01 Oct 1997 00:00:00" (this
is also the style recommended for Internet dates).  The default is to
use the latter notation.

B<date_style()> can be used to set or retrieve the current style.
Called with no arguments, it returns the current style, which will be
one of "ace" or "java."  Called with an argument, it will set the
style to one or the other.

=head2 timestamps() method

  $timestamps_on = $db->timestamps();
  $db->timestamps(1);

Whenever a data object is updated, AceDB records the time and date of
the update, and the user ID it was running under.  Ordinarily, the
retrieval of timestamp information is suppressed to conserve memory
and bandwidth.  To turn on timestamps, call the B<timestamps()> method 
with a true value.  You can retrieve the current value of the setting
by calling the method with no arguments.

Note that activating timestamps disables some of the speed
optimizations in AcePerl.  Thus they should only be activated if you
really need the information.

=head2 auto_save()

Sets or queries the I<auto_save> variable.  If true, the "save"
command will be issued automatically before the connection to the
database is severed.  The default is true.

Examples:

   $db->auto_save(1);
   $flag = $db->auto_save;

=head2 error() method

    Ace->error;

This returns the last error message.  Like UNIX errno, this variable
is not reset between calls, so its contents are only valid after a
method call has returned a result value indicating a failure.

For your convenience, you can call error() in any of several ways:

    print Ace->error();
    print $db->error();  # $db is an Ace database handle
    print $obj->error(); # $object is an Ace::Object

There's also a global named $Ace::Error that you are free to use.

=head2 datetime() and date()

  $datetime = Ace->datetime($time);
  $today    = Ace->datetime();
  $date     = Ace->date($time);
  $today    = Ace->date([$time]);

These convenience functions convert the UNIX timestamp given by $time
(seconds since the epoch) into a datetime string in the format that
ACEDB requires.  date() will truncate the time portion.

If not provided, $time defaults to localtime().

=head1 OTHER METHODS

=head2 debug()

  $debug_level = Ace->debug([$new_level])

This class method gets or sets the debug level.  Higher integers
increase verbosity.  0 or undef turns off debug messages.

=head2 name2db()

 $db = Ace->name2db($name [,$database])

This class method associates a database URL with an Ace database
object. This is used internally by the Ace::Object class in order to
discover what database they "belong" to.

=head2 cache()

Get or set the Cache::SizeAwareFileCache object, if one has been
created.

=head2 memory_cache_fetch()

  $obj = $db->memory_cache_fetch($class,$name)

Given an object class and name return a copy of the object from the
in-memory cache.  The object will only be cached if a copy of the
object already exists in memory space.  This is ordinarily called
internally.

=head2 memory_cache_store($obj)

Store an object into the memory cache.  This is ordinarily called
internally.

=head2 memory_cache_delete($obj)

Delete an object from the memory cache. This is ordinarily called
internally.

=head2 memory_cache_clear()

Completely clears the memory cache.

=head2 file_cache_fetch()

  $obj = $db->file_cache_fetch($class,$name)

Given an object class and name return a copy of the object from the
file cache.  This is ordinarily called internally.

=head2 file_cache_store($obj)

Store an object into the file cache.  This is ordinarily called
internally.

=head2 file_cache_delete($obj)

Delete an object from the file cache.  This is ordinarily called
internally.

=head1 THE LOW LEVEL C API

Internally Ace.pm makes C-language calls to libace to send query
strings to the server and to retrieve the results.  The class that
exports the low-level calls is named Ace::AceDB.

The following methods are available in Ace::AceDB:

=over 4

=item new($host,$port,$query_timeout)

Connect to the host $host at port $port. Queries will time out after
$query_timeout seconds.  If timeout is not specified, it defaults to
120 (two minutes).

If successful, this call returns an Ace::AceDB connection object.
Otherwise, it returns undef.  Example:

  $acedb = Ace::AceDB->new('localhost',200005,5) 
           || die "Couldn't connect";

The Ace::AceDB object can also be accessed from the high-level Ace
interface by calling the ACE::db() method:

  $db = Ace->new(-host=>'localhost',-port=>200005);
  $acedb = $db->db();

=item query($request)

Send the query string $request to the server and return a true value
if successful.  You must then call read() repeatedly in order to fetch
the query result.

=item read()

Read the result from the last query sent to the server and return it
as a string.  ACE may return the result in pieces, breaking between
whole objects.  You may need to read repeatedly in order to fetch the
entire result.  Canonical example:

  $acedb->query("find Sequence D*");
  die "Got an error ",$acedb->error() if $acedb->status == STATUS_ERROR;
  while ($acedb->status == STATUS_PENDING) {
     $result .= $acedb->read;
  }

=item status()

Return the status code from the last operation.  Status codes are
exported by default when you B<use> Ace.pm.  The status codes you may
see are:

  STATUS_WAITING    The server is waiting for a query.
  STATUS_PENDING    A query has been sent and Ace is waiting for
                    you to read() the result.
  STATUS_ERROR      A communications or syntax error has occurred

=item error()

Returns a more detailed error code supplied by the Ace server.  Check
this value when STATUS_ERROR has been returned.  These constants are
also exported by default.  Possible values:

 ACE_INVALID
 ACE_OUTOFCONTEXT
 ACE_SYNTAXERROR
 ACE_UNRECOGNIZED

Please see the ace client library documentation for a full description
of these error codes and their significance.

=item encore()

This method may return true after you have performed one or more
read() operations, and indicates that there is more data to read.  You
will not ordinarily have to call this method.

=back

=head1 BUGS

1. The ACE model should be consulted prior to updating the database.

2. There is no automatic recovery from connection errors.

3. Debugging has only one level of verbosity, despite the best
of intentions.

4. Performance is poor when fetching big objects, because of 
many object references that must be created.  This could be
improved.

5. When called in an array context at("tag[0]") should return the
current tag's entire column.  It returns the current subtree instead.

6. There is no way to add comments to objects.

7. When timestamps are active, many optimizations are disabled. 

8. Item number eight is still missing.

=head1 SEE ALSO

L<Ace::Object>, L<Ace::Local>, L<Ace::Model>,
L<Ace::Sequence>,L<Ace::Sequence::Multi>.

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org> with extensive help from Jean
Thierry-Mieg <mieg@kaa.crbm.cnrs-mop.fr>

Copyright (c) 1997-1998 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

# -------------------- AUTOLOADED SUBS ------------------

sub debug {
  my $package = shift;
  my $d = $DEBUG_LEVEL;
  $DEBUG_LEVEL = shift if @_;
  $d;
}

# Return true if the database is still connected.  This is oddly convoluted
# because there are numerous things that can go wrong, including:
#   1. server has gone away
#   2. server has timed out our connection! (grrrrr)
#   3. communications channel contains unread garbage and is in an inconsistent state
sub ping {
  my $self = shift;
  local($SIG{PIPE})='IGNORE';  # so we don't get a fatal exception during the check
  my $result = $self->raw_query('');
  return unless $result;  # server has gone away
  return if $result=~/broken connection|client time out/;  # server has timed us out  
  return unless $self->{database}->status() == STATUS_WAITING(); #communications oddness
  return 1;
}

# Get or set the display style for dates
sub date_style {
  my $self = shift;
  $self->{'date_style'} = $_[0] if defined $_[0];
  return $self->{'date_style'};
}

# Get or set whether we retrieve timestamps
sub timestamps {
  my $self = shift;
  $self->{'timestamps'} = $_[0] if defined $_[0];
  return $self->{'timestamps'};
}

# Add one or more objects to the database
sub put {
  my $self = shift;
  my @objects = @_;
  my $count = 0;
  $Ace::Error = '';
  foreach my $object (@objects) {
    croak "Can't put a non-Ace object into an Ace database"
      unless $object->isa('Ace::Object');
    croak "Can't put a non-object into a database"
      unless $object->isObject;
    $object = $object->fetch unless $object->isRoot;  # make sure we're putting root object
    my $data = $object->asAce;
    $data =~ s/\n/; /mg;
    my $result = $self->raw_query("parse = $data");
    $Ace::Error = $result if $result =~ /sorry|parse error/mi;
    return $count if $Ace::Error;
    $count++;  # bump if succesful
  }
  return $count;
}

# Parse a single object and return the result as an object
sub parse {
  my $self = shift;
  my $ace_data = shift;
  my @lines = split("\n",$ace_data);
  foreach (@lines) { s/;/\\;/;  } # protect semicolons  
  my $query = join("; ",@lines);
  my $result = $self->raw_query("parse = $query");
  $Ace::Error = $result=~/sorry|parse error/mi ? $result : '';
  my @results = $self->_list(1,0);
  return $results[0];
}

# Parse a single object as longtext and return the result
# as an object
sub parse_longtext {
  my $self  = shift;
  my ($title,$body) = @_;
      my $mm = "parse =
Longtext $title
$body
***LongTextEnd***
" ;
  $mm =~ s/\//\\\//g ;
  $mm =~ s/\n/\\n/g ;
  $mm .= "\n" ;
  my $result = $self->raw_query($mm) ;
  $Ace::Error = $result=~/sorry|parse error/mi ? $result : '';
  my @results = $self->_list(1,0);
  return $results[0];
}


# Parse a file and return all the results
sub parse_file {
  my $self = shift;
  my ($file,$keepgoing) = @_;
  local(*ACE);
  local($/) = '';  # paragraph mode
  my(@objects,$errors);
  open(ACE,$file) || croak "$file: $!";
  while (<ACE>) {
    chomp;
    my $obj = $self->parse($_);
    unless ($obj) {
      $errors .= $Ace::Error;  # keep track of errors
      last unless $keepgoing;
    }
    push(@objects,$obj);
  }
  close ACE;
  $Ace::Error = $errors;
  return @objects;
}

# Create a new Ace::Object in the indicated database
# (doesn't actually write into database until you do a commit)
sub new {
  my $self = shift;
  my ($class,$name) = rearrange([qw/CLASS NAME/],@_);
  return if $self->fetch($class,$name);
  my $obj = $self->class_for($class,$name)->new($class,$name,$self);
  return $obj;
}

# Return the layout, which contains classes that should be displayed
sub layout {
  my $self = shift;
  my $result = $self->raw_query('layout');
  $result=~s{\n(\s*\n|//.*\n|\0)+\Z}{}m;  # get rid of extraneous information
  $result;
}

# Return a hash of all the classes and the number of objects in each
sub class_count {
  my $self = shift;
  return $self->raw_query('classes') =~ /^\s+(\S+) (\d+)/gm;
}

# Return a hash of miscellaneous status information from the server
# (to be expanded later)
sub status {
  my $self = shift;
  my $data = $self->raw_query('status');
  study $data;

  my %status;

  # -Code section
  my ($program)    = $data=~/Program:\s+(.+)/m;
  my ($aceversion) = $data=~/Version:\s+(.+)/m;
  my ($build)      = $data=~/Build:\s+(.+)/m;
  $status{code}    = { program=>$program,
		       version=>$aceversion,
		       build  =>$build};

  # -Database section
  my ($title)      = $data=~/Title:\s+(.+)/m;
  my ($name)       = $data=~/Name:\s+(.+)/m;
  my ($release)    = $data=~/Release:\s+(.+)/m;
  my ($directory)  = $data=~/Directory:\s+(.+)/m;
  my ($session)    = $data=~/Session:\s+(\d+)/m;
  my ($user)       = $data=~/User:\s+(.+)/m;
  my ($write)      = $data=~/Write Access:\s+(.+)/m;
  my ($address)    = $data=~/Global Address:\s+(\d+)/m;
  $status{database} = {
		       title     => $title,
		       version   => $name,
		       dbformat  => $release,
		       directory => $directory,
		       session   => $session,
		       user      => $user,
		       write     => $write,
		       address   => $address,
		       };

  # other info - not all
  my ($classes)   = $data=~/classes:\s+(\d+)/;
  my ($keys)      = $data=~/keys:\s+(\d+)/;
  my ($memory)    = $data=~/blocks:\s+\d+,\s+allocated \(kb\):\s+(\d+)/;
  $status{resources} = {
		      classes => $classes,
		      keys    => $keys,
		      memory  => $memory * 1024,
		      };
  return wantarray ? %status : \%status;
}

sub title {
  my $self = shift;
  my $status= $self->status;
  $status->{database}{title};
}

sub version {
  my $self = shift;
  my $status= $self->status;
  $status->{database}{version};
}

sub auto_save {
  my $self = shift;
  if ($self->db && $self->db->can('auto_save')) {
    $self->db->auto_save;
  } else {
    $self->{'auto_save'} = $_[0] if defined $_[0];
    return $self->{'auto_save'};
  }
}

# Perform an ace query and return the result
sub find {
  my $self = shift;
  my ($query,$count,$offset,$filled,$total) = rearrange(['QUERY','COUNT',
							 'OFFSET',['FILL','FILLED'],'TOTAL'],@_);
  $offset += 0;
  $query = "find $query" unless $query=~/^find/i;
  my $cnt = $self->count(-query=>$query);
  $$total = $cnt if defined $total;
  return $cnt unless wantarray;
  $filled ? $self->_fetch($count,$offset) : $self->_list($count,$offset);
}

#########################################################
# Grep function returns count in a scalar context, list
# of retrieved objects in a list context.
sub grep {
  my $self = shift;
  my ($pattern,$count,$offset,$filled,$filltag,$total,$long) = 
      rearrange(['PATTERN','COUNT','OFFSET',['FILL','FILLED'],'FILLTAG','TOTAL','LONG'],@_);
  $offset += 0;
  my $grep = defined($long) && $long ? 'LongGrep' : 'grep';
  my $r = $self->raw_query("$grep $pattern");
  my ($cnt) = $r =~ /Found (\d+) objects/m;
  $$total = $cnt if defined $total;
  return $cnt if !wantarray;
  if ($filltag) {
    @h = $self->_fetch($count,$offset,$filltag);
  } else {
    @h = $filled ? $self->_fetch($count,$offset) : $self->_list($count,$offset);
  }
  @h;
}

sub pick {
    my ($self,$class,$item) = @_;
    $Ace::Error = '';
    # assumption of uniqueness of name is violated by some classes!
    #    return () unless $self->count($class,$item) == 1;
    return unless $self->count($class,$item) >= 1;

    # if we get here, then we've got some data to return.
    # yes, we're repeating code slightly...
    my @result;
    my $ts = $self->{'timestamps'} ? '-T' : '';
    my $result = $self->raw_query("show -j $ts");
    unless ($result =~ /(\d+) object dumped/m) {
	$Ace::Error = 'Unexpected close during pick';
	return;
    }

    @result = grep (!m!^\s*//!,split("\n\n",$result));
    return $result[0];
}


# these two only get loaded if the Ace::Freesubs .XS isn't compiled
sub freeprotect {
  my $class = shift;
  my $text = shift;
  $text =~ s/\n/\\n/g;
  $text =~ s/\t/\\t/g;
  $text =~ s/"/\\"/g;
  return qq("$text");
}

sub split {
  my $class = shift;
  my $text = shift;
  $text =~ s/\\n/\n/g;
  $text =~ s/\\t/\t/g;
  my ($id,$ts);
  ($class,$id,$ts) = $text=~m/^\?(.+)(?<!\\)\?(.+)(?<!\\)\?([^?]*)$/s;
  $class ||= '';  # fix uninitialized variable warnings
  $id    ||= '';
  $class =~ s/\\\?/?/g;
  $id =~  s/\\\?/?/g;
  return ($class,$id) unless $ts;
  return ($class,$id,$ts);  # return timestamp
}

# Return a list of all the classes known to the server.
sub classes {
  my ($self,$invisible) = @_;
  my $query = defined($invisible) && $invisible ?
    "query find class !buried" 
      :
    "query find class visible AND !buried";
  $self->raw_query($query);
  return $self->_list;
}

################## iterators ##################
# Fetch many objects in iterative style
sub fetch_many {
  my $self = shift;
  my ($class,$pattern,$filled,$query,$chunksize) = rearrange( ['CLASS',
							       ['PATTERN','NAME'],
							       ['FILL','FILLED'],
							       'QUERY',
							       'CHUNKSIZE'],@_);
  $pattern ||= '*';
  $pattern = Ace->freeprotect($pattern);
  if (defined $query) {
    $query = "query $query" unless $query=~/^query\s/;
  } elsif (defined $class) {
    $query = qq{query find $class $pattern};
  } else {
    croak "must call fetch_many() with the -class or -query arguments";
  }
  my $iterator = Ace::Iterator->new($self,$query,$filled,$chunksize);
  return $iterator;
}

sub _register_iterator {
  my ($self,$iterator) = @_;
  $self->{iterators}{$iterator} = $iterator;
}

sub _unregister_iterator {
  my ($self,$iterator) = @_;
  $self->_restore_iterator($iterator);
  delete $self->{iterators}{$iterator};
}

sub _save_iterator {
  my $self = shift;
  my $iterator = shift;
  return unless $self->{iterators}{$iterator};
  $self->{iterator_stack} ||= [];
  return 1 if grep { $_ eq $iterator } @{$self->{iterator_stack}};
  $self->raw_query("spush",'no_alert');
  unshift @{$self->{iterator_stack}},$iterator;
  1;  # result code -- CHANGE THIS LATER
}

# horrid method that keeps the database's view of
# iterators in synch with our view
sub _restore_iterator {
  my $self = shift;
  my $iterator = shift;

  # no such iterator known, return false
  return unless $self->{iterators}{$iterator};

  # make other iterators save themselves
  $self->_alert_iterators;

  # fetch the list of iterators stored on the stack
  my $list = $self->{iterator_stack};
  # spick not supported. Abandon ship
  return if @$list > 1 and $self->{no_spick};

  # Find the iterator in our list. This mirrors the
  # position in the server stack
  my $i;
  for ($i=0; $i<@$list; $i++) {
    last if $list->[$i] eq $iterator;
  }
  return unless $i < @$list;

  # Sse spop if the list size is 1.  Otherwise use spick, which is
  # only supported in hacked versions of the server.
  my $result = $i == 0 ? $self->raw_query("spop",'no_alert') 
                       : $self->raw_query("spick $i",'no_alert');
  
  if ($result =~ /Keyword spick does not match/) {
    # _restore_iterator will now only work for a single iterator (non-reentrantly)
    $self->{no_spick}++;
    $self->raw_query('spop','no_alert') foreach @$list;  # empty database stack
    $self->{iterator_stack} = [];             # and local copy
    return;
  }

  unless (($result =~ /The stack now holds (\d+) keyset/ && ($1 == (@$list-1) ))
	  or 
	  ($result =~ /stack is (now )?empty/ && @$list == 1)
	 ) {
    $Ace::Error = 'Unexpected result from spick: $result';
    return;
  }

  splice(@$list,$i,1);   # remove from position
  return 1;
}

sub datetime {
  my $self = shift;
  my $time = shift || time;
  my ($sec,$min,$hour,$day,$mon,$year) = localtime($time);
  $year += 1900;   # avoid Y3K bug
  sprintf("%4d-%02d-%02d %02d:%02d:%02d",$year,$mon+1,$day,$hour,$min,$sec);
}

sub date {
  my $self = shift;
  my $time = shift || time;
  my ($sec,$min,$hour,$day,$mon,$year) = localtime($time);
  $year += 1900;   # avoid Y3K bug
  sprintf("%4d-%02d-%02d",$year,$mon+1,$day);
}
