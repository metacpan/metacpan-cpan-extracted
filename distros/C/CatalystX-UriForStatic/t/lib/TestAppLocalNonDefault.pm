package TestAppLocalNonDefault;
our $VERSION = '0.01';

use Moose;
use namespace::autoclean;

extends 'Catalyst';
with 'CatalystX::UriForStatic';

__PACKAGE__->config(
    envkey      => 'my_sysenv',
    local_value => 'devel',
    static_host => 'http://static.example.net',
    my_sysenv   => 'devel',
);

__PACKAGE__->setup;

1;