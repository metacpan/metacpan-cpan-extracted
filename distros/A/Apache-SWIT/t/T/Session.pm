use strict;
use warnings FATAL => 'all';

package T::Session;
use base 'Apache::SWIT::Session';

__PACKAGE__->add_var('persbox');

sub access_handler {
	my ($class, $r) = @_;
	my $res = $class->SUPER::access_handler($r);
	return ($r->pnotes('SWITSession')->get_persbox && $r->uri =~ /\.html/)
			? Apache2::Const::FORBIDDEN() : $res;
}

sub cookie_name { return 'foo' }

1;
