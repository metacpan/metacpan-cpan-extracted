package DBM::Deep::10002;

use 5.006_000;

use strict;
use warnings;

our $VERSION = q(1.0002);

use Fcntl qw( :flock );

use Clone ();
use Digest::MD5 ();
use FileHandle::Fmode ();
use Scalar::Util ();

#use DBM::Deep::10002::Engine;
#use DBM::Deep::10002::File;

##
# Setup constants for users to pass to new()
##
sub TYPE_HASH   () { DBM::Deep::10002::Engine->SIG_HASH  }
sub TYPE_ARRAY  () { DBM::Deep::10002::Engine->SIG_ARRAY }

# This is used in all the children of this class in their TIE<type> methods.
sub _get_args {
    my $proto = shift;

    my $args;
    if (scalar(@_) > 1) {
        if ( @_ % 2 ) {
            $proto->_throw_error( "Odd number of parameters to " . (caller(1))[2] );
        }
        $args = {@_};
    }
    elsif ( ref $_[0] ) {
        unless ( eval { local $SIG{'__DIE__'}; %{$_[0]} || 1 } ) {
            $proto->_throw_error( "Not a hashref in args to " . (caller(1))[2] );
        }
        $args = $_[0];
    }
    else {
        $args = { file => shift };
    }

    return $args;
}

sub new {
    ##
    # Class constructor method for Perl OO interface.
    # Calls tie() and returns blessed reference to tied hash or array,
    # providing a hybrid OO/tie interface.
    ##
    my $class = shift;
    my $args = $class->_get_args( @_ );

    ##
    # Check if we want a tied hash or array.
    ##
    my $self;
    if (defined($args->{type}) && $args->{type} eq TYPE_ARRAY) {
        $class = 'DBM::Deep::10002::Array';
        #require DBM::Deep::10002::Array;
        tie @$self, $class, %$args;
    }
    else {
        $class = 'DBM::Deep::10002::Hash';
        #require DBM::Deep::10002::Hash;
        tie %$self, $class, %$args;
    }

    return bless $self, $class;
}

# This initializer is called from the various TIE* methods. new() calls tie(),
# which allows for a single point of entry.
sub _init {
    my $class = shift;
    my ($args) = @_;

    $args->{storage} = DBM::Deep::10002::File->new( $args )
        unless exists $args->{storage};

    # locking implicitly enables autoflush
    if ($args->{locking}) { $args->{autoflush} = 1; }

    # These are the defaults to be optionally overridden below
    my $self = bless {
        type        => TYPE_HASH,
        base_offset => undef,
        staleness   => undef,

        storage     => undef,
        engine      => undef,
    }, $class;

    $args->{engine} = DBM::Deep::10002::Engine->new( { %{$args}, obj => $self } )
        unless exists $args->{engine};

    # Grab the parameters we want to use
    foreach my $param ( keys %$self ) {
        next unless exists $args->{$param};
        $self->{$param} = $args->{$param};
    }

    eval {
      local $SIG{'__DIE__'};

      $self->lock;
      $self->_engine->setup_fh( $self );
      $self->_storage->set_inode;
      $self->unlock;
    }; if ( $@ ) {
      my $e = $@;
      eval { local $SIG{'__DIE__'}; $self->unlock; };
      die $e;
    }

    return $self;
}

sub TIEHASH {
    shift;
    #require DBM::Deep::10002::Hash;
    return DBM::Deep::10002::Hash->TIEHASH( @_ );
}

sub TIEARRAY {
    shift;
    #require DBM::Deep::10002::Array;
    return DBM::Deep::10002::Array->TIEARRAY( @_ );
}

sub lock {
    my $self = shift->_get_self;
    return $self->_storage->lock( $self, @_ );
}

sub unlock {
    my $self = shift->_get_self;
    return $self->_storage->unlock( $self, @_ );
}

sub _copy_value {
    my $self = shift->_get_self;
    my ($spot, $value) = @_;

    if ( !ref $value ) {
        ${$spot} = $value;
    }
    elsif ( eval { local $SIG{__DIE__}; $value->isa( 'DBM::Deep::10002' ) } ) {
        ${$spot} = $value->_repr;
        $value->_copy_node( ${$spot} );
    }
    else {
        my $r = Scalar::Util::reftype( $value );
        my $c = Scalar::Util::blessed( $value );
        if ( $r eq 'ARRAY' ) {
            ${$spot} = [ @{$value} ];
        }
        else {
            ${$spot} = { %{$value} };
        }
        ${$spot} = bless ${$spot}, $c
            if defined $c;
    }

    return 1;
}

#sub _copy_node {
#    die "Must be implemented in a child class\n";
#}
#
#sub _repr {
#    die "Must be implemented in a child class\n";
#}

sub export {
    ##
    # Recursively export into standard Perl hashes and arrays.
    ##
    my $self = shift->_get_self;

    my $temp = $self->_repr;

    $self->lock();
    $self->_copy_node( $temp );
    $self->unlock();

    my $classname = $self->_engine->get_classname( $self );
    if ( defined $classname ) {
      bless $temp, $classname;
    }

    return $temp;
}

sub import {
    ##
    # Recursively import Perl hash/array structure
    ##
    if (!ref($_[0])) { return; } # Perl calls import() on use -- ignore

    my $self = shift->_get_self;
    my ($struct) = @_;

    # struct is not a reference, so just import based on our type
    if (!ref($struct)) {
        $struct = $self->_repr( @_ );
    }

    #XXX This isn't the best solution. Better would be to use Data::Walker,
    #XXX but that's a lot more thinking than I want to do right now.
    eval {
        local $SIG{'__DIE__'};
        $self->_import( Clone::clone( $struct ) );
    }; if ( my $e = $@ ) {
        die $e;
    }

    return 1;
}

#XXX Need to keep track of who has a fh to this file in order to
#XXX close them all prior to optimize on Win32/cygwin
sub optimize {
    ##
    # Rebuild entire database into new file, then move
    # it back on top of original.
    ##
    my $self = shift->_get_self;

#XXX Need to create a new test for this
#    if ($self->_storage->{links} > 1) {
#        $self->_throw_error("Cannot optimize: reference count is greater than 1");
#    }

    #XXX Do we have to lock the tempfile?

    my $db_temp = DBM::Deep::10002->new(
        file => $self->_storage->{file} . '.tmp',
        type => $self->_type,

        # Bring over all the parameters that we need to bring over
        num_txns => $self->_engine->num_txns,
        byte_size => $self->_engine->byte_size,
        max_buckets => $self->_engine->max_buckets,
    );

    $self->lock();
    $self->_copy_node( $db_temp );
    undef $db_temp;

    ##
    # Attempt to copy user, group and permissions over to new file
    ##
    my @stats = stat($self->_fh);
    my $perms = $stats[2] & 07777;
    my $uid = $stats[4];
    my $gid = $stats[5];
    chown( $uid, $gid, $self->_storage->{file} . '.tmp' );
    chmod( $perms, $self->_storage->{file} . '.tmp' );

    # q.v. perlport for more information on this variable
    if ( $^O eq 'MSWin32' || $^O eq 'cygwin' ) {
        ##
        # Potential race condition when optmizing on Win32 with locking.
        # The Windows filesystem requires that the filehandle be closed
        # before it is overwritten with rename().  This could be redone
        # with a soft copy.
        ##
        $self->unlock();
        $self->_storage->close;
    }

    if (!rename $self->_storage->{file} . '.tmp', $self->_storage->{file}) {
        unlink $self->_storage->{file} . '.tmp';
        $self->unlock();
        $self->_throw_error("Optimize failed: Cannot copy temp file over original: $!");
    }

    $self->unlock();
    $self->_storage->close;

    $self->_storage->open;
    $self->lock();
    $self->_engine->setup_fh( $self );
    $self->unlock();

    return 1;
}

sub clone {
    ##
    # Make copy of object and return
    ##
    my $self = shift->_get_self;

    return DBM::Deep::10002->new(
        type        => $self->_type,
        base_offset => $self->_base_offset,
        staleness   => $self->_staleness,
        storage     => $self->_storage,
        engine      => $self->_engine,
    );
}

#XXX Migrate this to the engine, where it really belongs and go through some
# API - stop poking in the innards of someone else..
{
    my %is_legal_filter = map {
        $_ => ~~1,
    } qw(
        store_key store_value
        fetch_key fetch_value
    );

    sub set_filter {
        ##
        # Setup filter function for storing or fetching the key or value
        ##
        my $self = shift->_get_self;
        my $type = lc shift;
        my $func = shift;

        if ( $is_legal_filter{$type} ) {
            $self->_storage->{"filter_$type"} = $func;
            return 1;
        }

        return;
    }
}

sub begin_work {
    my $self = shift->_get_self;
    return $self->_engine->begin_work( $self, @_ );
}

sub rollback {
    my $self = shift->_get_self;
    return $self->_engine->rollback( $self, @_ );
}

sub commit {
    my $self = shift->_get_self;
    return $self->_engine->commit( $self, @_ );
}

##
# Accessor methods
##

sub _engine {
    my $self = $_[0]->_get_self;
    return $self->{engine};
}

sub _storage {
    my $self = $_[0]->_get_self;
    return $self->{storage};
}

sub _type {
    my $self = $_[0]->_get_self;
    return $self->{type};
}

sub _base_offset {
    my $self = $_[0]->_get_self;
    return $self->{base_offset};
}

sub _staleness {
    my $self = $_[0]->_get_self;
    return $self->{staleness};
}

sub _fh {
    my $self = $_[0]->_get_self;
    return $self->_storage->{fh};
}

##
# Utility methods
##

sub _throw_error {
    die "DBM::Deep::10002: $_[1]\n";
    my $n = 0;
    while( 1 ) {
        my @caller = caller( ++$n );
        next if $caller[0] =~ m/^DBM::Deep::10002/;

        die "DBM::Deep::10002: $_[1] at $0 line $caller[2]\n";
        last;
    }
}

sub STORE {
    ##
    # Store single hash key/value or array element in database.
    ##
    my $self = shift->_get_self;
    my ($key, $value) = @_;

    if ( !FileHandle::Fmode::is_W( $self->_fh ) ) {
        $self->_throw_error( 'Cannot write to a readonly filehandle' );
    }

    ##
    # Request exclusive lock for writing
    ##
    $self->lock( LOCK_EX );

    # User may be storing a complex value, in which case we do not want it run
    # through the filtering system.
    if ( !ref($value) && $self->_storage->{filter_store_value} ) {
        $value = $self->_storage->{filter_store_value}->( $value );
    }

    $self->_engine->write_value( $self, $key, $value);

    $self->unlock();

    return 1;
}

sub FETCH {
    ##
    # Fetch single value or element given plain key or array index
    ##
    my $self = shift->_get_self;
    my ($key) = @_;

    ##
    # Request shared lock for reading
    ##
    $self->lock( LOCK_SH );

    my $result = $self->_engine->read_value( $self, $key);

    $self->unlock();

    # Filters only apply to scalar values, so the ref check is making
    # sure the fetched bucket is a scalar, not a child hash or array.
    return ($result && !ref($result) && $self->_storage->{filter_fetch_value})
        ? $self->_storage->{filter_fetch_value}->($result)
        : $result;
}

