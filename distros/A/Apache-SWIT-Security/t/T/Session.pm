use strict;
use warnings FATAL => 'all';

package T::Session;
use base 'Apache::SWIT::Security::Session';

sub is_uri_ok {
	my ($self, $uri, %param) = @_;
	if ($uri eq '/test/foo') {
		return 1 if $param{qqq};
		return undef;
	}
	die $uri unless $uri eq '/test/basic_handler';
	return if $param{deny};
	return 1;
}

1;
