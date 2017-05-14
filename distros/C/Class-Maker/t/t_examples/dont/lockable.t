BEGIN
{
	$| = 1; print "1..1\n";
}

my $loaded;

use strict;

use warnings;

use Carp;

END { print "not ok 1\n" unless $loaded; }

use Object::Lockable;

print "ok 1\n";

	eval
	{
		my $lock = new Object::Lockable( limited => 5 ) or die "unable to instantiate object";

		$lock->unlock();

		print "Can't pass lock\n" if $lock->try;

		$lock->lock();

		print "Can't pass lock\n" if $lock->try;

		my $key = '1234';

		$lock->passkey( $key );

		$lock->assert( $lock->try( KEY => $key ) );

		$lock->lock();

		for( 1..10 )
		{
			printf "%d. try\n",$_;

			$lock->assert( $lock->try( KEY => '5678' ) );
		}

		$lock->assert( $lock->try( KEY => $key ) );

		$lock->unblock();

		$lock->assert( $lock->try( KEY => $key ) );

		$lock->debugDump();
	};
	if($@)
	{
    	warn "Exception: $@\n";

    	print "\nnot ";
	}

printf "ok %d\n", ++$loaded;
