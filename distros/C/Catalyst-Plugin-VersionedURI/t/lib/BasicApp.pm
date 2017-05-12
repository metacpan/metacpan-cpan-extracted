package BasicApp;

use strict;
use warnings;

use Catalyst qw/ VersionedURI /;

our $VERSION = '1.2.3';

__PACKAGE__->config({
    'Plugin::VersionedURI' => {
        uri => [ qw# foo/ bar  # ],
    }
});

__PACKAGE__->setup;

1;
