package Cache::Memcached::Managed;

# Make sure we have version info for this module

$VERSION= '0.25';

# Make sure we're as strict as possible
# With as much feedback that we can get

use strict;
use warnings;

# Use the external modules that we need

use Scalar::Util qw(blessed reftype);

# Initialize default expiration
# Initialize the hash with specific expirations
# Initialize the delimiter to be used
# Initialize the counter for unique ID's
# Initialize the seconds to wait after a delete of a directory key is done
# Initialize the default timeout for ping
# Initialize number of values to be fetched from memcached at a time
# Initialize the server we're running on

my $expiration = '1D';
my %expiration;
my $default_del = '#';
my $unique = 0;
my $deadtime = 0;
my $pingtime = 10;
my $atatime  = 256;
my $server = eval { `uname -n` } || 'unknown'; chomp $server;
my $_oneline;

# At compile time
#  Create simple accessors

BEGIN {
    eval "sub $_ { shift->{'$_'} }" foreach qw(
 data
 delimiter
 directory
 expiration
 flush_interval
 namespace
     );
} #BEGIN

# Satisfy -require-

1;

#---------------------------------------------------------------------------
#
# Class methods
#
#---------------------------------------------------------------------------
# new
#
# Return instantiated object
#
#  IN: 1 class
#      2..N hash with parameters
# OUT: 1 instantiated object

sub new {
    my $class = shift;
    my %self = @_ < 2 ? (data => (shift || '127.0.0.1:11211')) : @_;

    # want to force an inactive object
    if (delete $self{'inactive'}) {
        require Cache::Memcached::Managed::Inactive;
        return Cache::Memcached::Managed::Inactive->new;
    }

    # set defaults
    $self{expiration} = $expiration  if !$self{expiration};
    $self{delimiter}  = $default_del if !length( $self{delimiter} || '' );
    $self{namespace}  = $>           if !defined $self{namespace};

    # set group names
    $self{group_names}  =
      [ $self{group_names} ? sort @{ $self{group_names} } : 'group' ];
    $self{_group_names} = { map { $_ => undef } @{ $self{group_names} } };

    # obtain client class
    my $memcached_class = $self{memcached_class} ||= 'Cache::Memcached';
    die $@ if !eval "require $memcached_class; 1";

    # check both backends
    my @all_servers;
  BACKEND:
    foreach ( qw( data directory ) ) {

        # nothing to do
        my $spec = $self{$_};
        next BACKEND if !$spec;
        
        # giving an existing object
        if ( blessed $spec ) {

            # unfortunately, there does not seem to be an API for this
            if ( my $servers = $spec->{servers} ) {
                push @all_servers, @{$servers};
                next BACKEND;
            }
        }

        # assume a single server spec
        my $parameters;
        my $type = reftype $spec;
        if ( !$type ) {
            my @servers = split ',', $spec;
            push @all_servers, @servers;
            $parameters = { servers => \@servers };
        }

        # list ref of servers
        elsif ( $type eq 'ARRAY' ) {
            push @all_servers, @{$spec};
            $parameters = { servers => $spec };
        }

        # ready made parameter hash
        elsif ( $type eq 'HASH' ) {
            $parameters = $spec;

            # attempt to find server spec in there
            $spec = $parameters->{servers};
            $type = reftype $spec;

            # also need to fixup config
            if ( !$type ) {
                my @servers = split ',', $spec;
                push @all_servers, @servers;
                $parameters->{servers} = \@servers;
            }

            # regular array spec already
            elsif ( $type eq 'ARRAY' ) {
                push @all_servers, @{$spec};
            }

            # huh?
            else {
                undef $parameters;
            }
        }

        # huh?
        die "Don't know how to handle '$spec' as server specification"
          if !$parameters;

        # create the object for the backend
        $self{$_} = $memcached_class->new($parameters);
    }

    # huh?
    die "No valid data server specification found" if !blessed $self{data};

    # set directory server as data server if there was no data server
    $self{directory} = $self{data} if !blessed $self{directory};

    # remember the pid for fork checking
    $self{_last_pid} = $$;

    # set server specification
    $self{servers} = [ sort @all_servers ];

    return bless \%self,$class;
} #new

#---------------------------------------------------------------------------
#
# Instance methods
#
#---------------------------------------------------------------------------
# add
#
# Add ID + value, only done if not yet in the cache
#
#  IN: 1 instantiated object
#      2 value
#      3 id
# OUT: 1 true if successful
#
# or:
#
#  IN: 1 instantiated object
#      2..N parameter hash
# OUT: 1 true if successful

sub add { shift->_do( 'add',@_ ) } #add

#---------------------------------------------------------------------------
# dead
#
# Cycles through all of the available memcached servers and checks whether
# they are alive or not.  Returns all of the memcached servers that seem to
# be inactive.
#
#  IN: 1 instantiated object
#      2 timeout to apply (default: 10 seconds)
# OUT: 1..N memcached servers that did not reply (in time)
#
#  or:
#
# OUT: 1 hash ref with dead servers

sub dead {

# Obtain the class
# Obtain the timeout
# Create key to be used
# Create value to be used

    my $self = shift;
    my $timeout = shift || $pingtime;
    my $key = $self->_unique_key;
    my $value = time;

# Initialize list of problem servers
# For all of the servers to be checked (in alphabetical order)
#  Create new memcached server object for this server only
#  Obtain value from which
#   Makes sure alarm() will do a die()
#   Set the alarm
#   Set the value in the server
#   Attempt to get it back
#   Delete the key 
#   Return the value obtained

    my @dead;
    foreach ($self->servers) {
        my $server = $self->{memcached_class}->new( {servers => [$_]} );
        my $fetched = eval {
            local $SIG{ALRM} = sub { die "timed out\n" };
            alarm $timeout;
            $server->set( $key,$value );
            my $result = $server->get( $key );
            $server->delete( $key ) if $result;
            $result;
        } || 0;

#  Reset the alarm
#  Mark server as problem if value obtained not equal to value stored

        alarm 0;
        push @dead,$_ if $fetched != $value;
    }

# Return list of problem servers (sorted) or as a hash ref

    return wantarray ? @dead : {map {$_ => undef} @dead};
} #dead

#---------------------------------------------------------------------------
# decr
#
# Decrement an existing ID, only done if not yet in the cache
#
#  IN: 1 instantiated object
#      2 value
#      3 id
# OUT: 1 true if successful
#
# or:
#
#  IN: 1 instantiated object
#      2..N parameter hash
# OUT: 1 true if successful

sub decr { shift->_do( 'decr',@_ ) } #decr

#---------------------------------------------------------------------------
# delete
#
# Delete an existing ID
#
#  IN: 1 instantiated object
#      2 id
# OUT: 1 true if successful
#
# or:
#
#  IN: 1 instantiated object
#      2..N parameter hash
# OUT: 1 true if successful

sub delete {

# Obtain the object
# Check the socket

    my $self = shift;
    return unless $self->_check_socket;

# Obtain the parameters
# Perform the delete

    my %param = @_ == 1 ? (id => shift) : @_;
    $self->data->delete(
     $self->_data_key( @param{qw(id key namespace version)} ) );
} #delete

#---------------------------------------------------------------------------
# delete_group
#
# Delete all information about a group, given by group name and ID
#
#  IN: 1 instantiated object
#      2..N hash with group names and ID's to delete info of
# OUT: 1 number of items deleted

sub delete_group {

# Obtain the object
# Obtain the parameter hash
# Obtain local copies of stuff we need fast access to here
# Obtain the namespace

    my $self = shift;
    my %param = @_;
    my ($data,$directory) = map {$self->$_} qw(data directory);
    my ($namespace) = $self->_lexicalize( \%param,qw(namespace) );

# Initialize number of items deleted
# Obtain reference to the group names
# While there are group name / id pairs to process
#  Obtain groupname and ID
#  Make sure group name is fully qualified
#  Reloop if not a valid group name

    my $deleted = 0;
    my $group_names = $self->{'_group_names'};
    while (my ($group_name,$group_id) = each %param) {
        $self->_group_id( $group_name );
        die "'$group_name' is not a valid group name"
         unless exists $group_names->{$group_name};

#  Obtain the directory key
#  Obtain the index keys
#  Obtain the backend keys for these index keys

        my $directory_key =
         $self->_directory_key( $namespace,$group_name,$group_id );
        my @index_key = $self->_index_keys( $directory_key );
        my @data_key = $self->_data_keys( $directory_key,0,@index_key );

#  Delete the lowest index key
#  Delete the directory key
#  Delete all of the index keys
#  Delete all of the backend keys
#  Add the number of entries deleted

        $directory->delete( $self->_lowest_index_key($directory_key),$deadtime);
        $directory->delete( $directory_key,$deadtime );
        $directory->delete( $_ ) foreach @index_key;
        $data->delete( $_ ) foreach @data_key;
        $deleted += @data_key;
    }

# Return the result

    $deleted;
} #delete_group

#---------------------------------------------------------------------------
# errors
#
# Cycles through all of the available memcached servers and returns the
# number of errors recorded.
#
#  IN: 1 instantiated object
#      2 flag: reset error counters
# OUT: 1 reference to hash with number of errors for each server

sub errors {

# Obtain the parameters
# Return with error counters if we don't want to reset the error counters

   my ($self,$reset) = @_;
   return $self->directory->get_multi( $self->servers ) unless $reset;

# Obtain the directory backend
# Obtain the error counters
# Delete all the error counters that were returned
# Return the hash ref with errors

   my $directory = $self->directory;
   my $errors = $directory->get_multi( $self->servers );
   $directory->delete( $_ ) foreach keys %{$errors};
   $errors;
} #errors

