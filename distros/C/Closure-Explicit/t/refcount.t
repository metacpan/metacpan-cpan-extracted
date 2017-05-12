use strict;
use warnings;

use Test::More tests => 6;
use Test::Fatal;
use Test::Refcount;

use Closure::Explicit qw(callback);

{
	package Example;
	sub new { my $class = shift; bless {}, $class }
	sub method { my $self = shift; pass('called method') }
}
local $SIG{__WARN__} = sub { note "had warning: @_" };
my $self = new_ok('Example');
is_oneref($self, 'start with a single ref');
{
	ok((my $code = callback {
			$self->method;
		} [qw($self)]
	), 'get callback');
	is_oneref($self, 'still with a single ref');
}
{
	ok((my $code = callback {
			my $self = shift;
			$self->method;
		} weaken => [qw($self)]
	), 'get callback');
	is_oneref($self, 'still with a single ref');
}
done_testing();