sub DELETE {
    ##
    # Delete single key/value pair or element given plain key or array index
    ##
    my $self = shift->_get_self;
    my ($key) = @_;

    if ( !FileHandle::Fmode::is_W( $self->_fh ) ) {
        $self->_throw_error( 'Cannot write to a readonly filehandle' );
    }

    ##
    # Request exclusive lock for writing
    ##
    $self->lock( LOCK_EX );

    ##
    # Delete bucket
    ##
    my $value = $self->_engine->delete_key( $self, $key);

    if (defined $value && !ref($value) && $self->_storage->{filter_fetch_value}) {
        $value = $self->_storage->{filter_fetch_value}->($value);
    }

    $self->unlock();

    return $value;
}

sub EXISTS {
    ##
    # Check if a single key or element exists given plain key or array index
    ##
    my $self = shift->_get_self;
    my ($key) = @_;

    ##
    # Request shared lock for reading
    ##
    $self->lock( LOCK_SH );

    my $result = $self->_engine->key_exists( $self, $key );

    $self->unlock();

    return $result;
}

sub CLEAR {
    ##
    # Clear all keys from hash, or all elements from array.
    ##
    my $self = shift->_get_self;

    if ( !FileHandle::Fmode::is_W( $self->_fh ) ) {
        $self->_throw_error( 'Cannot write to a readonly filehandle' );
    }

    ##
    # Request exclusive lock for writing
    ##
    $self->lock( LOCK_EX );

    #XXX Rewrite this dreck to do it in the engine as a tight loop vs.
    # iterating over keys - such a WASTE - is this required for transactional
    # clearning?! Surely that can be detected in the engine ...
    if ( $self->_type eq TYPE_HASH ) {
        my $key = $self->first_key;
        while ( $key ) {
            # Retrieve the key before deleting because we depend on next_key
            my $next_key = $self->next_key( $key );
            $self->_engine->delete_key( $self, $key, $key );
            $key = $next_key;
        }
    }
    else {
        my $size = $self->FETCHSIZE;
        for my $key ( 0 .. $size - 1 ) {
            $self->_engine->delete_key( $self, $key, $key );
        }
        $self->STORESIZE( 0 );
    }

    $self->unlock();

    return 1;
}

##
# Public method aliases
##
sub put { (shift)->STORE( @_ ) }
sub store { (shift)->STORE( @_ ) }
sub get { (shift)->FETCH( @_ ) }
sub fetch { (shift)->FETCH( @_ ) }
sub delete { (shift)->DELETE( @_ ) }
sub exists { (shift)->EXISTS( @_ ) }
sub clear { (shift)->CLEAR( @_ ) }

package DBM::Deep::10002::Array;

use 5.006_000;

use strict;
use warnings;

our $VERSION = q(1.0002);

# This is to allow DBM::Deep::10002::Array to handle negative indices on
# its own. Otherwise, Perl would intercept the call to negative
# indices for us. This was causing bugs for negative index handling.
our $NEGATIVE_INDICES = 1;

use base 'DBM::Deep::10002';

use Scalar::Util ();

sub _get_self {
    eval { local $SIG{'__DIE__'}; tied( @{$_[0]} ) } || $_[0]
}

sub _repr { shift;[ @_ ] }

sub _import {
    my $self = shift;
    my ($struct) = @_;

    $self->push( @$struct );

    return 1;
}

sub TIEARRAY {
    my $class = shift;
    my $args = $class->_get_args( @_ );

    $args->{type} = $class->TYPE_ARRAY;

    return $class->_init($args);
}

sub FETCH {
    my $self = shift->_get_self;
    my ($key) = @_;

    $self->lock( $self->LOCK_SH );

    if ( !defined $key ) {
        DBM::Deep::10002->_throw_error( "Cannot use an undefined array index." );
    }
    elsif ( $key =~ /^-?\d+$/ ) {
        if ( $key < 0 ) {
            $key += $self->FETCHSIZE;
            unless ( $key >= 0 ) {
                $self->unlock;
                return;
            }
        }
    }
    elsif ( $key ne 'length' ) {
        $self->unlock;
        DBM::Deep::10002->_throw_error( "Cannot use '$key' as an array index." );
    }

    my $rv = $self->SUPER::FETCH( $key );

    $self->unlock;

    return $rv;
}

sub STORE {
    my $self = shift->_get_self;
    my ($key, $value) = @_;

    $self->lock( $self->LOCK_EX );

    my $size;
    my $idx_is_numeric;
    if ( !defined $key ) {
        DBM::Deep::10002->_throw_error( "Cannot use an undefined array index." );
    }
    elsif ( $key =~ /^-?\d+$/ ) {
        $idx_is_numeric = 1;
        if ( $key < 0 ) {
            $size = $self->FETCHSIZE;
            if ( $key + $size < 0 ) {
                die( "Modification of non-creatable array value attempted, subscript $key" );
            }
            $key += $size
        }
    }
    elsif ( $key ne 'length' ) {
        $self->unlock;
        DBM::Deep::10002->_throw_error( "Cannot use '$key' as an array index." );
    }

    my $rv = $self->SUPER::STORE( $key, $value );

    if ( $idx_is_numeric ) {
        $size = $self->FETCHSIZE unless defined $size;
        if ( $key >= $size ) {
            $self->STORESIZE( $key + 1 );
        }
    }

    $self->unlock;

    return $rv;
}

sub EXISTS {
    my $self = shift->_get_self;
    my ($key) = @_;

    $self->lock( $self->LOCK_SH );

    if ( !defined $key ) {
        DBM::Deep::10002->_throw_error( "Cannot use an undefined array index." );
    }
    elsif ( $key =~ /^-?\d+$/ ) {
        if ( $key < 0 ) {
            $key += $self->FETCHSIZE;
            unless ( $key >= 0 ) {
                $self->unlock;
                return;
            }
        }
    }
    elsif ( $key ne 'length' ) {
        $self->unlock;
        DBM::Deep::10002->_throw_error( "Cannot use '$key' as an array index." );
    }

    my $rv = $self->SUPER::EXISTS( $key );

    $self->unlock;

    return $rv;
}

sub DELETE {
    my $self = shift->_get_self;
    my ($key) = @_;

    $self->lock( $self->LOCK_EX );

    my $size = $self->FETCHSIZE;
    if ( !defined $key ) {
        DBM::Deep::10002->_throw_error( "Cannot use an undefined array index." );
    }
    elsif ( $key =~ /^-?\d+$/ ) {
        if ( $key < 0 ) {
            $key += $size;
            unless ( $key >= 0 ) {
                $self->unlock;
                return;
            }
        }
    }
    elsif ( $key ne 'length' ) {
        $self->unlock;
        DBM::Deep::10002->_throw_error( "Cannot use '$key' as an array index." );
    }

    my $rv = $self->SUPER::DELETE( $key );

    if ($rv && $key == $size - 1) {
        $self->STORESIZE( $key );
    }

    $self->unlock;

    return $rv;
}

# Now that we have a real Reference sector, we should store arrayzize there. However,
# arraysize needs to be transactionally-aware, so a simple location to store it isn't
# going to work.
sub FETCHSIZE {
    my $self = shift->_get_self;

    $self->lock( $self->LOCK_SH );

    my $SAVE_FILTER = $self->_storage->{filter_fetch_value};
    $self->_storage->{filter_fetch_value} = undef;

    my $size = $self->FETCH('length') || 0;

    $self->_storage->{filter_fetch_value} = $SAVE_FILTER;

    $self->unlock;

    return $size;
}

sub STORESIZE {
    my $self = shift->_get_self;
    my ($new_length) = @_;

    $self->lock( $self->LOCK_EX );

    my $SAVE_FILTER = $self->_storage->{filter_store_value};
    $self->_storage->{filter_store_value} = undef;

    my $result = $self->STORE('length', $new_length, 'length');

    $self->_storage->{filter_store_value} = $SAVE_FILTER;

    $self->unlock;

    return $result;
}

sub POP {
    my $self = shift->_get_self;

    $self->lock( $self->LOCK_EX );

    my $length = $self->FETCHSIZE();

    if ($length) {
        my $content = $self->FETCH( $length - 1 );
        $self->DELETE( $length - 1 );

        $self->unlock;

        return $content;
    }
    else {
        $self->unlock;
        return;
    }
}

sub PUSH {
    my $self = shift->_get_self;

    $self->lock( $self->LOCK_EX );

    my $length = $self->FETCHSIZE();

    while (my $content = shift @_) {
        $self->STORE( $length, $content );
        $length++;
    }

    $self->unlock;

    return $length;
}

# XXX This really needs to be something more direct within the file, not a
# fetch and re-store. -RobK, 2007-09-20
sub _move_value {
    my $self = shift;
    my ($old_key, $new_key) = @_;

    my $val = $self->FETCH( $old_key );
    if ( eval { local $SIG{'__DIE__'}; $val->isa( 'DBM::Deep::10002::Hash' ) } ) {
        $self->STORE( $new_key, { %$val } );
    }
    elsif ( eval { local $SIG{'__DIE__'}; $val->isa( 'DBM::Deep::10002::Array' ) } ) {
        $self->STORE( $new_key, [ @$val ] );
    }
    else {
        $self->STORE( $new_key, $val );
    }
}

sub SHIFT {
    my $self = shift->_get_self;

    $self->lock( $self->LOCK_EX );

    my $length = $self->FETCHSIZE();

    if ($length) {
        my $content = $self->FETCH( 0 );

        for (my $i = 0; $i < $length - 1; $i++) {
            $self->_move_value( $i+1, $i );
        }
        $self->DELETE( $length - 1 );

        $self->unlock;

        return $content;
    }
    else {
        $self->unlock;
        return;
    }
}

sub UNSHIFT {
    my $self = shift->_get_self;
    my @new_elements = @_;

    $self->lock( $self->LOCK_EX );

    my $length = $self->FETCHSIZE();
    my $new_size = scalar @new_elements;

    if ($length) {
        for (my $i = $length - 1; $i >= 0; $i--) {
            $self->_move_value( $i, $i+$new_size );
        }
    }

    for (my $i = 0; $i < $new_size; $i++) {
        $self->STORE( $i, $new_elements[$i] );
    }

    $self->unlock;

    return $length + $new_size;
}

sub SPLICE {
    my $self = shift->_get_self;

    $self->lock( $self->LOCK_EX );

    my $length = $self->FETCHSIZE();

    ##
    # Calculate offset and length of splice
    ##
    my $offset = shift;
    $offset = 0 unless defined $offset;
    if ($offset < 0) { $offset += $length; }

    my $splice_length;
    if (scalar @_) { $splice_length = shift; }
    else { $splice_length = $length - $offset; }
    if ($splice_length < 0) { $splice_length += ($length - $offset); }

    ##
    # Setup array with new elements, and copy out old elements for return
    ##
    my @new_elements = @_;
    my $new_size = scalar @new_elements;

    my @old_elements = map {
        $self->FETCH( $_ )
    } $offset .. ($offset + $splice_length - 1);

    ##
    # Adjust array length, and shift elements to accomodate new section.
    ##
    if ( $new_size != $splice_length ) {
        if ($new_size > $splice_length) {
            for (my $i = $length - 1; $i >= $offset + $splice_length; $i--) {
                $self->_move_value( $i, $i + ($new_size - $splice_length) );
            }
        }
        else {
            for (my $i = $offset + $splice_length; $i < $length; $i++) {
                $self->_move_value( $i, $i + ($new_size - $splice_length) );
            }
            for (my $i = 0; $i < $splice_length - $new_size; $i++) {
                $self->DELETE( $length - 1 );
                $length--;
            }
        }
    }

    ##
    # Insert new elements into array
    ##
    for (my $i = $offset; $i < $offset + $new_size; $i++) {
        $self->STORE( $i, shift @new_elements );
    }

    $self->unlock;

    ##
    # Return deleted section, or last element in scalar context.
    ##
    return wantarray ? @old_elements : $old_elements[-1];
}

