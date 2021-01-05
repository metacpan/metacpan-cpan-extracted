package Data::Money::BaseException::InvalidCurrencyFormat;

$Data::Money::BaseException::InvalidCurrencyFormat::VERSION   = '0.19';
$Data::Money::BaseException::InvalidCurrencyFormat::AUTHORITY = 'cpan:GPHAT';

=head1 NAME

Data::Money::BaseException::InvalidCurrencyFormat - Exception handle for 'invalid currency format'.

=head1 VERSION

Version 0.19

=cut

use 5.006;
use Data::Dumper;

use Moo;
use namespace::clean;

has error => (is => 'ro', default => sub { 'Invalid currency format.' });

with 'Data::Money::BaseException';

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY>

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 REPOSITORY

L<https://github.com/manwar/Data-Money>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Cory Watson

This program is free software; you can redistribute it and/or modify it under the
terms of either: the GNU General Public License as published by the Free Software
Foundation; or the Artistic License.

See L<here|http://dev.perl.org/licenses> for more information.

=cut

1; # End of Data::Money::BaseException::InvalidCurrencyFormat
