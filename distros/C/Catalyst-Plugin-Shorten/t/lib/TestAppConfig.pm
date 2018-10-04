package TestAppConfig;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

use Catalyst qw/
	Shorten
	Shorten::Store::Dummy
/;

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->config(
    name => 'TestApp',
	'Plugin::Shorten' => {
		set => [qw/a 1 b 2 c 3 d 4 e 5 f 6 g 7 h 8 i 9 A B C D E F G H I/],
		offset => 10000000,
		map => {
			params => 'data',
			uri => 'url',
			s => 'g'
		}
	}
);

# Start the application
__PACKAGE__->setup();

1;
