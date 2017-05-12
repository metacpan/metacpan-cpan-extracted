use strict;
use warnings;

use Test::More tests => 4;
use Test::Fatal;

use Closure::Explicit qw(callback);

{
	package Example;
	sub new { my $class = shift; bless {}, $class }
	sub method { my $self = shift; pass('called method') }
}
local $SIG{__WARN__} = sub { note "had warning: @_" };
my $self = new_ok('Example');

# Can we flag captures
ok(exception {
	callback {
		$self->method;
	}
}, 'raise exception on capture');

# Can we whitelist captures
is(exception {
	callback {
		$self->method;
	} [qw($self)];
}, undef, 'no exception when lexical is whitelisted');

# Can we weaken captures
is(exception {
	callback {
		my $self = shift;
		$self->method;
	} weaken => [qw($self)];
}, undef, 'no exception when requesting a weakref');
done_testing();

