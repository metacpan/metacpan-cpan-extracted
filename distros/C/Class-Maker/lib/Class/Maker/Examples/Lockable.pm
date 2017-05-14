
# (c) 2009 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
package Lockable;

our $VERSION = '0.03';

require 5.005_62; use strict; use warnings;

Class::Maker::class
{
	public =>
	{
		bool => [ qw( locked blocked ) ],

		int => [qw( limited passed failed )],

		string => [ qw( passkey unlockkey ) ],
	},
};

sub _preinit
{
	my $this = shift;

		$this->unlockkey(1);

		$this->locked(1);

		$this->blocked(0);

		$this->passed(0);

		$this->limited(5);
}

sub lock
{
	my $this = shift;

		warn 'Closing lock' if $Class::Maker::DEBUG;

return $this->locked(1);
}

sub block
{
	my $this = shift;

		warn 'Blocking lock!' if $Class::Maker::DEBUG;

return $this->blocked(1);
}

sub unlock
{
	my $this = shift;

		warn 'Opening lock' if $Class::Maker::DEBUG;

		if( $this->blocked )
		{
			warn 'Cant unlock, because blocked !' if $Class::Maker::DEBUG;

			return $this->locked(1);
		}

return $this->locked(0);
}

sub unblock
{
	my $this = shift;

		warn 'Unblocking lock' if $Class::Maker::DEBUG;

return $this->blocked(0);
}

sub try
{
	my $this = shift;

	my %args = @_;

		warn 'Try lock' if $Class::Maker::DEBUG;

		if( $this->blocked )
		{
			warn 'Try failed - Lock is blocked !' if $Class::Maker::DEBUG;

			return $this->locked;
		}

		if( $this->unlockkey )
		{
			warn 'Require Key' if $Class::Maker::DEBUG;

			if( exists $args{KEY} )
			{
				if( $this->passkey eq $args{KEY} )
				{
					warn sprintf "Opening with key '%s'", $args{KEY} if $Class::Maker::DEBUG;

					$this->unlock;
				}
			}
			else
			{
				warn 'Key required through ->unlockkey param, but try( KEY => ) is missing';
			}
		}

		if( $this->locked )
		{
			$this->failed( $this->failed + 1 );

			if( $this->failed > $this->limited )
			{
				$this->block();
			}
		}
		else
		{
			$this->failed( 0 );

			$this->passed( $this->passed + 1 );
		}

return $this->locked;
}

sub assert
{
	my $this = shift;

		if( $this->locked )
		{
			print "Wrong Key\n";
		}
		else
		{
			print "Lock passed !\n";
		}
}

1;
__END__

=head1 NAME

Lockable - classes for locking mechanims

=head1 SYNOPSIS

  use Object::Lockable;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Object::Lockable, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXAMPLE

my $lock = new Object::Lockable( showpackage => 1, debug => 1, limited => 5 ) or die "unable to instantiate object";

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

=head2 EXPORT

None by default.

=head1 AUTHOR

muenalan@cpan.org

=head1 SEE ALSO

perl(1).

=cut
