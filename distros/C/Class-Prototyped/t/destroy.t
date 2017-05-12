use strict;
$^W++;
use Class::Prototyped qw(:EZACCESS);
use Data::Dumper;
use Test;

BEGIN {
	$|++;
	plan tests => 12
}

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1;

my $record = '';

package MyClass;
@MyClass::ISA = qw(Class::Prototyped);

sub DESTROY {
	$record .= "You are in MyClass::DESTROY for " . ref($_[0]) . "\n";
}

package MyClass_Alt;
@MyClass_Alt::ISA = qw(Class::Prototyped);

sub DESTROY {
	$record .= "You are in MyClass_Alt::DESTROY for " . ref($_[0]) . "\n";
}

package main;

my $name1;
my $name2;
my $name3;


# This demonstrates normal destruction.
{
	my $foo = MyClass->new(
		'destroy!' => sub {
				$record .= "You are in the objects destroy.\n";
				$_[0]->super('destroy');
				$record .= "Just called super-destroy.\n";
			},
		);
	$name1 = ref($foo);
}
ok( $record, <<END);
You are in the objects destroy.
Just called super-destroy.
You are in MyClass::DESTROY for $name1
END

use Data::Dumper;

# This demonstrates destruction where $p2 has a reference in it to $p1.  Note
# that the destructor for $p1 runs as soon as the C::P::destory destructor
# runs on $p2, thus interrupting the $p2 destruction sequence
$record = '';
{
	my $p2 = MyClass->new(
		'destroy!' => sub {
				$record .= "p2 before super for " . ref($_[0]) . "\n";
				$_[0]->super('destroy');
				$record .= "p2 after super for " . ref($_[0]) . "\n";
			},
		);
	$name2 = ref($p2);

	{
		my $p1 = MyClass->new(
			'destroy!' => sub {
					$record .= "p1 before super for " . ref($_[0]) . "\n";
					$_[0]->super('destroy');
					$record .= "p1 after super for " . ref($_[0]) . "\n";
				},
			);
		$name1 = ref($p1);

		$p2->addSlot('p1' => $p1);
	}
}
ok( $record, <<END);
p2 before super for $name2
p1 before super for $name1
p1 after super for $name1
You are in MyClass::DESTROY for $name1
p2 after super for $name2
You are in MyClass::DESTROY for $name2
END


# This demonstrates destruction where $p2 has a parent slot that points to
# $p1.  In this situation, the $p2 destruction sequence is not interrupted
# because the reference to $p1 is not removed until the $p2 destruction
# sequence has completed.
$record = '';
{
	my $p2 = MyClass->new(
		'destroy!' => sub {
				$record .= "p2 before super for " . ref($_[0]) . "\n";
				$_[0]->super('destroy');
				$record .= "p2 after super for " . ref($_[0]) . "\n";
			},
		);
	$name2 = ref($p2);

	{
		my $p1 = MyClass->new(
			'destroy!' => sub {
					$record .= "p1 before super for " . ref($_[0]) . "\n";
					$_[0]->super('destroy');
					$record .= "p1 after super for " . ref($_[0]) . "\n";
				},
			);
		$name1 = ref($p1);

		$p2->addSlot('parent*' => $p1);
	}
}
ok( $record, <<END);
p2 before super for $name2
p2 after super for $name2
You are in MyClass::DESTROY for $name2
p1 before super for $name1
p1 after super for $name1
You are in MyClass::DESTROY for $name1
END


