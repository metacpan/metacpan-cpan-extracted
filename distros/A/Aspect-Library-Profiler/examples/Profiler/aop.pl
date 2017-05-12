#!perl

use strict;
use warnings;
use Aspect;

aspect Profiler =>
	call qr/^SlowObject::/ &
	cflow run => 'SlowObject::run';

my $slow_object = SlowObject->new;

print "This example will complete in 4 seconds...\n";

# these calls will be profiled
$slow_object->run;

# but this will not, because it is not in the call flow of SlowObject::run
$slow_object->slow;

# -----------------------------------------------------------------------------

package SlowObject;

sub new { bless {}, shift }

sub run {
	my $self = shift;
	$self->fast;
	$self->$_ for qw(fast slow very_slow);
	print "Done with SlowObject::run\n\n";
}

sub fast {}
sub slow { sleep 1 }
sub very_slow { sleep 2 }
