#! perl

use strict;
use warnings;

package Comics::Fetcher::Single;

use parent qw(Comics::Fetcher::Cascade);

=head1 NAME

Comics::Fetcher::Single -- Simple url grabber

=head1 DESCRIPTION

This is just a wrapper around L<Comics::Fetcher::Cascade>.

=cut

our $VERSION = "1.00";

1;
