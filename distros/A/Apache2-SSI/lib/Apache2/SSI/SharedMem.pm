##----------------------------------------------------------------------------
## Apache2 Server Side Include Parser - ~/lib/Apache2/SSI/SharedMem.pm
## Version v0.1.2
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/01/18
## Modified 2024/09/04
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Apache2::SSI::SharedMem;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $SUPPORTED_RE $SYSV_SUPPORTED $SEMOP_ARGS @EXPORT_OK %EXPORT_TAGS $N $SHEM_REPO );
    use Config;
    use JSON ();
    use Scalar::Util ();
    use constant SHM_BUFSIZ     =>  65536;
    use constant SEM_LOCKER     =>  0;
    use constant SEM_MARKER     =>  1;
    use constant SHM_LOCK_WAIT  =>  0;
    use constant SHM_LOCK_EX    =>  1;
    use constant SHM_LOCK_UN    => -1;
    use constant SHM_EXISTS     =>  1;
    use constant LOCK_SH        =>  1;
    use constant LOCK_EX        =>  2;
    use constant LOCK_NB        =>  4;
    use constant LOCK_UN        =>  8;
    # if( $^O =~ /^(?:Android|cygwin|dos|MSWin32|os2|VMS|riscos)/ )
    # Even better
    our $SUPPORTED_RE = qr/\bIPC\/SysV\b/m;
    if( $Config{extensions} =~ m/$SUPPORTED_RE/ && 
        # No support for threads
        !$Config{useithreads} &&
        $^O !~ /^(?:Android|cygwin|dos|MSWin32|os2|VMS|riscos)/i )
    {
        require IPC::SysV;
        IPC::SysV->import( qw( IPC_RMID IPC_PRIVATE IPC_SET IPC_STAT IPC_CREAT IPC_EXCL IPC_NOWAIT
                               SEM_UNDO S_IRWXU S_IRWXG S_IRWXO
                               GETNCNT GETZCNT GETVAL SETVAL GETPID GETALL SETALL
                               shmat shmdt memread memwrite ftok ) );
        our $SYSV_SUPPORTED = 1;
        eval( <<'EOT' );
        our $SEMOP_ARGS = 
        {
            (LOCK_EX) =>
            [       
                1, 0, 0,                        # wait for readers to finish
                2, 0, 0,                        # wait for writers to finish
                2, 1, SEM_UNDO,                 # assert write lock
            ],
            (LOCK_EX | LOCK_NB) =>
            [
                1, 0, IPC_NOWAIT,               # wait for readers to finish
                2, 0, IPC_NOWAIT,               # wait for writers to finish
                2, 1, (SEM_UNDO | IPC_NOWAIT),  # assert write lock
            ],
            (LOCK_EX | LOCK_UN) =>
            [
                2, -1, (SEM_UNDO | IPC_NOWAIT),
            ],
            (LOCK_SH) =>
            [
                2, 0, 0,                        # wait for writers to finish
                1, 1, SEM_UNDO,                 # assert shared read lock
            ],
            (LOCK_SH | LOCK_NB) =>
            [
                2, 0, IPC_NOWAIT,               # wait for writers to finish
                1, 1, (SEM_UNDO | IPC_NOWAIT),  # assert shared read lock
            ],
            (LOCK_SH | LOCK_UN) =>
            [
                1, -1, (SEM_UNDO | IPC_NOWAIT), # remove shared read lock
            ],
        };
EOT
        if( $@ )
        {
            warn( "Error while trying to evel \$SEMOP_ARGS: $@\n" );
        }
    }
    else
    {
        our $SYSV_SUPPORTED = 0;
    }
    our @EXPORT_OK = qw(LOCK_EX LOCK_SH LOCK_NB LOCK_UN);
    our %EXPORT_TAGS = (
            all     => [qw( LOCK_EX LOCK_SH LOCK_NB LOCK_UN )],
            lock    => [qw( LOCK_EX LOCK_SH LOCK_NB LOCK_UN )],
            'flock' => [qw( LOCK_EX LOCK_SH LOCK_NB LOCK_UN )],
    );
    # Credits IPC::Shareable
    our $N = do { my $foo = eval { pack "L!", 0 }; $@ ? '' : '!' };
    our $SHEM_REPO = {};
    our $VERSION = 'v0.1.2';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    # Default action when accessing a shared memory? If 1, it will create it if it does not exist already
    $self->{create}     = 0;
    $self->{destroy}    = 0;
    $self->{exclusive}  = 0;
    $self->{key}        = &IPC::SysV::IPC_PRIVATE;
    $self->{mode}       = 0666;
    $self->{serial}     = '';
    # SHM_BUFSIZ
    $self->{size}       = SHM_BUFSIZ;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return;
    $self->{addr}       = undef();
    $self->{id}         = undef();
    $self->{locked}     = 0;
    $self->{owner}      = $$;
    $self->{removed}    = 0;
    $self->{semid}      = undef();
    return( $self );
}