# We don't need to populate it, yet.
# It will be useful, though, when we split out HASH and ARRAY
sub EXTEND {
    ##
    # Perl will call EXTEND() when the array is likely to grow.
    # We don't care, but include it because it gets called at times.
    ##
}

sub _copy_node {
    my $self = shift;
    my ($db_temp) = @_;

    my $length = $self->length();
    for (my $index = 0; $index < $length; $index++) {
        my $value = $self->get($index);
        $self->_copy_value( \$db_temp->[$index], $value );
    }

    return 1;
}

##
# Public method aliases
##
sub length { (shift)->FETCHSIZE(@_) }
sub pop { (shift)->POP(@_) }
sub push { (shift)->PUSH(@_) }
sub unshift { (shift)->UNSHIFT(@_) }
sub splice { (shift)->SPLICE(@_) }

# This must be last otherwise we have to qualify all other calls to shift
# as calls to CORE::shift
sub shift { (CORE::shift)->SHIFT(@_) }

package DBM::Deep::10002::Hash;

use 5.006_000;

use strict;
use warnings;

our $VERSION = q(1.0002);

use base 'DBM::Deep::10002';

sub _get_self {
    eval { local $SIG{'__DIE__'}; tied( %{$_[0]} ) } || $_[0]
}

#XXX Need to add a check here for @_ % 2
sub _repr { shift;return { @_ } }

sub _import {
    my $self = shift;
    my ($struct) = @_;

    foreach my $key (keys %$struct) {
        $self->put($key, $struct->{$key});
    }

    return 1;
}

sub TIEHASH {
    ##
    # Tied hash constructor method, called by Perl's tie() function.
    ##
    my $class = shift;
    my $args = $class->_get_args( @_ );
    
    $args->{type} = $class->TYPE_HASH;

    return $class->_init($args);
}

sub FETCH {
    my $self = shift->_get_self;
    DBM::Deep::10002->_throw_error( "Cannot use an undefined hash key." ) unless defined $_[0];
    my $key = ($self->_storage->{filter_store_key})
        ? $self->_storage->{filter_store_key}->($_[0])
        : $_[0];

    return $self->SUPER::FETCH( $key, $_[0] );
}

sub STORE {
    my $self = shift->_get_self;
    DBM::Deep::10002->_throw_error( "Cannot use an undefined hash key." ) unless defined $_[0];
	my $key = ($self->_storage->{filter_store_key})
        ? $self->_storage->{filter_store_key}->($_[0])
        : $_[0];
    my $value = $_[1];

    return $self->SUPER::STORE( $key, $value, $_[0] );
}

sub EXISTS {
    my $self = shift->_get_self;
    DBM::Deep::10002->_throw_error( "Cannot use an undefined hash key." ) unless defined $_[0];
	my $key = ($self->_storage->{filter_store_key})
        ? $self->_storage->{filter_store_key}->($_[0])
        : $_[0];

    return $self->SUPER::EXISTS( $key );
}

sub DELETE {
    my $self = shift->_get_self;
    DBM::Deep::10002->_throw_error( "Cannot use an undefined hash key." ) unless defined $_[0];
	my $key = ($self->_storage->{filter_store_key})
        ? $self->_storage->{filter_store_key}->($_[0])
        : $_[0];

    return $self->SUPER::DELETE( $key, $_[0] );
}

sub FIRSTKEY {
	##
	# Locate and return first key (in no particular order)
	##
    my $self = shift->_get_self;

	##
	# Request shared lock for reading
	##
	$self->lock( $self->LOCK_SH );
	
	my $result = $self->_engine->get_next_key( $self );
	
	$self->unlock();
	
	return ($result && $self->_storage->{filter_fetch_key})
        ? $self->_storage->{filter_fetch_key}->($result)
        : $result;
}

sub NEXTKEY {
	##
	# Return next key (in no particular order), given previous one
	##
    my $self = shift->_get_self;

	my $prev_key = ($self->_storage->{filter_store_key})
        ? $self->_storage->{filter_store_key}->($_[0])
        : $_[0];

	##
	# Request shared lock for reading
	##
	$self->lock( $self->LOCK_SH );
	
	my $result = $self->_engine->get_next_key( $self, $prev_key );
	
	$self->unlock();
	
	return ($result && $self->_storage->{filter_fetch_key})
        ? $self->_storage->{filter_fetch_key}->($result)
        : $result;
}

##
# Public method aliases
##
sub first_key { (shift)->FIRSTKEY(@_) }
sub next_key { (shift)->NEXTKEY(@_) }

sub _copy_node {
    my $self = shift;
    my ($db_temp) = @_;

    my $key = $self->first_key();
    while ($key) {
        my $value = $self->get($key);
        $self->_copy_value( \$db_temp->{$key}, $value );
        $key = $self->next_key($key);
    }

    return 1;
}

package DBM::Deep::10002::File;

use 5.006_000;

use strict;
use warnings;

our $VERSION = q(1.0002);

use Fcntl qw( :DEFAULT :flock :seek );

sub new {
    my $class = shift;
    my ($args) = @_;

    my $self = bless {
        autobless          => 1,
        autoflush          => 1,
        end                => 0,
        fh                 => undef,
        file               => undef,
        file_offset        => 0,
        locking            => 1,
        locked             => 0,
#XXX Migrate this to the engine, where it really belongs.
        filter_store_key   => undef,
        filter_store_value => undef,
        filter_fetch_key   => undef,
        filter_fetch_value => undef,
    }, $class;

    # Grab the parameters we want to use
    foreach my $param ( keys %$self ) {
        next unless exists $args->{$param};
        $self->{$param} = $args->{$param};
    }

    if ( $self->{fh} && !$self->{file_offset} ) {
        $self->{file_offset} = tell( $self->{fh} );
    }

    $self->open unless $self->{fh};

    return $self;
}

sub open {
    my $self = shift;

    # Adding O_BINARY should remove the need for the binmode below. However,
    # I'm not going to remove it because I don't have the Win32 chops to be
    # absolutely certain everything will be ok.
    my $flags = O_CREAT | O_BINARY;

    if ( !-e $self->{file} || -w _ ) {
      $flags |= O_RDWR;
    }
    else {
      $flags |= O_RDONLY;
    }

    my $fh;
    sysopen( $fh, $self->{file}, $flags )
        or die "DBM::Deep::10002: Cannot sysopen file '$self->{file}': $!\n";
    $self->{fh} = $fh;

    # Even though we use O_BINARY, better be safe than sorry.
    binmode $fh;

    if ($self->{autoflush}) {
        my $old = select $fh;
        $|=1;
        select $old;
    }

    return 1;
}

sub close {
    my $self = shift;

    if ( $self->{fh} ) {
        close $self->{fh};
        $self->{fh} = undef;
    }

    return 1;
}

sub set_inode {
    my $self = shift;

    unless ( defined $self->{inode} ) {
        my @stats = stat($self->{fh});
        $self->{inode} = $stats[1];
        $self->{end} = $stats[7];
    }

    return 1;
}

sub print_at {
    my $self = shift;
    my $loc  = shift;

    local ($/,$\);

    my $fh = $self->{fh};
    if ( defined $loc ) {
        seek( $fh, $loc + $self->{file_offset}, SEEK_SET );
    }

    print( $fh @_ );

    return 1;
}

sub read_at {
    my $self = shift;
    my ($loc, $size) = @_;

    local ($/,$\);

    my $fh = $self->{fh};
    if ( defined $loc ) {
        seek( $fh, $loc + $self->{file_offset}, SEEK_SET );
    }

    my $buffer;
    read( $fh, $buffer, $size);

    return $buffer;
}

sub DESTROY {
    my $self = shift;
    return unless $self;

    $self->close;

    return;
}

sub request_space {
    my $self = shift;
    my ($size) = @_;

    #XXX Do I need to reset $self->{end} here? I need a testcase
    my $loc = $self->{end};
    $self->{end} += $size;

    return $loc;
}

##
# If db locking is set, flock() the db file.  If called multiple
# times before unlock(), then the same number of unlocks() must
# be called before the lock is released.
##
sub lock {
    my $self = shift;
    my ($obj, $type) = @_;

    $type = LOCK_EX unless defined $type;

    if (!defined($self->{fh})) { return; }

    if ($self->{locking}) {
        if (!$self->{locked}) {
            flock($self->{fh}, $type);

            # refresh end counter in case file has changed size
            my @stats = stat($self->{fh});
            $self->{end} = $stats[7];

            # double-check file inode, in case another process
            # has optimize()d our file while we were waiting.
            if (defined($self->{inode}) && $stats[1] != $self->{inode}) {
                $self->close;
                $self->open;

                #XXX This needs work
                $obj->{engine}->setup_fh( $obj );

                flock($self->{fh}, $type); # re-lock

                # This may not be necessary after re-opening
                $self->{end} = (stat($self->{fh}))[7]; # re-end
            }
        }
        $self->{locked}++;

        return 1;
    }

    return;
}

##
# If db locking is set, unlock the db file.  See note in lock()
# regarding calling lock() multiple times.
##
sub unlock {
    my $self = shift;

    if (!defined($self->{fh})) { return; }

    if ($self->{locking} && $self->{locked} > 0) {
        $self->{locked}--;
        if (!$self->{locked}) { flock($self->{fh}, LOCK_UN); }

        return 1;
    }

    return;
}

sub flush {
    my $self = shift;

    # Flush the filehandle
    my $old_fh = select $self->{fh};
    my $old_af = $|; $| = 1; $| = $old_af;
    select $old_fh;

    return 1;
}

package DBM::Deep::10002::Engine;

use 5.006_000;

use strict;
use warnings;

our $VERSION = q(1.0002);

use Scalar::Util ();

# File-wide notes:
# * Every method in here assumes that the storage has been appropriately
#   safeguarded. This can be anything from flock() to some sort of manual
#   mutex. But, it's the caller's responsability to make sure that this has
#   been done.

# Setup file and tag signatures.  These should never change.
sub SIG_FILE     () { 'DPDB' }
sub SIG_HEADER   () { 'h'    }
sub SIG_HASH     () { 'H'    }
sub SIG_ARRAY    () { 'A'    }
sub SIG_NULL     () { 'N'    }
sub SIG_DATA     () { 'D'    }
sub SIG_INDEX    () { 'I'    }
sub SIG_BLIST    () { 'B'    }
sub SIG_FREE     () { 'F'    }
sub SIG_SIZE     () {  1     }

