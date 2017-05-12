use 5.012;
use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

use App::CPAN2Pkg::Lock;

my $lock = App::CPAN2Pkg::Lock->new;

# initial state
isa_ok( $lock, "App::CPAN2Pkg::Lock", "constructor works" );
ok( $lock->is_available, "lock is available first" );
is( $lock->owner, undef, "no initial lock owner" );

# getting lock
dies_ok { $lock->get() } "need to provide a new owner";
$lock->get( "foo" );
ok( ! $lock->is_available, "lock no more available" );
is( $lock->owner, "foo", "owner correctly recored" );

# getting lock twice
dies_ok { $lock->get("bar") } "cannot get lock twice";
is( $lock->owner, "foo", "owner not updated when lock fails" );

# releasing lock
$lock->release; 
ok( $lock->is_available, "lock now available" );
is( $lock->owner, undef, "no more owner after release" );

