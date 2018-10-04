package TestApp;
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
);

# Start the application
__PACKAGE__->setup();

1;