my $STALE_SIZE = 2;

# Please refer to the pack() documentation for further information
my %StP = (
    1 => 'C', # Unsigned char value (no order needed as it's just one byte)
    2 => 'n', # Unsigned short in "network" (big-endian) order
    4 => 'N', # Unsigned long in "network" (big-endian) order
    8 => 'Q', # Usigned quad (no order specified, presumably machine-dependent)
);

################################################################################

sub new {
    my $class = shift;
    my ($args) = @_;

    my $self = bless {
        byte_size   => 4,

        digest      => undef,
        hash_size   => 16,  # In bytes
        hash_chars  => 256, # Number of chars the algorithm uses per byte
        max_buckets => 16,
        num_txns    => 1,   # The HEAD
        trans_id    => 0,   # Default to the HEAD

        data_sector_size => 64, # Size in bytes of each data sector

        entries => {}, # This is the list of entries for transactions
        storage => undef,
    }, $class;

    # Never allow byte_size to be set directly.
    delete $args->{byte_size};
    if ( defined $args->{pack_size} ) {
        if ( lc $args->{pack_size} eq 'small' ) {
            $args->{byte_size} = 2;
        }
        elsif ( lc $args->{pack_size} eq 'medium' ) {
            $args->{byte_size} = 4;
        }
        elsif ( lc $args->{pack_size} eq 'large' ) {
            $args->{byte_size} = 8;
        }
        else {
            DBM::Deep::10002->_throw_error( "Unknown pack_size value: '$args->{pack_size}'" );
        }
    }

    # Grab the parameters we want to use
    foreach my $param ( keys %$self ) {
        next unless exists $args->{$param};
        $self->{$param} = $args->{$param};
    }

    my %validations = (
        max_buckets      => { floor => 16, ceil => 256 },
        num_txns         => { floor => 1,  ceil => 255 },
        data_sector_size => { floor => 32, ceil => 256 },
    );

    while ( my ($attr, $c) = each %validations ) {
        if (   !defined $self->{$attr}
            || !length $self->{$attr}
            || $self->{$attr} =~ /\D/
            || $self->{$attr} < $c->{floor}
        ) {
            $self->{$attr} = '(undef)' if !defined $self->{$attr};
            warn "Floor of $attr is $c->{floor}. Setting it to $c->{floor} from '$self->{$attr}'\n";
            $self->{$attr} = $c->{floor};
        }
        elsif ( $self->{$attr} > $c->{ceil} ) {
            warn "Ceiling of $attr is $c->{ceil}. Setting it to $c->{ceil} from '$self->{$attr}'\n";
            $self->{$attr} = $c->{ceil};
        }
    }

    if ( !$self->{digest} ) {
        require Digest::MD5;
        $self->{digest} = \&Digest::MD5::md5;
    }

    return $self;
}

################################################################################

sub read_value {
    my $self = shift;
    my ($obj, $key) = @_;

    # This will be a Reference sector
    my $sector = $self->_load_sector( $obj->_base_offset )
        or return;

    if ( $sector->staleness != $obj->_staleness ) {
        return;
    }

    my $key_md5 = $self->_apply_digest( $key );

    my $value_sector = $sector->get_data_for({
        key_md5    => $key_md5,
        allow_head => 1,
    });

    unless ( $value_sector ) {
        $value_sector = DBM::Deep::10002::Engine::Sector::Null->new({
            engine => $self,
            data   => undef,
        });

        $sector->write_data({
            key_md5 => $key_md5,
            key     => $key,
            value   => $value_sector,
        });
    }

    return $value_sector->data;
}

sub get_classname {
    my $self = shift;
    my ($obj) = @_;

    # This will be a Reference sector
    my $sector = $self->_load_sector( $obj->_base_offset )
        or DBM::Deep::10002->_throw_error( "How did get_classname fail (no sector for '$obj')?!" );

    if ( $sector->staleness != $obj->_staleness ) {
        return;
    }

    return $sector->get_classname;
}

sub key_exists {
    my $self = shift;
    my ($obj, $key) = @_;

    # This will be a Reference sector
    my $sector = $self->_load_sector( $obj->_base_offset )
        or return '';

    if ( $sector->staleness != $obj->_staleness ) {
        return '';
    }

    my $data = $sector->get_data_for({
        key_md5    => $self->_apply_digest( $key ),
        allow_head => 1,
    });

    # exists() returns 1 or '' for true/false.
    return $data ? 1 : '';
}

sub delete_key {
    my $self = shift;
    my ($obj, $key) = @_;

    my $sector = $self->_load_sector( $obj->_base_offset )
        or return;

    if ( $sector->staleness != $obj->_staleness ) {
        return;
    }

    return $sector->delete_key({
        key_md5    => $self->_apply_digest( $key ),
        allow_head => 0,
    });
}

sub write_value {
    my $self = shift;
    my ($obj, $key, $value) = @_;

    my $r = Scalar::Util::reftype( $value ) || '';
    {
        last if $r eq '';
        last if $r eq 'HASH';
        last if $r eq 'ARRAY';

        DBM::Deep::10002->_throw_error(
            "Storage of references of type '$r' is not supported."
        );
    }

    my ($class, $type);
    if ( !defined $value ) {
        $class = 'DBM::Deep::10002::Engine::Sector::Null';
    }
    elsif ( $r eq 'ARRAY' || $r eq 'HASH' ) {
        if ( $r eq 'ARRAY' && tied(@$value) ) {
            DBM::Deep::10002->_throw_error( "Cannot store something that is tied." );
        }
        if ( $r eq 'HASH' && tied(%$value) ) {
            DBM::Deep::10002->_throw_error( "Cannot store something that is tied." );
        }
        $class = 'DBM::Deep::10002::Engine::Sector::Reference';
        $type = substr( $r, 0, 1 );
    }
    else {
        $class = 'DBM::Deep::10002::Engine::Sector::Scalar';
    }

    # This will be a Reference sector
    my $sector = $self->_load_sector( $obj->_base_offset )
        or DBM::Deep::10002->_throw_error( "Cannot write to a deleted spot in DBM::Deep::10002." );

    if ( $sector->staleness != $obj->_staleness ) {
        DBM::Deep::10002->_throw_error( "Cannot write to a deleted spot in DBM::Deep::10002.n" );
    }

    # Create this after loading the reference sector in case something bad happens.
    # This way, we won't allocate value sector(s) needlessly.
    my $value_sector = $class->new({
        engine => $self,
        data   => $value,
        type   => $type,
    });

    $sector->write_data({
        key     => $key,
        key_md5 => $self->_apply_digest( $key ),
        value   => $value_sector,
    });

    # This code is to make sure we write all the values in the $value to the disk
    # and to make sure all changes to $value after the assignment are reflected
    # on disk. This may be counter-intuitive at first, but it is correct dwimmery.
    #   NOTE - simply tying $value won't perform a STORE on each value. Hence, the
    # copy to a temp value.
    if ( $r eq 'ARRAY' ) {
        my @temp = @$value;
        tie @$value, 'DBM::Deep::10002', {
            base_offset => $value_sector->offset,
            staleness   => $value_sector->staleness,
            storage     => $self->storage,
            engine      => $self,
        };
        @$value = @temp;
        bless $value, 'DBM::Deep::10002::Array' unless Scalar::Util::blessed( $value );
    }
    elsif ( $r eq 'HASH' ) {
        my %temp = %$value;
        tie %$value, 'DBM::Deep::10002', {
            base_offset => $value_sector->offset,
            staleness   => $value_sector->staleness,
            storage     => $self->storage,
            engine      => $self,
        };

        %$value = %temp;
        bless $value, 'DBM::Deep::10002::Hash' unless Scalar::Util::blessed( $value );
    }

    return 1;
}

# XXX Add staleness here
sub get_next_key {
    my $self = shift;
    my ($obj, $prev_key) = @_;

    # XXX Need to add logic about resetting the iterator if any key in the reference has changed
    unless ( $prev_key ) {
        $obj->{iterator} = DBM::Deep::10002::Iterator->new({
            base_offset => $obj->_base_offset,
            engine      => $self,
        });
    }

    return $obj->{iterator}->get_next_key( $obj );
}

################################################################################

sub setup_fh {
    my $self = shift;
    my ($obj) = @_;

    # We're opening the file.
    unless ( $obj->_base_offset ) {
        my $bytes_read = $self->_read_file_header;

        # Creating a new file
        unless ( $bytes_read ) {
            $self->_write_file_header;

            # 1) Create Array/Hash entry
            my $initial_reference = DBM::Deep::10002::Engine::Sector::Reference->new({
                engine => $self,
                type   => $obj->_type,
            });
            $obj->{base_offset} = $initial_reference->offset;
            $obj->{staleness} = $initial_reference->staleness;

            $self->storage->flush;
        }
        # Reading from an existing file
        else {
            $obj->{base_offset} = $bytes_read;
            my $initial_reference = DBM::Deep::10002::Engine::Sector::Reference->new({
                engine => $self,
                offset => $obj->_base_offset,
            });
            unless ( $initial_reference ) {
                DBM::Deep::10002->_throw_error("Corrupted file, no master index record");
            }

            unless ($obj->_type eq $initial_reference->type) {
                DBM::Deep::10002->_throw_error("File type mismatch");
            }

            $obj->{staleness} = $initial_reference->staleness;
        }
    }

    return 1;
}

sub begin_work {
    my $self = shift;
    my ($obj) = @_;

    if ( $self->trans_id ) {
        DBM::Deep::10002->_throw_error( "Cannot begin_work within an active transaction" );
    }

    my @slots = $self->read_txn_slots;
    my $found;
    for my $i ( 0 .. $#slots ) {
        next if $slots[$i];

        $slots[$i] = 1;
        $self->set_trans_id( $i + 1 );
        $found = 1;
        last;
    }
    unless ( $found ) {
        DBM::Deep::10002->_throw_error( "Cannot allocate transaction ID" );
    }
    $self->write_txn_slots( @slots );

    if ( !$self->trans_id ) {
        DBM::Deep::10002->_throw_error( "Cannot begin_work - no available transactions" );
    }

    return;
}

sub rollback {
    my $self = shift;
    my ($obj) = @_;

    if ( !$self->trans_id ) {
        DBM::Deep::10002->_throw_error( "Cannot rollback without an active transaction" );
    }

    # Each entry is the file location for a bucket that has a modification for
    # this transaction. The entries need to be expunged.
    foreach my $entry (@{ $self->get_entries } ) {
        # Remove the entry here
        my $read_loc = $entry
          + $self->hash_size
          + $self->byte_size
          + $self->byte_size
          + ($self->trans_id - 1) * ( $self->byte_size + $STALE_SIZE );

        my $data_loc = $self->storage->read_at( $read_loc, $self->byte_size );
        $data_loc = unpack( $StP{$self->byte_size}, $data_loc );
        $self->storage->print_at( $read_loc, pack( $StP{$self->byte_size}, 0 ) );

        if ( $data_loc > 1 ) {
            $self->_load_sector( $data_loc )->free;
        }
    }

    $self->clear_entries;

    my @slots = $self->read_txn_slots;
    $slots[$self->trans_id-1] = 0;
    $self->write_txn_slots( @slots );
    $self->inc_txn_staleness_counter( $self->trans_id );
    $self->set_trans_id( 0 );

    return 1;
}

