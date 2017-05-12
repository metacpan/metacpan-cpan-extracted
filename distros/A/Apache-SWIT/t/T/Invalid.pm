use strict;
use warnings FATAL => 'all';

package T::Invalid;
use base 'Apache::SWIT';

sub swit_invalid_request {
	my ($class, $r) = @_;
	return [ Apache2::Const::OK, qr/Invalid handler called/ ];
}

sub _raw_respond {
	my ($class, $r, $to) = @_;
	return $class->SUPER::_raw_respond($r->{req}, $to);
}

sub invalid_handler($$) {
	my ($class, $r) = @_;
	return $class->swit_update_handler({ req => $r });
}

1;