sub addr { return( shift->_set_get_scalar( 'addr', @_ ) ); }

sub attach
{
    my $self = shift( @_ );
    my $flags = shift( @_ );
    $flags = $self->flags if( !defined( $flags ) );
    my $addr = $self->addr;
    return( $addr ) if( defined( $addr ) );
    my $id = $self->id;
    return( $self->error( "No shared memory id! Have you opened it first?" ) ) if( !length( $id ) );
    $addr = shmat( $id, undef(), $flags );
    return( $self->error( "Unable to attach to shared memory: $!" ) ) if( !defined( $addr ) );
    $self->addr( $addr );
    return( $addr );
}

sub create { return( shift->_set_get_boolean( 'create', @_ ) ); }

sub destroy { return( shift->_set_get_boolean( 'destroy', @_ ) ); }

sub detach
{
    my $self = shift( @_ );
    my $addr = $self->addr;
    return if( !defined( $addr ) );
    my $rv = shmdt( $addr );
    return( $self->error( "Unable to detach from shared memory: $!" ) ) if( !defined( $rv ) );
    $self->addr( undef() );
    return( $self );
}

sub exclusive { return( shift->_set_get_boolean( 'exclusive', @_ ) ); }

sub exists
{
    my $self = shift( @_ );
    my $opts = {};
    if( ref( $_[0] ) eq 'HASH' )
    {
        $opts = shift( @_ );
    }
    else
    {
        @$opts{ qw( key mode size ) } = @_;
    }
    $opts->{size} = $self->size unless( length( $opts->{size} ) );
    $opts->{size} = int( $opts->{size} );
    my $serial;
    if( length( $opts->{key} ) )
    {
        $serial = $self->_str2key( $opts->{key} );
        # $serial = $opts->{key};
    }
    else
    {
        $serial = $self->serial;
        # $serial = $self->key;
    }
    my $flags = $self->flags({ mode => 0644 });
    # Remove the create bit
    $flags = ( $flags ^ &IPC::SysV::IPC_CREAT );
    my $semid;
    local $@;
    # try-catch
    my $rv = eval
    {
        $semid = semget( $serial, 3, $flags );
        if( defined( $semid ) )
        {
            my $found = semctl( $semid, SEM_MARKER, &IPC::SysV::GETVAL, 0 );
            semctl( $semid, 0, &IPC::SysV::IPC_RMID, 0 );
            return( $found == SHM_EXISTS ? 1 : 0 );
        }
        else
        {
            return(0) if( $! =~ /\bNo[[:blank:]]+such[[:blank:]]+file\b/ );
            return;
        }
    };
    if( $@ )
    {
        semctl( $semid, 0, &IPC::SysV::IPC_RMID, 0 ) if( $semid );
        return(0);
    }
    return( $rv );
}