sub commit {
    my $self = shift;
    my ($obj) = @_;

    if ( !$self->trans_id ) {
        DBM::Deep::10002->_throw_error( "Cannot commit without an active transaction" );
    }

    foreach my $entry (@{ $self->get_entries } ) {
        # Overwrite the entry in head with the entry in trans_id
        my $base = $entry
          + $self->hash_size
          + $self->byte_size;

        my $head_loc = $self->storage->read_at( $base, $self->byte_size );
        $head_loc = unpack( $StP{$self->byte_size}, $head_loc );

        my $spot = $base + $self->byte_size + ($self->trans_id - 1) * ( $self->byte_size + $STALE_SIZE );
        my $trans_loc = $self->storage->read_at(
            $spot, $self->byte_size,
        );

        $self->storage->print_at( $base, $trans_loc );
        $self->storage->print_at(
            $spot,
            pack( $StP{$self->byte_size} . ' ' . $StP{$STALE_SIZE}, (0) x 2 ),
        );

        if ( $head_loc > 1 ) {
            $self->_load_sector( $head_loc )->free;
        }
    }

    $self->clear_entries;

    my @slots = $self->read_txn_slots;
    $slots[$self->trans_id-1] = 0;
    $self->write_txn_slots( @slots );
    $self->inc_txn_staleness_counter( $self->trans_id );
    $self->set_trans_id( 0 );

    return 1;
}

sub read_txn_slots {
    my $self = shift;
    my $bl = $self->txn_bitfield_len;
    my $num_bits = $bl * 8;
    return split '', unpack( 'b'.$num_bits,
        $self->storage->read_at(
            $self->trans_loc, $bl,
        )
    );
}

sub write_txn_slots {
    my $self = shift;
    my $num_bits = $self->txn_bitfield_len * 8;
    $self->storage->print_at( $self->trans_loc,
        pack( 'b'.$num_bits, join('', @_) ),
    );
}

sub get_running_txn_ids {
    my $self = shift;
    my @transactions = $self->read_txn_slots;
    my @trans_ids = map { $_+1} grep { $transactions[$_] } 0 .. $#transactions;
}

sub get_txn_staleness_counter {
    my $self = shift;
    my ($trans_id) = @_;

    # Hardcode staleness of 0 for the HEAD
    return 0 unless $trans_id;

    return unpack( $StP{$STALE_SIZE},
        $self->storage->read_at(
            $self->trans_loc + 4 + $STALE_SIZE * ($trans_id - 1),
            4,
        )
    );
}

sub inc_txn_staleness_counter {
    my $self = shift;
    my ($trans_id) = @_;

    # Hardcode staleness of 0 for the HEAD
    return unless $trans_id;

    $self->storage->print_at(
        $self->trans_loc + 4 + $STALE_SIZE * ($trans_id - 1),
        pack( $StP{$STALE_SIZE}, $self->get_txn_staleness_counter( $trans_id ) + 1 ),
    );
}

sub get_entries {
    my $self = shift;
    return [ keys %{ $self->{entries}{$self->trans_id} ||= {} } ];
}

sub add_entry {
    my $self = shift;
    my ($trans_id, $loc) = @_;

    $self->{entries}{$trans_id} ||= {};
    $self->{entries}{$trans_id}{$loc} = undef;
}

# If the buckets are being relocated because of a reindexing, the entries
# mechanism needs to be made aware of it.
sub reindex_entry {
    my $self = shift;
    my ($old_loc, $new_loc) = @_;

    TRANS:
    while ( my ($trans_id, $locs) = each %{ $self->{entries} } ) {
        foreach my $orig_loc ( keys %{ $locs } ) {
            if ( $orig_loc == $old_loc ) {
                delete $locs->{orig_loc};
                $locs->{$new_loc} = undef;
                next TRANS;
            }
        }
    }
}

sub clear_entries {
    my $self = shift;
    delete $self->{entries}{$self->trans_id};
}

################################################################################

{
    my $header_fixed = length( SIG_FILE ) + 1 + 4 + 4;
    my $this_file_version = 2;

    sub _write_file_header {
        my $self = shift;

        my $nt = $self->num_txns;
        my $bl = $self->txn_bitfield_len;

        my $header_var = 1 + 1 + 1 + 1 + $bl + $STALE_SIZE * ($nt - 1) + 3 * $self->byte_size;

        my $loc = $self->storage->request_space( $header_fixed + $header_var );

        $self->storage->print_at( $loc,
            SIG_FILE,
            SIG_HEADER,
            pack('N', $this_file_version), # At this point, we're at 9 bytes
            pack('N', $header_var),        # header size
            # --- Above is $header_fixed. Below is $header_var
            pack('C', $self->byte_size),

            # These shenanigans are to allow a 256 within a C
            pack('C', $self->max_buckets - 1),
            pack('C', $self->data_sector_size - 1),

            pack('C', $nt),
            pack('C' . $bl, 0 ),                           # Transaction activeness bitfield
            pack($StP{$STALE_SIZE}.($nt-1), 0 x ($nt-1) ), # Transaction staleness counters
            pack($StP{$self->byte_size}, 0), # Start of free chain (blist size)
            pack($StP{$self->byte_size}, 0), # Start of free chain (data size)
            pack($StP{$self->byte_size}, 0), # Start of free chain (index size)
        );

        #XXX Set these less fragilely
        $self->set_trans_loc( $header_fixed + 4 );
        $self->set_chains_loc( $header_fixed + 4 + $bl + $STALE_SIZE * ($nt-1) );

        return;
    }

    sub _read_file_header {
        my $self = shift;

        my $buffer = $self->storage->read_at( 0, $header_fixed );
        return unless length($buffer);

        my ($file_signature, $sig_header, $file_version, $size) = unpack(
            'A4 A N N', $buffer
        );

        unless ( $file_signature eq SIG_FILE ) {
            $self->storage->close;
            DBM::Deep::10002->_throw_error( "Signature not found -- file is not a Deep DB" );
        }

        unless ( $sig_header eq SIG_HEADER ) {
            $self->storage->close;
            DBM::Deep::10002->_throw_error( "Pre-1.00 file version found" );
        }

        unless ( $file_version == $this_file_version ) {
            $self->storage->close;
            DBM::Deep::10002->_throw_error(
                "Wrong file version found - " .  $file_version .
                " - expected " . $this_file_version
            );
        }

        my $buffer2 = $self->storage->read_at( undef, $size );
        my @values = unpack( 'C C C C', $buffer2 );

        if ( @values != 4 || grep { !defined } @values ) {
            $self->storage->close;
            DBM::Deep::10002->_throw_error("Corrupted file - bad header");
        }

        #XXX Add warnings if values weren't set right
        @{$self}{qw(byte_size max_buckets data_sector_size num_txns)} = @values;

        # These shenangians are to allow a 256 within a C
        $self->{max_buckets} += 1;
        $self->{data_sector_size} += 1;

        my $bl = $self->txn_bitfield_len;

        my $header_var = scalar(@values) + $bl + $STALE_SIZE * ($self->num_txns - 1) + 3 * $self->byte_size;
        unless ( $size == $header_var ) {
            $self->storage->close;
            DBM::Deep::10002->_throw_error( "Unexpected size found ($size <-> $header_var)." );
        }

        $self->set_trans_loc( $header_fixed + scalar(@values) );
        $self->set_chains_loc( $header_fixed + scalar(@values) + $bl + $STALE_SIZE * ($self->num_txns - 1) );

        return length($buffer) + length($buffer2);
    }
}

sub _load_sector {
    my $self = shift;
    my ($offset) = @_;

    # Add a catch for offset of 0 or 1
    return if $offset <= 1;

    my $type = $self->storage->read_at( $offset, 1 );
    return if $type eq chr(0);

    if ( $type eq $self->SIG_ARRAY || $type eq $self->SIG_HASH ) {
        return DBM::Deep::10002::Engine::Sector::Reference->new({
            engine => $self,
            type   => $type,
            offset => $offset,
        });
    }
    # XXX Don't we need key_md5 here?
    elsif ( $type eq $self->SIG_BLIST ) {
        return DBM::Deep::10002::Engine::Sector::BucketList->new({
            engine => $self,
            type   => $type,
            offset => $offset,
        });
    }
    elsif ( $type eq $self->SIG_INDEX ) {
        return DBM::Deep::10002::Engine::Sector::Index->new({
            engine => $self,
            type   => $type,
            offset => $offset,
        });
    }
    elsif ( $type eq $self->SIG_NULL ) {
        return DBM::Deep::10002::Engine::Sector::Null->new({
            engine => $self,
            type   => $type,
            offset => $offset,
        });
    }
    elsif ( $type eq $self->SIG_DATA ) {
        return DBM::Deep::10002::Engine::Sector::Scalar->new({
            engine => $self,
            type   => $type,
            offset => $offset,
        });
    }
    # This was deleted from under us, so just return and let the caller figure it out.
    elsif ( $type eq $self->SIG_FREE ) {
        return;
    }

    DBM::Deep::10002->_throw_error( "'$offset': Don't know what to do with type '$type'" );
}

sub _apply_digest {
    my $self = shift;
    return $self->{digest}->(@_);
}

sub _add_free_blist_sector { shift->_add_free_sector( 0, @_ ) }
sub _add_free_data_sector { shift->_add_free_sector( 1, @_ ) }
sub _add_free_index_sector { shift->_add_free_sector( 2, @_ ) }

sub _add_free_sector {
    my $self = shift;
    my ($multiple, $offset, $size) = @_;

    my $chains_offset = $multiple * $self->byte_size;

    my $storage = $self->storage;

    # Increment staleness.
    # XXX Can this increment+modulo be done by "&= 0x1" ?
    my $staleness = unpack( $StP{$STALE_SIZE}, $storage->read_at( $offset + SIG_SIZE, $STALE_SIZE ) );
    $staleness = ($staleness + 1 ) % ( 2 ** ( 8 * $STALE_SIZE ) );
    $storage->print_at( $offset + SIG_SIZE, pack( $StP{$STALE_SIZE}, $staleness ) );

    my $old_head = $storage->read_at( $self->chains_loc + $chains_offset, $self->byte_size );

    $storage->print_at( $self->chains_loc + $chains_offset,
        pack( $StP{$self->byte_size}, $offset ),
    );

    # Record the old head in the new sector after the signature and staleness counter
    $storage->print_at( $offset + SIG_SIZE + $STALE_SIZE, $old_head );
}

sub _request_blist_sector { shift->_request_sector( 0, @_ ) }
sub _request_data_sector { shift->_request_sector( 1, @_ ) }
sub _request_index_sector { shift->_request_sector( 2, @_ ) }