# In this test, $p3 and $p2 reference $p1.  The destructor for $p2 completes
# removing one of the references to $p1.  Then the destructor for $p3 runs,
# at which point the last reference to $p1 is removed and so the destructor
# for $p1 interrupts the $p3 destruction sequence.
$record = '';
{
	my $p3 = MyClass->new(
		'destroy!' => sub {
				$record .= "p3 before super for " . ref($_[0]) . "\n";
				$_[0]->super('destroy');
				$record .= "p3 after super for " . ref($_[0]) . "\n";
			},
		);
	$name3 = ref($p3);

	{
		my $p2 = MyClass->new(
			'destroy!' => sub {
					$record .= "p2 before super for " . ref($_[0]) . "\n";
					$_[0]->super('destroy');
					$record .= "p2 after super for " . ref($_[0]) . "\n";
				},
			);
		$name2 = ref($p2);

		{
			my $p1 = MyClass->new(
				'destroy!' => sub {
						$record .= "p1 before super for " . ref($_[0]) . "\n";
						$_[0]->super('destroy');
						$record .= "p1 after super for " . ref($_[0]) . "\n";
					},
				);
			$name1 = ref($p1);

			$p2->addSlot('p1' => $p1);
			$p3->addSlot('p1' => $p1);
		}
	}
}
ok( $record, <<END);
p2 before super for $name2
p2 after super for $name2
You are in MyClass::DESTROY for $name2
p3 before super for $name3
p1 before super for $name1
p1 after super for $name1
You are in MyClass::DESTROY for $name1
p3 after super for $name3
You are in MyClass::DESTROY for $name3
END


# Same test, but using parent slots instead.  Note that as a result, the
# destruction sequence for $p3 completes before the destructor for $p1
# is triggered
$record = '';
{
	my $p3 = MyClass->new(
		'destroy!' => sub {
				$record .= "p3 before super for " . ref($_[0]) . "\n";
				$_[0]->super('destroy');
				$record .= "p3 after super for " . ref($_[0]) . "\n";
			},
		);
	$name3 = ref($p3);

	{
		my $p2 = MyClass->new(
			'destroy!' => sub {
					$record .= "p2 before super for " . ref($_[0]) . "\n";
					$_[0]->super('destroy');
					$record .= "p2 after super for " . ref($_[0]) . "\n";
				},
			);
		$name2 = ref($p2);

		{
			my $p1 = MyClass->new(
				'destroy!' => sub {
						$record .= "p1 before super for " . ref($_[0]) . "\n";
						$_[0]->super('destroy');
						$record .= "p1 after super for " . ref($_[0]) . "\n";
					},
				);
			$name1 = ref($p1);

			$p2->addSlot('parent*' => $p1);
			$p3->addSlot('parent*' => $p1);
		}
	}
}
ok( $record, <<END);
p2 before super for $name2
p2 after super for $name2
You are in MyClass::DESTROY for $name2
p3 before super for $name3
p3 after super for $name3
You are in MyClass::DESTROY for $name3
p1 before super for $name1
p1 after super for $name1
You are in MyClass::DESTROY for $name1
END


# Here we use qw([parent* promote]) instead of parent* to move the parent slot
# up in precedence over class*.  In the previous tests, the destroy method
# wasn't inherited from $p1 because the destroy method in C::P by way of
# MyClass took precedence.
$record = '';
{
	my $p2 = MyClass->new(
		'destroy!' => sub {
				$record .= "p2 before super for " . ref($_[0]) . "\n";
				$_[0]->super('destroy');
				$record .= "p2 after super for " . ref($_[0]) . "\n";
			},
		);
	$name2 = ref($p2);

	{
		my $p1 = MyClass->new(
			'destroy!' => sub {
					$record .= "p1 before super for " . ref($_[0]) . "\n";
					$_[0]->super('destroy');
					$record .= "p1 after super for " . ref($_[0]) . "\n";
				},
			);
		$name1 = ref($p1);

		$p2->addSlot([qw(parent* promote)] => $p1);
	}
}
ok( $record, <<END);
p2 before super for $name2
p1 before super for $name2
p1 after super for $name2
p2 after super for $name2
You are in MyClass::DESTROY for $name2
p1 before super for $name1
p1 after super for $name1
You are in MyClass::DESTROY for $name1
END