sub flags
{
    my $self   = shift( @_ );
    my $opts   = {};
    no warnings 'uninitialized';
    $opts = Scalar::Util::reftype( $_[0] ) eq 'HASH'
        ? shift( @_ )
        : !( scalar( @_ ) % 2 )
            ? { @_ }
            : {};
    $opts->{create} = $self->create unless( length( $opts->{create} ) );
    $opts->{exclusive} = $self->exclusive unless( length( $opts->{exclusive} ) );
    $opts->{mode} = $self->mode unless( length( $opts->{mode} ) );
    my $flags  = 0;
    $flags    |= &IPC::SysV::IPC_CREAT if( $opts->{create} );
    $flags    |= &IPC::SysV::IPC_EXCL  if( $opts->{exclusive} );
    $flags    |= ( $opts->{mode} || 0666 );
    return( $flags );
}

# sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }
sub id
{
    my $self = shift( @_ );
    my @callinfo = caller;
    no warnings 'uninitialized';
    if( @_ )
    {
        $self->{id} = shift( @_ );
    }
    return( $self->{id} );
}

sub key
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{key} = shift( @_ );
        $self->{serial} = $self->_str2key( $self->{key} );
    }
    return( $self->{key} );
}

sub lock
{
    my $self = shift( @_ );
    my $type = shift( @_ );
    my $timeout = shift( @_ );
    # $type = LOCK_EX if( !defined( $type ) );
    $type = LOCK_SH if( !defined( $type ) );
    return( $self->unlock ) if( ( $type & LOCK_UN ) );
    return( 1 ) if( $self->locked & $type );
    $timeout = 0 if( !defined( $timeout ) || $timeout !~ /^\d+$/ );
    # If the lock is different, release it first
    $self->unlock if( $self->locked );
    my $semid = $self->semid ||
        return( $self->error( "No semaphore id set yet." ) );
    local $@;
    # try-catch
    my $rv = eval
    {
        local $SIG{ALRM} = sub{ die( "timeout" ); };
        alarm( $timeout );
        my $rc = $self->op( @{$SEMOP_ARGS->{ $type }} );
        alarm(0);
        return( $rc );
    };
    if( $@ )
    {
        return( $self->error( "Unable to set a lock: $@" ) );
    }
    if( $rv )
    {
        $self->locked( $type );
    }
    else
    {
        return( $self->error( "Failed to set a lock on semaphore id \"$semid\": $!" ) );
    }
    return( $self );
}

sub locked { return( shift->_set_get_scalar( 'locked', @_ ) ); }

sub mode { return( shift->_set_get_scalar( 'mode', @_ ) ); }

sub op
{
    my $self = shift( @_ );
    return( $self->error( "Invalid number of argument: '", join( ', ', @_ ), "'." ) ) if( @_ % 3 );
    my $data = pack( "s$N*", @_ );
    my $id = $self->semid;
    return( $self->error( "No semaphore set yet. You must open the shared memory first to set the semaphore." ) ) if( !length( $id ) );
    return( semop( $id, $data ) );
}