sub _request_sector {
    my $self = shift;
    my ($multiple, $size) = @_;

    my $chains_offset = $multiple * $self->byte_size;

    my $old_head = $self->storage->read_at( $self->chains_loc + $chains_offset, $self->byte_size );
    my $loc = unpack( $StP{$self->byte_size}, $old_head );

    # We don't have any free sectors of the right size, so allocate a new one.
    unless ( $loc ) {
        my $offset = $self->storage->request_space( $size );

        # Zero out the new sector. This also guarantees correct increases
        # in the filesize.
        $self->storage->print_at( $offset, chr(0) x $size );

        return $offset;
    }

    # Read the new head after the signature and the staleness counter
    my $new_head = $self->storage->read_at( $loc + SIG_SIZE + $STALE_SIZE, $self->byte_size );
    $self->storage->print_at( $self->chains_loc + $chains_offset, $new_head );
    $self->storage->print_at(
        $loc + SIG_SIZE + $STALE_SIZE,
        pack( $StP{$self->byte_size}, 0 ),
    );

    return $loc;
}

################################################################################

sub storage     { $_[0]{storage} }
sub byte_size   { $_[0]{byte_size} }
sub hash_size   { $_[0]{hash_size} }
sub hash_chars  { $_[0]{hash_chars} }
sub num_txns    { $_[0]{num_txns} }
sub max_buckets { $_[0]{max_buckets} }
sub blank_md5   { chr(0) x $_[0]->hash_size }
sub data_sector_size { $_[0]{data_sector_size} }

# This is a calculated value
sub txn_bitfield_len {
    my $self = shift;
    unless ( exists $self->{txn_bitfield_len} ) {
        my $temp = ($self->num_txns) / 8;
        if ( $temp > int( $temp ) ) {
            $temp = int( $temp ) + 1;
        }
        $self->{txn_bitfield_len} = $temp;
    }
    return $self->{txn_bitfield_len};
}

sub trans_id     { $_[0]{trans_id} }
sub set_trans_id { $_[0]{trans_id} = $_[1] }

sub trans_loc     { $_[0]{trans_loc} }
sub set_trans_loc { $_[0]{trans_loc} = $_[1] }

sub chains_loc     { $_[0]{chains_loc} }
sub set_chains_loc { $_[0]{chains_loc} = $_[1] }

################################################################################

package DBM::Deep::10002::Iterator;

sub new {
    my $class = shift;
    my ($args) = @_;

    my $self = bless {
        breadcrumbs => [],
        engine      => $args->{engine},
        base_offset => $args->{base_offset},
    }, $class;

    Scalar::Util::weaken( $self->{engine} );

    return $self;
}

sub reset { $_[0]{breadcrumbs} = [] }

sub get_sector_iterator {
    my $self = shift;
    my ($loc) = @_;

    my $sector = $self->{engine}->_load_sector( $loc )
        or return;

    if ( $sector->isa( 'DBM::Deep::10002::Engine::Sector::Index' ) ) {
        return DBM::Deep::10002::Iterator::Index->new({
            iterator => $self,
            sector   => $sector,
        });
    }
    elsif ( $sector->isa( 'DBM::Deep::10002::Engine::Sector::BucketList' ) ) {
        return DBM::Deep::10002::Iterator::BucketList->new({
            iterator => $self,
            sector   => $sector,
        });
    }

    DBM::Deep::10002->_throw_error( "get_sector_iterator(): Why did $loc make a $sector?" );
}

sub get_next_key {
    my $self = shift;
    my ($obj) = @_;

    my $crumbs = $self->{breadcrumbs};
    my $e = $self->{engine};

    unless ( @$crumbs ) {
        # This will be a Reference sector
        my $sector = $e->_load_sector( $self->{base_offset} )
            # If no sector is found, thist must have been deleted from under us.
            or return;

        if ( $sector->staleness != $obj->_staleness ) {
            return;
        }

        my $loc = $sector->get_blist_loc
            or return;

        push @$crumbs, $self->get_sector_iterator( $loc );
    }

    FIND_NEXT_KEY: {
        # We're at the end.
        unless ( @$crumbs ) {
            $self->reset;
            return;
        }

        my $iterator = $crumbs->[-1];

        # This level is done.
        if ( $iterator->at_end ) {
            pop @$crumbs;
            redo FIND_NEXT_KEY;
        }

        if ( $iterator->isa( 'DBM::Deep::10002::Iterator::Index' ) ) {
            # If we don't have any more, it will be caught at the
            # prior check.
            if ( my $next = $iterator->get_next_iterator ) {
                push @$crumbs, $next;
            }
            redo FIND_NEXT_KEY;
        }

        unless ( $iterator->isa( 'DBM::Deep::10002::Iterator::BucketList' ) ) {
            DBM::Deep::10002->_throw_error(
                "Should have a bucketlist iterator here - instead have $iterator"
            );
        }

        # At this point, we have a BucketList iterator
        my $key = $iterator->get_next_key;
        if ( defined $key ) {
            return $key;
        }
        #XXX else { $iterator->set_to_end() } ?

        # We hit the end of the bucketlist iterator, so redo
        redo FIND_NEXT_KEY;
    }

    DBM::Deep::10002->_throw_error( "get_next_key(): How did we get here?" );
}

package DBM::Deep::10002::Iterator::Index;

sub new {
    my $self = bless $_[1] => $_[0];
    $self->{curr_index} = 0;
    return $self;
}

sub at_end {
    my $self = shift;
    return $self->{curr_index} >= $self->{iterator}{engine}->hash_chars;
}

sub get_next_iterator {
    my $self = shift;

    my $loc;
    while ( !$loc ) {
        return if $self->at_end;
        $loc = $self->{sector}->get_entry( $self->{curr_index}++ );
    }

    return $self->{iterator}->get_sector_iterator( $loc );
}

package DBM::Deep::10002::Iterator::BucketList;

sub new {
    my $self = bless $_[1] => $_[0];
    $self->{curr_index} = 0;
    return $self;
}

sub at_end {
    my $self = shift;
    return $self->{curr_index} >= $self->{iterator}{engine}->max_buckets;
}

sub get_next_key {
    my $self = shift;

    return if $self->at_end;

    my $idx = $self->{curr_index}++;

    my $data_loc = $self->{sector}->get_data_location_for({
        allow_head => 1,
        idx        => $idx,
    }) or return;

    #XXX Do we want to add corruption checks here?
    return $self->{sector}->get_key_for( $idx )->data;
}

package DBM::Deep::10002::Engine::Sector;

sub new {
    my $self = bless $_[1], $_[0];
    Scalar::Util::weaken( $self->{engine} );
    $self->_init;
    return $self;
}

#sub _init {}
#sub clone { DBM::Deep::10002->_throw_error( "Must be implemented in the child class" ); }

sub engine { $_[0]{engine} }
sub offset { $_[0]{offset} }
sub type   { $_[0]{type} }

sub base_size {
   my $self = shift;
   return $self->engine->SIG_SIZE + $STALE_SIZE;
}

sub free {
    my $self = shift;

    my $e = $self->engine;

    $e->storage->print_at( $self->offset, $e->SIG_FREE );
    # Skip staleness counter
    $e->storage->print_at( $self->offset + $self->base_size,
        chr(0) x ($self->size - $self->base_size),
    );

    my $free_meth = $self->free_meth;
    $e->$free_meth( $self->offset, $self->size );

    return;
}

package DBM::Deep::10002::Engine::Sector::Data;

our @ISA = qw( DBM::Deep::10002::Engine::Sector );

# This is in bytes
sub size { $_[0]{engine}->data_sector_size }
sub free_meth { return '_add_free_data_sector' }

sub clone {
    my $self = shift;
    return ref($self)->new({
        engine => $self->engine,
        type   => $self->type,
        data   => $self->data,
    });
}

package DBM::Deep::10002::Engine::Sector::Scalar;

our @ISA = qw( DBM::Deep::10002::Engine::Sector::Data );

sub free {
    my $self = shift;

    my $chain_loc = $self->chain_loc;

    $self->SUPER::free();

    if ( $chain_loc ) {
        $self->engine->_load_sector( $chain_loc )->free;
    }

    return;
}

sub type { $_[0]{engine}->SIG_DATA }
sub _init {
    my $self = shift;

    my $engine = $self->engine;

    unless ( $self->offset ) {
        my $data_section = $self->size - $self->base_size - $engine->byte_size - 1;

        $self->{offset} = $engine->_request_data_sector( $self->size );

        my $data = delete $self->{data};
        my $dlen = length $data;
        my $continue = 1;
        my $curr_offset = $self->offset;
        while ( $continue ) {

            my $next_offset = 0;

            my ($leftover, $this_len, $chunk);
            if ( $dlen > $data_section ) {
                $leftover = 0;
                $this_len = $data_section;
                $chunk = substr( $data, 0, $this_len );

                $dlen -= $data_section;
                $next_offset = $engine->_request_data_sector( $self->size );
                $data = substr( $data, $this_len );
            }
            else {
                $leftover = $data_section - $dlen;
                $this_len = $dlen;
                $chunk = $data;

                $continue = 0;
            }

            $engine->storage->print_at( $curr_offset, $self->type ); # Sector type
            # Skip staleness
            $engine->storage->print_at( $curr_offset + $self->base_size,
                pack( $StP{$engine->byte_size}, $next_offset ),  # Chain loc
                pack( $StP{1}, $this_len ),                      # Data length
                $chunk,                                          # Data to be stored in this sector
                chr(0) x $leftover,                              # Zero-fill the rest
            );

            $curr_offset = $next_offset;
        }

        return;
    }
}

sub data_length {
    my $self = shift;

    my $buffer = $self->engine->storage->read_at(
        $self->offset + $self->base_size + $self->engine->byte_size, 1
    );

    return unpack( $StP{1}, $buffer );
}

sub chain_loc {
    my $self = shift;
    return unpack(
        $StP{$self->engine->byte_size},
        $self->engine->storage->read_at(
            $self->offset + $self->base_size,
            $self->engine->byte_size,
        ),
    );
}

sub data {
    my $self = shift;

    my $data;
    while ( 1 ) {
        my $chain_loc = $self->chain_loc;

        $data .= $self->engine->storage->read_at(
            $self->offset + $self->base_size + $self->engine->byte_size + 1, $self->data_length,
        );

        last unless $chain_loc;

        $self = $self->engine->_load_sector( $chain_loc );
    }

    return $data;
}

package DBM::Deep::10002::Engine::Sector::Null;

our @ISA = qw( DBM::Deep::10002::Engine::Sector::Data );

sub type { $_[0]{engine}->SIG_NULL }
sub data_length { 0 }
sub data { return }

sub _init {
    my $self = shift;

    my $engine = $self->engine;

    unless ( $self->offset ) {
        my $leftover = $self->size - $self->base_size - 1 * $engine->byte_size - 1;

        $self->{offset} = $engine->_request_data_sector( $self->size );
        $engine->storage->print_at( $self->offset, $self->type ); # Sector type
        # Skip staleness counter
        $engine->storage->print_at( $self->offset + $self->base_size,
            pack( $StP{$engine->byte_size}, 0 ),  # Chain loc
            pack( $StP{1}, $self->data_length ),  # Data length
            chr(0) x $leftover,                   # Zero-fill the rest
        );

        return;
    }
}

package DBM::Deep::10002::Engine::Sector::Reference;

our @ISA = qw( DBM::Deep::10002::Engine::Sector::Data );