#---------------------------------------------------------------------------
# flush_all
#
# Flush the contents of all servers (without rebooting them)
#
#  IN: 1 instantiated object
#      2 number of seconds between flushes (default: flush_interval)
# OUT: 1 number of servers successfully flushed

sub flush_all {

# Obtain the object
# Obtain the data server
# Obtain the servers

    my ($self,$interval) = @_;
    my $data = $self->data;
    my @server = $self->servers;

# Use default interval if none specified
# Initialize number of servers flushed
# Initialize amount of time to wait

    $interval = $self->flush_interval unless defined $interval;
    my $flushed = 0;
    my $time    = 0;

# For all of the servers minus the directory server
#  Create the action
#  Increment flushed if flush was successful
#  Increment time if we need to

    foreach (0..$#server) {
        my $action = $interval ? "flush_all $time" : "flush_all";
        $flushed++ if $self->_oneline( $data,$action,$_,"OK" );
        $time += $interval if $interval;
    }

# Return whether all servers successfully flushed

    $flushed = @server;
} #flush_all

#---------------------------------------------------------------------------
# get
#
# Get a single value from the cache
#
#  IN: 1 instantiated object
#      2 id
# OUT: 1 value if found or undef
#
# or:
#
#  IN: 1 instantiated object
#      2..N parameter hash
# OUT: 1 value if found or undef

sub get {

# Obtain the object
# Check the socket

    my $self  = shift;
    return unless $self->_check_socket;

# Obtain the parameters
# Perform the actual getting of the value

    my %param = @_ == 1 ? (id => shift) : @_;
    my $data_key = $self->_data_key( @param{qw(id key namespace version)} );
    $self->data->get( $data_key );
} #get

#---------------------------------------------------------------------------
# get_group
#
# Return the contents of the group, optionally deleting it
#
#  IN: 1 instantiated object
#      2..N parameter hash (group / delete / namespace)
# OUT: 1 hash reference with result
#
# The structure of the hash is:
#
# $result
#  |--- key
#        |-- version
#            |-- id
#                |-- value

sub get_group {

# Obtain the object
# Obtain the parameters
# Obtain local copies of stuff we need

    my $self = shift;
    my %param = @_;
    my ($data,$delimiter,$directory) =
     map {$self->$_} qw(data delimiter directory);

# Obtain delete flag
# Obtain namespace to be used

    my $delete = delete $param{'delete'};
    my ($namespace) = $self->_lexicalize( \%param,qw(namespace) );

# Quit now if more than 1 group specified
# Obtain group name and ID
# Make sure groupname is fully qualified
# Die now if not a valid group

    die "Can only fetch one group at a time" if keys %param > 1;
    my ($group_name,$group_id) = each %param;
    $self->_group_id( $group_name,!!$delete );
    die "'$group_name' is not a valid group name"
     unless exists $self->{'_group_names'}->{$group_name};

# Obtain the directory key
# Obtain the index keys
# Obtain the data keys for these index keys

    my $directory_key =
     $self->_directory_key( $namespace,$group_name,$group_id );
    my @index_key = $self->_index_keys( $directory_key );
    my @data_key = $self->_data_keys( $directory_key,$delete,@index_key );

# If we're deleting
#  Delete the lowest index key
#  Delete the directory key
#  Delete all of the index keys

    if ($delete) {
        $directory->delete( $self->_lowest_index_key($directory_key),$deadtime);
        $directory->delete( $directory_key,$deadtime );
        $directory->delete( $_ ) foreach @index_key;
    }

# Initialize result hash
# Obtain all of the data in one fell swoop
# For all of the backend keys for this group
#  Split out uid, version, key and ID
#  Remove the entry from the cache if deleting
#  Move the value out of the gotten hash into the result hash if right namespace

    my %result;
    while (my @todo = splice @data_key,0,$atatime) {
        my $gotten = $data->get_multi( @todo );
        foreach my $data_key (keys %{$gotten}) {
            my (undef,$version,$key,$id) = split $delimiter,$data_key,4;
            $data->delete( $data_key ) if $delete;
            $result{$key}->{$version}->{$id||''} = delete $gotten->{$data_key};
        }
    }

# Return the result as a hash ref if in scalar context
# Return only the values if in list context

    return \%result unless wantarray;
    map {values %{$_}} map {values %{$_}} values %result;
} #get_group

#---------------------------------------------------------------------------
# get_multi
#
# Get a multiple values from the cache, sharing the same key, version and
# namespace
#
#  IN: 1 instantiated object
#      2 reference to list of ID's
# OUT: 1 hash ref of ID's and values found
#
# or:
#
#  IN: 1 instantiated object
#      2..N parameter hash
# OUT: 1 hash ref of ID's and values found

sub get_multi {

# Obtain the object
# Check the socket

    my $self  = shift;
    return {} unless $self->_check_socket;

# Obtain the parameters
# Obtain the key
# Obtain the version
# Obtain the namespace

    my %param = @_ == 1 ? (id => shift) : @_;
    my $key = $self->_create_key( $param{'key'} );
    my $version = $param{'version'};
    my ($namespace) = $self->_lexicalize( \%param,qw(namespace) );

# Obtain the data keys
# Create result hash

    my @data_key =
     map {$self->_data_key( $_,$key,$namespace,$version )} @{$param{'id'}};
    my %result;

# Obtain the data server backend
# Make sure we use the right delimiter
# While we have a batch of data to fetch
#  Perform the actual getting of the values
#  For all of the values obtained this time
#   Move the value to the result hash with just the ID as the key

    my $data = $self->data;
    my $delimiter = $self->delimiter;
    while (my @todo = splice @data_key,0,$atatime) {
        my $hash = $data->get_multi( @todo );
        foreach (keys %{$hash}) {
            $result{(split $delimiter,$_,4)[3]} = delete $hash->{$_};
        }
    }

# Return the reference to the resulting hash

    \%result;
} #get_multi

#---------------------------------------------------------------------------
# grab_group
#
#  IN: 1 instantiated object
#      2..N parameter hash (group / namespace)
# OUT: 1 hash reference with result
#
# The structure of the hash is:
#
# $result
#  |--- key
#        |-- version
#            |-- id
#                |-- value

sub grab_group { shift->get_group( delete => 1,@_ ) } #grab_group

#---------------------------------------------------------------------------
# group
#
# Return the ID's of a group, ordered by key.
#
#  IN: 1 instantiated object
#      2..N parameter hash
# OUT: 1 hash reference with result
#
# The structure of the hash is:
#
# $result
#  |--- key
#        |--- [id1,id2..idN]

sub group {

# Obtain the parameters
# Check the socket

    my $self = shift;
    return {} unless $self->_check_socket;

# Obtain the parameter hash
# Obtain the namespace
# Quit now if more than one group specified

    my %param = @_;
    my ($namespace) = $self->_lexicalize( \%param,qw(namespace) );
    die "Can only fetch one group at a time" if keys %param > 1;

# Obtain the group name and group ID
# Make sure group name is fully qualified
# Return now if not a valid group

    my ($group_name,$group_id) = each %param;
    $self->_group_id( $group_name );
    return {} unless exists $self->{'_group_names'}->{$group_name};

# Initialize result hash
# Make sure we use the right delimiter
# For all of the backend keys for this group
#  Split out the parts
#  Save the ID in the list for the key

    my %result;
    my $delimiter = $self->delimiter;
    foreach ($self->_data_keys(
     $self->_directory_key( $namespace,$group_name,$group_id ) )) {
        my ($key,$id) = (split $delimiter)[2,3];
        push @{$result{$key}},$id;
    }

# Make sure the ID's are listed in order
# Return the result

    $_ = [sort @$_] foreach values %result;
    \%result;
} #group

#---------------------------------------------------------------------------
# group_names
#
# Return the specifications of all groups defined in alphabetical order in
# list context, or as a hash ref in scalar context
#
#  IN: 1 instantiated object
# OUT: 1..N group names specifications in alphabetical order
#
#  or:
#
# OUT: 1 hash ref with group names

sub group_names {

# Obtain the object
# Return the group names sorted or as a hash ref

    my $self = shift;
    return wantarray ? @{$self->{'group_names'}} : $self->{'_group_names'};
} #group_names

#---------------------------------------------------------------------------
# inactive
#
#  IN: 1 instantiated object
# OUT: 1 false

sub inactive { undef } #inactive

#---------------------------------------------------------------------------
# incr
#
# Decrement an existing ID
#
#  IN: 1 instantiated object
#      2 value
#      3 id
# OUT: 1 true if successful
#
# or:
#
#  IN: 1 instantiated object
#      2..N parameter hash
# OUT: 1 true if successful

sub incr { shift->_do( 'incr',@_ ) } #incr

#---------------------------------------------------------------------------
# replace
#
# Replace an existing ID
#
#  IN: 1 instantiated object
#      2 value
#      3 id
# OUT: 1 true if successful
#
# or:
#
#  IN: 1 instantiated object
#      2..N parameter hash
# OUT: 1 true if successful

sub replace { shift->_do( 'replace',@_ ) } #replace

#---------------------------------------------------------------------------
# reset
#
# Reset the client side of the cache system
#
#  IN: 1 instantiated object
# OUT: 1 returns true

sub reset {
    my $self = shift;

    # obtain local copy of data and directory object
    my ( $data, $directory ) = ( $self->data, $self->directory );

    # all of the Cache::Memcached objects we need to handle
    foreach ( $data == $directory ? ($data) : ( $data, $directory ) ) {

        # disconnect all sockets
        $_->disconnect_all    if $_->can('disconnect_all');;

        # kickstart connection logic
        $_->forget_dead_hosts if $_->can('forget_dead_hosts');
    }

    # make sure we try to connect again
    $self->_mark_connected;

    # set last pid used flag
    $self->{'_last_pid'} = $$;

    return 1;
} #reset

