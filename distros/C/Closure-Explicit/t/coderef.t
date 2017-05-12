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
	# please don't do this in real code
	my $code = sub { $self->method };
	&callback($code);
}, 'raise exception on capture');

# Can we whitelist captures
is(exception {
	# really don't do this in real code
	my $code = sub { $self->method };
	&callback($code, [qw($self)]);
}, undef, 'no exception when lexical is whitelisted');

# Can we weaken captures
is(exception {
	# this is not recommended at all
	my $code = sub { my $self = shift; $self->method };
	&callback($code, weaken => [qw($self)]);
}, undef, 'no exception when requesting a weakref');
done_testing();

