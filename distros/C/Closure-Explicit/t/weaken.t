use strict;
use warnings;

use Test::More tests => 10;
use Test::Fatal;
use Test::Refcount;
use Scalar::Util ();

use Closure::Explicit qw(callback);

{
	package Example;
	use Test::More;
	our $GLOBAL_SELF;
	sub new { my $class = shift; my $self = bless {}, $class; Scalar::Util::weaken($GLOBAL_SELF = $self); $self }
	sub method { my $self = shift; is($self, $GLOBAL_SELF, 'have correct $self') }
}
local $SIG{__WARN__} = sub { note "had warning: @_" };
my $self = new_ok('Example');
is_oneref($self, 'start with a single ref');
{
	ok(exception {
		my $code = callback {
			$self->method;
		}
	}, 'have exception without capture');
	is_oneref($self, 'still with a single ref');
}
{
	ok((my $code = callback {
			$self->method;
		} [qw($self)]
	), 'get callback');
	is_oneref($self, 'still with a single ref');
	$code->();
}
{
	ok((my $code = callback {
			my $self = shift;
			$self->method;
		} weaken => [qw($self)]
	), 'get callback');
	is_oneref($self, 'still with a single ref');
	$code->();
}
done_testing();

