package Business::GoCardless::Version;

=head1 NAME

Business::GoCardless::Version

=head1 DESCRIPTION

A role for a gocardless version information.

=cut

use strict;
use warnings;

use Moo::Role;

$Business::GoCardless::VERSION     = '0.16';
$Business::GoCardless::API_VERSION = 'v1';

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

1;