# Note that we get the same behavior (including access to MyClass::DESTROY
# via the $p1 inheritance path) when we have a classless object.
$record = '';
{
	my $p2 = Class::Prototyped->new(
		'destroy!' => sub {
				$record .= "p2 before super for " . ref($_[0]) . "\n";
				$_[0]->super('destroy');
				$record .= "p2 after super for " . ref($_[0]) . "\n";
			},
		);
	$name2 = ref($p2);

	{
		my $p1 = MyClass->new(
			'destroy!' => sub {
					$record .= "p1 before super for " . ref($_[0]) . "\n";
					$_[0]->super('destroy');
					$record .= "p1 after super for " . ref($_[0]) . "\n";
				},
			);
		$name1 = ref($p1);

		$p2->addSlot('parent*' => $p1);
	}
}
ok( $record, <<END);
p2 before super for $name2
p1 before super for $name2
p1 after super for $name2
p2 after super for $name2
You are in MyClass::DESTROY for $name2
p1 before super for $name1
p1 after super for $name1
You are in MyClass::DESTROY for $name1
END


# Demonstration of two objects referencing the same chained destructor
$record = '';
{
	my $p3 = MyClass->new(
		'destroy!' => sub {
				$record .= "p3 before super for " . ref($_[0]) . "\n";
				$_[0]->super('destroy');
				$record .= "p3 after super for " . ref($_[0]) . "\n";
			},
		);
	$name3 = ref($p3);

	{
		my $p2 = MyClass->new(
			'destroy!' => sub {
					$record .= "p2 before super for " . ref($_[0]) . "\n";
					$_[0]->super('destroy');
					$record .= "p2 after super for " . ref($_[0]) . "\n";
				},
			);
		$name2 = ref($p2);

		{
			my $p1 = MyClass->new(
				'destroy!' => sub {
						$record .= "p1 before super for " . ref($_[0]) . "\n";
						$_[0]->super('destroy');
						$record .= "p1 after super for " . ref($_[0]) . "\n";
					},
				);
			$name1 = ref($p1);

			$p2->addSlot([qw(parent* promote)] => $p1);
			$p3->addSlot([qw(parent* promote)] => $p1);
		}
	}
}
ok( $record, <<END);
p2 before super for $name2
p1 before super for $name2
p1 after super for $name2
p2 after super for $name2
You are in MyClass::DESTROY for $name2
p3 before super for $name3
p1 before super for $name3
p1 after super for $name3
p3 after super for $name3
You are in MyClass::DESTROY for $name3
p1 before super for $name1
p1 after super for $name1
You are in MyClass::DESTROY for $name1
END


# Demonstration of chained destructors
$record = '';
{
	my $p3 = MyClass->new(
		'destroy!' => sub {
				$record .= "p3 before super for " . ref($_[0]) . "\n";
				$_[0]->super('destroy');
				$record .= "p3 after super for " . ref($_[0]) . "\n";
			},
		);
	$name3 = ref($p3);

	{
		my $p2 = MyClass->new(
			'destroy!' => sub {
					$record .= "p2 before super for " . ref($_[0]) . "\n";
					$_[0]->super('destroy');
					$record .= "p2 after super for " . ref($_[0]) . "\n";
				},
			);
		$name2 = ref($p2);

		$p3->addSlot([qw(parent* promote)] => $p2);

		{
			my $p1 = MyClass->new(
				'destroy!' => sub {
						$record .= "p1 before super for " . ref($_[0]) . "\n";
						$_[0]->super('destroy');
						$record .= "p1 after super for " . ref($_[0]) . "\n";
					},
				);
			$name1 = ref($p1);

			$p2->addSlot([qw(parent* promote)] => $p1);
		}
	}
}
ok( $record, <<END);
p3 before super for $name3
p2 before super for $name3
p1 before super for $name3
p1 after super for $name3
p2 after super for $name3
p3 after super for $name3
You are in MyClass::DESTROY for $name3
p2 before super for $name2
p1 before super for $name2
p1 after super for $name2
p2 after super for $name2
You are in MyClass::DESTROY for $name2
p1 before super for $name1
p1 after super for $name1
You are in MyClass::DESTROY for $name1
END


