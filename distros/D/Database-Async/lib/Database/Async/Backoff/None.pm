package Database::Async::Backoff::None;

use strict;
use warnings;

our $VERSION = '0.019'; # VERSION

use parent qw(Database::Async::Backoff);

use mro qw(c3);

Database::Async::Backoff->register(
    none => __PACKAGE__
);

sub next { 0 }

1;
