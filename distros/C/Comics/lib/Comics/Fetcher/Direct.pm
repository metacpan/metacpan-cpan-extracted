#! perl

use strict;
use warnings;
use utf8;
use Carp;

package Comics::Fetcher::Direct;

use parent qw(Comics::Fetcher::Cascade);

=head1 NAME

Comics::Fetcher::Direct -- Named url grabber

=head1 DESCRIPTION

This is just a wrapper around L<Comics::Fetcher::Cascade>.

=cut

our $VERSION = "1.00";

1;
