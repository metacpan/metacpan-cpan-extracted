package Business::Mondo::Version;

=head1 NAME

Business::Mondo::Version

=head1 DESCRIPTION

A role for a Mondo version information.

=cut

use strict;
use warnings;

use Moo::Role;

$Business::Mondo::VERSION     = '9999.99';
$Business::Mondo::API_VERSION = 'v1';
$Business::Mondo::API_URL     = 'https://api.getmondo.co.uk';

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/leejo/business-mondo

=cut

1;
