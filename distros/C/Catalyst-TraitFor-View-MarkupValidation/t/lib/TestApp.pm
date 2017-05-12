package TestApp;
use Moose;
use namespace::autoclean;

use Catalyst qw/-Debug/;

extends 'Catalyst';
__PACKAGE__->config( 'MARKUP_VALIDATOR_URI' => 'http://example.com/check' );
__PACKAGE__->setup;
1;
