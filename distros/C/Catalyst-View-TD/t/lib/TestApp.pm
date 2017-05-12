package TestApp;

use strict;
use warnings;

use Catalyst; # qw/-Debug/;

our $VERSION = '0.12';

__PACKAGE__->config(
    name                  => 'TestApp',
    default_message       => 'hi',
    default_view          => 'Appconfig',
    'View::TD::Appconfig' => {
        postprocessor => sub { $_[0] =~ s/\s+$//; $_[0] },
    },
);

__PACKAGE__->setup;

1;
