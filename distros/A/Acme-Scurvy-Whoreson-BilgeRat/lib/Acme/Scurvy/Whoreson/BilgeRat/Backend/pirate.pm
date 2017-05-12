package Acme::Scurvy::Whoreson::BilgeRat::Backend::pirate;

$VERSION = '1.0';

use warnings;
use strict;

use base 'Acme::Scurvy::Whoreson::BilgeRat';

sub new {
	my $class = shift;
	bless {
		nouns => [
			'bilge rat', 'whoreson', 'land-lubber',
			'cur',  'swab', 'potvaliant'
		],
		adjectives => [
			'scurvy', 'whoreson', 'lily-livered',
			'black-spotted', 'grog-shy', 'cowardly',
                        'potvaliant'
		],
		grammars => [qw(
			N
			AN
			AAN
		)]
	}, $class;
}

# sub generateinsult { my $self = shift; return 'this is a subclassed stringification'; }
'aaaaarrrrrrrrrr';
