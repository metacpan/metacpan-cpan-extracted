package TestApp;

use strict;
use warnings;

use Catalyst qw/ VersionedURI /;

our $VERSION = '1.2.3';

__PACKAGE__->config({
    'Plugin::VersionedURI' => {
        in_path => 1,
        uri => [ qw# foo/ bar  # ],
    }
});

__PACKAGE__->setup;

1;
