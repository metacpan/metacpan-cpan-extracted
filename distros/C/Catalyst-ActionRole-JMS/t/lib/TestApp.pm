package TestApp;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

use Catalyst $ENV{TEST_VERBOSE} ? qw(-Debug) : () ;

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->config(
    name => 'TestApp',
    disable_component_resolution_regex_fallback => 1,
);

__PACKAGE__->setup();

1;