sub _init {
    my $self = shift;

    my $e = $self->engine;

    unless ( $self->offset ) {
        my $classname = Scalar::Util::blessed( delete $self->{data} );
        my $leftover = $self->size - $self->base_size - 2 * $e->byte_size;

        my $class_offset = 0;
        if ( defined $classname ) {
            my $class_sector = DBM::Deep::10002::Engine::Sector::Scalar->new({
                engine => $e,
                data   => $classname,
            });
            $class_offset = $class_sector->offset;
        }

        $self->{offset} = $e->_request_data_sector( $self->size );
        $e->storage->print_at( $self->offset, $self->type ); # Sector type
        # Skip staleness counter
        $e->storage->print_at( $self->offset + $self->base_size,
            pack( $StP{$e->byte_size}, 0 ),             # Index/BList loc
            pack( $StP{$e->byte_size}, $class_offset ), # Classname loc
            chr(0) x $leftover,                         # Zero-fill the rest
        );
    }
    else {
        $self->{type} = $e->storage->read_at( $self->offset, 1 );
    }

    $self->{staleness} = unpack(
        $StP{$STALE_SIZE},
        $e->storage->read_at( $self->offset + $e->SIG_SIZE, $STALE_SIZE ),
    );

    return;
}

sub free {
    my $self = shift;

    my $blist_loc = $self->get_blist_loc;
    $self->engine->_load_sector( $blist_loc )->free if $blist_loc;

    my $class_loc = $self->get_class_offset;
    $self->engine->_load_sector( $class_loc )->free if $class_loc;

    $self->SUPER::free();
}

sub staleness { $_[0]{staleness} }

sub get_data_for {
    my $self = shift;
    my ($args) = @_;

    # Assume that the head is not allowed unless otherwise specified.
    $args->{allow_head} = 0 unless exists $args->{allow_head};

    # Assume we don't create a new blist location unless otherwise specified.
    $args->{create} = 0 unless exists $args->{create};

    my $blist = $self->get_bucket_list({
        key_md5 => $args->{key_md5},
        key => $args->{key},
        create  => $args->{create},
    });
    return unless $blist && $blist->{found};

    # At this point, $blist knows where the md5 is. What it -doesn't- know yet
    # is whether or not this transaction has this key. That's part of the next
    # function call.
    my $location = $blist->get_data_location_for({
        allow_head => $args->{allow_head},
    }) or return;

    return $self->engine->_load_sector( $location );
}

sub write_data {
    my $self = shift;
    my ($args) = @_;

    my $blist = $self->get_bucket_list({
        key_md5 => $args->{key_md5},
        key => $args->{key},
        create  => 1,
    }) or DBM::Deep::10002->_throw_error( "How did write_data fail (no blist)?!" );

    # Handle any transactional bookkeeping.
    if ( $self->engine->trans_id ) {
        if ( ! $blist->has_md5 ) {
            $blist->mark_deleted({
                trans_id => 0,
            });
        }
    }
    else {
        my @trans_ids = $self->engine->get_running_txn_ids;
        if ( $blist->has_md5 ) {
            if ( @trans_ids ) {
                my $old_value = $blist->get_data_for;
                foreach my $other_trans_id ( @trans_ids ) {
                    next if $blist->get_data_location_for({
                        trans_id   => $other_trans_id,
                        allow_head => 0,
                    });
                    $blist->write_md5({
                        trans_id => $other_trans_id,
                        key      => $args->{key},
                        key_md5  => $args->{key_md5},
                        value    => $old_value->clone,
                    });
                }
            }
        }
        else {
            if ( @trans_ids ) {
                foreach my $other_trans_id ( @trans_ids ) {
                    #XXX This doesn't seem to possible to ever happen . . .
                    next if $blist->get_data_location_for({ trans_id => $other_trans_id, allow_head => 0 });
                    $blist->mark_deleted({
                        trans_id => $other_trans_id,
                    });
                }
            }
        }
    }

    #XXX Is this safe to do transactionally?
    # Free the place we're about to write to.
    if ( $blist->get_data_location_for({ allow_head => 0 }) ) {
        $blist->get_data_for({ allow_head => 0 })->free;
    }

    $blist->write_md5({
        key      => $args->{key},
        key_md5  => $args->{key_md5},
        value    => $args->{value},
    });
}

sub delete_key {
    my $self = shift;
    my ($args) = @_;

    # XXX What should happen if this fails?
    my $blist = $self->get_bucket_list({
        key_md5 => $args->{key_md5},
    }) or DBM::Deep::10002->_throw_error( "How did delete_key fail (no blist)?!" );

    # Save the location so that we can free the data
    my $location = $blist->get_data_location_for({
        allow_head => 0,
    });
    my $old_value = $location && $self->engine->_load_sector( $location );

    my @trans_ids = $self->engine->get_running_txn_ids;

    if ( $self->engine->trans_id == 0 ) {
        if ( @trans_ids ) {
            foreach my $other_trans_id ( @trans_ids ) {
                next if $blist->get_data_location_for({ trans_id => $other_trans_id, allow_head => 0 });
                $blist->write_md5({
                    trans_id => $other_trans_id,
                    key      => $args->{key},
                    key_md5  => $args->{key_md5},
                    value    => $old_value->clone,
                });
            }
        }
    }

    my $data;
    if ( @trans_ids ) {
        $blist->mark_deleted( $args );

        if ( $old_value ) {
            $data = $old_value->data;
            $old_value->free;
        }
    }
    else {
        $data = $blist->delete_md5( $args );
    }

    return $data;
}

sub get_blist_loc {
    my $self = shift;

    my $e = $self->engine;
    my $blist_loc = $e->storage->read_at( $self->offset + $self->base_size, $e->byte_size );
    return unpack( $StP{$e->byte_size}, $blist_loc );
}

sub get_bucket_list {
    my $self = shift;
    my ($args) = @_;
    $args ||= {};

    # XXX Add in check here for recycling?

    my $engine = $self->engine;

    my $blist_loc = $self->get_blist_loc;

    # There's no index or blist yet
    unless ( $blist_loc ) {
        return unless $args->{create};

        my $blist = DBM::Deep::10002::Engine::Sector::BucketList->new({
            engine  => $engine,
            key_md5 => $args->{key_md5},
        });

        $engine->storage->print_at( $self->offset + $self->base_size,
            pack( $StP{$engine->byte_size}, $blist->offset ),
        );

        return $blist;
    }

    my $sector = $engine->_load_sector( $blist_loc )
        or DBM::Deep::10002->_throw_error( "Cannot read sector at $blist_loc in get_bucket_list()" );
    my $i = 0;
    my $last_sector = undef;
    while ( $sector->isa( 'DBM::Deep::10002::Engine::Sector::Index' ) ) {
        $blist_loc = $sector->get_entry( ord( substr( $args->{key_md5}, $i++, 1 ) ) );
        $last_sector = $sector;
        if ( $blist_loc ) {
            $sector = $engine->_load_sector( $blist_loc )
                or DBM::Deep::10002->_throw_error( "Cannot read sector at $blist_loc in get_bucket_list()" );
        }
        else {
            $sector = undef;
            last;
        }
    }

    # This means we went through the Index sector(s) and found an empty slot
    unless ( $sector ) {
        return unless $args->{create};

        DBM::Deep::10002->_throw_error( "No last_sector when attempting to build a new entry" )
            unless $last_sector;

        my $blist = DBM::Deep::10002::Engine::Sector::BucketList->new({
            engine  => $engine,
            key_md5 => $args->{key_md5},
        });

        $last_sector->set_entry( ord( substr( $args->{key_md5}, $i - 1, 1 ) ) => $blist->offset );

        return $blist;
    }

    $sector->find_md5( $args->{key_md5} );

    # See whether or not we need to reindex the bucketlist
    if ( !$sector->has_md5 && $args->{create} && $sector->{idx} == -1 ) {
        my $new_index = DBM::Deep::10002::Engine::Sector::Index->new({
            engine => $engine,
        });

        my %blist_cache;
        #XXX q.v. the comments for this function.
        foreach my $entry ( $sector->chopped_up ) {
            my ($spot, $md5) = @{$entry};
            my $idx = ord( substr( $md5, $i, 1 ) );

            # XXX This is inefficient
            my $blist = $blist_cache{$idx}
                ||= DBM::Deep::10002::Engine::Sector::BucketList->new({
                    engine => $engine,
                });

            $new_index->set_entry( $idx => $blist->offset );

            my $new_spot = $blist->write_at_next_open( $md5 );
            $engine->reindex_entry( $spot => $new_spot );
        }

        # Handle the new item separately.
        {
            my $idx = ord( substr( $args->{key_md5}, $i, 1 ) );
            my $blist = $blist_cache{$idx}
                ||= DBM::Deep::10002::Engine::Sector::BucketList->new({
                    engine => $engine,
                });

            $new_index->set_entry( $idx => $blist->offset );

            #XXX THIS IS HACKY!
            $blist->find_md5( $args->{key_md5} );
            $blist->write_md5({
                key     => $args->{key},
                key_md5 => $args->{key_md5},
                value   => DBM::Deep::10002::Engine::Sector::Null->new({
                    engine => $engine,
                    data   => undef,
                }),
            });
        }

        if ( $last_sector ) {
            $last_sector->set_entry(
                ord( substr( $args->{key_md5}, $i - 1, 1 ) ),
                $new_index->offset,
            );
        } else {
            $engine->storage->print_at( $self->offset + $self->base_size,
                pack( $StP{$engine->byte_size}, $new_index->offset ),
            );
        }

        $sector->free;

        $sector = $blist_cache{ ord( substr( $args->{key_md5}, $i, 1 ) ) };
        $sector->find_md5( $args->{key_md5} );
    }

    return $sector;
}

sub get_class_offset {
    my $self = shift;

    my $e = $self->engine;
    return unpack(
        $StP{$e->byte_size},
        $e->storage->read_at(
            $self->offset + $self->base_size + 1 * $e->byte_size, $e->byte_size,
        ),
    );
}

sub get_classname {
    my $self = shift;

    my $class_offset = $self->get_class_offset;

    return unless $class_offset;

    return $self->engine->_load_sector( $class_offset )->data;
}

#XXX Add singleton handling here
sub data {
    my $self = shift;

    my $new_obj = DBM::Deep::10002->new({
        type        => $self->type,
        base_offset => $self->offset,
        staleness   => $self->staleness,
        storage     => $self->engine->storage,
        engine      => $self->engine,
    });

    if ( $self->engine->storage->{autobless} ) {
        my $classname = $self->get_classname;
        if ( defined $classname ) {
            bless $new_obj, $classname;
        }
    }

    return $new_obj;
}

package DBM::Deep::10002::Engine::Sector::BucketList;

our @ISA = qw( DBM::Deep::10002::Engine::Sector );

sub _init {
    my $self = shift;

    my $engine = $self->engine;

    unless ( $self->offset ) {
        my $leftover = $self->size - $self->base_size;

        $self->{offset} = $engine->_request_blist_sector( $self->size );
        $engine->storage->print_at( $self->offset, $engine->SIG_BLIST ); # Sector type
        # Skip staleness counter
        $engine->storage->print_at( $self->offset + $self->base_size,
            chr(0) x $leftover, # Zero-fill the data
        );
    }

    if ( $self->{key_md5} ) {
        $self->find_md5;
    }

    return $self;
}

