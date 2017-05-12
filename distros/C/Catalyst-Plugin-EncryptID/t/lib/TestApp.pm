package TestApp;

use strict;
use warnings;

use Catalyst qw/EncryptID/;

our $VERSION = '0.01';

TestApp->config(
	name    => 'TestApp',
	EncryptID => {
		secret => 'abc123xyz',
		padding_character => '!'
	}
);

TestApp->setup;

1;