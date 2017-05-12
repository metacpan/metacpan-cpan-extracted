package BerkeleyDB::Locks;

use 5.006;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use BerkeleyDB::Locks ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.04';

bootstrap BerkeleyDB::Locks $VERSION;

# Preloaded methods go here.

{
	package BerkeleyDB::Env ;

	sub lockmonitor {
		my $dbenv = shift ;
		return BerkeleyDB::Locks->new( $dbenv ) ;
		}
	}

sub dbenv {
	return 0 ;
	}

sub waiters {
	return 1 ;
	}

sub new {
	my $class = shift ;
	my $dbenv = shift ;
	return bless [ $dbenv->[0] ], $class ;
	}

sub poll {
	my $self = shift ;
	my @w = map { $_->[2] } @{ _waiters( $self->[ &dbenv ] ) } ;
	return map { $_ => $self->properties( $_ ) } @w ;
	}

sub monitor {
	my $self = shift ;
	my @w = map { pack "L*", @$_ } @{ _waiters( $self->[ &dbenv ] ) } ;

	$self->[ &waiters ] ||= {} ;
	my %rv = map { $_ => 1 } map { $_->[2] }
			map { [ unpack "L*", $_ ] }
			grep $self->[ &waiters ]->{$_}, @w ;

	my @rv = map { $_ => $self->properties( $_ ) } keys %rv ;
	$self->release( keys %rv ) ;
	$self->[ &waiters ] = { map { $_ => 1 } @w } ;

	return @rv ;
	}

sub properties {
	my $self = shift ;
	my $lockID = shift ;

	return warn '$lockID undefined' unless $lockID ;
	return _properties( $self->[ &dbenv ], $lockID ) ;
	}

sub release {
	my $self = shift ;
	return map { _release( $self->[ &dbenv ], $_ ) } @_ ;
	}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

BerkeleyDB::Locks - Perl extension for Berkeley DB 4.1



=head1 SYNOPSIS

  use BerkeleyDB ;
  use BerkeleyDB::Locks;

  $env = new BerkeleyDB::Env ... ;
  $watch = $env->lockmonitor ;

  while (1) {
	my @released = $watch->monitor ;
	warn "released: " join ' ', @released ;
	sleep (10) ;
	}
  

=head1 DESCRIPTION

To demystify the Berkeley locking subsystem, realize that "a lock" in 
Berkeley-ese refers to a verb, not a noun.  A lock is an event that links 
the locker (a process identifier) and a lock-object which represents a 
database page or record.  

A complete list of lock states follows.  An active lock is generally either 
WAITING or HELD.  A FREE lock is not assigned to either a locker or lock 
object.  The other states represent error conditions or are transient.

	ABORTED
	ERROR
	EXPIRED
	FREE
	HELD
	NOTEXIST
	PENDING
	WAITING


In normal operation, a locker operates on a database object without 
interference.  The locker applies a B<hold> lock to the object, performs
its operation, and then frees the lock.

Heavy or critical operations on an object are coordinated using the 
locking subsystem.  If an object is unavailable, the locker's request is 
queued with a B<wait> lock.   Each waiting lock request is served in turn, 
and subsequently upgraded to a B<hold> lock.  When the locker operation is 
complete, the lock is freed.

A lock-up occurs when a B<hold> lock is never released and the queued locks
wait indefinitely for their turn.

The B<monitor()> function traverses the table of lockers, locates all of the 
active locks associated with each locker, and maintains a complete list of 
waiting conditions.

A wait condition is defined by a waiting lock and a holding lock attached 
to the same lock object.  These transient Lock events are defined by two 
properties:  The lock offset defines the structure location;  and the gen 
value which is incremented for each event.

A wait condition that persists between consecutive calls to B<monitor()>
is an indication of a lock-up.  B<monitor()> releases the holding locks on
the object under contention.  B<monitor()> returns the identities of these
holding locks and their properties (before release) as name value pairs.

The holding locks are identified by their offset location.  Their properties
are hashes containing the following values:

	mode:	Creation mode
	status:	Current status of lock (listed above)
	gen:	Increments for each lock activation 
	locker:	Integer ID of the locker
	obj:	Offset ID of the object
	
The B<poll()> function also identifies the objects under waiting locks.  
This function returns the object holders and holder properties similar to 
the B<monitor()> function.  B<poll()> does not release the held locks.  
Also, B<poll()> reports the holders for all wait conditions.  B<monitor()> 
only reports holders of persistent wait conditions.


=head1 CAVEATS

This lock monitoring tool does not guarantee "fitness of use".  This API is
the result of fiddling under the Berkeley hood.  These capabilities have not
been made public by the Berkeley developers.  

The Berkeley locking subsystem is perfectly stable.  Every locking fault 
I've encountered was caused by an implementation bug.  Nevertheless, I 
believe this module can be a very helpful debugging tool-  the reporting
features are intended to be used.  One indispensible enhancement is a 
function that allows a process to look up its own assigned locker IDs.  
Thus, a process can determine when it has caused a lock-up and abort its 
operation before releasing its locks.

I cannot give any details about the consequences of prematurely releasing
a lock.  My lock-ups are generally caused because a thread dies before 
releasing its held locks.  But since the purpose of locking is to ensure
data integrity, assume that careless use of this lock monitor may result 
in data corruption.  For that reason, this module is best suited in 
production environments where continuous operation has greater priority 
than data integrity; for example, where the Berkeley system operates on a
data copy.  Otherwise, use of this lock monitor should be restricted to 
the bench.

This application has only been tested on Berkeley DB 4.1.  The lock 
architecture changed significantly between Berkeley DB 3 and Berkeley DB 4.
Support for Berkeley DB 3 can be considered an enhancement.

=head2 EXPORT

None by default.


=head1 AUTHOR

Jim Schueler, E<lt>jschueler@tqis.com<gt>

=head1 SEE ALSO

L<perl>.

=cut
