package Business::Monzo::Version;

=head1 NAME

Business::Monzo::Version

=head1 DESCRIPTION

A role for a Monzo version information.

=cut

use strict;
use warnings;

use Moo::Role;

$Business::Monzo::VERSION     = '0.07';
$Business::Monzo::API_VERSION = 'v1';
$Business::Monzo::API_URL     = 'https://api.monzo.com';

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/leejo/business-monzo

=cut

1;
