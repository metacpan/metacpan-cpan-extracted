package TestAppC3Fail;
use strict;
use warnings;
use Class::C3; # This causes the fail, saying use MRO::Compat is fine..

our $VERSION = '0.0001';

use Catalyst::Runtime 5.70;
use Catalyst;

__PACKAGE__->config(
    name => 'TestAppC3Fail',
);

my @keys = sort keys( %{ __PACKAGE__->config } );

__PACKAGE__->setup;

my @new_keys = sort
    # Ignore key added by horrid hack in Catalyst::Runtime 5.90080
    grep { $_ ne '__configured_from_psgi_middleware'}
    keys( %{ __PACKAGE__->config } );

use Test::More;

is_deeply(\@new_keys, \@keys, 'Config keys correct')
    or diag explain [\@keys, \@new_keys];

1;

