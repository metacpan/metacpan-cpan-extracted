###############################################################################
# Purpose : Generic Cache Factory with various policy factories.
# Author  : Sam Graham
# Created : 23 Jun 2008
# CVS     : $Id: CacheFactory.pm,v 1.25 2010-02-16 12:25:40 illusori Exp $
###############################################################################

package Cache::CacheFactory;

use warnings;
use strict;

use Carp;

use Cache::Cache;

use Cache::CacheFactory::Storage;
use Cache::CacheFactory::Expiry;
use Cache::CacheFactory::Object;

use base qw/Cache::Cache/;

$Cache::CacheFactory::VERSION = '1.10';

$Cache::CacheFactory::NO_MAX_SIZE = -1;

@Cache::CacheFactory::EXPORT    = qw();
@Cache::CacheFactory::EXPORT_OK = qw(
    best_available_storage_policy
    best_available_pruning_policy
    best_available_validity_policy
    $NO_MAX_SIZE
    );
%Cache::CacheFactory::EXPORT_TAGS = (
    best_available => [ qw(
        best_available_storage_policy
        best_available_pruning_policy
        best_available_validity_policy
        ) ],
    );


sub new
{
    my $class = shift;
    my ( $self, %options );

    %options = ref( $_[ 0 ] ) ? %{$_[ 0 ]} : @_;

    $self = { policies => {}, compat => {}, };
    bless $self, ( ref( $class ) || $class );

    #
    #  Compat options with Cache::Cache subclasses.
    $self->{ namespace } = $options{ namespace } || 'Default';

    #
    #  Compat with Cache::Cache.
    $self->{ compat }->{ default_expires_in } = $options{ default_expires_in }
        if exists $options{ default_expires_in };

    #
    #  Cache-wide settings.
    $self->set_positional_set( $options{ positional_set } )
        if exists $options{ positional_set };

    #  Control first-run eligibility for auto-purging.
    $self->set_last_auto_purge( $options{ last_auto_purge } )
        if defined( $options{ last_auto_purge } );

    #  Auto-purge intervals.
    $self->set_auto_purge_interval( $options{ auto_purge_interval } )
        if exists $options{ auto_purge_interval };
    $self->set_auto_purge_on_set_interval(
        $options{ auto_purge_on_set_interval } )
        if exists $options{ auto_purge_on_set_interval };
    $self->set_auto_purge_on_get_interval(
        $options{ auto_purge_on_get_interval } )
        if exists $options{ auto_purge_on_get_interval };

    #  Auto-purge toggles.
    $self->set_auto_purge_on_set( $options{ auto_purge_on_set } )
        if exists $options{ auto_purge_on_set };
    $self->set_auto_purge_on_get( $options{ auto_purge_on_get } )
        if exists $options{ auto_purge_on_get };

    #  Do we quietly (or silently) fail on missing policies?
    $self->{ nonfatal_missing_policies } = 1
        if $options{ nonfatal_missing_policies };
    $self->{ nonwarning_missing_policies } = 1
        if $options{ nonwarning_missing_policies };

    #  Do we deeply clone our data when setting it?
    $self->{ no_deep_clone } = 1
        if $options{ no_deep_clone };

    #
    #  Grab our policies from the options.
    $self->set_storage_policies(  $options{ storage  } );
    $self->set_pruning_policies(  $options{ pruning  } )
        if $options{ pruning  };
    $self->set_validity_policies( $options{ validity } )
        if $options{ validity };

    if( $#{$self->{ policies }->{ storage }->{ order }} == -1 )
    {
        #  OK, we've got no storage policies, we only get this
        #  far if nonfatal_missing_policies has been set.
        #  Either way it's a fatal error for a cache, so we
        #  return an undef.
        $self->warning( "No valid storage policies supplied" )
            unless $self->{ nonwarning_missing_policies };
        return( undef );
    }

    return( $self );
}

sub new_cache_entry_object
{
#    my ( $self ) = @_;
    return( Cache::CacheFactory::Object->new() );
}

sub set
{
    my $self = shift;
    my ( $param, $object, $key, $data, $mode );

    #  Aiii, backwards-compat with Cache::Cache->set().
    if( $self->{ compat }->{ positional_set } and
        ( ( $self->{ compat }->{ positional_set } ne 'auto' ) or
          ( $_[ 0 ] ne 'key' ) ) )
    {
        my ( $next_arg, $expires_in );

        $key        = shift;
        $data       = shift;
        $expires_in = shift;
        $param = {};
        if( defined( $next_arg = shift ) )
        {
            #  Hackery to support mode from add()/replace().
            if( $next_arg eq 'mode' )
            {
                $mode = shift;
            }
            else
            {
                $param->{ expires_in } = $expires_in;
                #  TODO: warn if expires set and not time policy?
            }
        }
        $mode = shift if defined( $next_arg = shift ) and $next_arg eq 'mode';
    }
    else
    {
        $param = ref( $_[ 0 ] ) ? { %{$_[ 0 ]} } : { @_ };
        if( exists( $param->{ key } ) )
        {
            $key  = $param->{ key };
            delete $param->{ key };
        }
        else
        {
            warn "No key supplied to ${self}->set(), are you calling it " .
                "with compat-style positional parameters but haven't set " .
                "the positional_set option?";
            return;
        }
        if( exists( $param->{ data } ) )
        {
            $data = $param->{ data };
            delete $param->{ data };
        }
        else
        {
            warn "No data supplied to ${self}->set(), are you calling it " .
                "with compat-style positional parameters but haven't set " .
                "the positional_set option?";
            return;
        }
        if( exists( $param->{ mode } ) )
        {
            $mode = $param->{ mode };
            delete $param->{ mode };
        }
    }

    if( $mode )
    {
        if( $self->exists( $key ) )
        {
            return if $mode eq 'add';
        }
        else
        {
            return if $mode eq 'replace';
        }
    }

    $param->{ created_at }    = time() unless $param->{ created_at };
    $param->{ no_deep_clone } = 1      if $self->{ no_deep_clone };

    #  Create Cache::CacheFactory::Object instance.
    $object = $self->new_cache_entry_object();

    #  Initialize it from the param.
    $object->initialize( $key, $data, $param );

    $self->foreach_driver( 'validity', 'set_object_validity',
        $key, $object, $param );
    $self->foreach_driver( 'pruning',  'set_object_pruning',
        $key, $object, $param );
    if( $param->{ no_deep_clone } )
    {
        #  Since most Cache::Cache's do their own deep cloning
        #  we try a bit of a hack to try to bypass that.
        $self->foreach_policy( 'storage',
            sub
            {
                my ( $self, $policy, $storage ) = @_;

                #  Only try this hack on things that subclass behaviour
                #  we understand.
                if( $storage->isa( 'Cache::BaseCache' ) )
                {
                    my ( $backend );

                    if( $backend = $storage->_get_backend() )
                    {
                        $object->set_size( undef );
                        $object->set_key( undef );

                        $backend->store( $storage->get_namespace(),
                            $key, $object );
                        return;
                    }
                }

                #  Ok, we couldn't figure out how to do our dirty hack...
                $storage->set_object( $key, $object, $param );
            } );
    }
    else
    {
        $self->foreach_driver( 'storage',  'set_object',
            $key, $object, $param );
    }

    $self->auto_purge( 'set' );
}

sub get
{
    my ( $self, $key ) = @_;
    my ( $object );

    my $storage_policies  = $self->{ policies }->{ storage };
    my $validity_policies = $self->{ policies }->{ validity };
    foreach my $storage_policy ( @{$storage_policies->{ order }} )
    {
        my $storage = $storage_policies->{ drivers }->{ $storage_policy };
        next unless defined( $object = $storage->get_object( $key ) );

        foreach my $validity_policy ( @{$validity_policies->{ order }} )
        {
            next if $validity_policies->{ drivers }->{ $validity_policy }->is_valid( $self, $storage, $object );
            #  TODO: should remove from this storage. optionally?
            undef $object;
            last;
        }
        last if defined $object;
    }

    #  Check of auto_purge_on_get isn't strictly neccessary but
    #  it saves the cost of a method call in the failure case.
    $self->auto_purge( 'get' ) if $self->{ auto_purge_on_get };

    return( $object->get_data() ) if defined $object;
    return( undef );
}

sub get_object
{
    my ( $self, $key ) = @_;
    my ( $object );

    $self->foreach_policy( 'storage',
        sub
        {
            my ( $self, $policy, $storage ) = @_;

            $object = $storage->get_object( $key );
            $self->last() if defined $object;
        } );

    return( $object );
}

sub set_object
{
    my ( $self, $key, $object ) = @_;

    #  Backwards compat with Cache::Object objects.
    unless( $object->isa( 'Cache::CacheFactory::Object' ) )
    {
        my ( $param );

        $param = {};
        $param->{ no_deep_clone } = 1 if $self->{ no_deep_clone };
        $object = Cache::CacheFactory::Object->new_from_old( $object, $param );
        #  TODO: compat with expires_at
    }

    $self->foreach_driver( 'storage', 'set_object', $key, $object );
}

sub remove
{
    my ( $self, $key ) = @_;

    $self->foreach_driver( 'storage', 'remove', $key );
}

#
#  CacheFactory extensions.
sub exists
{
    my ( $self, $key ) = @_;
    my ( $exists );

    $self->foreach_policy( 'storage',
        sub
        {
            my ( $self, $policy, $storage ) = @_;

            #  If they've implemented an exists method, use it,
            #  otherwise just do it the slow way.
            if( $storage->can( 'exists' ) )
            {
                $exists = $storage->exists( $key );
            }
            else
            {
                $exists = defined( $storage->get_object( $key ) );
            }

            return $self->last() if $exists;
        } );

    return( $exists ? 1 : 0 );
}


#
#  These following provide Cache::Memcached style interface.
#    get_multi(), incr() and decr() cannot be "properly" implemented
#    to use underlying functions because our object wrapper prevents
#    the operations being single calls to the storage policy's
#    implementation (if they have one), this then directly negates
#    the purpose of these methods existing in the first place.
sub delete
{
    my ( $self, $key ) = @_;

    $self->remove( $key );
}

sub add
{
    my $self = shift;

    $self->set( @_, mode => 'add' );
}

sub replace
{
    my $self = shift;

    $self->set( @_, mode => 'replace' );
}

#  
#sub get_multi
#{
#    my ( $self, @keys ) = @_;
#}

#sub incr
#{
#    my ( $self, $key, $value ) = @_;
#}

#sub decr
#{
#    my ( $self, $key, $value ) = @_;
#}

sub Clear
{
    my ( $self, @args ) = @_;

    $self->foreach_driver( 'storage', 'Clear', @args );
}

sub clear
{
    my ( $self, @args ) = @_;

    $self->foreach_driver( 'storage', 'clear', @args );
}

sub Purge
{
    my ( $self, @args ) = @_;

    $self->purge( @args );
}

sub purge
{
    my ( $self, @args ) = @_;

    $self->foreach_driver( 'pruning', 'purge', $self, @args );
}

sub auto_purge
{
    my ( $self, $set_or_get ) = @_;

    return unless $self->{ "auto_purge_on_${set_or_get}" };

    return if $self->{ last_auto_purge } >=
              time() - $self->{ "auto_purge_${set_or_get}_interval" };

    #  Set timestamp before purge in case we bomb out.
    #  Ideally we should do some manner of locking to prevent
    #  concurrent purges. 
    #  Maybe that's the application's business instead.
    $self->{ last_auto_purge } = time();

    $self->purge();

    #  Update timestamp after purge so we don't spinlock if the purge
    #  takes longer than the interval.
    $self->{ last_auto_purge } = time();
}

sub Size
{
    my ( $self, @args ) = @_;
    my ( $size );

    $size = 0;
    $self->foreach_policy( 'storage',
        sub
        {
            my ( $self, $policy, $driver ) = @_;

            #  Cache::FastMemoryCache 0.01 dies on Size(), workaround.
            return if $driver->isa( 'Cache::FastMemoryCache' );
            $size += $driver->Size( @args );
        } );

    return( $size );
}

sub size
{
    my ( $self ) = @_;
    my ( $size );

    $size = 0;
    $self->foreach_policy( 'storage',
        sub
        {
            my ( $self, $policy, $driver ) = @_;

            $size += $driver->size();
        } );

    return( $size );
}

sub get_namespaces
{
    my ( $self ) = @_;
    my ( %namespaces );

    %namespaces = ();
    $self->foreach_policy( 'storage',
        sub
        {
            my ( $self, $policy, $driver ) = @_;

            #  Cache::NullCache->get_namespaces() dies, workaround it.
            return $self->last() if $driver->isa( 'Cache::NullCache' );
            foreach my $namespace ( $driver->get_namespaces() )
            {
                $namespaces{ $namespace }++;
            }
        } );

    return( keys( %namespaces ) );
}

sub get_keys
{
    my ( $self ) = @_;
    my ( %keys );

    %keys = ();
    $self->foreach_policy( 'storage',
        sub
        {
            my ( $self, $policy, $driver ) = @_;

            foreach my $key ( $driver->get_keys() )
            {
                $keys{ $key }++;
            }
        } );

    return( keys( %keys ) );
}

sub get_identifiers
{
    my ( $self ) = @_;

    return( $self->get_keys() );
}



sub set_positional_set
{
    my ( $self, $positional_set ) = @_;

    $self->{ compat }->{ positional_set } = $positional_set;
}

sub get_positional_set
{
    my ( $self ) = @_;

    return( $self->{ compat }->{ positional_set } );
}

sub set_default_expires_in
{
    my ( $self, $default_expires_in ) = @_;
    my ( $time_pruning, $time_validity );

    $time_pruning  = $self->get_policy_driver( 'pruning', 'time' );
    $time_validity = $self->get_policy_driver( 'validity', 'time' );

    unless( $time_pruning or $time_validity )
    {
        carp "Cannot set_default_expires_in() when neither a pruning nor " .
            "a validity policy of 'time' is set.";
        return;
    }

    $time_pruning->set_default_expires_in( $default_expires_in )
        if $time_pruning;
    $time_validity->set_default_expires_in( $default_expires_in )
        if $time_validity;
}

sub get_default_expires_in
{
    my ( $self ) = @_;
    my ( $time_pruning, $time_validity );

    $time_pruning  = $self->get_policy_driver( 'pruning', 'time' );
    $time_validity = $self->get_policy_driver( 'validity', 'time' );

    unless( $time_pruning or $time_validity )
    {
        carp "Cannot get_default_expires_in() when neither a pruning nor " .
            "a validity policy of 'time' is set.";
        return( undef );
    }

    #  If they have both set, we go with the validity one since that's
    #  generally the one that has more immediate effect.
    #  If they're setting it via default_expires_in then both should
    #  be the same anyway...
    return( $time_validity->get_default_expires_in() ) if $time_validity;
    return( $time_pruning->get_default_expires_in() )  if $time_pruning;
}

sub limit_size
{
    my ( $self, $size ) = @_;
    my ( $size_policy );

    $size_policy = $self->get_policy_driver( 'pruning', 'size' );

    unless( $size_policy )
    {
        carp "Cannot limit_size() when no 'size' pruning policy is set.";
        return;
    }

    $size_policy->limit_size( $self, $size );
}

sub set_last_auto_purge
{
    my ( $self, $last_auto_purge ) = @_;

    $self->{ last_auto_purge } =
        ( $last_auto_purge eq 'now' ) ? time() : $last_auto_purge;
}

sub get_last_auto_purge
{
    my ( $self ) = @_;

    return( $self->{ last_auto_purge } );
}

sub set_auto_purge_on_set
{
    my ( $self, $auto_purge_on_set ) = @_;

    $self->{ auto_purge_on_set } = $auto_purge_on_set;
}

sub get_auto_purge_on_set
{
    my ( $self ) = @_;

    return( $self->{ auto_purge_on_set } );
}

sub set_auto_purge_on_get
{
    my ( $self, $auto_purge_on_get ) = @_;

    $self->{ auto_purge_on_get } = $auto_purge_on_get;
}

sub get_auto_purge_on_get
{
    my ( $self ) = @_;

    return( $self->{ auto_purge_on_get } );
}

sub set_auto_purge_interval
{
    my ( $self, $auto_purge_interval ) = @_;

    $self->set_auto_purge_on_set_interval( $auto_purge_interval );
    $self->set_auto_purge_on_get_interval( $auto_purge_interval );
}

sub get_auto_purge_interval
{
    my ( $self ) = @_;

    return( $self->get_auto_purge_on_get_interval() ||
        $self->get_auto_purge_on_set_interval() );
}

sub set_auto_purge_on_set_interval
{
    my ( $self, $auto_purge_interval ) = @_;

    $self->{ auto_purge_on_set_interval } = $auto_purge_interval;
}

sub get_auto_purge_on_set_interval
{
    my ( $self ) = @_;

    return( $self->{ auto_purge_on_set_interval } );
}

sub set_auto_purge_on_get_interval
{
    my ( $self, $auto_purge_interval ) = @_;

    $self->{ auto_purge_on_get_interval } = $auto_purge_interval;
}

sub get_auto_purge_on_get_interval
{
    my ( $self ) = @_;

    return( $self->{ auto_purge_on_get_interval } );
}

sub set_namespace
{
    my ( $self, $namespace ) = @_;

    $self->{ namespace } = $namespace;
    $self->foreach_driver( 'storage', 'set_namespace', $namespace );
}

sub get_namespace
{
    my ( $self ) = @_;

    return( $self->{ namespace } );
}

#  Coerce the policy arg into a hashref and ordered param list.
sub _normalize_policies
{
    my ( $self, $policies ) = @_;

    return( {
        order => [ $policies ],
        param => { $policies => {} },
        } )
        unless ref( $policies );
    return( {
        order => [ keys( %{$policies} ) ],
        param => $policies,
        } )
        if ref( $policies ) eq 'HASH';
    if( ref( $policies ) eq 'ARRAY' )
    {
        my ( $ret );

        $self->error( "Policy arg wasn't even-sized arrayref" )
            unless $#{$policies} % 2;

        $ret = { order => [], param => {} };
        for( my $i = 0; $i <= $#{$policies}; $i += 2 )
        {
            push @{$ret->{ order }}, $policies->[ $i ];
            $ret->{ param }->{ $policies->[ $i ] } = $policies->[ $i + 1 ];
        }

        return( $ret );
    }
    $self->error( "Unknown policy format: " . ref( $policies ) );
}

sub set_policy
{
    my ( $self, $policytype, $policies ) = @_;
    my ( $factoryclass );

    $self->error( "No $policytype policy set" ) unless $policies;

    $policies = $self->_normalize_policies( $policies );
    $self->{ policies }->{ $policytype } = $policies;

    $factoryclass = 'Cache::CacheFactory::' .
        ( $policytype eq 'storage' ? 'Storage' : 'Expiry' );

    #  Handle compat param.
    $policies->{ param }->{ time }->{ default_expires_in } =
        $self->{ compat }->{ default_expires_in }
        if exists $self->{ compat }->{ default_expires_in } and
           $policies->{ param }->{ time } and
           not exists $policies->{ param }->{ time }->{ default_expires_in };

    $policies->{ drivers } = {};
    foreach my $policy ( @{$policies->{ order }} )
    {
        my ( $driver, $param );

        $param = $policies->{ param }->{ $policy };
        delete $policies->{ param }->{ $policy };

        #  Ensure we set the namespace if one isn't set explicitly.
        $param->{ namespace } = $self->{ namespace }
            if $policytype eq 'storage' and not exists $param->{ namespace };

        $driver = $factoryclass->new( $policy, $param );
        if( $driver )
        {
            $policies->{ drivers }->{ $policy } = $driver;
        }
        else
        {
            my ( $driver_module, $error );

            $driver_module = $factoryclass->get_registered_class( $policy );
            $error = "Unable to load driver for $policytype policy: $policy";
            if( $driver_module )
            {
                $error .= "; is $driver_module installed?";
            }
            else
            {
                $error .= "; is '$policy' a typo, or a custom policy that " .
                    "hasn't been registered with $factoryclass?";
            }
            if( $self->{ nonfatal_missing_policies } )
            {
                $self->warning( $error )
                    unless $self->{ nonwarning_missing_policies };
            }
            else
            {
                $self->error( $error );
            }
            #  Prune it from the policy run order.
            $policies->{ order } =
                [ grep { $_ ne $policy } @{$policies->{ order }} ];
        }

    }
}

sub get_policy_driver
{
    my ( $self, $policytype, $policy ) = @_;

    return( $self->{ policies }->{ $policytype }->{ drivers }->{ $policy } );
}
sub get_policy_drivers
{
    my ( $self, $policytype ) = @_;

    return( $self->{ policies }->{ $policytype }->{ drivers } );
}

#
#
#  Next few methods run a closure against each policy or invoke a
#  method against each policy's driver.  It's a bit inefficient but
#  saves on duplicating the same ordering and looping code everywhere
#  and keeps me sane(ish).  Oh for a native ordered-hashref.
sub last
{
#    my ( $self ) = @_;
    $_[ 0 ]->{ _last } = 1;
}

sub foreach_policy
{
    my ( $self, $policytype, $closure ) = @_;

    my $policies = $self->{ policies }->{ $policytype };
    foreach my $policy ( @{$policies->{ order }} )
    {
        $closure->( $self, $policy, $policies->{ drivers }->{ $policy } );
        next unless $self->{ _last };
        delete $self->{ _last };
        return;
    }
}

sub foreach_driver
{
    my ( $self, $policytype, $method, @args ) = @_;

    my $policies = $self->{ policies }->{ $policytype };
    foreach my $policy ( @{$policies->{ order }} )
    {
        $policies->{ drivers }->{ $policy }->$method( @args );
        next unless $self->{ _last };
        delete $self->{ _last };
        return;
    }
}

sub set_storage_policies
{
    my ( $self, $policies ) = @_;

    $self->set_policy( 'storage', $policies );
}

sub set_pruning_policies
{
    my ( $self, $policies ) = @_;

    $self->set_policy( 'pruning', $policies );
}

sub set_validity_policies
{
    my ( $self, $policies ) = @_;

    $self->set_policy( 'validity', $policies );
}

sub _error_message
{
    my $self = shift;
    my ( $error );

    $error = join( '', @_ );
    return( "Cache error: $error" );
}

sub error
{
    my $self = shift;
    die( $self->_error_message( @_ ) );
}

sub warning
{
    my $self = shift;
    warn( $self->_error_message( @_ ) );
}

#
#
#  Non-OO functions.
#

sub _best_available_policy
{
    my ( $policytype, @policies ) = @_;
    my ( $factoryclass );

    $factoryclass = 'Cache::CacheFactory::' .
        ( $policytype eq 'storage' ? 'Storage' : 'Expiry' );
    while( my $policy = shift( @policies ) )
    {
        return( $policy ) if $factoryclass->get_registered_class( $policy );
    }
    return( undef );
}

sub best_available_storage_policy
{
    return( _best_available_policy( 'storage', @_ ) );
}

sub best_available_pruning_policy
{
    return( _best_available_policy( 'pruning', @_ ) );
}

sub best_available_validity_policy
{
    return( _best_available_policy( 'validity', @_ ) );
}


1;

__END__

=pod

=head1 NAME

Cache::CacheFactory - Factory class for Cache::Cache and other modules.

=head1 SYNOPSIS

 use Cache::CacheFactory;

 my $cache = Cache::CacheFactory->new( storage => 'file' );

 $cache->set( 'customer', 'Fred' );
 ... Later ...
 print $cache->get( 'customer' );
 ... prints "Fred"

=head1 DESCRIPTION

Cache::CacheFactory is a drop-in replacement for the L<Cache::Cache> subclasses
allowing you to access a variety of caching policies from a single place,
mixing and matching as you choose rather than having to search for the
cache module that provides the exact combination you want.

In a nutshell you specify a policy for storage, for pruning and for
validity checks and CacheFactory hooks you up with the right modules
to provide that behaviour while providing you with the same API you're
used to from Cache::Cache - the only thing you need to change is
your call to the constructor.

More advanced use allows you to set multiple policies for pruning and
validity checks, and even for storage although that's currently of
limited use.

=head1 METHODS

=over

=item $cache = Cache::CacheFactory->new( %options )

=item $cache = Cache::CacheFactory->new( $options )

Construct a new cache object with the specified options supplied as
either a hash or a hashref.

Errors during construction are usually fatal and reported via
C<die>, some have C<nonfatal_*> options to override this behaviour
in which case an C<undef> value will be returned from C<new()>.

See L</"OPTIONS"> below for more details on possible options.

=item $cache->set( key => $key, data => $data, [ expires_in => $expires_in, %additional_args ] )

=item $cache->add( key => $key, data => $data, [ expires_in => $expires_in, %additional_args ] )

=item $cache->replace( key => $key, data => $data, [ expires_in => $expires_in, %additional_args ] )

=item $cache->set( $key, $data, [ $expires_in ] ) (only in compat-mode)

=item $cache->add( $key, $data, [ $expires_in ] ) (only in compat-mode)

=item $cache->replace( $key, $data, [ $expires_in ] ) (only in compat-mode)

Associates C<$data> with C<$key> in the cache.

C<< $cache->add() >> is a special form of C<< $cache->set() >> that will
set the key if-and-only-if it doesn't already exist in the cache.

C<< $cache->replace() >> is a special form of C<< $cache->set() >> that will
set the key if-and-only-if it does already exist in the cache.

B<Note>: the existence test and set in C<< $cache->add() >> and
C<< $cache->replace() >> is B<NOT> an atomic operation, if you
have a shared cache you will need to implement your own locking
mechanism if you need to rely on this behaviour.

A deep copy of C<$data> will automatically be taken if it is a reference,
you can turn this behaviour off with the cache option C<no_deep_copy>
detailed in L</"OPTIONS"> below.

C<$expires_in> indicates the time in seconds until this data should be
erased, or the constant C<$EXPIRES_NOW>, or the constant C<$EXPIRES_NEVER>.
Defaults to C<$EXPIRES_NEVER>. This variable can also be in the extended
format of "[number] [unit]", e.g., "10 minutes". The valid units are s,
second, seconds, sec, m, minute, minutes, min, h, hour, hours, d, day,
days, w, week, weeks, M, month, months, y, year, and years. Additionally,
C<$EXPIRES_NOW> can be represented as "now" and C<$EXPIRES_NEVER> can be
represented as "never".

C<$expires_in> is silently ignored (future versions may warn) if
the cache didn't choose a 'time' pruning or validity policy at setup.

Any additional args will be passed on to the policies chosen at setup
time (and documented by those policy modules.)

B<IMPORTANT:> The positional args version of this method is only
available if the compat flag C<positional_set> was supplied as an
option when the cache was created.

If C<positional_set> is a true value but not set to C<'auto'> then the
hash format is disabled and C<set()> acts as if it is always given
positional args - this will do unwanted things if you pass it hash
args.

If C<positional_set> was given C<'auto'> as a value then C<set()> will
attempt to auto-detect when you're supplying positional args and
when you're supplying hash args, it does this by the rather-breakable
means of asking if the first arg is called 'key', if so then it
assumes you're passing a hash, otherwise it'll fall back to using
positional args.

Examples:

  $cache->set(
      key        => 'customer',
      data       => 'Fred',
      expires_in => '10 minutes',
      );

  $created_at = time();
  $template = build_my_template( '/path/to/webpages/index.html' );
  $cache->set(
      key          => 'index',
      data         => $template,
      created_at   => $time,
      dependencies => [ '/path/to/webpages/index.html', ],
      );

=item $data = $cache->get( $key );

Gets the data associated with C<$key> from the first storage policy
that contains a fresh cached copy.

=item $cache->remove( $key );

Removes the data associated with C<$key> from each of the storage policies
in this cache.

=item $cache->delete( $key );

This is a convenience alias for C<< $cache->remove( $key ) >>.

=item $boolean = $cache->exists( $key );

Returns true if data associated with C<$key> exists in the cache and
false if there is no data associated with that key.

This method makes no assumption about the form of the data stored:
if you store a value of C<undef> you will still get a true return from
C<< $cache->exists() >>.

=item $object = $cache->get_object( $key );

Returns the L<Cache::CacheFactory::Object> used to store the underlying
data associated with C<$key>. This behaves much the same as the
L<Cache::Object> returned by C<< Cache::Cache->get_object() >>.

=item $cache->set_object( $key, $object );

Associates C<$key> with L<Cache::CacheFactory::Object> C<$object>. If you
supply a L<Cache::Object> in C<$object> instead, L<Cache::CacheFactory> will
create a new L<Cache::CacheFactory::Object> instance as a copy before
storing the copy.

=item @keys = $cache->get_keys();

Returns a list of all keys in this instance's namespace across
all storage policies.

=item @keys = $cache->get_identifiers();

B<This method is deprecated>. Behaves identically to
C<< $cache->get_keys() >>, use that instead. Provided only
for backwards compatibility.

=item $cache->set_namespace( $namespace );

Sets the cache's namespace as per the C<namespace> option.
This does B<NOT> move any existing cache contents over to
the new namespace, it simply points the cache object at the
new namespace.

=item $namespace = $cache->get_namespace();

Returns the current namespace as set either by
C<< $cache->set_namespace() >> or the C<namespace> option.

=item $cache->Clear();

Clears all caches using each of the storage policies. This does
not just clear caches with the exact same policies: it calls
C<Clear()> on each policy in turn.

=item $cache->clear();

Removes all cached data for this instance's namespace from each
of the storage policies.

=item $cache->Purge();

B<COMPAT BUSTER:> C<Purge()> now does the same thing as C<purge()>
since it isn't clear quite what it should do with multiple
caches with different pruning and storage policies. Its use
is strongly deprecated.

=item $cache->purge();

Applies the pruning policy to all data in this namespace.

=item $size = $cache->Size();

Returns the total size of all objects in all caches with any
of the storage policies of this cache.

=item $size = $cache->size();

Returns the total size of all objects in this namespace in any of
the storage policies of this cache.

=item @namespaces = $cache->get_namespaces();

Returns a list of all namespaces in any of the storage policies of
this cache.

=item $cache->set_positional_set( 0 | 1 | 'auto' );

=item $positional_set = $cache->get_positional_set();

These two methods allow you to alter the behaviour of the
C<positional_set> compatibility option.

See the documentation on C<< $cache->set() >> or L</"OPTIONS">
for more information on this setting.

=item $cache->set_default_expires_in( $expires_in );

=item $expires_in = $cache->get_default_expires_in();

These two methods allow you to alter the C<expires_in>
compatibility option.

See the documentation on C<< $cache->set() >> or  L</"OPTIONS">
for more information on this setting.

Note that when you have both a pruning and validity policy
of 'time' the C<default_expires_in> of the validity policy
is returned in preference to the pruning policy. Both will
most likely be identical unless you're intentionally setting
them differently via the new API, in which case: use the
new API to get the value you want.

=item $cache->set_last_auto_purge( 0 | 'now' | $seconds_since_epoch );

=item $seconds_since_epoch = $cache->get_last_auto_purge();

Sets or gets the timestamp of the last auto-purge.

See the documention for C<last_auto_purge> in L</"OPTIONS">
for further details.

=item $cache->set_auto_purge_on_set( 0 | 1 );

=item $cache->set_auto_purge_on_get( 0 | 1 );

=item $boolean = $cache->get_auto_purge_on_set();

=item $boolean = $cache->get_auto_purge_on_get();

Turns auto-purging on/off for C<< $cache->set() >> or
C<< $cache->get() >>, or returns the current state
of auto-purging for each.

See the documention for C<auto_purge_on_set> and
C<auto_purge_on_get> in L</"OPTIONS"> for further details.

=item $cache->set_auto_purge_interval( $seconds );

=item $cache->set_auto_purge_on_set_interval( $seconds );

=item $cache->set_auto_purge_on_get_interval( $seconds );

=item $seconds = $cache->get_auto_purge_interval();

=item $seconds = $cache->get_auto_purge_on_set_interval();

=item $seconds = $cache->get_auto_purge_on_get_interval();

Set or get the appropriate auto-purge interval as per the
C<auto_purge_interval>, C<auto_purge_on_set_interval> or
C<auto_purge_on_get_interval> options.

Look at L</"OPTIONS"> for further details.

=item $cache->limit_size( $size );

Only available if a pruning policy of 'size' has been set,
this method will allow you to perform a one-off prune of
the storage policies to C<$size> size or below.

This behaves like the C<limit_size()> method of
L<Cache::SizeAwareCache>.

=back

=head1 NON-OBJECT-ORIENTATED FUNCTIONS

=over

=item $policy = best_available_storage_policy( @policies );

=item $policy = best_available_pruning_policy( @policies );

=item $policy = best_available_validity_policy( @policies );

These helper functions take a list of policies in the order you
prefer them and returns the first one that is installed on the
running system. This is useful if you don't know which packages
are installed on the target system and have a list of alternatives
you want to check against.

For example:

  use Cache::CacheFactory qw/:best_available/;

  my $cache = Cache::CacheFactory->new(
      storage => best_available_storage_policy( qw/sharedmemory memory file/ ),
      );

This would produce either: a shared-memory cache if
L<Cache::SharedMemoryCache> was available, failing that it would
try a memory cache if L<Cache::MemoryCache> was available, and finally
it would try L<Cache::FileCache> if the other two failed.

By default these functions are not exported, you will need to
supply C<:best_available> on the use line to import them.

=back

=head1 CONSTANTS

You can export the following constants:

=over

=item $NO_MAX_SIZE

You can export this with C<< use Cache::CacheFactory qw/$NO_MAX_SIZE/; >>
and supply it to the C<max_size> option of a 'size' pruning policy.

This value of C<$NO_MAX_SIZE> is compatible with that defined by
L<Cache::SizeAwareCache>, so you can use either source.

See L<Cache::CacheFactory::Expiry::Size> for further details.

=back

=head1 OPTIONS

The following options may be passed to the C<new()> constructor:

=over

=item storage => $storage_policy

=item storage => { $storage_policy1 => $policy1_options, $storage_policy2 => $policy2_options, ... }

=item storage => [ $storage_policy1 => $policy1_options, $storage_policy2 => $policy2_options, ... ]

=item pruning => $pruning_policy

=item pruning => { $pruning_policy1 => $policy1_options, $pruning_policy2 => $policy2_options, ... }

=item pruning => [ $pruning_policy1 => $policy1_options, $pruning_policy2 => $policy2_options, ... ]

=item validity => $validity_policy

=item validity => { $validity_policy1 => $policy1_options, $validity_policy2 => $policy2_options, ... }

=item validity => [ $validity_policy1 => $policy1_options, $validity_policy2 => $policy2_options, ... ]

Chooses a storage, pruning, or validity policy (or policies) possibly
passing in a hashref of options to each policy.

Passing a hashref of policies is probably a bad idea since you have
no control over the order in which policies are processed, if you
supply them as an arrayref then they will be run in order.

See L</"POLICIES"> below for more information on policies.

=item namespace => $namespace

The namespace associated with this cache. Defaults to "Default" if
not explicitly set. All keys are unique within a given namespace,
you B<will> risk key-clashes with other applications if you use a
persistent or shared storage policy and do not set a namespace
to something unique to do with your application.

=item auto_purge_on_set   => 0 | 1

=item auto_purge_on_get   => 0 | 1

If set to a true value turns auto-purging on, if set to a false
value turns auto-purging off.

C<auto_purge_on_set> determines if calling C<< $cache->set() >>
can trigger an auto-purge, and C<auto_purge_on_get> does the
same for C<< $cache->get() >>.

Since a purge can be an expensive operation you will usually
want to enable only C<auto_purge_on_set> if you're in the usual
I<read-often write-seldom> environment, although see the example
below in C<auto_purge_interval> for an alternative strategy.

=item auto_purge_interval => $interval

=item auto_purge_on_set_interval => $interval

=item auto_purge_on_get_interval => $interval

Sets the interval between auto-purges to C<$interval> seconds.

When checking whether an auto-purge should occur, the last
purge time is compared to the current time, if it is more than
C<$interval> seconds in the past, a new C<purge()> will be
triggered.

By use of C<auto_purge_on_set_interval> and
C<auto_purge_on_get_interval> you can tune the interval
independently for each.

This may be useful in some situations:

  my $cache = Cache::CacheFactory->new(
    storage => 'memory',
    pruning => { 'time' => { default_prune_after => '1 m' } },
    auto_purge_on_set => 1,
    auto_purge_on_get => 1,
    auto_purge_on_set_interval => 5,
    auto_purge_on_get_interval => 30,
    );

This will set a cache that prunes items older than 1 minute and
will auto-purge after a C<< $cache->set() >> if there hasn't
been an auto-purge in the past 5 seconds. It will also auto-purge
after a C<< $cache->get() >> if there hasn't been an auto-purge
in the past 30 seconds.

This means that the expense of the auto-purge will usually be
added to the (relatively) expensive C<set()> most of the time, and
only delay the usually cheap C<get()> if there hasn't been a
recent C<set()> to trigger the auto-purge.

C<auto_purge_interval> sets both C<auto_purge_on_set_interval> and
C<auto_purge_on_get_interval> to the same value.

Note that for the auto-purge intervals to be used you will need to
turn on either C<auto_purge_on_set> or C<auto_purge_on_get>.

=item default_expires_in  => $expiry_time

This option is for backwards compatibility with L<Cache::Cache>.

If set it is passed on to the C<'time'> pruning and/or validity policy
if you have chosen either of them.

B<WARNING:> if you do NOT have an pruning or validity policy of 'time',
this option is silently ignored. This may raise a warning in future
versions.

You can also manipulate this option via
C<< $cache->set_default_expires_in() >> and
C<< $cache->get_default_expires_in() >> after cache creation.

=item positional_set => 0 | 1 | 'auto'

This option is for backwards compatibility with L<Cache::Cache>.

If set to a true value that isn't 'auto' it indicates that
C<< $cache->set() >> should behave exactly as that in
L<Cache::Cache>, accepting only positional
parameters. If you set this option you will be unable to
supply parameters to policies other than C<expires_in> to
the C<'time'> pruning or validity policy.

If set to a value of 'auto' L<Cache::CacheFactory>
will attempt to auto-detect whether you're supplying positional
or named parameters to C<< $cache->set() >>. This mechanism is
not very robust: it simply looks to see if the first parameter
is the value 'key', if so it assumes you're supplying named
parameters.

The default behaviour, or if you set C<positional_set> to a false
value, is to assume that named parameters are being supplied.

Generally speaking, if you know for sure that all your code is
using positional parameters you should set it to true, if you
know all your code is using the new named parameters syntax
you should set it false (or leave it undefined), and if you're
uncertain or migrating from one to the other, you should set it
to 'auto' and be careful that you always supply the C<key> param
first.

You can also manipulate this option via
C<< $cache->set_positional_set() >> and
C<< $cache->get_positional_set() >> after cache creation.

=item last_auto_purge => 0 | 'now' | $seconds_since_epoch

This option grants you initial control of when the cache should
consider the most recent auto-purge to have occurred, by default
this is set to 0 meaning no auto-purge has occurred and one
should run as soon as it is triggered.

If you set it to 'now' then the cache will "pretend" that
an auto-purge occurred at the same time as the cache creation
and won't run another until the auto-purge interval has
expired (C<auto_purge_interval>, C<auto_purge_on_set_interval>,
or C<auto_purge_on_get_interval> as appropriate).

You can also supply a number of seconds since the epoch,
as returned by C<time()>, if you want more precise control -
such as if your application stores the last auto-purge
time in some external manner.

=item nonfatal_missing_policies => 0 | 1

=item nonwarning_missing_policies => 0 | 1

Setting C<nonfatal_missing_policies> to a true value will
suppress the default C<die> behaviour when a requested policy
is missing and will instead generate a C<warn>.

If you also set C<nonwarning_missing_policies> to a true value,
this C<warn> will also be surpressed.

=item no_deep_clone => 0 | 1

Setting C<no_deep_clone> to a true value will prevent the
default behaviour of taking a deep clone of the data provided to
C<< $cache->set() >>.

This can be a performance gain if you don't need to be paranoid
about the cache sharing references with whatever handed them in,
or if you want to handle the cloning yourself within your application.

Regretfully C<no_deep_clone> on the cache can only act in an
advisory capacity to storage policies, they may choose to
disregard the flag and many of the L<Cache::Cache> modules
will do just this. (Not unreasonably: they predate
L<Cache::CacheFactory> considerably.) L<Cache::CacheFactory>
tries hard to convince them to avoid taking clones but may or
may not succeed depending on precisely what you're attempting,
you'll have to suck it and see I'm afraid.

Using this option with a storage policy of 'memory' will provide
you with similar behaviour to L<Cache::FastMemoryCache>, with
the exception that, unavoidably, a deep clone is always created
on C<< $cache->get() >>. If this is undesirable, install
L<Cache::FastMemoryCache> and use a storage policy of 'fastmemory'
in conjunction with setting C<no_deep_clone>.

=back

=head1 POLICIES

There are three types of policy you can set: storage, pruning and
validity.

L<Storage|/"Storage Policies"> determines what mechanism is used to store
the data.

L<Pruning|"Pruning and Validity Policies"> determines what mechanism is used
to reap or prune the cache.

L<Validity|"Pruning and Validity Policies"> determines what mechanism is
used to determine if a cache entry is still up-to-date.

=head2 Storage Policies

Some common storage policies:

=over

=item file

Implemented using L<Cache::FileCache>, this provides
on-disk caching.

=item memory

Implemented using L<Cache::MemoryCache>, this provides
per-process in-memory caching.

=item sharedmemory

Implemented using L<Cache::SharedMemoryCache>,
this provides in-memory caching with the cache shared between processes.

=item fastmemory

Implemented using L<Cache::FastMemoryCache>,
this provides in-memory caching like the 'memory' policy but with
all the deep-copies of data stripped out, best used in conjunction
with the C<no_deep_clone> option set on the cache.

=item null

Implemented using L<Cache::NullCache>, this cache is
used to provide a fake cache that never stores anything.

=back

=head2 Pruning and Validity Policies

All I<pruning> and I<validity> policies are interchangable, the difference
between the two is when the policy is applied:

A pruning policy is applied when you C<purge()> or periodically if
C<auto_purge_on_set> or C<autopurge_on_get> is set, it removes all
entries that fail the policy from the cache. Note that an item can
be I<eligible> to be pruned but still be in the cache and fetched
successfully from the cache - it won't be removed until C<purge()>
is called either manually or automatically.

A validity policy is applied when an entry is retreived to ensure
that it's still valid (or fresh or up-to-date if you prefer). If the entry
isn't still valid then it's ignored as if it was never in the cache.
Unlike pruning, validity always applies - you will never be able
to fetch an item from the cache if it is invalid according to the
policies you have chosen.

A handy shorthand is that pruning determines how long we keep the
data lying around in case we need it again, validity determines
whether we trust that it's still accurate.

=over

=item time

This provides pruning and validity policies similar to those
built into L<Cache::Cache> using the C<expires_at>
param.

It allows you to check for entries that are over a certain age.

=item size

This policy prunes the cache to attempt to keep it under a
supplied size, much like
L<Cache::SizeAwareFileCache>
and the other C<Cache::SizeAware*> modules.

This policy probably doesn't make much sense as a validity
policy, although you can use it.

=item lastmodified

This policy compares the created date of the cache entry
to the last-modified date of a list of file dependencies.

If the create date is older than any of the file last-modified
dates the entry is pruned or regarded as invalid.

This is useful if you have data compiled or parsed from
source data-files that may change, such as HTML templates
or XML files.

=item forever

This debugging policy never regards items as invalid or
prunable, it's implemented as the default behaviour in
L<Cache::CacheFactory::Expiry::Base>.

=back

=head1 WRITING NEW POLICIES

It's possible to write custom policy modules of your own, all
policies are constructed using the
L<Cache::CacheFactory::Storage>
or L<Cache::CacheFactory::Expiry>
class factories. C<Storage> provides the storage policies and
C<Expiry> provides both the pruning and validity policies.

New storage policies should conform to the L<Cache::Cache>
API, in particular they need to implement C<set_object> and
C<get_object>.

New expiry policies (both pruning and validity) should follow
the API defined by
L<Cache::CacheFactory::Expiry::Base>,
ideally by subclassing it.

Once you've written your new policy module you'll need to
register it with L<Cache::CacheFactory>
as documented in L<Class::Factory>, probably
by placing one of the the following lines (depending on type)
somewhere in your module:

  Cache::CacheFactory::Storage->register_factory_type(
      mypolicyname => 'MyModules::MyPolicyName' );

  Cache::CacheFactory::Expiry->register_factory_type(
      mypolicyname => 'MyModules::MyPolicyName' );

Then you just need to make sure that your application has a

  use MyModules::MyPolicyName;

before you ask L<Cache::CacheFactory> to
create a cache with 'mypolicyname' as a policy.

=head1 INTERNAL METHODS

The following methods are mostly for internal use, but may be useful
to redefine if you're subclassing L<Cache::CacheFactory> for some
reason.

=over

=item $object = $cache->new_cache_entry_object();

Returns a new and uninitialized object to use for a cache entry,
by default this object will be a L<Cache::CacheFactory::Object>,
if for some reason you want to overrule that decision you can
return your own object.

=item $cache->set_policy( $policytype, $policies );

Used as part of the C<new()> constructor, this sets the policy
type C<$policytype> to use the policies defined in C<$policies>,
this may do strange things if you do it to an already used cache
instance.

=item $cache->set_storage_policies( $policies );

=item $cache->set_pruning_policies( $policies );

=item $cache->set_validity_policies( $policies );

Convenience wrappers around C<set_policy>.

=item $cache->get_policy_driver( $policytype, $policy );

Gets the driver object instance for the matching C<$policytype> and
C<$policy>, useful if it has non-standard extensions to the API
that you can't access through L<Cache::CacheFactory>.

=item $cache->get_policy_drivers( $policytype );

Returns a hashref of policies to driver object instances for policy
type C<$policytype>, you should probably use C<get_policy_driver()>
instead to get a specific driver though.

=item $cache->foreach_policy( $policytype, $closure );

Runs the closure/coderef C<$closure> over each policy of type
C<$policytype> supplying args: C<Cache::CacheFactory> instance,
policy name, and policy driver.

The closure is run over each policy in order, or until the closure
calls the C<last()> method on the C<Cache::CacheFactory> instance.

  use Data::Dumper;
  use Cache::CacheFactory;

  $cache = Cache::CacheFactory->new( ... );
  $cache->foreach_policy( 'storage',
      sub
      {
          my ( $cache, $policy, $driver ) = @_;

          print "Storage policy '$policy' has driver: ",
              Data::Dumper::Dumper( $driver ), "\n";
          return $cache->last() if $policy eq 'file';
      } );

This will print the policy name and driver object for each storage
policy in turn until it encounters a C<'file'> policy.

=item $cache->foreach_driver( $policytype, $method, @args );

Much like C<foreach_policy()> above, this method iterates over
each policy, this time invoking method C<$method> on the driver
with the arguments specified in C<@args>.

  $cache->foreach_driver( 'storage', 'do_something', 'with', 'args' );

will call:

  $driver->do_something( 'with', 'args' );

on each storage driver in turn.

The return value of the method called is discarded, if it's
important to you then you should use C<foreach_policy> and
call the method on the driver arg provided, collating the
results however you wish.

=item $cache->last();

Indicates that C<foreach_policy()> or C<foreach_driver> should
exit at the end of the current iteration. C<last()> does B<NOT>
exit your closure for you, if you want it to behave like perl's
C<last> construct you will want to do C<< return $cache->last() >>.

=item $cache->auto_purge( 'set' | 'get' );

Attempts an auto-purge according to the C<auto_purge_on_set> and
C<auto_purge_on_get> settings and the C<< $cache->get_last_auto_purge() >>
value.

=item $cache->error( $error_message );

Raise a fatal error with message given by C<$error_message>.

=item $cache->warning( $warning_message );

Raise a warning with message given by C<$warning_message>.

=back

=head1 KNOWN ISSUES AND BUGS

=over

=item Pruning and validity policies are per-cache rather than per-storage

Pruning and validity policies are set on a per-cache basis rather than
on a per-storage-policy basis, this makes multiple storage policies
largely pointless for most purposes where you'd find it useful.

If you wanted the cache to transparently use a small fast memory cache
first and fall back to a larger slower file cache as backup: you can't
do it, because the size pruning policy would be the same for both storage
policies.

About the only current use of multiple storage policies is to have a
memory cache and a file cache so that processes that haven't pulled
a copy into their memory cache yet will retreive it from the copy
another process has placed in the file cache. This might be slightly
more useful than a shared memory cache since the on-file cache will
persist even if there's no running processes unlike the shared memory
cache.

Per-storage pruning and validity settings may make it into a future
version if they prove useful and won't over-complicate matters - for
now it's best to create a wrapper module that internally creates the
caches seperately but presents the Cache::Cache API externally.

=item Add/replace aren't atomic

The C<< $cache->add/replace() >> methods aren't atomic, this mostly
defeats their purpose in a shared-cache situation. This could be
considered a bug.

=item Aren't there a million Cache::Cache replacements already?

At the time I started writing L<Cache::CacheFactory> I'd been trying
to find a caching solution that had the combination of features I
needed, I had no luck in finding one.

Since then I've found a couple of other similar modules, and more
have been written and released, you may or may not find them suiting
your needs more closely, so I suggest taking a good look:

L<CHI> - this module appears to have much the same motivation and
strategy as L<Cache::CacheFactory> in terms of storage policies,
however, from what I can gather, it doesn't appear to split
validity/pruning policies into seperate and/or combinable modules.

L<Cache> - not sure how I missed this one when I was researching,
it's a mature module that gives you flexibile validity/pruning
policies but doesn't have such a wide range of storage policies
available.

Please note that these descriptions are from my own imperfect
understanding of the modules concerned, by no means take them
as an authorative description of their functionality. Please
feel free to contact me if I've included any inaccuracies. :)

=back

=head1 SEE ALSO

L<Cache::Cache>, L<Cache::CacheFactory::Object>,
L<Cache::CacheFactory::Expiry::Base>,
L<Cache::CacheFactory::Expiry::Time>,
L<Cache::CacheFactory::Expiry::Size>,
L<Cache::CacheFactory::Expiry::LastModified>,
L<Cache::FastMemoryCache>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cache::CacheFactory


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cache-CacheFactory>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cache-CacheFactory>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cache-CacheFactory>

=item * Search CPAN

L<http://search.cpan.org/dist/Cache-CacheFactory>

=back

=head1 AUTHORS

Original author: Sam Graham <libcache-cachefactory-perl BLAHBLAH illusori.co.uk>

Last author:     $Author: illusori $

=head1 ACKNOWLEDGEMENTS

DeWitt Clinton for the original L<Cache::Cache>, most of the hard
work is done by this module and its subclasses.

Chris Winters for L<Class::Factory>, saving me the trouble of finding
out what policy modules are or aren't available.

John Millaway for L<Cache::FastMemoryCache>, which inspired the
C<no_deep_clone> option.

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 Sam Graham, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
