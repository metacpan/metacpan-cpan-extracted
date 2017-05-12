package Apache::SharedMem;
#$Id: SharedMem.pm,v 1.61 2001/10/04 12:15:22 rs Exp $

=pod

=head1 NAME

Apache::SharedMem - Share data between Apache children processes through the shared memory

=head1 SYNOPSIS

    use Apache::SharedMem qw(:lock :status);

    my $share = new Apache::SharedMem || die($Apache::SharedMem::ERROR);

    $share->set(key => 'some data');

    # ...maybe in another apache child
    my $var = $share->get(key);

    $share->delete(key);

    # delete all keys if the total size is larger than $max_size
    $share->clear if($share->size > $max_size);

    # using an exclusive blocking lock, but with a timeout
    my $lock_timeout = 40; # seconds
    if($share->lock(LOCK_EX, $lock_timeout))
    {
        my $data =...
        ...some traitement...
        
        $share->set(key => $data); # the implicite lock is not overrided
        warn('failed to store data in shared memory') if($share->status & FAILURE);

        $share->unlock;
    }
    
    $share->release;

=head1 DESCRIPTION

This module make it easier to share data between Apache children processes through shared memory.
This module internal functionment is much inspired from IPC::SharedCache, but without any cache management.
The share memory segment key is automatically deduced by the caller package, which means that 2 modules
can use same keys without being concerned about namespace clash. An additionnal namespace is used per application,
which means that the same module, with the same namespace used in two applications doesn't clash too. Application
distinction is made on two things : the process' UID and DOCUMENT_ROOT (for http applications) or current
working directory.

This module handles all shared memory interaction via the IPC::SharedLite and all data 
serialization with Storable. See L<IPC::ShareLite> and L<Storable> for details.

=head1 USAGE

If you are running under mod_perl, you should put this line in your httpd.conf:

    # must be a valid path
    PerlAddVar PROJECT_DOCUMENT_ROOT /path/to/your/projects/root

and in your startup.pl:

    use Apache::SharedMem;

This allow Apache::SharedMem to determine a unique rootkey for all virtual hosts,
and to cleanup this rootkey on Apache stop. PROJECT_DOCUMENT_ROOT is used instead of a
per virtal host's DOCUMENT_ROOT for rootkey's generation.

You can also provide a PROJECT_ID, it's the server's uid by default. This value have to
be numeric:

    PerlAddVar PROJECT_ID 10

=cut

BEGIN
{
    use strict;
    use 5.005;
    use Carp;
    use IPC::SysV qw();
    use IPC::ShareLite qw(:lock);
    use Storable qw(freeze thaw);

    use base qw(Exporter);

    %Apache::SharedMem::EXPORT_TAGS = 
    (
        'all'   => [qw(
                       LOCK_EX LOCK_SH LOCK_UN LOCK_NB
                       WAIT NOWAIT
                       SUCCESS FAILURE
                   )],
        'lock'  => [qw(LOCK_EX LOCK_SH LOCK_UN LOCK_NB)], 
        'wait'  => [qw(WAIT NOWAIT)],
        'status'=> [qw(SUCCESS FAILURE)],
    );
    @Apache::SharedMem::EXPORT_OK   = @{$Apache::SharedMem::EXPORT_TAGS{'all'}};

    use constant WAIT       => 1;
    use constant NOWAIT     => 0;
    use constant SUCCESS    => 1;
    use constant FAILURE    => 2;

    # default values
    use constant IPC_MODE   => 0600; 
    use constant IPC_SEGSIZE=> 65_536;

    $Apache::SharedMem::VERSION  = '0.09';
}

# main
{
    if(exists $ENV{'GATEWAY_INTERFACE'} && $ENV{'GATEWAY_INTERFACE'} =~ /^CGI-Perl/ 
        && defined $Apache::Server::Starting && $Apache::Server::Starting)
    {
        # we are under startup.pl
        if($Apache::SharedMem::ROOTKEY = _get_rootkey())
        {
            Apache->server->register_cleanup(\&Apache::SharedMem::_cleanup);
        }
        else
        {
            print(STDERR "Apache::SharedMem: can't determine the global root key, have you put 'PerlAddVar PROJECT_DOCUMENT_ROOT /path/to/your/project/root/' in your httpd.conf ?\n");
        }
    }
}

=pod

=head1 METHODS

=head2 new  (namespace => 'Namespace', ipc_mode => 0666, ipc_segment_size => 1_000, debug => 1)

=over 4

=item *

C<rootkey> optional, integer

Changes the root segment key. It must be an unsigned integer. Don't use this 
option unless you really know what you are doing. 

This key allows Apache::SharedMem to find the root map of all namespaces (see below) 
owned by your application.

The rootkey is automatically generated using the C<ftok> provided by IPC::SysV. 
Process' UID and DOCUMENT_ROOT (or current working directory) are given to C<ftok> 
so as to guarantee an unique key as far as possible. 

Note, if you are using mod_perl, and you'v load mod_perl via startup.pl 
(see USAGE section for more details), the rootkey is generated once at the apache 
start, based on the supplied PROJECT_DOCUMENT_ROOT and Apache's uid.

=item *

C<namespace> optional, string

Setup manually the namespace. To share same datas, your program must use the same 
namespace. This namespace is set by default to the caller's package name. In most
cases the default value is a good choice. But you may setup manually this value if,
for example, you want to share the same datas between two or more modules. 

=item *

C<ipc_mode> optional, octal

