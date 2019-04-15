package Database::Async::Backoff::Exponential;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

sub new {
    my ($class, %args) = @_;
    bless \%args, $class
}


1;