#---------------------------------------------------------------------------
# set
#
# Set an ID, create if doesn't exist yet
#
#  IN: 1 instantiated object
#      2 value
#      3 id
# OUT: 1 true if successful
#
# or:
#
#  IN: 1 instantiated object
#      2..N parameter hash
# OUT: 1 true if successful

sub set { shift->_do( 'set',@_ ) } #set

#---------------------------------------------------------------------------
# servers
#
# Return the specifications of all memcached servers being used in
# alphabetical order in list context, or as a hash ref in scalar context
#
#  IN: 1 instantiated object
# OUT: 1..N server specifications in alphabetical order
#
#  or:
#
# OUT: 1 hash ref with server configs

sub servers {

    return wantarray
      ? @{ shift->{servers} }
      : { map { $_ => undef } @{ shift->{servers} } };
} #servers

#---------------------------------------------------------------------------
# start
#
# Start the indicated memcached backend servers
#
#  IN: 1 instantiated object
#      2..N config of memcached servers to start (default: all)
# OUT: 1 whether all indicated memcached servers started

sub start {

# Obtain the object
# Obtain the servers to start

    my $self = shift;
    @_ = $self->servers unless @_;

# Initialize started counter
# For all of the servers to start
#  Obtain IP and port
#  Increment counter if start was successful
    
    my $started = 0;
    foreach (@_) {
        my ($ip,$port) = split ':';
        $started++ unless system 'memcached',
         '-d','-u',(scalar getpwuid $>),'-l',$ip,'-p',$port;
    }

# Return whether all servers started

    $started == @_;
} #start

#---------------------------------------------------------------------------
# stats
#
# Return a hash ref with simple statistics for each server
#
#  IN: 1 instantiated object
#      2..N config specifications of servers (default: all)
# OUT: 1 hash reference
#
# $stats
#   |-- server
#        |-- key
#             |-- value