Setup manually the segment mode (see L<IPC::ShareLite>) for more details (default: 0600).
Warning: this value _must_ be octal, see chmod documentation in perlfunc manpage for more details.

=item *

C<ipc_segment_size> optional, integer

Setup manually the segment size (see L<IPC::ShareLite>) for more details (default: 65_536).

=item *

C<debug> optional, boolean

Turn on/off the debug mode (default: 0)

=back

In most case, you don't need to give any arguments to the constructor.

C<ipc_mode> and C<ipc_segment_size> are used only on the first namespace
initialisation. Using different values on an existing key (in shared memory)
has no effect. 

Note that C<ipc_segment_size> is default value of IPC::ShareLite, see
L<IPC::ShareLite> 

On succes return an Apache::SharedMem object, on error, return undef().
You can get error string via $Apache::SharedMem::ERROR.

=cut

sub new 
{
    my $pkg = shift;
    my $self = bless({}, ref($pkg) || $pkg);

    my $options = $self->{options} =
    {
        rootname            => undef, # obsolete, use rootkey instead
        rootkey             => undef, # if not spécified, take the rootname value if exists or _get_rootkey()
        namespace           => (caller())[0],
        ipc_mode            => IPC_MODE,
        ipc_segment_size    => IPC_SEGSIZE,
        readonly            => 0,
        debug               => 0,
    };

    croak("odd number of arguments for object construction")
      if(@_ % 2);
    for(my $x = 0; $x <= $#_; $x += 2)
    {
        croak("Unknown parameter $_[$x] in $pkg object creation")
          unless(exists($options->{lc($_[$x])}));
        $options->{lc($_[$x])} = $_[($x + 1)];
    }

    _init_dumper() if($options->{debug});

    if($options->{rootname})
    {
        carp('obsolete parameter: rootname');
        # delete rootname parameter and if rootkey is undefined, copy the old rootname value in it.
        (defined $options->{rootkey} ? my $devnull : $options->{rootkey}) = delete($options->{rootname});
    }

    $options->{rootkey} = defined($options->{rootkey}) ? $options->{rootkey} : $self->_get_rootkey;

    foreach my $name (qw(namespace rootkey))
    {
        croak("$pkg object creation missing $name parameter.")
          unless(defined($options->{$name}) && $options->{$name} ne '');
    }

    $self->_debug("create Apache::SharedMem instence. options: ", join(', ', map("$_ => " . (defined($options->{$_}) ? $options->{$_} : 'UNDEF'), keys %$options)))
      if($options->{debug});

    $self->_init_namespace || $options->{readonly} || return undef;

    return $self;
}

=pod

=head2 get  (key, [wait, [timeout]])

my $var = $object->get('mykey', WAIT, 50);
if($object->status & FAILURE)
{
    die("can't get key 'mykey´: " . $object->error);
}

=over 4

=item *

C<key> required, string

This is the name of elemenet that you want get from the shared namespace. It can be any string that perl
support for hash's key.

=item *

C<wait> optional

Defined the locking status of the request. If you must get the value, and can't continue without it, set
this argument to constant WAIT, unless you can set it to NOWAIT. 

If the key is locked when you are tring to get the value, NOWAIT return status FAILURE, and WAIT hangup
until the value is unlocked. An alternative is to setup a WAIT timeout, see below.

NOTE: you needs :wait tag import: 

    use Apache::SharedMem qw(:wait)

timeout (optional) integer: 

if WAIT is on, timeout setup the number of seconds to wait for a blocking lock, usefull for preventing 
dead locks.

=back

Following status can be set (needs :status tag import):

SUCCESS FAILURE

On error, method return undef(), but undef() is also a valid answer, so don't test the method status
by this way, use ($obj->status & SUCCESS) instead.

=cut

sub get
{
    my $self    = shift || croak('invalide method call');
    my $key     = defined($_[0]) && $_[0] ne '' ? shift : croak(defined($_[0]) ? 'Not enough arguments for get method' : 'Invalid argument "" for get method');
    my $wait    = defined($_[0]) ? shift : (shift, 1);
    my $timeout = shift;
    croak('Too many arguments for get method') if(@_);
    $self->_unset_error;
    
    $self->_debug("$key ", $wait ? '(wait)' : '(no wait)');

    my($lock_success, $out_lock) = $self->_smart_lock(($wait ? LOCK_SH : LOCK_SH|LOCK_NB), $timeout);
    unless($lock_success)
    {
        $self->_set_error('can\'t get shared lock for "get" method');
        $self->_set_status(FAILURE);
        return(undef());
    }

    # extract datas from the shared memory
    my $share = $self->_get_namespace;

    $self->lock($out_lock, $timeout);

    if(exists $share->{$key})
    {
        $self->_set_status(SUCCESS);
        return($share->{$key}); # can be undef() !
    }
    else
    {
        $self->_set_status(FAILURE);
        $self->_set_error("can't get key $key, it doesn't exists");
        return(undef());
    }
}

=pod

=head2 set  (key, value, [wait, [timeout]])

my $rv = $object->set('mykey' => 'somevalue');
if($object->status eq FAILURE)
{
    die("can't set key 'mykey´: " . $object->error);
}

Try to set element C<key> to C<value> from the shared segment.

=over 4

=item *

C<key> required

name of place where to store the value

=item *

C<value> required

data to store

=item *

C<wait> optional

WAIT or NOWAIT (default WAIT) make or not a blocking shared lock (need :wait tag import).

=item *

C<timeout> optional

if WAIT is on, timeout setup the number of seconds to wait for a blocking lock (usefull for preventing dead locks)

=back

return status: SUCCESS FAILURE

=cut

sub set
{
    my $self    = shift || croak('invalid method call');
    my $key     = defined($_[0]) && $_[0] ne '' ? shift : croak(defined($_[0]) ? 'Not enough arguments for set method' : 'Invalid argument "" for set method');
    my $value   = defined($_[0]) ? shift : croak('Not enough arguments for set method');
    my $wait    = defined($_[0]) ? shift : (shift, 1);
    my $timeout = shift;
    croak('Too many arguments for set method') if(@_);
    $self->_unset_error;
    
    $self->_debug("$key $value ", $wait ? '(wait)' : '(no wait)');

    my($lock_success, $out_lock) = $self->_smart_lock(($wait ? LOCK_EX : LOCK_EX|LOCK_NB), $timeout);
    unless($lock_success)
    {
        $self->_set_error('can\'t get exclusive lock for "set" method');
        $self->_set_status(FAILURE);
        return(undef());
    }

    my $share = $self->_get_namespace;
    $share->{$key} = $value;
    $self->_store_namespace($share);

    $self->lock($out_lock, $timeout);

    $self->_set_status(SUCCESS);
    # return value, like a common assigment
    return($value);
}

=pod

=head2 delete  (key, [wait, [timeout]])

=cut

sub delete
{
    my $self    = shift;
    my $key     = defined($_[0]) ? shift : croak('Not enough arguments for delete method');
    my $wait    = defined($_[0]) ? shift : (shift, 1);
    my $timeout = shift;
    croak('Too many arguments for delete method') if(@_);
    $self->_unset_error;

    $self->_debug("$key ", $wait ? '(wait)' : '(no wait)');

    my $exists = $self->exists($key, $wait, $timeout);
    if(!defined $exists)
    {
        $self->_set_error("can\'t delete key '$key': ", $self->error);
        $self->_set_status(FAILURE);
        return(undef());
    }
    elsif(!$exists)
    {
        $self->_debug("DELETE[$$]: key '$key' wasn't exists");
        $self->_set_status(FAILURE);
        return(undef());
    }

    my($lock_success, $out_lock) = $self->_smart_lock(($wait ? LOCK_EX : LOCK_EX|LOCK_NB), $timeout);
    unless($lock_success)
    {
        $self->_set_error('can\'t get exclusive lock for "delete" method');
        $self->_set_status(FAILURE);
        return(undef());
    }


    my $share = $self->_get_namespace;
    my $rv    = delete($share->{$key});
    $self->_store_namespace($share);
   
    $self->lock($out_lock, $timeout);

    $self->_set_status(SUCCESS);
    # like a real delete
    return($rv);
}

=pod

=head2 exists  (key, [wait, [timeout]])

=cut

sub exists
{
    my $self    = shift;
    my $key     = defined($_[0]) ? shift : croak('Not enough arguments for exists method');
    my $wait    = defined($_[0]) ? shift : (shift, 1);
    my $timeout = shift;
    croak('Too many arguments for exists method') if(@_);
    $self->_unset_error;

    $self->_debug("key: $key");

    my($lock_success, $out_lock) = $self->_smart_lock(($wait ? LOCK_SH : LOCK_SH|LOCK_NB), $timeout);
    unless($lock_success)
    {
        $self->_set_error('can\'t get shared lock for "exists" method');
        $self->_set_status(FAILURE);
        return(undef());
    }

    my $share = $self->_get_namespace;

    $self->lock($out_lock, $timeout);

    $self->_set_status(SUCCESS);
    return(exists $share->{$key});
}

=pod

=head2 firstkey  ([wait, [timeout]])

=cut

sub firstkey
{
    my $self    = shift;
    my $wait    = defined($_[0]) ? shift : (shift, 1);
    my $timeout = shift;
    croak('Too many arguments for firstkey method') if(@_);
    $self->_unset_error;

    my($lock_success, $out_lock) = $self->_smart_lock(($wait ? LOCK_SH : LOCK_SH|LOCK_NB), $timeout);
    unless($lock_success)
    {
        $self->_set_error('can\'t get shared lock for "firstkey" method');
        $self->_set_status(FAILURE);
        return(undef());
    }

    my $share = $self->_get_namespace;

    $self->lock($out_lock, $timeout);
    
    my $firstkey = (keys(%$share))[0];
    $self->_set_status(SUCCESS);
    return($firstkey, $share->{$firstkey});
}

=pod

=head2 nextkey  (lastkey, [wait, [timeout]])

=cut

sub nextkey
{
    my $self    = shift;
    my $lastkey = defined($_[0]) ? shift : croak('Not enough arguments for nextkey method');
    my $wait    = defined($_[0]) ? shift : (shift, 1);
    my $timeout = shift;
    croak('Too many arguments for nextkey method') if(@_);
    $self->_unset_error;

    my($lock_success, $out_lock) = $self->_smart_lock(($wait ? LOCK_SH : LOCK_SH|LOCK_NB), $timeout);
    unless($lock_success)
    {
        $self->_set_error('can\'t get shared lock for "nextkey" method');
        $self->_set_status(FAILURE);
        return(undef());
    }

    my $share = $self->_get_namespace;

    $self->lock($out_lock, $timeout);
    
    $self->_set_status(SUCCESS);
    my @keys = keys %share;
    for(my $x = 0; $x < $#keys; $x++)
    {
        return($share->{$keys[$x+1]}) if($share->{$keys[$x]} eq $lastkey);
    }
    return(undef());
}

=pod

=head2 clear ([wait, [timeout]])

return 0 on error

=cut

sub clear
{
    my $self    = shift;
    my $wait    = defined($_[0]) ? shift : (shift, 1);
    my $timeout = shift;
    croak('Too many arguments for clear method') if(@_);
    $self->_unset_error;

    my($lock_success, $out_lock) = $self->_smart_lock(($wait ? LOCK_EX : LOCK_EX|LOCK_NB), $timeout);
    unless($lock_success)
    {
        $self->_set_error('can\'t get shared lock for "clear" method');
        $self->_set_status(FAILURE);
        return(0);
    }

    $self->_store_namespace({});

    $self->lock($out_lock, $timeout);
    
    $self->_set_status(SUCCESS);
    return(undef());
}

=pod

=head2 release [namespace]

Release share memory space taken by the given namespace or object's namespace. Root map will be release too if empty.

=cut

sub release
{
    my $self        = shift;
    my $options     = $self->{options};
    my $namespace   = defined $_[0] ? shift : $options->{namespace};
    $self->_unset_error;

    $self->_debug($namespace);

    if($options->{readonly})
    {
        $self->_set_error('can\'t call release namespace on readonly mode');
        $self->_set_status(FAILURE);
        return undef;
    }

    $self->_root_lock(LOCK_EX);
    my $root = $self->_get_root;

    unless(exists $root->{'map'}->{$namespace})
    {
        $self->_set_error("Apache::SharedMem: namespace '$namespace' doesn't exists in the map");
        $self->_set_status(FAILURE);
        return(undef());
    }

    my $properties = delete($root->{'map'}->{$namespace});

    $self->_store_root($root);
    $self->_root_unlock;

    delete($self->{namespace});

    my $share = new IPC::ShareLite
    (
        -key     => $properties->{key},
        -size    => $properties->{size},
        -mode    => $properties->{mode},
        -create  => 0,
        -destroy => 1,
    );
    unless(defined $share)
    {
        $self->_set_error("Apache::SharedMem: unable to get shared cache block: $!");
        $self->_set_status(FAILURE);
        return(undef());
    }

    unless(keys %{$root->{'map'}})
    {
        # map is empty, destroy it
        $self->_debug("root map is empty, delete it");
        undef($self->{root});
        my $rm = new IPC::ShareLite
        (
            -key     => $options->{rootkey}, 
            -size    => $options->{ipc_segsize},
            -mode    => $options->{ipc_mode},
            -create  => 0,
            -destroy => 1
        );
        unless(defined $rm)
        {
            $self->_set_status(FAILURE);
            $self->_set_error("can't delete empty root map: $!");
        }
        undef $rm; # call DESTROY method explicitly
    }

    $self->_set_status(SUCCESS);
    return(1);
}

=pod

=head2 destroy

Destroy all namespace found in the root map, and root map itself.

=cut

sub destroy
{
    my $self    = shift;

    $self->_root_lock(LOCK_SH);
    my $root = $self->_get_root;
    $self->_root_unlock;

    my @ns_list = keys(%{$root->{'map'}});
    $self->_debug('segment\'s list for deletion : ', join(', ', @ns_list));
    my $err = 0;
    foreach $ns (@ns_list)
    {
        $self->_debug("release namespace: $ns");
        $self->release($ns);
        $err++ unless($self->status & SUCCESS);
    }
    $self->_set_status($err ? FAILURE : SUCCESS);
}

=pod

=head2 size ([wait, [timeout]])

=cut

sub size
{
    my $self    = shift;
    my $wait    = defined($_[0]) ? shift : (shift, 1);
    my $timeout = shift;
    croak('Too many arguments for size method') if(@_);
    $self->_unset_error;

    my($lock_success, $out_lock) = $self->_smart_lock(($wait ? LOCK_SH : LOCK_SH|LOCK_NB), $timeout);
    unless($lock_success)
    {
        $self->_set_error('can\'t get shared lock for "size" method');
        $self->_set_status(FAILURE);
        return(undef());
    }

    my $serialized;
    eval { $serialized = $self->{namespace}->fetch(); };
    confess("Apache::SharedMem: Problem fetching segment. IPC::ShareLite error: $@") if $@;
    confess("Apache::SharedMem: Problem fetching segment. IPC::ShareLite error: $!") unless(defined $serialized);

    $self->lock($out_lock, $timeout);

    $self->_set_status(SUCCESS);
    return(length $serialized);
}

=pod

=head2 namespaces

Debug method, return the list of all namespace in the root map.
(devel only)

=cut

sub namespaces
{
    my $self    = shift;
    my $record  = $self->_get_root;
    return(keys %{$record->{'map'}});
}

sub dump_map
{
    my $self    = shift;

    _init_dumper();
    my $root_record = $self->_get_root || return undef;
    return Data::Dumper::Dumper($root_record);
}

sub dump
{
    my $self        = shift;
    my $namespace   = defined $_[0] ? shift : croak('too few arguments');

    _init_dumper();
    if(my $ns_obj = $self->_get_namespace_ipcobj($self->_get_root, $namespace))
    {
        return Data::Dumper::Dumper($self->_get_record($ns_obj));
    }
    else
    {
        carp("can't read namespace $namespace: ", $self->error);
        return undef;
    }
}

=pod

=head2 lock ([lock_type, [timeout]])

get a lock on the share segment. It returns C<undef()> if failed, 1 if successed.

=over 4

=item *

C<lock_type> optional

type of lock (LOCK_EX, LOCK_SH, LOCK_NB, LOCK_UN)

=item *

C<timeout> optional

time to wait for an exclusive lock before aborting

=back

return status: FAILURE SUCCESS

=cut

sub lock
{
    my($self, $type, $timeout) = @_;
    $self->_debug("type ", (defined $type ? $type : 'default'), defined $timeout ? ", timeout $timeout" : '');
    my $rv = $self->_lock($type, $timeout, $self->{namespace});
    # we keep a trace of the actual lock status for smart lock mecanisme
    $self->{_lock_status} = $type if($self->status eq SUCCESS);
    return($rv);
}

sub _root_lock  { $_[0]->_debug("type $_[1]", defined $_[2] ? ", timeout $_[2]" : ''); $_[0]->_lock($_[1], $_[2], $_[0]->{root}) }

sub _lock
{
    confess('Apache::SharedMem: Not enough arguments for lock method') if(@_ < 3);
    my($self, $type, $timeout, $ipc_obj) = @_;
    $self->_unset_error;

    $timeout = 0 if(!defined $timeout || $timeout =~ /\D/ || $timeout < 0);
    return($self->unlock) if(defined $type && $type eq LOCK_UN); # strang bug, LOCK_UN, seem not to be same as unlock for IPC::ShareLite... 

    # get a lock
    my $rv;
    eval
    {
        local $SIG{ALRM} = sub {die "timeout"};
        alarm $timeout;
        $rv = $ipc_obj->lock(defined $type ? $type : LOCK_EX);
        alarm 0;
    };
    if($@ || !$rv)
    {
        $self->_set_error("Can\'t lock get lock: $!$@");
        $self->_set_status(FAILURE);
        return(undef());
    };
    $self->_set_status(SUCCESS);
    return(1);
}

=pod

=head2 unlock

freeing a lock

=cut

sub unlock
{
    my $self = shift;
    $self->_debug;
    my $rv = $self->_unlock($self->{namespace});
    $self->{_lock_status} = LOCK_UN if($rv);
    return($rv);
}
sub _root_unlock { $_[0]->_debug; $_[0]->_unlock($_[0]->{root}) }

sub _unlock
{
    my($self, $ipc_obj) = @_;
    $self->_unset_error;

    $ipc_obj->unlock or
    do
    { 
        $self->_set_error("Can't unlock segment"); 
        $self->_set_status(FAILURE);
        return(undef());
    };
    $self->_set_status(SUCCESS);
    return(1);
}

=pod

=head2 error

return the last error message that happened.

=cut

sub error  { return($_[0]->{__last_error__}); }

=pod

=head2 status

Return the last called method status. This status should be used with bitmask operators
&, ^, ~ and | like this :

    # is last method failed ?
    if($object->status & FAILURE) {something to do on failure}

    # is last method don't succed ?
    if($object->status ^ SUCCESS) {something to do on failure}

It's not recommended to use equality operator (== and !=) or (eq and ne), they may don't
work in future versions.

To import status' constants, you have to use the :status import tag, like below :

    use Apache::SharedMem qw(:status);

=cut

sub status { return($_[0]->{__status__}); }

sub _smart_lock
{
    # this method try to implement a smart fashion to manage locks.
    # problem is when user place manually a lock before a get, set,... call. the
    # methode handle his own lock, and in this code :
    #   $share->lock(LOCK_EX);
    #   my $var = $share->get(key);
    #   ...make traitement on $var
    #   $share->set(key=>$var);
    #   $share->unlock;
    #
    # in this example, the first "get" call, change the lock for a share lock, and free
    # the lock at the return.
    # 
    my($self, $type, $timeout) = @_;
    
    if(!defined($self->{_lock_status}) || $self->{_lock_status} & LOCK_UN)
    {
        # no lock have been set, act like a normal lock
        $self->_debug("locking type $type, return LOCK_UN");
        return($self->lock($type, $timeout), LOCK_UN);
    }
    elsif(($self->{_lock_status} & LOCK_SH) && ($type & LOCK_EX))
    {
        # the current lock is powerless than targeted lock type
        my $old_lock = $self->{_lock_status};
        $self->_debug("locking type $type, return $old_lock");
        return($self->lock($type, $timeout), $old_lock);
    }

    $self->_debug("live lock untouch, return $self->{_lock_status}");
    return(1, $self->{_lock_status});
}

sub _init_root
{
    my $self    = shift;
    my $options = $self->{options};
    my $record;

    $self->_debug;
    # try to get a handle on an existing root for this namespace
    my $root = new IPC::ShareLite
    (
        -key        => $options->{rootkey},
        -mode       => $options->{ipc_mode},
        -size       => $options->{ipc_segment_size},
        -create     => 0,
        -destroy    => 0,
    );

    if(defined $root)
    {
        # we have found an existing root
        $self->{root} = $root;
        $self->_root_lock(LOCK_SH);
        $record = $self->_get_root;
        $self->_root_unlock;
        unless(ref $record && ref($record) eq 'HASH' && exists $record->{'map'})
        {
            $self->_debug("map dump: ", $record, Data::Dumper::Dumper($record)) if($options->{debug});
            confess("Apache::SharedMem object initialization: wrong root map type")
        }

        # checking map version
        unless(exists $record->{'version'} && $record->{'version'} >= 2)
        {
            # old map style, we ne upgrade it
            $self->_root_lock(LOCK_EX);
            foreach my $namespace (keys %{$record->{'map'}})
            {
                $namespace = 
                {
                    key     => $namespace,
                    mode    => $options->{ipc_mode},
                    size    => $options->{ipc_segment_size},
                }
            }
            $self->_store_root($record);
            $self->_root_unlock;
        }

        return($record);
    }

    $self->_debug('root map first initalisation');

    if($options->{readonly})
    {
        $self->_set_error("root map ($options->{rootkey}) doesn't exists, can't create one in readonly mode");
        $self->_set_status(FAILURE);
        return(undef);
    }

    # prepare empty root record for new root creation
    $record = 
    {
        'map'       => {},
        'last_key'  => $options->{rootkey},
        'version'   => 2, # map version
    };

    $root = new IPC::ShareLite
    (
        -key        => $options->{rootkey},
        -mode       => $options->{ipc_mode},
        -size       => $options->{ipc_segment_size},
        -create     => 1,
        -exclusive  => 1,
        -destroy    => 0,
    );
    confess("Apache::SharedMem object initialization: Unable to initialize root ipc shared memory segment ($options->{rootkey}): $!")
      unless(defined $root);

    $self->{root} = $root;
    $self->_root_lock(LOCK_EX);
    $self->_store_root($record);
    $self->_root_unlock;

    return($record);
}

sub _get_namespace_ipcobj
{
    my($self, $rootrecord, $namespace) = @_;

    if(my $properties = $rootrecord->{'map'}->{$namespace})
    {
        $self->_debug('namespace exists');
        # namespace already exists
        $share = new IPC::ShareLite
        (   
            -key            => $properties->{key},
            -mode           => $properties->{mode},
            -size           => $properties->{size},
            -create         => 0,
            -destroy        => 0,
        );
        confess("Apache::SharedMem: Unable to get shared cache block ($namespace=$properties->{key}): $!") unless(defined $share);
        $self->_set_status(SUCCESS);
        return $share;
    }
    else
    {
        $self->_set_status(FAILURE);
        $self->_set_error("no such namespace: '$namespace'");
        return undef();
    }
}

sub _init_namespace
{
    my $self        = shift;
    my $options     = $self->{options};
    my $namespace   = $options->{namespace};

    $self->_debug;
    my $rootrecord  = $self->_init_root || return undef;

    my $share;
    if(exists $rootrecord->{'map'}->{$namespace})
    {
        $share = $self->_get_namespace_ipcobj($rootrecord, $namespace);
    }
    else
    {
        if($options->{readonly})
        {
            $self->_set_error("namespace '$namespace' doesn't exists, can't create one in readonly mode");
            $self->_set_status(FAILURE);
            return(undef);
        }

        $self->_debug('namespace doesn\'t exists, creating...');
        # otherwise we need to find a new segment
        my $ipc_key  = $rootrecord->{'last_key'}+1;
        my $ipc_mode = $options->{ipc_mode};
        my $ipc_size = $options->{ipc_segment_size};
        for(my $end = $ipc_key + 10_000; $ipc_key != $end; $ipc_key++)
        {
            $share = new IPC::ShareLite
            (
                -key        => $ipc_key,
                -mode       => $ipc_mode,
                -size       => $ipc_size,
                -create     => 1,
                -exclusive  => 1,
                -destroy    => 0,
            );
            last if(defined $share);
        }
        croak("Apache::SharedMem: searched through 10,000 consecutive locations for a free shared memory segment, giving up: $!")
          unless(defined $share);

        # update the root record
        $self->_root_lock(LOCK_EX);
        $rootrecord->{'map'}->{$namespace} =
        {
            key     => $ipc_key,
            mode    => $ipc_mode,
            size    => $ipc_size,
        };
        $rootrecord->{'last_key'} = $ipc_key;
        $self->_store_record({}, $share); # init contents, to avoid root map's corruption in certain circumstances
        $self->_store_root($rootrecord);
        $self->_root_unlock;
    }

    return($self->{namespace} = $share);
}

# return a most hase possible, unique IPC identifier
sub _get_rootkey
{
    my $self = shift;
    my($ipckey, $docroot, $uid);

    if(exists $ENV{'GATEWAY_INTERFACE'} && $ENV{'GATEWAY_INTERFACE'} =~ /^CGI-Perl/)
    {
        # we are under mod_perl
        if(defined $Apache::SharedMem::ROOTKEY)
        {
            $ipckey = $Apache::SharedMem::ROOTKEY; # look at import() for more details
        }
        else
        {
            require Apache;
            if(defined $Apache::Server::Starting && $Apache::Server::Starting)
            {
                # we are in the startup.pl
                my $s    = Apache->server;
                $docroot = $s->dir_config->get('PROJECT_DOCUMENT_ROOT')
                    ? ($s->dir_config->get('PROJECT_DOCUMENT_ROOT'))[-1] : return undef;
                $uid     = $s->dir_config->get('PROJECT_ID')
                    ? ($s->dir_config->get('PROJECT_ID'))[-1] : $s->uid;
            }
            else
            {
                my $r    = Apache->request;
                my $s    = $r->server;
                $docroot = $r->document_root;
                $uid     = $s->uid;
            }
        }
    }
    elsif(exists $ENV{'DOCUMENT_ROOT'})
    {
        # we are under mod_cgi
        $docroot = $ENV{DOCUMENT_ROOT};
        $uid     = $<;
    }
    else
    {
        # we are in an undefined environment
        $docroot = $ENV{PWD};
        $uid     = $<;
    }

    unless(defined $ipckey)
    {
        confess("PROJECT_DOCUMENT_ROOT doesn't exists or can't be accessed: " . (defined $docroot ? $docroot : '[undefined]'))
          if(not defined $docroot || $docroot eq '' || not -e $docroot || not -r $docroot);
        confess("PROJECT_ID is not numeric: " . (defined $uid ? $uid : '[undefined]')) 
          if(not defined $uid || $uid =~ /[^\d\-]/);
        $ipckey = IPC::SysV::ftok($docroot, $uid);
    }

    $self->_debug("document_root=$docroot, uid=$uid, rootkey=$ipckey") if(defined $self);
    return($ipckey);
}

sub _get_namespace { $_[0]->_debug; $_[0]->_get_record($_[0]->{namespace}) }
sub _get_root      { $_[0]->_debug; $_[0]->_get_record($_[0]->{root}) }

sub _get_record
{
    my($self, $ipc_obj) = @_;

    return undef unless(defined $ipc_obj);

    my($serialized, $record);

    # fetch the shared block
    eval { $serialized = $ipc_obj->fetch(); };
    confess("Apache::SharedMem: Problem fetching segment. IPC::ShareLite error: $@") if $@;
    confess("Apache::SharedMem: Problem fetching segment. IPC::ShareLite error: $!") unless(defined $serialized);

    $self->_debug(4, 'storable src: ', $serialized);

    if($serialized ne '')
    {
        # thaw the shared block
        eval { $record = thaw($serialized) };
        confess("Apache::SharedMem: Invalid share block recieved from shared memory. Storable error: $@") if $@;
        confess("Apache::SharedMem: Invalid share block recieved from shared memory.") unless(ref($record) eq 'HASH');
    }
    else
    {
        # record not initialized
        $record = {};
    }

    $self->_debug(4, 'dump: ', Data::Dumper::Dumper($record)) if($self->{options}->{debug});

    return($record);
}

sub _store_namespace { $_[0]->_debug; $_[0]->_store_record($_[1], $_[0]->{namespace}) }
sub _store_root      { $_[0]->_debug; $_[0]->_store_record($_[1], $_[0]->{root}) }

sub _store_record
{
    my $self    = shift;
    my $share   = defined($_[0]) ? (ref($_[0]) eq 'HASH' ? shift() : croak('Apache::SharedMem: unexpected error, wrong data type')) : croak('Apache::SharedMem; unexpected error, missing argument');
    my $ipc_obj = defined $_[0] ? shift : return undef;

    if($self->{options}->{readonly})
    {
        $self->_set_error('can\'t store any data in readonly mode');
        $self->_set_status(FAILURE);
        return undef;
    }

    $self->_debug(4, 'dump: ', Data::Dumper::Dumper($share)) if($self->{options}->{debug});

    my $serialized;

    # freeze the shared block
    eval { $serialized = freeze($share) };
    confess("Apache::SharedMem: Problem while the serialization of shared data. Storable error: $@") if $@;
    confess("Apache::SahredMem: Problem while the serialization of shared data.") unless(defined $serialized && $serialized ne '');

    $self->_debug(4, 'storable src: ', $serialized);

    # store the serialized data
    eval { $ipc_obj->store($serialized) };
    confess("Apache::SharedMem: Problem storing share segment. IPC::ShareLite error: $@") if $@;

    return($share);
}

sub _debug
{
    return() unless($_[0]->{options}->{debug});
    my $self  = shift;
    my $dblvl = defined($_[0]) && $_[0] =~ /^\d$/ ? shift : 1;
    printf(STDERR "### DEBUG %s method(%s) pid[%s]: %s\n", (caller())[0], (split(/::/, (caller(1))[3]))[-1], $$, join('', @_)) if($self->{options}->{debug} >= $dblvl);
}

sub _set_error
{
    my $self = shift;
    $self->_debug($Apache::SharedMem::ERROR = $self->{__last_error__} = join('', @_));
}

sub _unset_error
{
    my $self = shift;
    $Apache::SharedMem::ERROR = $self->{__last_error__} = '';
}

sub _set_status
{
    my $self = shift;
    $self->{__status__} = defined($_[0]) ? $_[0] : '';
    $self->_debug("setting status to $_[0]");
}

sub _init_dumper
{
    require Data::Dumper;
    $Data::Dumper::Indent    = 2;
    $Data::Dumper::Terse     = 1;
    $Data::Dumper::Quotekeys = 0;
}

sub _cleanup
{
    if(defined $Apache::SharedMem::ROOTKEY)
    {
        my $share = new Apache::SharedMem;
        $share->destroy if(defined $share)
    }
}

DESTROY
{
    # auto unlock on destroy, it seem to work under mod_perl with Apache::Registry, not tested yet under mod_perl handlers
    $_[0]->unlock 
      if(defined $_[0]->{_lock_status} && ($_[0]->{_lock_status} & LOCK_SH || $_[0]->{_lock_status} & LOCK_EX));
}

1;

=pod

=head1 EXPORTS

=head2 Default exports

None.

=head2 Available exports

Following constant is available for exports : LOCK_EX LOCK_SH LOCK_UN LOCK_NB
WAIT NOWAIT SUCCESS FAILURE

=head2 Export tags defined

The tag ":all" will get all of the above exports.
Following tags are also available :

=over 4

=item

:status

Contents: SUCCESS FAILURE

This tag is really recommended to the importation all the time.

=item

:lock

Contents: LOCK_EX LOCK_SH LOCK_UN LOCK_NB

=item

:wait

WAIT NOWAIT

=back

=head1 AUTHOR

Olivier Poitrey E<lt>rs@rhapsodyk.netE<gt>

=head1 LICENCE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with the program; if not, write to the Free Software
Foundation, Inc. :

59 Temple Place, Suite 330, Boston, MA 02111-1307

=head1 COPYRIGHT

Copyright (C) 2001 - Olivier Poitrey

=head1 PREREQUISITES

Apache::SharedMem needs IPC::ShareLite, Storable both available from the CPAN.

=head1 SEE ALSO

L<IPC::ShareLite>, L<shmget>, L<ftok>

=head1 HISTORY

$Log: SharedMem.pm,v $
Revision 1.61  2001/10/04 12:15:22  rs
Very major bugfix that made module unable to work correctly under mod_perl !
New version 0.09 to CPAN immediatly

Revision 1.60  2001/10/02 09:40:32  rs
Bugfix in _get_rootkey private method: trap empty docroot or no read access
to docroot error.

Revision 1.59  2001/09/24 08:19:40  rs
status now return bitmask values

Revision 1.58  2001/09/21 14:45:30  rs
little doc fixes

Revision 1.57  2001/09/21 12:43:41  rs
Change copyright

Revision 1.56  2001/09/20 12:45:03  rs
Documentation update: adding an EXPORTS section

Revision 1.55  2001/09/19 14:19:41  rs
made a trace more verbose

Revision 1.54  2001/09/18 08:46:32  rs
Documentation upgrade

Revision 1.53  2001/09/17 14:56:41  rs
Suppression of ROOTKEYS global hash, obsolete.
Documentation update: USAGE => PROJECT_ID

Revision 1.52  2001/08/29 15:54:01  rs
little bug fix in _get_rootkey

Revision 1.51  2001/08/29 14:28:08  rs
add warning on no existing document_root in _get_rootkey

Revision 1.50  2001/08/29 12:59:02  rs
some documentation update.
get method now return undef() if value is undefined.

Revision 1.49  2001/08/29 08:30:32  rs
syntax bugfix

Revision 1.48  2001/08/29 08:27:13  rs
doc fix

Revision 1.47  2001/08/29 08:24:23  rs
meny documentation updates

Revision 1.46  2001/08/28 16:42:14  rs
adding better support of mod_perl with a cleanup method handled to Apache's
registry_cleanup.

Revision 1.45  2001/08/28 10:17:00  rs
little documentation fix

Revision 1.44  2001/08/28 08:45:12  rs
stop using autouse for Data::Dumper, mod_perl don't like it
add auto unlock on DESTROY, seem to work under mod_perl with Apache::Registry
TODO test with mod_perl handlers

Revision 1.43  2001/08/27 15:42:02  rs
bugfix in release method, on root map cleanup, ipc_mode must be defined
bugfix in _init_namespace method, if object was create without any "set" called,
the empty namespace won't be allocated.

Revision 1.42  2001/08/24 16:11:25  rs
    - Implement a more efficient IPC key generation for the root segment, using
      the system ftok() function provied by IPC::SysV module
    - Pod documentation
    - Default IPC mode is now 0600
    - We now keep ipc_mode and ipc_segment_size in the root map for calling IPC::ShareLite
      with same values.
    - Add "readonly" parameter to constructor
    - Feature enhancement, add "dump" and "dump_map" methods
    - Data::Dumper is now autoused
    - Feature enhancement, release method now release root map when it go empty
    - Feature enhancement, add a "destroy" method, that call "release" method on all root-map's
      namespaces. Usefull for cleaning shared memory on Apache shutdown.
    - Misc bugfixes

Revision 1.41  2001/08/23 08:37:03  rs
major bug, _get_rootkey was call mod_perl method on a wrong object

Revision 1.40  2001/08/23 08:08:18  rs
little documentation update

Revision 1.39  2001/08/23 00:56:32  rs
vocabulary correction in POD documentation

Revision 1.38  2001/08/22 16:10:15  rs
- Pod documentation
- Default IPC mode is now 0600
- We now keep ipc_mode and ipc_segment_size in the root map for calling IPC::ShareLite
  with same values.
- Bugfix, release now really clean segments (seem to be an IPC::ShareLite bug)

Revision 1.37  2001/08/21 13:17:35  rs
switch to version O.07

Revision 1.36  2001/08/21 13:17:02  rs
add method _get_rootkey. this method allow constructor to determine a more
uniq ipc key. key is generated with IPC::SysV::ftok() function, based on
ducument_root and user id.

Revision 1.35  2001/08/17 13:28:18  rs
make precedence more readable in "_set_status" method
some pod corrections

Revision 1.34  2001/08/08 14:15:07  rs
forcing default lock to LOCK_EX

Revision 1.33  2001/08/08 14:01:45  rs
grrr syntax error second part, it's not my day.

Revision 1.32  2001/08/08 13:59:01  rs
syntax error introdius with the last fix

Revision 1.31  2001/08/08 13:56:35  rs
Starting version 0.06
fixing an "undefined value" bug in lock methode

Revision 1.30  2001/07/04 08:41:11  rs
major documentation corrections

Revision 1.29  2001/07/03 15:24:19  rs
fix doc

Revision 1.28  2001/07/03 14:53:02  rs
make a real changes log

