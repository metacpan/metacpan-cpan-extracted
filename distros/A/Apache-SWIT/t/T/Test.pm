use strict;
use warnings FATAL => 'all';

package T::Test;
use base 'Apache::SWIT::Test';
use Apache::SWIT::Session;

BEGIN { __PACKAGE__->do_startup; };

sub new {
	my ($class, $args) = @_;
	$args->{session_class} = 'Apache::SWIT::Session'
		unless exists($args->{session_class});
	return $class->SUPER::new($args);
}

1;
