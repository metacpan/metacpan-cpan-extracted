package Data::STUID::Generator;
use strict;
use Config ();
BEGIN {
    if (! $Config::Config{use64bitint}) {
        die __PACKAGE__ . ' required 64bit int';
    }
}
use Class::Accessor::Lite
    new => 1,
    rw => [qw(parent sem_name shm_name shared_mem mutex host_id)]
;
use IPC::SysV qw(S_IRWXU S_IRUSR S_IWUSR IPC_CREAT IPC_NOWAIT SEM_UNDO);
use IPC::SharedMem;
use IPC::Semaphore;
use Scalar::Util ();
use Time::HiRes ();

use constant TOTAL_BITS    => 64;
use constant EPOCH_OFFSET  => 946684800;
use constant HOST_ID_BITS  => 16;
use constant TIME_BITS     => 36;
use constant SERIAL_BITS   => (TOTAL_BITS - HOST_ID_BITS - TIME_BITS);
use constant TIME_SHIFT    => HOST_ID_BITS + SERIAL_BITS;
use constant SERIAL_SHIFT  => HOST_ID_BITS;

# XXX WHAT ON EARTH ARE YOU DOING HERE?
#
# We normally protect ourselves from leaking resources in DESTROY, but...
# when we are enveloped in a PSGI app, a reference to us stays alive until
# global destruction.
#
# At global destruction time, the order in which objects get cleaned
# up is undefined, so it often happens that the mutex/shared memory gets
# freed before the dispatcher object -- so when DESTROY gets called,
# $self->{mutex} and $self->{shared_mem} are gone already, and we can't
# call remove().
#
# To avoid this, we keep a guard object that makes sure that the resources
# are cleaned up at END {} time
my @RESOURCE_GUARDS;
END {
    undef @RESOURCE_GUARDS;
}

sub _guard (&) { bless [ $_[0] ], 'Data::STUID::Generator::guard' }
sub Data::STUID::Generator::guard::DESTROY {
    if (my $cb = $_[0]->[0]) {
        $cb->();
    }
}

sub prepare {
    my $self = shift;

    if (! $self->sem_name) {
        $self->sem_name(File::Temp->new(
            TEMPALTE => "stuid-sem-XXXXX",
            UNLINK => 1,
            TEMPDIR => 1,
        ));
    }
    if (! $self->shm_name) {
        $self->shm_name(File::Temp->new(
            TEMPLATE => "stuid-shm-XXXXX",
            UNLINK => 1,
            TEMPDIR => 1,
        ));
    }

    my $semkey = IPC::SysV::ftok( $self->sem_name->filename );
    my $mutex  = IPC::Semaphore->new( $semkey, 1, S_IRUSR | S_IWUSR | IPC_CREAT );
    my $shmkey = IPC::SysV::ftok( $self->shm_name->filename );
    my $shm    = IPC::SharedMem->new( $shmkey, 24, S_IRWXU | IPC_CREAT );
    if (! $shm) {
        die "PANIC: Could not open shared memory: $!";
    }
    $mutex->setall(1);
    $shm->write( pack( "ql", 0, 0 ), 0, 24 );

    $self->parent($$);
    $self->mutex( $mutex );
    $self->shared_mem( $shm );

    push @RESOURCE_GUARDS, (sub {
        my $SELF = shift;
        Scalar::Util::weaken($SELF);
        _guard {
            eval { $SELF->cleanup };
        };
    })->($self);

    $self->{prepared}++;
}

sub cleanup {
    my $self = shift;
    if ( ! defined $self->parent || $self->parent != $$ ) {
        if (Data::STUID::DEBUG) {
            printf STDERR "Parent pid (%d) does not much current pid (%d). Skipping cleanup\n", $self->parent, $$;
        }
        return;
    }

    {
        local $@;
        if ( my $mutex = $self->{mutex} ) {
            eval {
                if (Data::STUID::DEBUG) {
                    printf STDERR "Cleaning up semaphore (%s)\n", $mutex->id;
                }
                $mutex->remove;
            };
        }
        if ( my $shm = $self->{shared_mem} ) {
            eval {
                if (Data::STUID::DEBUG) {
                    printf STDERR "Cleaning up shared memory (%s)\n", $shm->id;
                }
                $shm->remove;
            };
        }
    }
}

sub create_id {
    my ($self)  = @_;

    $self->prepare() unless $self->{prepared};

    my $mutex = $self->mutex;
    my $shm   = $self->shared_mem;

    my ($rc, $errno);
    my $acquire = 0;
    do {
        $acquire++;
        $rc = $mutex->op( 0, -1, SEM_UNDO | IPC_NOWAIT );
        $errno = $!;
        if ( $rc <= 0 ) {
            Time::HiRes::usleep( int( rand(5_000) ) );
        }
    } while ( $rc <= 0 && $acquire < 100);

    if ( $rc <= 0 ) {
        croakff(
            "[Dispatcher] SEMAPHORE: Process %s failed to acquire mutex (tried %d times, \$! = %d, rc = %d, val = %d, zcnt = %d, ncnt = %d, id = %d)",
            $$,
            $acquire,
            $errno,
            $rc,
            $mutex->getval(0),
            $mutex->getzcnt(0),
            $mutex->getncnt(0),
            $mutex->id
        );
    }

    my $guard = _guard {
        $mutex->op( 0, 1, SEM_UNDO );
    };

    my $host_id = (int($self->host_id + $$)) & 0xffff; # 16 bits
    my $time_id = time();

    my ($shm_time, $shm_serial) = unpack( "ql", $shm->read(0, 24) );
    if ( $shm_time == $time_id ) {
        $shm_serial++;
    } else {
        $shm_serial = 1;
    }

    if ( $shm_serial >= (1 << SERIAL_BITS) - 1) {
        # Overflow :/ we received more than SERIAL_BITS
        die "serial bits overflowed";
    }
    $shm->write( pack( "ql", $time_id, $shm_serial ), 0, 24 );

    my $id;
    my $time_bits = ($time_id - EPOCH_OFFSET) << TIME_SHIFT;
    my $serial_bits = $shm_serial << SERIAL_SHIFT;
    $id = $time_bits | $serial_bits | $host_id;

    return $id;
}

1;