# Demonstration of the search for DESTROY taking the same path as the search
# for destroy
$record = '';
{
	my $p3 = MyClass->new(
		'destroy!' => sub {
				$record .= "p3 before super for " . ref($_[0]) . "\n";
				$_[0]->super('destroy');
				$record .= "p3 after super for " . ref($_[0]) . "\n";
			},
		);
	$name3 = ref($p3);

	{
		my $p2 = MyClass->new(
			'destroy!' => sub {
					$record .= "p2 before super for " . ref($_[0]) . "\n";
					$_[0]->super('destroy');
					$record .= "p2 after super for " . ref($_[0]) . "\n";
				},
			);
		$name2 = ref($p2);

		$p3->addSlot('parent2**' => $p2);

		{
			my $p1 = MyClass_Alt->new(
				'destroy!' => sub {
						$record .= "p1 before super for " . ref($_[0]) . "\n";
						$_[0]->super('destroy');
						$record .= "p1 after super for " . ref($_[0]) . "\n";
					},
				);
			$name1 = ref($p1);

			$p3->addSlot('parent1**' => $p1);
		}
	}
}
ok( $record, <<END);
p3 before super for $name3
p1 before super for $name3
p1 after super for $name3
p3 after super for $name3
You are in MyClass_Alt::DESTROY for $name3
p1 before super for $name1
p1 after super for $name1
You are in MyClass_Alt::DESTROY for $name1
p2 before super for $name2
p2 after super for $name2
You are in MyClass::DESTROY for $name2
END

# Demonstration of the search for DESTROY taking a different path from the
# search for destroy
$record = '';
{
	my $p3 = MyClass->new(
		'destroy!' => sub {
				$record .= "p3 before super for " . ref($_[0]) . "\n";
				$_[0]->super('destroy');
				$record .= "p3 after super for " . ref($_[0]) . "\n";
			},
		);
	$name3 = ref($p3);

	{
		my $p2 = MyClass->new(
			'destroy!' => sub {
					$record .= "p2 before super for " . ref($_[0]) . "\n";
					$_[0]->super('destroy');
					$record .= "p2 after super for " . ref($_[0]) . "\n";
				},
			);
		$name2 = ref($p2);

		$p3->addSlot('parent2**' => $p2);

		{
			my $p1 = Class::Prototyped->new(
				'destroy!' => sub {
						$record .= "p1 before super for " . ref($_[0]) . "\n";
						$_[0]->super('destroy');
						$record .= "p1 after super for " . ref($_[0]) . "\n";
					},
				);
			$name1 = ref($p1);

			$p3->addSlot('parent1**' => $p1);
		}
	}
}
ok( $record, <<END);
p3 before super for $name3
p1 before super for $name3
p1 after super for $name3
p3 after super for $name3
You are in MyClass::DESTROY for $name3
p1 before super for $name1
p1 after super for $name1
p2 before super for $name2
p2 after super for $name2
You are in MyClass::DESTROY for $name2
END


# Demonstration of a real-world dependency on the parent slot remaining viable
$record = '';
{
	my $p3;
	{
		my $p2;
		{
			my $p1;
			{
				$p1 = Class::Prototyped->new(
					name => 'p1',
					count => 0,
				);
				my $ref = ref($p1);
				$p1->addSlots(
					'new!' => sub {
						my $self = $_[0]->super('new', 'parent*' => @_);
						$self->count($self->count()+1);
						$record .= "Incremented count to " . $self->count . " using " .
								ref($self) . " from new called on " . ref($_[0]) . "\n";
						return $self;
					},
					'destroy!' => sub {
						if (ref($_[0]) eq $ref) {
							$record .= "p1::destroy called on self with a count of " .
									$_[0]->count . "\n";
						} else {
							$record .= "p1::destroy called on " . $_[0]->name() . " (" .
									ref($_[0]) . ")\n";
							$_[0]->count($_[0]->count()-1);
							$record .= "Decremented count to " . $_[0]->count . "\n";
						}
					},
				);
			}
			$name1 = ref($p1);

			$p2 = $p1->new(name => 'p2');
			$name2 = ref($p2);

			$p3 = $p2->new(name => 'p3');
			$name3 = ref($p3);

		}
	}
}
ok( $record, <<END);
Incremented count to 1 using $name2 from new called on $name1
Incremented count to 2 using $name3 from new called on $name2
p1::destroy called on p3 ($name3)
Decremented count to 1
p1::destroy called on p2 ($name2)
Decremented count to 0
p1::destroy called on self with a count of 0
END