sub size {
    my $self = shift;
    unless ( $self->{size} ) {
        my $e = $self->engine;
        # Base + numbuckets * bucketsize
        $self->{size} = $self->base_size + $e->max_buckets * $self->bucket_size;
    }
    return $self->{size};
}

sub free_meth { return '_add_free_blist_sector' }

sub bucket_size {
    my $self = shift;
    unless ( $self->{bucket_size} ) {
        my $e = $self->engine;
        # Key + head (location) + transactions (location + staleness-counter)
        my $location_size = $e->byte_size + $e->byte_size + ($e->num_txns - 1) * ($e->byte_size + $STALE_SIZE);
        $self->{bucket_size} = $e->hash_size + $location_size;
    }
    return $self->{bucket_size};
}

# XXX This is such a poor hack. I need to rethink this code.
sub chopped_up {
    my $self = shift;

    my $e = $self->engine;

    my @buckets;
    foreach my $idx ( 0 .. $e->max_buckets - 1 ) {
        my $spot = $self->offset + $self->base_size + $idx * $self->bucket_size;
        my $md5 = $e->storage->read_at( $spot, $e->hash_size );

        #XXX If we're chopping, why would we ever have the blank_md5?
        last if $md5 eq $e->blank_md5;

        my $rest = $e->storage->read_at( undef, $self->bucket_size - $e->hash_size );
        push @buckets, [ $spot, $md5 . $rest ];
    }

    return @buckets;
}

sub write_at_next_open {
    my $self = shift;
    my ($entry) = @_;

    #XXX This is such a hack!
    $self->{_next_open} = 0 unless exists $self->{_next_open};

    my $spot = $self->offset + $self->base_size + $self->{_next_open}++ * $self->bucket_size;
    $self->engine->storage->print_at( $spot, $entry );

    return $spot;
}

sub has_md5 {
    my $self = shift;
    unless ( exists $self->{found} ) {
        $self->find_md5;
    }
    return $self->{found};
}

sub find_md5 {
    my $self = shift;

    $self->{found} = undef;
    $self->{idx}   = -1;

    if ( @_ ) {
        $self->{key_md5} = shift;
    }

    # If we don't have an MD5, then what are we supposed to do?
    unless ( exists $self->{key_md5} ) {
        DBM::Deep::10002->_throw_error( "Cannot find_md5 without a key_md5 set" );
    }

    my $e = $self->engine;
    foreach my $idx ( 0 .. $e->max_buckets - 1 ) {
        my $potential = $e->storage->read_at(
            $self->offset + $self->base_size + $idx * $self->bucket_size, $e->hash_size,
        );

        if ( $potential eq $e->blank_md5 ) {
            $self->{idx} = $idx;
            return;
        }

        if ( $potential eq $self->{key_md5} ) {
            $self->{found} = 1;
            $self->{idx} = $idx;
            return;
        }
    }

    return;
}

sub write_md5 {
    my $self = shift;
    my ($args) = @_;

    DBM::Deep::10002->_throw_error( "write_md5: no key" ) unless exists $args->{key};
    DBM::Deep::10002->_throw_error( "write_md5: no key_md5" ) unless exists $args->{key_md5};
    DBM::Deep::10002->_throw_error( "write_md5: no value" ) unless exists $args->{value};

    my $engine = $self->engine;

    $args->{trans_id} = $engine->trans_id unless exists $args->{trans_id};

    my $spot = $self->offset + $self->base_size + $self->{idx} * $self->bucket_size;
    $engine->add_entry( $args->{trans_id}, $spot );

    unless ($self->{found}) {
        my $key_sector = DBM::Deep::10002::Engine::Sector::Scalar->new({
            engine => $engine,
            data   => $args->{key},
        });

        $engine->storage->print_at( $spot,
            $args->{key_md5},
            pack( $StP{$engine->byte_size}, $key_sector->offset ),
        );
    }

    my $loc = $spot
      + $engine->hash_size
      + $engine->byte_size;

    if ( $args->{trans_id} ) {
        $loc += $engine->byte_size + ($args->{trans_id} - 1) * ( $engine->byte_size + $STALE_SIZE );

        $engine->storage->print_at( $loc,
            pack( $StP{$engine->byte_size}, $args->{value}->offset ),
            pack( $StP{$STALE_SIZE}, $engine->get_txn_staleness_counter( $args->{trans_id} ) ),
        );
    }
    else {
        $engine->storage->print_at( $loc,
            pack( $StP{$engine->byte_size}, $args->{value}->offset ),
        );
    }
}

sub mark_deleted {
    my $self = shift;
    my ($args) = @_;
    $args ||= {};

    my $engine = $self->engine;

    $args->{trans_id} = $engine->trans_id unless exists $args->{trans_id};

    my $spot = $self->offset + $self->base_size + $self->{idx} * $self->bucket_size;
    $engine->add_entry( $args->{trans_id}, $spot );

    my $loc = $spot
      + $engine->hash_size
      + $engine->byte_size;

    if ( $args->{trans_id} ) {
        $loc += $engine->byte_size + ($args->{trans_id} - 1) * ( $engine->byte_size + $STALE_SIZE );

        $engine->storage->print_at( $loc,
            pack( $StP{$engine->byte_size}, 1 ), # 1 is the marker for deleted
            pack( $StP{$STALE_SIZE}, $engine->get_txn_staleness_counter( $args->{trans_id} ) ),
        );
    }
    else {
        $engine->storage->print_at( $loc,
            pack( $StP{$engine->byte_size}, 1 ), # 1 is the marker for deleted
        );
    }

}

sub delete_md5 {
    my $self = shift;
    my ($args) = @_;

    my $engine = $self->engine;
    return undef unless $self->{found};

    # Save the location so that we can free the data
    my $location = $self->get_data_location_for({
        allow_head => 0,
    });
    my $key_sector = $self->get_key_for;

    my $spot = $self->offset + $self->base_size + $self->{idx} * $self->bucket_size;
    $engine->storage->print_at( $spot,
        $engine->storage->read_at(
            $spot + $self->bucket_size,
            $self->bucket_size * ( $engine->max_buckets - $self->{idx} - 1 ),
        ),
        chr(0) x $self->bucket_size,
    );

    $key_sector->free;

    my $data_sector = $self->engine->_load_sector( $location );
    my $data = $data_sector->data;
    $data_sector->free;

    return $data;
}

sub get_data_location_for {
    my $self = shift;
    my ($args) = @_;
    $args ||= {};

    $args->{allow_head} = 0 unless exists $args->{allow_head};
    $args->{trans_id}   = $self->engine->trans_id unless exists $args->{trans_id};
    $args->{idx}        = $self->{idx} unless exists $args->{idx};

    my $e = $self->engine;

    my $spot = $self->offset + $self->base_size
      + $args->{idx} * $self->bucket_size
      + $e->hash_size
      + $e->byte_size;

    if ( $args->{trans_id} ) {
        $spot += $e->byte_size + ($args->{trans_id} - 1) * ( $e->byte_size + $STALE_SIZE );
    }

    my $buffer = $e->storage->read_at(
        $spot,
        $e->byte_size + $STALE_SIZE,
    );
    my ($loc, $staleness) = unpack( $StP{$e->byte_size} . ' ' . $StP{$STALE_SIZE}, $buffer );

    if ( $args->{trans_id} ) {
        # We have found an entry that is old, so get rid of it
        if ( $staleness != (my $s = $e->get_txn_staleness_counter( $args->{trans_id} ) ) ) {
            $e->storage->print_at(
                $spot,
                pack( $StP{$e->byte_size} . ' ' . $StP{$STALE_SIZE}, (0) x 2 ), 
            );
            $loc = 0;
        }
    }

    # If we're in a transaction and we never wrote to this location, try the
    # HEAD instead.
    if ( $args->{trans_id} && !$loc && $args->{allow_head} ) {
        return $self->get_data_location_for({
            trans_id   => 0,
            allow_head => 1,
            idx        => $args->{idx},
        });
    }
    return $loc <= 1 ? 0 : $loc;
}

sub get_data_for {
    my $self = shift;
    my ($args) = @_;
    $args ||= {};

    return unless $self->{found};
    my $location = $self->get_data_location_for({
        allow_head => $args->{allow_head},
    });
    return $self->engine->_load_sector( $location );
}

sub get_key_for {
    my $self = shift;
    my ($idx) = @_;
    $idx = $self->{idx} unless defined $idx;

    if ( $idx >= $self->engine->max_buckets ) {
        DBM::Deep::10002->_throw_error( "get_key_for(): Attempting to retrieve $idx" );
    }

    my $location = $self->engine->storage->read_at(
        $self->offset + $self->base_size + $idx * $self->bucket_size + $self->engine->hash_size,
        $self->engine->byte_size,
    );
    $location = unpack( $StP{$self->engine->byte_size}, $location );
    DBM::Deep::10002->_throw_error( "get_key_for: No location?" ) unless $location;

    return $self->engine->_load_sector( $location );
}

package DBM::Deep::10002::Engine::Sector::Index;

our @ISA = qw( DBM::Deep::10002::Engine::Sector );

sub _init {
    my $self = shift;

    my $engine = $self->engine;

    unless ( $self->offset ) {
        my $leftover = $self->size - $self->base_size;

        $self->{offset} = $engine->_request_index_sector( $self->size );
        $engine->storage->print_at( $self->offset, $engine->SIG_INDEX ); # Sector type
        # Skip staleness counter
        $engine->storage->print_at( $self->offset + $self->base_size,
            chr(0) x $leftover, # Zero-fill the rest
        );
    }

    return $self;
}

#XXX Change here
sub size {
    my $self = shift;
    unless ( $self->{size} ) {
        my $e = $self->engine;
        $self->{size} = $self->base_size + $e->byte_size * $e->hash_chars;
    }
    return $self->{size};
}

sub free_meth { return '_add_free_index_sector' }

sub free {
    my $self = shift;
    my $e = $self->engine;

    for my $i ( 0 .. $e->hash_chars - 1 ) {
        my $l = $self->get_entry( $i ) or next;
        $e->_load_sector( $l )->free;
    }

    $self->SUPER::free();
}

sub _loc_for {
    my $self = shift;
    my ($idx) = @_;
    return $self->offset + $self->base_size + $idx * $self->engine->byte_size;
}

sub get_entry {
    my $self = shift;
    my ($idx) = @_;

    my $e = $self->engine;

    DBM::Deep::10002->_throw_error( "get_entry: Out of range ($idx)" )
        if $idx < 0 || $idx >= $e->hash_chars;

    return unpack(
        $StP{$e->byte_size},
        $e->storage->read_at( $self->_loc_for( $idx ), $e->byte_size ),
    );
}

sub set_entry {
    my $self = shift;
    my ($idx, $loc) = @_;

    my $e = $self->engine;

    DBM::Deep::10002->_throw_error( "set_entry: Out of range ($idx)" )
        if $idx < 0 || $idx >= $e->hash_chars;

    $self->engine->storage->print_at(
        $self->_loc_for( $idx ),
        pack( $StP{$e->byte_size}, $loc ),
    );
}

1;
__END__
