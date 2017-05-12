use strict;
use warnings;

use Test::More tests => 10;
use Test::Fatal;

use Closure::Explicit qw(callback);

{
	package Example;
	use Test::More;
	sub new { my $class = shift; bless {}, $class }
	sub method { my $self = shift; pass('called method') }
}
local $SIG{__WARN__} = sub { note "had warning: @_" };
my $self = new_ok('Example');

# Can we flag captures
ok(exception {
	callback {
		1;
		{; $self->method; }
		1;
	}
}, 'nested scope raises exception');

ok(exception {
	(callback {
		for my $self (1..4) { 1 }
		$self->method;
	})->()
}, 'still raise an exception after lexical var in foreach loop');

is(exception {
	(callback {
		my $self = 123;
		print "$self\n";
	})->();
}, undef, 'no exception for lexical in this scope');

is(exception {
	(callback {
		1;
		{
			my $self = 123;
			print "$self\n";
		}
	})->();
}, undef, 'no exception for lexical in nested scope');

ok(exception {
	(callback {
		1;
		{
			my $self = 123;
			print "$self\n";
		}
		$self->method;
	})->();
}, 'lexical in nested scope does not prevent us flagging capture at top-level');

# Can we whitelist captures
is(exception {
	(callback {
		for my $self (1..4) { 1 }
		$self->method;
	} [qw($self)])->();
}, undef, 'no exception when lexical is whitelisted');

# Can we weaken captures
is(exception {
	(callback {
		my $self = shift;
		$self->method;
	} weaken => [qw($self)])->();
}, undef, 'no exception when requesting a weakref');
done_testing();

