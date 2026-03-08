=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<Data::ZPath::_ScalarProxy>.

=cut

use Test2::V0 -target => 'Data::ZPath::_ScalarProxy';
use Test2::Tools::Spec;

describe "class `$CLASS`" => sub {

	tests 'method `TIESCALAR`' => sub {
		my $value = 10;
		my $slot = sub {
			if ( @_ ) {
				$value = $_[0];
			}
			return $value;
		};

		my $obj = Data::ZPath::_ScalarProxy->TIESCALAR($slot);
		ok( $obj->isa('Data::ZPath::_ScalarProxy'), 'tiescalar returns proxy object' );
	};

	tests 'method `FETCH`' => sub {
		my $value = 10;
		my $slot = sub {
			if ( @_ ) {
				$value = $_[0];
			}
			return $value;
		};

		tie my $proxy, 'Data::ZPath::_ScalarProxy', $slot;
		is( $proxy, 10, 'FETCH reads through slot' );
	};

	tests 'method `STORE`' => sub {
		my $value = 10;
		my $slot = sub {
			if ( @_ ) {
				$value = $_[0];
			}
			return $value;
		};

		tie my $proxy, 'Data::ZPath::_ScalarProxy', $slot;
		$proxy = 27;
		is( $value, 27, 'STORE writes through slot' );
	};
};

done_testing;