sub stats {

# Obtain the object
# Return now if no active servers anymore

    my $self = shift;
    return {} unless $self->_check_socket;

# Create hash with configs to be done
# Initialize the result ref
# For all of the objects that we have
#  For all of the servers we want to do this
#   Reloop if not to be done
#   Obtain STATS info

    my %todo = @_ ? map {$_ => undef} @_ : %{$self->servers};
    my %result;
    foreach my $cache ($self->data,$self->directory) {
        foreach my $host ( $self->servers ) {
            next unless exists $todo{$host} and not exists $result{$host};
            $result{$host} = {
             map {s#^STAT ##; split m#\s+#}
             $self->_morelines( $cache,$host,"stats" )
            };
        }
    }

# Return the result hash as a ref

    \%result;
} #stats

#---------------------------------------------------------------------------
# stop
#
# Stop the indicated memcached backend servers
#
#  IN: 1 instantiated object
#      2..N config of memcached servers to stop (default: all)
# OUT: 1 whether all indicated memcached servers stopped

sub stop {

# Obtain the object
# Obtain the pid's to kill
# Return whether all were killed

    my $self = shift;
    my @pid = map {$_->{'pid'}} grep {$_->{'pid'}} values %{$self->stats( @_ )};
    @pid == kill 15,@pid;
} #stop

#---------------------------------------------------------------------------
# version
#
# Return version information of running memcached backend servers
#
#  IN: 1 instantiated object
#      2..N config of memcached servers to obtain version of (default: all)
# OUT: 1 hash ref with version info, keyed to config

sub version {

# Obtain the object
# Obtain the basic info to work with
# Normalize to version information

    my $self = shift;
    my $stats = $self->stats( @_ );
    $_ = $_->{'version'} foreach values %{$stats};

# Return the resulting hash reference

    $stats;
} #version

#---------------------------------------------------------------------------
#
# Internal methods
#
#---------------------------------------------------------------------------
# _data_key
#
# Expand the given id
#
#  IN: 1 instantiated object
#      2 id to expand (default: none)
#      3 key to use (default: caller sub)
#      4 namespace to use (default: object->namespace)
#      5 version to use (default: key's $package::VERSION)
#      6 number of levels to go back in caller stack (default: 2 )
# OUT: 1 expanded key

sub _data_key {

# Obtain the parameters
# Obtain key
# Obtain the delimiter

    my ($self,$id,$key,$namespace,$version,$levels) = @_;
    $key = $self->_create_key( $key,($levels ||= 2) + 1 );
    my $delimiter = $self->delimiter;

# If we don't have a version yet
#  Allow for non strict references
#  Adapt the version information
# Make sure we have a namespace
# Prefix the version information

    unless ($version) {
        no strict 'refs';
        $version = ($key =~ m#^(.*)::# ? ${$1.'::VERSION'} : '') ||
                   ($key =~ m#^/# ? $main::VERSION : '') ||
                   $Cache::Memcached::Managed::VERSION;
    }
    $namespace = $self->namespace unless defined $namespace;
    $key = $namespace.$delimiter.$version.$delimiter.$key;

# If some type of ref was specified for the ID
#  If it was a list ref
#   Join the elements
#  Elseif it was a hash ref
#   Join the sorted key/value pairs
#  Elseif it was a scalar ref
#   Just deref it

    if (my $type = ref $id) {
        if ($type eq 'ARRAY') {
            $id = join $delimiter,@{$id};
        } elsif ($type eq 'HASH') {
            $id = join $delimiter,map {$_ => $id->{$_}} sort keys %{$id};
        } elsif ($type eq 'SCALAR') {
            $id = $$id;

#  Else (unexpected type of ref)
#   Let the world know we didn't expect this

        } else {
            die "Don't know how to handle key of type '$type': $id";
        }
    }

# Expand the ID as appropriate and return the result

    $self->{'_data_key'} =
     $key.(defined $id and length $id ? $delimiter.$id : '');
} #_data_key

#---------------------------------------------------------------------------
# _data_keys
#
# Return the backend keys for a given directory_key
#
#  IN: 1 instantiated object (ignored)
#      2 directory key
#      3 flag: don't perform cleanup (default: perform cleanup)
#      4..N index keys, highest first (default: _index_keys)
# OUT: 1..N unordered list with backend keys

sub _data_keys {

# Obtain the main parameters
# Make sure we have index keys
# Obtain backend keys

    my ($self,$directory_key,$nocleanup) = splice @_,0,3;
    @_ = $self->_index_keys( $directory_key ) unless @_;

# Obtain shortcut to the directory backend
# Initialize lowest index number found
# Initialize list of index keys with duplicate backend keys found
# Initialize backend key hash

    my $directory = $self->directory;
    my $lowest = 1;
    my @double;
    my %data_key;

# While there are data keys to be fetched
#  If successful in obtaining next slice of the backend keys
#   Copy them into the final result hash
#   If we don't want to cleanup
#    Just put all of the values as keys

    while (@_) {
        if (my $result = $directory->get_multi( splice @_,0,$atatime )) {
            if ($nocleanup) {
                $data_key{$_} = undef foreach values %{$result};

#**************************************************************************
# Note that we're using the side effect of Perl taking the digits at the
# start of a string as the numerical value: this allows us to quickly
# check the index number of the index keys, and to calculate the lowest
# possible free index number that should be checked later.  That's why
# we're switching off warnings for this section here.
#**************************************************************************

#   Else (we want to cleanup)
#    For all of the index keys obtained
#     If this backend key was already found
#      Mark this index key as double
#     Else
#      Set this backend key
#      Save this as the lowest value

            } else {
                no warnings;
                foreach (sort {$b <=> $a} keys %{$result}) {
                    my $data_key = $result->{$_};
                    if (exists $data_key{$data_key}) {
                        push @double,$_;
                    } else {
                        $data_key{$data_key} = undef;
                        $lowest = $_;
                    }
                }
            }

#  Else (failed,the directory backend has died: this is REALLY bad)
#   Invalidate all backend servers
#   Invalidate all cache access for this process from now on
#   Return emptyhanded
        
        } else {
            $self->flush_all( $self->flush_interval );
            $self->_mark_disconnected;
            return;
        }
    }

# If we want to cleanup
#  Remove the index keys that we don't need anymore
#  Make sure we're silent about numifying the lowest key
#  Set the lowest index to be checked later if lowest was found

    unless ($nocleanup) {
        $directory->delete( $_ ) foreach @double;
        no warnings;
        $directory->set( $self->_lowest_index_key( $directory_key ),0+$lowest );
    }

# Return the result

    keys %data_key;
} #_data_keys

#---------------------------------------------------------------------------
# _check_socket
#
# Check whether the socket has been used in this process, disconnect if not
# yet used in this process
#
#  IN: 1 class or object (ignored)
# OUT: 1 whether successful

sub _check_socket {

# Quickest way out in the most common case

    return 1 if $$ == $_[0]->{'_last_pid'} and !exists $_[0]->{'_disconnected'};

# Obtain the object
# Return result of reset if we're in a different process now

    my $self = shift;
    return $self->reset if $$ != $self->{'_last_pid'};

# Mark object as connected if waited long enough
# Return (possibly changed) status

    $self->_mark_connected 
     if $self->{'_disconnected'} and time > $self->{'_disconnected'};
    return !$self->{'_disconnected'};
} #_check_socket;

#---------------------------------------------------------------------------
# _create_key
#
# Expand the given key
#
#  IN: 1 instantiated object
#      2 key to expand (default: caller sub)
#      3 number of levels to go back in caller stack (default: 2 )
# OUT: 1 fully qualified key

sub _create_key {

# Obtain the parameters
# Return now if we already have a fully qualified key

    my ($self,$key,$levels) = @_;
    return $key if $key and ($key =~ m#.+::# or $key =~ m#^/#);

# Set levels if not set yet
# Obtain caller info

    $levels ||= 2;
    my $caller = (caller($levels))[3] ||
     ($0 =~ m#^/# ? $0 : do {my $pwd = `pwd`; chomp $pwd; $pwd}."/$0");

# Set the default key if no key specified yet
# If we have a package relative key, removing prefix on the fly
#  Remove caller info's relative part
#  Prefix the caller info
# Return the resulting key

    $key ||= $caller;
    if ($key =~ s#^::##) {
        $caller =~ s#[^:]+$##;
        $key = $caller.$key;
    }
    $key;
} #_create_key

#---------------------------------------------------------------------------
# _directory_key
#
# Return the directory key for a given group name, ID and namespace
#
#  IN: 1 instantiated object
#      2 namespace
#      3 group name
#      4 ID

sub _directory_key {

# Obtain the delimiter (lose the object on the fly
# Create key and return that

    my $delimiter = shift->delimiter;
    __PACKAGE__.$delimiter.(join $delimiter,@_);
} #_directory_key

#---------------------------------------------------------------------------
# _do
#
# Perform one of the basic cache actions
#
#  IN: 1 instantiated object
#      2 method name
#      3 value
#      4 id
# OUT: 1 true if successful
#
# or:
#
#  IN: 1 instantiated object
#      2 method name
#      3..N parameter hash
# OUT: 1 true if successful

sub _do {

# Obtain object and method
# Check the socket

    my ($self,$method) = splice @_,0,2;
    return undef unless $self->_check_socket;

# Obtain the parameter hash
# Create the key, removing key specification on the fly

    my %param = @_ > 3
      ? @_ 
      :  ( value => shift, id => shift, expiration => shift );
    my $key = $self->_create_key( delete( $param{'key'} ),3 );

# Obtain the ID, removing it on the fly
# Set unique ID if so requested
# Obtain the value, removing it on the fly
# Make sure there is a valid value for increment and decrement
# Obtain the lexicals for parameters
# Convert the expiration to seconds

    my $id = delete $param{'id'};
    $id = $self->_unique_key if $id and $id eq ':unique';
    my $value = delete $param{'value'};
    $value = 1 if !defined $value and $method =~ m#(?:decr|incr)$#;
    my ($expiration,$namespace) =
     $self->_lexicalize( \%param,qw(expiration namespace) );
    $expiration = $self->_expiration2seconds( $expiration );

# Obtain the data server
# Obtain the data key, remove version from parameter hash on the fly
# Perform the named method

    my $data = $self->data;
    my $data_key =
     $self->_data_key( $id,$key,$namespace,delete $param{'version'} );
    my $result = $data->$method( $data_key,$value,$expiration );

# If action was successful
#  Return now if replace, decr or incr (assume always same groups)
# Elseif we're trying to increment (and action failed)
#  Add an entry with the indicated value or 1
# Elsif we're not doing a set (so: add|decr|replace and failed)
#  Just return with whatever we got

    if ($result) {
        return $result if $method =~ m#^(?:decr|incr|replace)$#;
    } elsif ($method eq 'incr') {
        $result = $data->add( $data_key,$value || 1,$expiration);
    } elsif ($method ne 'set') {
        return $result;
    }

    # still don't have a good result
    my $directory = $self->directory;
    if ( !$result ) {

        # can get the bucket
        if ( $data->can('get_sock') ) {
            if ( my $bucket = $data->get_sock($data_key) ) {

                # can lose prefix, increment error on server
                if ( $bucket =~ s#^Sock_## ) {
                    $directory->add( $bucket, 1 )
                      if !$directory->incr($bucket);
                }
            }
        }

        # block all access for this process
        $self->{'_disconnected'} = 1;

        # return indicating error
        return undef;
    }

# Obtain hash ref to valid group names
# For all group name links to be set (remaining pairs in parameter hash)
#  Normalize group ID if necessary
#  Obtain directory key
#  Obtain an index 

    my $group_names = $self->{'_group_names'};
    while (my ($group_name,$group_id) = each %param) {
        $group_id =~ s#^:key#$key#;
        my $directory_key =
         $self->_directory_key( $namespace,$group_name,$group_id );
	my $index = $directory->incr( $directory_key );

#  If we don't have a valid index
#   If not successful in initializing the directory key
#    Block all access for this process
#    Return indicating error

        unless (defined $index) {
            unless (defined $directory->add( $directory_key,$index = 1 )) {
                $self->{'_disconnected'} = 1;
                return undef;
            }
        }

#  If not successful in storing the data key
#   Block all access for this process
#   Return indicating error
            
        unless ($directory->set(
         $self->_index_key( $directory_key,$index ),$data_key,$expiration )) {
            $self->{'_disconnected'} = 1;
            return undef;
        }
    }

# Return the original result

    $result;
} #_do

#---------------------------------------------------------------------------
# _expiration2seconds
#
# Convert given expiration to number of seconds
#
#  IN: 1 instantiated object (ignored)
#      2 expiration
# OUT: 1 number of seconds

sub _expiration2seconds {

# Obtain the initial expiration
# Return now if nothing to check
# Return now if invalid characters found

    my $expiration = $_[1];
    return if !defined $expiration;
    return if $expiration !~ m#^[sSmMhHdDwW\d]+$#;

# Just a second specification

    return $expiration if $expiration !~ m#\D#;

# Convert seconds into seconds
# Convert minutes into seconds
# Convert hours into seconds
# Convert days into seconds
# Convert weeks into seconds

    my $seconds = 0;
    $seconds += $1 if $expiration =~ m#(\d+)[sS]#;
    $seconds += (60 * $1) if $expiration =~ m#(\d+)[mM]#;
    $seconds += (3600 * $1) if $expiration =~ m#(\+?\d+)[hH]#;
    $seconds += (86400 * $1) if $expiration =~ m#(\+?\d+)[dD]#;
    $seconds += (604800 * $1) if $expiration =~ m#(\+?\d+)[wW]#;

# Return the resulting sum

    $seconds;
} #_expiration2seconds

#---------------------------------------------------------------------------
# _index_key
#
# Return the index key for a given directory_key and ordinal number
#
#  IN: 1 instantiated object (ignored)
#      2 directory key
#      3 ordinal number
# OUT: 1 index key

sub _index_key { $_[2].$_[0]->delimiter.$_[1] } #_index_key

#---------------------------------------------------------------------------
# _index_keys
#
# Return the index keys for a given directory_key
#
#  IN: 1 instantiated object (ignored)
#      2 directory key
# OUT: 1 list with index keys (highest first)

sub _index_keys {

# Obtain the parameters
# Return emtyhanded if no index keys available

    my ($self,$directory_key) = @_;
    return unless my $found = $self->directory->get( $directory_key );

# Obtain the lowest possible index
# Create the index keys and return them

    my $lowest =
     $self->directory->get( $self->_lowest_index_key( $directory_key ) ) || 1;
    reverse map {$self->_index_key( $directory_key,$_ )} $lowest..$found;
} #_index_keys

#---------------------------------------------------------------------------
# _group_id
#
# Fully qualify a group name if relative name indicated
#
#  IN: 1 instantiated object (ignored)
#      2 group name to check (directly updated, must be left value)
#      3 number of extra levels to go up

sub _group_id {

# Prefix package name of relative group name indicated

    $_[1] = (caller(1 + ($_[2] || 0)))[0].$_[1] if $_[1] =~ m#^::#;
} #_group_id

#---------------------------------------------------------------------------
# _lexicalize
#
# Return values associated with the given method names, allowing for
# overrides from a parameter hash.  Removes these values from the parameter
# hash.
#
#  IN: 1 instantiated object
#      2 reference to parameter hash
#      3..N method names to check
# OUT: 1..N values associated with method names

sub _lexicalize {

# Obtain object and parameter hash
# Create temporary value holder
# Map the method names to the appropriate value

    my ($self,$param) = splice @_,0,2;
    my $v;
    map {$v = delete $param->{$_}; defined $v ? $v : $self->$_ } @_;
} #_lexicalize

#---------------------------------------------------------------------------
# _lowest_index_key
#
# Return the index key for the lowest possible index
#
#  IN: 1 instantiated object (ignored)
#      2 directory key
# OUT: 1 index key of lowest index

sub _lowest_index_key { $_[1].$_[0]->delimiter.'_lowest' } #_lowest_index_key

#---------------------------------------------------------------------------
# _mark_connected
#
# Mark the object as connected
#
#  IN: 1 instantiated object

sub _mark_connected { delete $_[0]->{'_disconnected'} } #_mark_connected

#---------------------------------------------------------------------------
# _mark_disconnected
#
# Mark the object as disconnected: all actions will fail for a random
# amount of time.
#
#  IN: 1 instantiated object
#      2 amount of time to mark as disconnected (default: 20..30)

sub _mark_disconnected {

# Mark the object as disconnected

    $_[0]->{'_disconnected'} = time + ($_[1] || 20 + int rand 10)
} #_mark_disconnected

#---------------------------------------------------------------------------
# _morelines
#
# Handle non-API request that returns multiple lines
#
#  IN: 1 instantiated object (ignored)
#      2 Cache::Memcached object
#      3 host to send to
#      4 line to send (no newline, default: just return next response)
#      5 bucket (default: 0)
# OUT: 1..N response lines

sub _morelines {
    my ( $self, $cache, $host, $send, $bucket ) = @_;

    # don't have any sock to host mapping, so quit
    return if !$cache->can('sock_to_host');

    # couldn't get a socket for given host
    return unless my $socket = $cache->sock_to_host($host);

    return map {
     s#[\r\n]+$##; m#^(?:END|ERROR)# ? () : ($_)
    } $cache->run_command( $socket, $send. "\r\n" );
} #_morelines

#---------------------------------------------------------------------------
# _oneline
#
#  IN: 1 instantiated object (ignored)
#      2 Cache::Memcached object
#      3 line to send (no newline, default: just return next response)
#      4 bucket (default: 0)
#      5 response string to check with (no newline, default: return response)
# OUT: 1 response or whether expected response returned

sub _oneline {
    my ( $self, $cache, $send, $bucket, $expect ) = @_;

    # can't get any socket, so quit
    return if !$cache->can('get_sock');

    # couldn't get a socket for the indicated bucket
    return unless my $socket = $cache->get_sock( [$bucket || 0,0] );

    # make sure we can call a "_oneline" compatible method
    $_oneline ||=
      $cache->can( '_oneline' ) ||
      $cache->can( '_write_and_read' )
      or die "Unsupported version of " . ( blessed $cache ) . "\n";

    # obtain response
    my $response = defined $send
     ? $_oneline->( $cache, $socket, $send . "\r\n" )
     : $_oneline->( $cache, $socket );

    # nothing to check against, just give back what we got
    return $response if !defined $expect;

    return ( $response and $expect."\r\n" eq $response );
} #_oneline

#---------------------------------------------------------------------------
# _unique_key
#
# Return a unique key
#
#  IN: 1 class or object (ignored)
# OUT: 1 guaranteed unique key

sub _unique_key {

# Create unique key and return that

    join $_[0]->delimiter,$server,$$,time,++$unique;
} #_unique_key

#---------------------------------------------------------------------------
# _spec2servers
#
# Converts server spec to list ref of servers
#
#  IN: 1 server spec
#      2 recursing flag (only used internally)
# OUT: 1 list ref of servers

sub _spec2servers {
    my ( $spec, $recursing ) = @_;

    # assume scalar definition if not a ref
    my $type = reftype $spec;
    if ( !defined $type ) {
        return [ split ',', $spec ];
    }

    # list ref of servers
    elsif ( $type eq 'ARRAY' ) {
        return $spec;
    }

    # huh?
    die "Don't know how to handle '$spec' as server specification";
}    #_spec2servers

#---------------------------------------------------------------------------

__END__

=head1 NAME

Cache::Memcached::Managed - provide API for managing cached information

=head1 SYNOPSIS

 use Cache::Memcached::Managed;

 my $cache = Cache::Memcached::Managed->new( '127.0.0.1:12345' );

 $cache->set( $value );

 $cache->set( $value,$id );

 $cache->set( value      => $value,
              id         => $id,
              key        => $key,
              version    => "1.1",
              namespace  => 'foo',
              expiration => '1D', );

 my $value = $cache->get( $id );

 my $value = $cache->get( id  => $id,
                          key => $key );

=head1 VERSION

This documentation describes version 0.22.

=head1 DIFFERENCES FROM THE Cache::Memcached API

The Cache::Memcached::Managed module provides an API to values, cached in
one or more memcached servers.  Apart from being very similar to the API
of L<Cache::Memcached>, the Cached::Memcached::Managed API allows for
management of groups of values, for simplified key generation and expiration,
as well as version and namespace management and a few other goodies.

These are the main differences between this module and the L<Cache::Memcached>
module.

=head2 automatic key generation

The calling subroutine provides the key (by default).  Whenever the "get"
and "set" operations occur in the same subroutine, you don't need to think
up an identifying key that will have to be unique across the entire cache.

=head2 ID refinement

An ID can be added to the (automatically) generated key (none is by default),
allowing easy identification of similar data objects (e.g. the primary key of
a Class::DBI object).  If necessary, a unique ID can be created automatically
(useful when logging events).

=head2 version management

The caller's package provides an identifying version (by default), allowing
differently formatted data-structures caused by source code changes, to live
separately from each other in the cache.

=head2 namespace support

A namespace identifier allows different realms to co-exist in the same cache (the uid by default).  This e.g. allows a group of developers to all use the same cache without interfering with each other.

=head2 group management

A piece of cached data can be assigned to any number of groups.  Cached data
can be retrieved and removed by specifying the group to which the data
belongs.  This can be used to selectively remove cached data that has been
invalidated by a database change, or to obtain logged events of which the
identification is not known (but the group name is).

=head2 easy (default) expiration specification

A default expiration per Cache::Memcached::Managed object can be specified.
Expirations can be used by using mnemonics D, H, M, S, (e.g. '2D3H' would
be 2 days and 3 hours).

=head2 automatic fork() detection

Sockets are automatically reset in forked processes, no manual reset needed.
This allows the module to be used to access cached data during the server
start phase in a mod_perl environment.

=head2 magical increment

Counters are automagically created with L<incr> if they don't exist yet.

=head2 instant invalidation

Support for the new "flush_all" memcached action to invalidate all data in
a cache in one fell swoop.

=head2 dead memcached server detection

An easy way to check whether all related memcached servers are still alive.

=head2 starting/stopping memcached servers

Easy start / stop of indicated memcached servers, mainly intended for
development and testing environments.

=head2 extensive test-suite

An extensive test-suite is included (which is sadly lacking in the
Cache::Memcached distribution).

=head1 BASIC PREMISES

The basic premise is that each piece of information that is to be cached,
can be identified by a L<key>, an optional L<ID>, a L<version> and a
L<namespace>.

The L<key> determines the basic identification of the value to be cached.
The L<ID> specifies a refinement on the basic identification.  The L<version>
ensures that differently formatted values with the same key and ID do not
interfere with each other.  The L<namespace> ensures that different realms
of information (for instance, for different users) do not interfere with each
other.

=head2 key

The default for the key is the fully qualified subroutine name from which
the cached value is accessed.  For instance, if a cached value is to be
accessed from subroutine "bar" in the Foo package, then the key is "Foo::bar".
Explicit keys can be specified and may contain any characters except the
L<delimiter>.

A special case is applicable if the cache is being accessed from the lowest
level in a script.  In that case the default key will be created consisted
of the server name (as determined by C<uname -n>) and the absolute path of
the executing script.

=head2 ID

If no ID is specified for a piece of information, then just the L<key> will be
assumed.  The ID can be any string.  It can for instance be the primary key
of a Class::DBI object.  ID's can be specified as a scalar value, or as list
ref, or as a hash ref (for instance, for multi-keyed Class::DBI objects).

Some examples:

 my $value = $cache->get( $id );

 my $value = $cache->get( [$id,$checkin,$checkout] );

 my $value =
  $cache->get( {id => $id,checkin => $checkin,checkout => $checkout} );

If the ID should be something unique, and you're not interested in the ID
per se (for instance, if you're only interested in the
L<group|"group management"> to which the information will be linked), you
can specify the string C<:unique> to have a unique ID automatically
generated.

=head2 version management

The version indicates which version (generation) of the data is to be fetched
or stored.  By default, it takes the value of the C<$VERSION> variable of the
package to which the L<key> is associated.  This allows new modules that cache
information to be easily installed in a server park without having to fear
data format changes.

A specific version can be specified with each of the L<add>, L<decr>,
L<get>, L<get_multi>, L<incr>, L<replace> and L<set> to indicate the link
with the group of the information being cached.

 Please always use a string as the version indicator.  Using floating point
 values may yield unexpected results, where B<1.0> would actually use B<1>
 as the version.

=head2 namespace management

The namespace indicates the realm to which the data belongs.  By default,
the effective user id of the process (as known by $>) is assumed.  This
allows several users to share the same L<"data server"> and
L<"directory server">, while each still having their own set of cached data.

A specific namespace can be specified with each of the L<add>, L<decr>,
L<get>, L<get_multi>, L<incr>, L<replace> and L<set> to indicate the link
with the group of the information being cached.

=head2 data server

The data server is a Cache::Memcached (compatible) object in which all data
(keyed to a L<"data key">) is stored.  It uses one or more memcached servers.
The data server can be obtained with the L<data> object.

=head2 data key

The data key identifies a piece of data in the L<"data server">.  It is
formed by appending the namespace (by default the user id of the process),
L<version>, L<key> and L<ID>, separated by the L<delimiter>.

If a scalar value is specified as an ID, then that value is used.

If the ID is specified as a list ref, then the values are concatenated with
the L<delimiter>.

If the ID is specified as a hash ref, then the sorted key and value pairs are
concatenated with the L<delimiter>.

=head2 group management

The group concept was added to allow easier management of cached
information.  Since it is impossible to delete cached information from
the L<"data server"> by a matching a wildcard key value (because you can
only access cached information if you know the exact key), another way was
needed to access groups of cached data.

Another way that would not need another (database) backend or be dependent
on running on a single hardware.  This is achieved by using a
L<"directory server">, which is basically just another memcached server
dedicated to keeping a directory of data kept in the L<"data server">.

The group concept allows you to associate a given L<"data key"> to a named
group and an group ID value (e.g. the group named "group" and the name of an
SQL table).  This information is then stored in the L<"directory server">,
from which it is possible to obtain a list of L<"data keys"> associated with
the group name and the ID value.

In the current implementation, the only one group name is recognized by
default:

=over 2

=item group

Intended for generic data without specific keys.

=back

You can specify your own set of group names with the "group_names"
parameter in L<new>.

Group names and ID's can be specified with each of the L<add>, L<decr>,
L<incr>, L<replace> and L<set> to indicate the link with the group of the
information being cached.

The pseudo group ID 'C<:key>' can be specified to indicate that the key
should be used for the group ID.  This is usually used in conjunction with
the generic 'C<group>' group name

A list of valid group names can be obtained with the L<group_names> method.

=head2 directory server

The directory server is a Cache::Memcached (compatible) object that is being
used to store L<"data key">s (as opposed to the data itself) used in
L<"group management">.  If no L<directory> server was specified, then the
data server will be assumed.

If there are multiple memcached servers used for the L<"data server">, then
it is advised to use a separate directory server (as a failure in one of
the memcached backend servers will leave you with an incomplete directory
otherwise).

Should the directory server fail, and it is vital that there is no stale data
in the data server, then a L<flush_all> would need to be executed to ensure
that no stale data remains behind.  Of course, this will also delete all
non-stale data from the data server, so your mileage may vary.

=head2 expiration specification

Expiration can be specified in seconds, but, for convenience, can also be
specified in days, hours and minutes (and seconds).  This is indicated by
a number, immediately followed by a letter B<D> (for days) or B<H> (for hours)
or B<M> (for minutes) or B<S> (for seconds).  For example:

 2D3H

means 2 days and 3 hours, which means B<183600> seconds.

=head2 transparent fork handling

Using this module, you do not have to worry if everything will still work
after a fork().  As soon as it is detected that the process has forked, new
handles will be opened to the memcached servers in the child process (so the
meticulous calling of "disconnect_all" of L<Cache::Memcached> is no longer
needed).

Transparent thread handling is still on the todo list.

=head1 CLASS METHODS

=head2 new

 my $cache = Cache::Memcached::Managed->new;

 my $cache = Cache::Memcached::Managed->new( '127.0.0.1:11311' );

 my $cache = Cache::Memcached::Managed->new(
  data           => '127.0.0.1:11311',   # default: '127.0.0.1:11211'
  directory      => '127.0.0.1:11411',   # default: data
  delimiter      => ';',                 # default: '#'
  expiration     => '1H',                # default: '1D'
  flush_interval => 10,                  # default: none
  namespace      => 'foo',               # default: $> ($EUID)
  group_names    => [qw(foo bar)],       # default: ['group']

  memcached_class => 'Cached::Memcached::Fast', # default: 'Cache::Memcached'
 );

 my $cache = Cache::Memcached::Managed->new( inactive => 1 );

Create a new Cache::Memcached::Managed object.  If there are less than two
input parameters, then the input parameter is assumed to be the value of
the "data" field, with a default of '127.0.0.1:11211'.  If there are more
than one input parameter, the parameters are assumed to be a hash with the
following fields:

=over 2

=item data

 data => '127.0.0.1:11211,127.0.0.1:11212',

 data => ['127.0.0.1:11211','127.0.0.1:11212'],

 data => {
  servers => ['127.0.0.1:11211','127.0.0.1:11212'],
  debug   => 1,
 },

 data => $memcached,

The specification of the memcached server backend(s) for the L<"data server">.
It should either be:

 - string with comma separated memcached server specification
 - list ref with memcached server specification
 - hash ref with Cache::Memcached object specification
 - blessed object adhering to the Cache::Memcached API

There is no default for this field, it B<must> be specified.  The blessed
object can later be obtained with the L<data> method.

=item delimiter

 delimiter => ';',    # default: '#'

Specify the delimiter to be used in key generation.  Should only be specified
if you expect L<key>, L<ID>, L<version> or L<namespace> values to contain the
character '#'.  Can be any character that will not be part of L<key>, L<ID>,
L<version> or L<namespace> values.

The current delimiter can be obtained with the L<delimiter> method.

Using the null byte (I<\\0>) is not advised at this moment, as there are
some encoding issues within L<Cache::Memcached> regarding null bytes.

=item directory

 directory => '127.0.0.1:11311,127.0.0.1:11312',

 directory => ['127.0.0.1:11311','127.0.0.1:11312'],

 directory => {
  servers => ['127.0.0.1:11311','127.0.0.1:11312'],
  debug   => 1,
 },

 directory => $memcached,

The specification of the memcached server backend(s) for the
L<"directory server">.  It should either be:

 - string with comma separated memcached server specification
 - list ref with memcached server specification
 - hash ref with Cache::Memcached object specification
 - blessed object adhering to the Cache::Memcached API

If this field is not specified, the L<"data server"> object will be assumed.
The blessed object can later be obtained with the L<directory> method.

=item expiration

 expiration => '1H',   # default: '1D'

The specification of the default L<expiration>.  The following postfixes
can be specified:

 - S seconds
 - M minutes
 - H hours
 - D days
 - W weeks

The default default expiration is one day ('1D').  The default expiration will
be used whenever no expiration has been specified with L<add>, L<decr>,
L<incr>, L<replace> or L<set>.  The default expiration can be obtained
with the L<expiration> method.

=item flush_interval

 flush_interval => 10,   # default: none

The specification of the default interval between which memcached servers
will be flushed with L<flush_all>.  No interval will be used by default
if not specified.

=item group_names

 group_names => [qw(foo bar)],   # default: ['group']

The specification of allowable group names.  Should be specified as a list
reference to the allowable group names.  Defaults to one element list reference
with 'group' only.

Any group name can be specified, as long it consists of alphanumeric characters
and does not interfere with other functions.  Currently disallowed name are:

 - data
 - delete
 - directory
 - expiration
 - id
 - group_names
 - namespace

There is hardly any penalty for using a lot of different group names in itself.
However, linking cached information to a lot of different groups B<does> have
a penalty.

=item inactive

 inactive => 1,

Indicate that the object is inactive.  If this is specified, an instantiated
object is returned with the same API as Cache::Memcached::Managed, but which
will not do anything.  Intended to be uses in situations where no active
memcached servers can be reached: all code will then function as if there
are no cached values in the cache.

=item memcached_class

  memcached_class => 'Cached::Memcached::Fast',

By default, this module uses the L<Cache::Memcached> class as a C<memcached>
client.  Recently, other implementations have been developed, such as
L<Cache::Memcached::Fast>, that are considered to be API compatible.  To be
able to use these other implementation of the memcached client, you can
specify the name of the class to be used.  By default, C<Cache::Memcached>
will be assumed: the module will be loaded automatically if not loaded already.

=item namespace

 namespace => 'foo',   # default: $> ($EUID)

The specification of the default L<namespace> to be used with L<set>, L<incr>,
L<decr>, L<add>, L<replace>, L<get>, L<get_multi>, L<group>, L<get_group> and
L<grab_group>.  Defaults to the effective user ID of the process, as
indicated by $> ($EUID).

=back

=head1 OBJECT METHODS

The following object methods are available (in alphabetical order):

=head2 add

 $cache->add( $value );

 $cache->add( $value, $id );

 $cache->add( $value, $id, $expiration );

 $cache->add( value      => $value,
              id         => $id,     # optional
              key        => $key,    # optional
              group      => 'foo',   # optional
              expiration => '3H',    # optional
              version    => '1.0',   # optional
              namespace  => 'foo',   # optional
            );

Add a value to the cache, but only if it doesn't exist yet.  Otherwise the
same as L<set>.

=head2 data

 my $data = $cache->data;

Returns the data server object as specified with L<new>.

=head2 dead

 my @dead = $cache->dead;

 my $dead = $cache->dead; # hash ref

Returns the memcached backend L<servers> that appear to be non-functional.
In list context returns the specifications of the servers in alphabetical
order.  Returns a hash reference in scalar context, where the unresponsive
servers are the keys.  Call L<errors> to obtain the number of errors that
were found for each memcached server.

=head2 decr

 $cache->decr;

 $cache->decr( $value );

 $cache->decr( $value, $id, $expiration );

 $cache->decr( value      => $value,  # default: 1
               id         => $id,     # default: key only
               key        => $key,    # default: caller environment
               expiration => '3H',    # default: $cache->expiration
               version    => '1.0',   # default: key environment
               namespace  => 'foo',   # default: $cache->namespace
             );

Decrement a value to the cache, but only if it already exists.  Otherwise the
same as L<set>.  Default for value is B<1>.

Please note that any L<group|"group management"> associations will B<never>
be honoured: it is assumed they would be all the same for all calls to this
counter and are therefore set only with L<set>, L<add> or L<incr>.

=head2 delete

 $cache->delete;

 $cache->delete( $id );

 $cache->delete( id        => $id,     # optional
                 key       => $key,    # optional
                 version   => '1.0',   # optional
                 namespace => 'foo',   # optional
               );

Delete a value, associated with the specified L<"data key">, from the cache.
Can be called with unnamed and named parameters (assumed if two or more
input parameters given).  If called with unnamed parameters, then they are:

=over 2

=item 1 id

The L<ID> to be used to identify the value to be deleted.  Defaults to no ID
(then uses L<key> only).

=back

When using named parameters, the following names can be specified:

=over 2

=item id

The L<ID> to be used to identify the value to be deleted.  Defaults to no ID
(then uses L<key> only).

=item key

The L<key> to be used to identify the value to be deleted.  Defaults to the
default key (as determined by the caller environment).

=item version

The L<version> to be used to identify the value to be deleted.  Defaults to
the version associated with the L<key>.

=item namespace

The L<namespace> to be used to identify the value to be deleted.  Defaults to
the default namespace associated with the object.

=back

=head2 delete_group

 my $deleted = $cache->delete_group( group => 'foo' );

Deletes all cached information related to one or more given groups (specified
as name and ID value pairs) and returns how many items were actually deleted.

=head2 delimiter

 my $delimiter = $cache->delimiter;

Returns the delimiter as (implicitely) specified with L<new>.

=head2 directory

 my $directory = $cache->directory;

Returns the directory cache object as (implicitely) specified with L<new>.

=head2 errors

 my $errors = $cache->errors( "reset" );
 foreach ($cache->servers) {
     print "Found $errors->{$_} errors for $_\n" if exists $errors->{$_};
 }

Return a hash reference with the number of errors when storing data values
in a memcached backend server.  Use L<dead> to find out whether a server is
not responding.  A true value for the input parameter indicates that the
error counts should be reset.

=head2 expiration

 $expiration = $cache->expiration;

Returns the default expiration as (implicitely) specified with L<new>.

=head2 flush_all

 my $flushed = $cache->flush_all;

 my $flushed = $cache->flush_all( 30 ); # flush with 30 second intervals

Initialize contents of all of the memcached backend servers of the
L<"data server">.  The input parameter specifies interval between flushes
of backend memcached servers, default is the L<flush_interval> value
implicitely) specified with L<new>.  Returns whether all memcached L<servers>
were successfully flushed.

Please note that this method returns immediately after instructing each of
the memcached servers.  Also note that the timed flush_all functionality has
only recently become part of the standard memcached API (starting from
publicly released version C<1.2.1>). See the file "flush_interval.patch" for
a patch for release 1.1.12 of the memcached software that implements timed
flush_all functionality.

=head2 flush_interval

 my $interval = $cache->flush_interval;

Returns the default flush interval values used with L<flush_all>, as
(implicitely) specified with L<new>.

=head2 get

 my $value = $cache->get;

 my $value = $cache->get( $id );

 my $value = $cache->get( id        => $id,     # optional
                          key       => $key,    # optional
                          version   => '1.1',   # optional
                          namespace => 'foo',   # optional
                        );

Obtain a value, associated with a L<"data key">, from the cache.  Can be called
with unnamed and named parameters.  If called with unnamed parameters, then
these are:

=over 2

=item 1 id

The L<ID> to be used to identify the value to be fetched.  Defaults to no ID
(then uses the default L<key> only).

=back

When using named parameters, the following names can be specified:

=over 2

=item id

The L<ID> to be used to identify the value to be fetched.  Defaults to no ID
(then uses L<key> only).

=item key

The L<key> to be used to identify the value to be fetched.  Defaults to the
default key (as determined by the caller environment).

=item version

The L<version> to be used to identify the value to be deleted.  Defaults to
the version associated with the L<key>.

=item namespace

The L<namespace> to be used to identify the value to be deleted.  Defaults to
the default namespace associated with the object.

=back

=head2 get_group

 my $group = $cache->get_group(
  group     => $groupname,
  namespace => $namespace,   # default: $cache->namespace
 );
 foreach my $key (sort keys %{$group}) {
   print "key: $key\n"
   my $versions = $group->{$key};
   foreach my $version (sort keys %{$versions}) {
     print "  version: $version\n";
     my $ids = $versions->{$version};
     foreach my $id (sort keys %{$ids}) {
       print "    id: $ids->{$id}\n";
     }
   }
 }

 my @value = $cache->get_group(
  group     => $groupname,
  namespace => $namespace,   # default: $cache->namespace
 );

Either returns a reference to a multi level hash for the given group name and
ID (containing the group's data) in scalar context, or a list with values
(regardless of key, version or id) in list context.

The input parameters are a hash that should contain the group name and
associated ID, with an optional namespace specification.

The structure of the returned hash reference is:

 $result
  |--- key
        |-- version
            |-- id
                |-- value

See L<"group management"> for more information about groups.  See
L<grab_group> for obtaining the group and deleting it at the same time.

=head2 get_multi

 my $hash = $cache->get_multi( \@id );

 my $hash = $cache->get_multi(
  id        => \@id,
  key       => $key,
  namespace => $namespace,
 );

Optimized way of obtaining multiple values, associated with the same key,
from the cache.  Returns a hash reference with values found, keyed to the
associated L<ID>.

Can be called with named and unnamed parameters.  If called with unnamed
parameters, the parameters are:

=over 2

=item 1 id

A list reference of L<ID>'s to be used to identify the values to be fetched.
Must be specified.

=back

When using named parameters, the following names can be specified:

=over 2

=item id

A list reference of L<ID>'s to be used to identify the values to be fetched.
Must be specified.

=item key

The L<key> to be used to identify the values to be fetched.  Defaults to the
default key (as determined by the caller environment).

=item namespace

The L<namespace> for which to fetch values.  Defaults to the namespace that
was (implicitely) specified with L<new>.

=back

=head2 grab_group

 my $group = $cache->grab_group(
  group     => $groupname,
  namespace => $namespace,   # default: $cache->namespace
 );

Same as L<get_group>, but removes the returned data from the cache at the
same time.

=head2 group

 my $group = $cache->group(
  group     => $groupname,
  namespace => $namespace,   # default: $cache->namespace
 );
 foreach my $key (sort keys %{$group}) {
     print "key: $key\n"
     print " ids: @{$group->{$key}}\n";
 }

Return a reference to a multi level hash for the given group name and ID.
The input parameters are a hash that should contain the group name and
associated ID, with an optional namespace specification.

The structure of the hash is:

 $result
  |--- key
        |--- [id1,id2..idN]

See L<"group management"> for more information about groups.

=head2 group_names

 my @group_name = $cache->group_names;
 
 my $group_names = $cache->group_names; # hash ref

Returns the valid group names as (implicitely) specified with L<new>.  Returns
them in alphabetical order if called in a list context, or as a hash ref if
called in scalar context.

=head2 inactive

 print "Inactive!\n" if $cache->inactive;

Returns whether the cache object is inactive.  This happens if a true value
is specified with L<new>.

=head2 incr

 $cache->incr;

 $cache->incr( $value );

 $cache->incr( $value, $id );

 $cache->incr( $value, $id, $expiration );

 $cache->incr( value      => $value,  # default: 1
               id         => $id,     # default: key only
               key        => $key,    # default: caller environment
               expiration => '3H',    # default: $cache->expiration
               version    => '1.1',   # default: key environment
               namespace  => 'foo',   # default: $cache->namespace
               group      => 'bar',   # default: none
             );

Increment a value to the cache.  Otherwise the same as L<set>.  Default for
value is B<1>.

Differently from the incr() of L<Cache::Memcached>, this increment function
is magical in the sense that it automagically will L<add> the counter if it
doesn't exist yet.

Please note that any L<group|"group management"> associations will only be
set when the counter is created (and will be ignored in any subsequent
increments of the same counter).

=head2 namespace

 my $namespace = $cache->namespace;

Obtain the default namespace, as (implicitely) specified with L<new>.

=head2 replace

 $cache->replace( $value );

 $cache->replace( $value, $id );

 $cache->replace( $value, $id, $expiration );

 $cache->replace( value      => $value,  # undef
                  id         => $id,     # default: key only
                  key        => $key,    # default: caller environment
                  expiration => '3H',    # default: $cache->expiration
                  version    => '1.1',   # default: key environment
                  namespace  => 'foo',   # default: $cache->namespace
                );

Replace a value to the cache, but only if it already exists.  Otherwise the
same as L<set>.

Please note that any L<group|"group management"> associations will B<never>
be honoured: it is assumed they would be all the same for all calls to this
counter and are therefore set only with L<set>, L<add> or L<incr>.

=head2 reset

 $cache->reset;

Resets the client side of the cache system.  Mainly for internal usage only.
Always returns true.

=head2 servers

 my @backend = $cache->servers;

 my $backend = $cache->servers; # hash ref

Returns the configuration details of the memcached backend servers that are
currently configured to be used.  Returns a list in alphabetical order in
list context, and a hash ref in scalar context.

See also L<dead> to find out if any of the memcached backend servers are
not responding.

=head2 set

 $cache->set;

 $cache->set( $value );

 $cache->set( $value,$id );

 $cache->set( $value, $id, $expiration );

 $cache->set( value      => $value,  # default: undef
              id         => $id,     # default: key only
              key        => $key,    # default: caller environment
              expiration => '3H',    # default: $cache->expiration
              version    => '1.1',   # default: key environment
              namespace  => 'foo',   # default: $cache->namespace
              group      => 'bar',   # default: none
            );

Set a value in the cache, regardless of whether it exists already or not.

Can be called with named or unnamed parameters (if called with two input
parameters or less).  If called with unnamed parameters, then the input
parameters are:

=over 2

=item 1 value

The value to set in the cache.  Defaults to C<undef>.

=item 2 id

The L<ID> to be used to identify the value.  Defaults to no ID (then uses
L<key> only).

=item 3 expiration

The expiration of the value.  Defaults to the value as specified with
L<expiration> for the L<key>.

=back

With named input parameters, the following names and values can be specified
as a hash (in alphabetical order).

=over 2

=item expiration

The expiration time in seconds of the given value.  Defaults to the value as
specified with L<expiration> for the L<key>.  Values below 30*24*60*60 (30
days) will be considered to be relative to the current time.  Other values
will be assumed to be absolute epoch times (seconds since 1 Jan. 1970 GMT).
See L<"expiration specification"> for more ways to set expiration.

=item id

The L<ID> to be used to identify the value.  Defaults to no ID (then uses
L<key> only).

=item key

The L<key> to be used to identify the value.  Defaults to the default key
(as determined by the caller environment).  Can be specified as a relative
key when prefixed with "::", so that "::bar" would refer to the key "Foo::bar"
if called from the package "Foo".

=item namespace

The L<namespace> to which to associate the value.  Defaults to the namespace
that was (implicitely) specified with L<new>.

=item value

The value to set in the cache.  Defaults to C<undef>.

=item version

The L<version> to be used to identify the value to be set.  Defaults to
the version associated with the L<key>.

=back

Other than these named parameters, any number of group name and ID pairs can
be specified to indicate a link to that group.

=head2 start

 my $started_ok = $cache->start;

 my $started_ok = $cache->start( $config );

Attempts to start the memcached servers that have been configured with L<new>
(and which can be find out with L<servers>) by default, or the servers with
the specified configs.  Returns whether all servers (implicitely) specified
have been started successfully.

This only works if the memcached server(s) will be running on the same
physical hardware as the script is running (which will generally not be
the case in a production environment).  It is therefore of limited
usage generally, but it is a handy feature to have if you're developing
or testing.

See also L<stop>.

=head2 stats

 my $stats = $cache->stats;

Return a hash ref with simple statistics of all of the memcached backend
L<servers>.  The structure of the hash ref is as follows:

 $stats
   |-- server specification
        |-- key
             |-- value

See the memcached server documentation on possible keys and values.

=head2 stop

 my $stopped = $cache->stop;

 my $stopped = $cache->stop( $config );

Attempts to stop the specified memcached L<servers> (as specified by config
value), returns whether all servers have actually stopped.  Defaults to
stopping all servers as initially specified with L<new>.

This only works if the memcached server(s) are running on the same
physical hardware as the script is running (which will generally not be
the case in a production environment).  It is therefore of limited
usage generally, but it is a handy feature to have if you're developing
or testing.

See also L<start>.

=head2 version

 my $version = $cache->version; # hash ref

 my $version = $cache->version( $config ); # hash ref

Obtain the version information of the specified memcached servers, or all
memcached servers being used if no input parameters are specified.  Returns
a hash reference in which the keys are the config information of the servers
used (as returned by L<servers>) and the values are the version information
of the associated memcached server.

=head1 EXAMPLES

=head2 generic grouped event logging

 $cache->set( group => 'event1',
              id    => ':unique',
              value => $value
            );

This would put the value C<$value> into the cache, linked to the group
'event1'.  Since we're not interested in the id of the event, but want to
make sure it is always unique, the pseudo id ':unique' is specified.

A recurring process, usually a cron job, would then need to do the following
to grab all of the values cached:

 my @value = $cache->grab_group( group => 'event1' );
 foreach (@value) {
 # perform whatever you want to do with the value in C<$_>
 }

Please not that only the values are returned because L<grab_group> is called
in list context.

=head2 generic content logging

 my $cache = Cache::Memcached::Managed->new(
  data        => $servers,
  group_names => [qw(hotel_id room_id)],
  expiration  => '1H',
 );
 package Foo;
 sub available {
   my ($cache,$hotel_id,$room_id,$checkin,$checkout) = @_;
   my $available;
   unless ($available = $cache->get( id => [$room_id,$checkin,$checkout] )) {
 # perform complicated calculations setting C<$available>
     $cache->set( id       => [$room_id,$checkin,$checkout],
                  value    => $available,
                  room_id  => $room_id,
                  hotel_id => $hotel_id,
                );
   }
   return $available;
 } #available

This example shows availability caching in a specific subroutine.  Because
the L<get> and the L<set> are located in de same subroutine, it is not
necessary to specify the L<key> (which will be automatically set to
"Foo::available").

Please also not the absence of a L<namespace> specification.  Since each
user of the "available" subroutine should have its "realm" depending on the
cache object, no namespace specification is done.

Now, whenever something related to the hotel_id is changed, a simple:

 $cache->delete_group( hotel_id => $hotel_id );

would be enough to also remove any availability cached in the above example
(for the same value of C<$hotel_id>).

The same would apply when something related to the room_id is changed: a
simple:

 $cache->delete_group( room_id => $room_id );

would be enough to also remove any availability cached in the above example
(for the same value of C<$room_id>).

=head1 CAVEATS

=head2 Race Conditions

Several race conditions exists that can not be fixed because of a lack of
semaphores when using memcached.

Most important race condition is when a group is deleted: between the moment
the main pointer ("directory key") is reset and all of the index keys are
removed, it is possible for another process to be adding information to the
same directory key already.  In a worst case scenario, this means that a
data key can get lost.

To prevent this, a delay of B<2> seconds is applied to each time a group
is deleted.  This should give some time for the cleaning process to clean
up before other processes start accessing again, but it is no way a guarantee
that other processes wouldn't be able to add information if the cleaning
process needs more than 2 seconds to clean up.

=head2 Cron jobs

Because the L<"data key">s by default includes the user id (uid) of the
process as the L<namespace> with which the entry was stored in the cache,
cron jobs (which usually run under a different user id) will need to set
the namespace to the user id of the process storing information into the
cache.

=head2 Incompatibility with Cache module

John Goulah pointed out to me that there is an inconsistency with unnamed
parameter passing in respect to the L<Cache> module.  Specifically, the
C<set> method:

 $c->set( $key, $data, [ $expiry ] );

is incompatible with this module's C<set> method:

 $cache->set;

 $cache->set( $value );

 $cache->set( $value, $id );

 $cache->set( $value, $id, $expiration );

The reason for this simple: in this module, B<all> parameters are optional.
So you can specify just a value: the key will be generated for you from the
caller environment.  Since I felt at the time that you would more likely
specify a value than a key, I made that the first parameter (as opposed to
the C<set> method of L<Cache>.  Changing to the format as imposed by the
L<Cache> module, is not an option at this moment in the lifetime of this
module, as it would break existing code (the same way as it breaks the
test-suite).

=head1 THEORY OF OPERATION

The group management is implemented by keeping a type of directory information
in a (separate) directory memcached server.

For each L<group|"group management"> one directory key is maintained in the
directory memcached server.  This key consists of the string
"Cache::Memcached::Managed::", appended with the L<namespace>, group name,
the L<delimiter> and the ID of the group.  For instance, the directory key
for the group

 group => 'foo'

when running as user "500" would be:

 Cache::Memcached::Managed#500#group#foo

The value of the directory key of a group is used as a counter.  Each time
a some content is added that is linked to the group, that counter will be
incremented and its value prepended to create an C<"index key">.  So the
first index key of the above example, would be:

 1#Cache::Memcached::Managed#500#group#foo

This index key is then also stored in the directory memcached server, with
the original L<"data key"> as its value, and with the same expiration as used
for the data key.

Whenever the index keys are needed of a group (e.g. for fetching all of its
members, or for deleting all of its members), the value of the directory key
of the group is inspected, and that is used to generate a list of index keys.
Suppose the value of the directory key is 5, then then following index keys
would be generated (essentially mapping 1..5):

 1#Cache::Memcached::Managed#500#group#foo
 2#Cache::Memcached::Managed#500#group#foo
 3#Cache::Memcached::Managed#500#group#foo
 4#Cache::Memcached::Managed#500#group#foo
 5#Cache::Memcached::Managed#500#group#foo

If the group is to be deleted or fetched, then all possible values for these
index keys are obtained.  For instance, this would fetch:

 1#Cache::Memcached::Managed#500#group#foo => 500#1.0#Foo::zip#23
 2#Cache::Memcached::Managed#500#group#foo => 500#1.1#Bar::pod#47
 3#Cache::Memcached::Managed#500#group#foo => 500#1.0#Foo::zip#23
 4#Cache::Memcached::Managed#500#group#foo => 500#1.1#Bar::pid#12
 5#Cache::Memcached::Managed#500#group#foo => 500#1.1#Bar::pid#14

Note that index key 1 and 3 return the same backend key.  This can be caused
by doing multiple sets with the same key / id combination.  The final list of
backend keys then becomes:

 500#1.0#Foo::zip#23
 500#1.1#Bar::pod#47
 500#1.1#Bar::pid#12
 500#1.1#Bar::pid#14

If the group is to be deleted (L<delete_group>), then the index keys are
removed from the directory memcached server.  And the associated data
keys are removed from the data memcached server.

If the group (data) is to be fetched (L<group> or L<get_group>), then the
superfluous index keys are removed from the directory memcached server.
In this example, that would be:

 1#Cache::Memcached::Managed#500#group#foo

because:

 3#Cache::Memcached::Managed#500#group#foo

also refers to the data key

 500#1.0#Foo::zip#23

Because of this, the lowest index key with a valid data key has become:

 2#Cache::Memcached::Managed#500#group#foo

making "2" the lowest ordinal number of the index keys.  In that case a
special key, the lowest index key, is saved in the directory memcached
server.  The name of the keys is the same as the directory key for the group,
postfixed with the L<delimiter> and the string "_lowest".  In this example,
this would be:

 Cache::Memcached::Managed#500#group#foo#_lowest

Whenever index keys are fetched, the value of this key is used to determine
the start point for the generation of index keys.  If, in the above example
another fetch of that group would be done, then these index_keys would be
generated (essentially mapping 2..5):

 2#Cache::Memcached::Managed#500#group#foo
 3#Cache::Memcached::Managed#500#group#foo
 4#Cache::Memcached::Managed#500#group#foo
 5#Cache::Memcached::Managed#500#group#foo

Since 32 bit counters are being used, about 4 billion items can be linked
to a group, before a group should be deleted to completely restart.  In most
live situation, this overflow condition will not occur, since this mechanism
was mainly intended to be able to delete groups of information from the cache.
And a deletion will remove the counter and all of its associated keys,
essentially starting again at 1.

=head1 REQUIRED MODULES

 Cache::Memcached (any)
 Scalar::Util (any)

=head1 AUTHOR

 Elizabeth Mattijsen

maintained by LNATION, <thisusedtobeanemail@gmail.com>

=head1 HISTORY

This module started life as an internal module at BOOKINGS Online Hotel
Reservation, the foremost European on-line hotel booking portal.  With
approval and funding of Bookings, this module was generalized and put on
CPAN, for which Elizabeth Mattijsen would like to express her gratitude.

=head1 COPYRIGHT

(C) 2005, 2006 BOOKINGS
(C) 2007, 2008 BOOKING.COM
(C) 2012 Elizabeth Mattijsen

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

=cut
