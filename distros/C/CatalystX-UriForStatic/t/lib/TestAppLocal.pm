package TestAppLocal;
our $VERSION = '0.01';

use Moose;
use namespace::autoclean;

extends 'Catalyst';
with 'CatalystX::UriForStatic';

__PACKAGE__->config(
    static_host => 'http://static.example.net',
    sysenv      => 'local',
);

__PACKAGE__->setup;

1;