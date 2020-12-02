package Database::Async::Backoff;

use strict;
use warnings;

our $VERSION = '0.013'; # VERSION

=head1 NAME

Database::Async::Backoff - support for backoff algorithms in L<Database::Async>

=head1 DESCRIPTION

=cut

use Database::Async::Backoff::Exponential;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class
}

1;

