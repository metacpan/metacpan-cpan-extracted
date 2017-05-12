package TestApp;

use Catalyst::Runtime;
use Moose;

extends 'Catalyst';
with    'CatalystX::VCS::Lookup';

__PACKAGE__->config(
	'VCS::Lookup' => { Revision => 'version' }
);

__PACKAGE__->setup;

1;
