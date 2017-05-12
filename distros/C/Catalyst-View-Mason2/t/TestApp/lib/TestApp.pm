package TestApp;
use Moose;
use namespace::autoclean;
use Catalyst::Runtime 5.80;
use File::Basename;
use Cwd qw(realpath);
use Catalyst;
extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->config(
    name         => 'TestApp',
    home         => dirname( dirname( realpath(__FILE__) ) ),
    default_view => 'Mason2::Basic',
);

__PACKAGE__->setup;

1;