sub open
{
    my $self = shift( @_ );
    my $opts = {};
    if( ref( $_[0] ) eq 'HASH' )
    {
        $opts = shift( @_ );
    }
    else
    {
        @$opts{ qw( key mode size ) } = @_;
    }
    $opts->{size} = $self->size unless( length( $opts->{size} ) );
    $opts->{size} = int( $opts->{size} );
    $opts->{mode} //= '';
    $opts->{key} //= '';
    my $serial;
    if( length( $opts->{key} ) )
    {
        $serial = $self->_str2key( $opts->{key} );
        # $serial = $opts->{key};
    }
    else
    {
        $serial = $self->serial;
        # $serial = $self->key;
    }
    my $create = 0;
    if( $opts->{mode} eq 'w' || $opts->{key} =~ s/^>// )
    {
        $create++;
    }
    elsif( $opts->{mode} eq 'r' || $opts->{key} =~ s/^<// )
    {
        $create = 0;
    }
    else
    {
        $create = $self->create;
    }
    my $flags = $self->flags( create => $create );
    my $id = shmget( $serial, $opts->{size}, $flags );
    if( defined( $id ) )
    {
        # Got shared memory
    }
    else
    {
        my $newflags = ( $flags & &IPC::SysV::IPC_CREAT ) ? $flags : ( $flags | &IPC::SysV::IPC_CREAT );
        my $limit = ( $serial + 10 );
        # IPC::SysV::ftok has likely made the serial unique, but as stated in the manual page, there is no guarantee
        while( $serial <= $limit )
        {
            $id = shmget( $serial, $opts->{size}, $newflags | &IPC::SysV::IPC_CREAT );
            $serial++;
            last if( defined( $id ) );
        }
    }
    
    if( !defined( $id ) )
    {
        return( $self->error( "Unable to create shared memory id with key \"$serial\" and flags \"$flags\": $!" ) );
    }
    $self->serial( $serial );
    
    # The value 3 can be anything above 0 and below the limit set by SEMMSL. On Linux system, this is usually 32,000. Seem semget(2) man page
    my $semid = semget( $serial, 3, $flags );
    if( !defined( $semid ) )
    {
        my $newflags = ( $flags | &IPC::SysV::IPC_CREAT );
        $semid = semget( $serial, 3, $newflags );
        return( $self->error( "Unable to get a semaphore for shared memory key \"", ( $opts->{key} || $self->key ), "\" wth id \"$id\": $!" ) ) if( !defined( $semid ) );
    }
    my $new = $self->new(
        key     => $opts->{key} || $self->key,
        debug   => $self->debug,
        mode    => $self->mode,
        destroy => $self->destroy,
    ) || return;
    $new->id( $id );
    $new->semid( $semid );
    if( !defined( $new->op( @{$SEMOP_ARGS->{LOCK_SH}} ) ) )
    {
        return( $self->error( "Unable to set lock on sempahore: $!" ) );
    }
    
    my $there = $new->stat( SEM_MARKER );
    $new->size( $opts->{size} );
    $new->flags( $flags );
    if( $there == SHM_EXISTS )
    {
    }
    else
    {
        # We initialise the semaphore with value of 1
        $new->stat( SEM_MARKER, SHM_EXISTS ) ||
            return( $self->error( "Unable to set semaphore during object creation: $!" ) );
        $SHEM_REPO->{ $id } = $new;
    }
    $new->op( @{$SEMOP_ARGS->{(LOCK_SH | LOCK_UN)}} );
    return( $new );
}

sub owner { return( shift->_set_get_scalar( 'owner', @_ ) ); }

sub pid
{
    my $self = shift( @_ );
    my $sem  = shift( @_ );
    my $semid = $self->semid ||
        return( $self->error( "No semaphore set yet. You must open the shared memory first to remove semaphore." ) );
    my $v = semctl( $semid, $sem, &IPC::SysV::GETPID, 0 );
    return( $v ? 0 + $v : undef() );
}

sub rand
{
    my $self = shift( @_ );
    my $size = $self->size || 1024;
    my $key  = shmget( &IPC::SysV::IPC_PRIVATE, $size, &IPC::SysV::S_IRWXU|&IPC::SysV::S_IRWXG|&IPC::SysV::S_IRWXO ) ||
        return( $self->error( "Unable to generate a share memory key: $!" ) );
    return( $key );
}

# $self->read( $buffer, $size );
sub read
{
    my $self   = shift( @_ );
    my $id     = $self->id;
    # Optional length parameter for non-reference data only
    my $size   = int( $_[1] || $self->size || SHM_BUFSIZ );
    return( $self->error( "No shared memory id! Have you opened it first?" ) ) if( !length( $id ) );
    my $buffer = '';
    my $addr = $self->addr;
    if( $addr )
    {
        memread( $addr, $buffer, 0, $size ) ||
            return( $self->error( "Unable to read data from shared memory address \"$addr\" using memread: $!" ) );
    }
    else
    {
        shmread( $id, $buffer, 0, $size ) ||
            return( $self->error( "Unable to read data from shared memory id \"$id\": $!" ) );
    }
    # Get rid of nulls end padded
    $buffer = unpack( "A*", $buffer );
    my $first_char = substr( $buffer, 0, 1 );
    my $j = JSON->new->utf8->relaxed->allow_nonref;
    my $data;
    local $@;
    # try-catch
    eval
    {
        # Does the value have any typical json format? " for a string, { for an hash and [ for an array
        if( $first_char eq '"' || $first_char eq '{' || $first_char eq '[' )
        {
            $data = $j->decode( $buffer );
        }
        else
        {
            $data = $buffer;
        }
    };
    if( $@ )
    {
        $self->error( "An error occured while json decoding data: $@", ( length( $buffer ) <= 1024 ? "\nData is: '$buffer'" : '' ) );
        # Maybe it's a string that starts with '{' or " or [ and triggered an error because it was not actually json data?
        # So we return the data stored as it is
        if( @_ )
        {
            $_[0] = $buffer;
            return( length( $buffer ) || "0E0" );
        }
        else
        {
            return( $buffer );
        }
    }
    
    if( @_ )
    {
        my $len = length( $_[0] );
        # If the decoded data is not a reference of any sort, and the length parameter was provided
        if( !ref( $data ) )
        {
            $_[0] = $size > 0 ? substr( $data, 0, $size ) : $data;
            return( length( $_[0] ) || "0E0" );
        }
        else
        {
            $_[0] = $data;
            return( $len || "0E0" );
        }
    }
    else
    {
        return( $data );
    }
}

sub remove
{
    my $self = shift( @_ );
    return( 1 ) if( $self->removed );
    my $id   = $self->id();
    return( $self->error( "No shared memory id! Have you opened it first?" ) ) if( !length( $id ) );
    my $semid = $self->semid;
    return( $self->error( "No semaphore set yet. You must open the shared memory first to remove semaphore." ) ) if( !length( $semid ) );
    $self->unlock();
    # Remove share memory segment
    if( !defined( shmctl( $id, &IPC::SysV::IPC_RMID, 0 ) ) )
    {
        return( $self->error( "Unable to remove share memory segement id '$id' (IPC_RMID is '", &IPC::SysV::IPC_RMID, "'): $!" ) );
    }
    # Remove semaphore
    my $rv;
    if( !defined( $rv = semctl( $semid, 0, &IPC::SysV::IPC_RMID, 0 ) ) )
    {
        $self->error( "Warning only: could not remove the semaphore id \"$semid\": $!" );
    }
    $self->removed( $rv ? 1 : 0 );
    if( $rv )
    {
        delete( $SHEM_REPO->{ $id } );
        $self->id( undef() );
        $self->semid( undef() );
    }
    return( $rv ? 1 : 0 );
}

sub removed { return( shift->_set_get_boolean( 'removed', @_ ) ); }

sub semid { return( shift->_set_get_scalar( 'semid', @_ ) ); }

sub serial { return( shift->_set_get_scalar( 'serial', @_ ) ); }

sub size { return( shift->_set_get_scalar( 'size', @_ ) ); }

sub stat
{
    my $self = shift( @_ );
    my $id   = $self->semid;
    return( $self->error( "No semaphore set yet. You must open the shared memory first to set the semaphore." ) ) if( !length( $id ) );
    if( @_ )
    {
        if( @_ == 1 )
        {
            my $sem = shift( @_ );
            my $v = semctl( $id, $sem, &IPC::SysV::GETVAL, 0 );
            return( $v ? 0 + $v : undef() );
        }
        else
        {
            my( $sem, $val ) = @_;
            return( semctl( $id, $sem, &IPC::SysV::SETVAL, $val ) );
        }
    }
    else
    {
        my $data = '';
        if( wantarray() )
        {
            semctl( $id, 0, &IPC::SysV::GETALL, $data ) || return( () );
            return( ( unpack( "s*", $data ) ) );
        }
        else
        {
            semctl( $id, 0, &IPC::SysV::IPC_STAT, $data ) ||
                return( $self->error( "Unable to stat semaphore with id '$id': $!" ) );
            return( Apache2::SSI::SemStat->new->unpack( $data ) );
        }
    }
}

sub supported { return( $SYSV_SUPPORTED ); }

sub unlock
{
    my $self = shift( @_ );
    return( 1 ) if( !$self->locked );
    my $semid = $self->semid;
    return( $self->error( "No semaphore set yet. You must open the shared memory first to unlock semaphore." ) ) if( !length( $semid ) );
    my $type = $self->locked | LOCK_UN;
    $type ^= LOCK_NB if( $type & LOCK_NB );
    if( defined( $self->op( @{$SEMOP_ARGS->{ $type }} ) ) )
    {
        $self->locked( 0 );
    }
    return( $self );
}

sub write
{
    my $self = shift( @_ );
    my $data = ( @_ == 1 ) ? shift( @_ ) : join( '', @_ );
    my $id   = $self->id();
    my $size = int( $self->size() ) || SHM_BUFSIZ;
    my @callinfo = caller;
    my $j = JSON->new->utf8->relaxed->allow_nonref->convert_blessed;
    my $encoded;
    local $@;
    # try-catch
    eval
    {
        $encoded = $j->encode( $data );
    };
    if( $@ )
    {
        return( $self->error( "An error occured json encoding data provided: $@" ) );
    }
    
    if( length( $encoded ) > $size )
    {
        return( $self->error( "Data to write are ", length( $encoded ), " bytes long and exceed the maximum you have set of '$size'." ) );
    }
    # $size = length( $encoded );
    my $addr = $self->addr;
    if( $addr )
    {
        memwrite( $addr, $encoded, 0, $size ) ||
            return( $self->error( "Unable to write to shared memory address '$addr' using memwrite: $!" ) );
    }
    else
    {
        shmwrite( $id, $encoded, 0, $size ) ||
            return( $self->error( "Unable to write to shared memory id '$id': $!" ) );
    }
    return( $self );
}

sub _str2key
{
    my $self = shift( @_ );
    my $key  = shift( @_ );
    if( !defined( $key ) || $key eq '' )
    {
        return( &IPC::SysV::IPC_PRIVATE );
    }
    elsif( $key =~ /^\d+$/ )
    {
        return( IPC::SysV::ftok( __FILE__, $key ) );
    }
    else
    {
        my $id = 0;
        $id += $_ for( unpack( "C*", $key ) );
        # We use the root as a reliable and stable path.
        # I initially though about using __FILE__, but during testing this would be in ./blib/lib and beside one user might use a version of this module somewhere while the one used under Apache/mod_perl2 could be somewhere else and this would render the generation of the IPC key unreliable and unrepeatable
        my $val = IPC::SysV::ftok( '/', $id );
        return( $val );
    }
}

END
{
    foreach my $id ( keys( %$SHEM_REPO ) )
    {
        my $s = $SHEM_REPO->{ $id };
        $s->unlock;
        next unless( $s->destroy );
        next unless( $s->owner == $$ );
        $s->remove;
    }
};

# DESTROY
# {
#     my $self = shift( @_ );
#     my @callinfo = caller;
#     ## $self->message( 3, "Got here from package $callinfo[0] in file $callinfo[1] at line $callinfo[2], destroying object for shared memory id \"", $self->id, "\" key \"", $self->key, "\" with destroy flags '", $self->destroy, "'." );
#     ## $self->message( 3, "Object contains following keys: ", sub{ $self->dump( $self ) } );
#     $self->unlock;
#     $self->remove if( $self->destroy );
# };


{
    package
        Apache2::SSI::SemStat;
    our $VERSION = 'v0.1.0';
    
    use constant UID => 0;
    use constant GID => 1;
    use constant CUID => 2;
    use constant CGID => 3;
    use constant MODE => 4;
    use constant CTIME => 5;
    use constant OTIME => 6;
    use constant NSEMS => 7;
    
    sub new
    {
        my $this = shift( @_ );
        my @vals = @_;
        return( bless( [ @vals ] => ref( $this ) || $this ) );
    }
    
    sub cgid { return( shift->[CGID] ); }
    
    sub ctime { return( shift->[CTIME] ); }
    
    sub cuid { return( shift->[CUID] ); }

    sub gid { return( shift->[GID] ); }
    
    sub mode { return( shift->[MODE] ); }

    sub nsems { return( shift->[NSEMS] ); }
    
    sub otime { return( shift->[OTIME] ); }

    sub uid { return( shift->[UID] ); }
}

1;
