package Data::Money::BaseException::ExcessivePrecision;

$Data::Money::BaseException::ExcessivePrecision::VERSION   = '0.18';
$Data::Money::BaseException::ExcessivePrecision::AUTHORITY = 'cpan:GPHAT';

=head1 NAME

Data::Money::BaseException::ExcessivePrecision - Exception handle for 'excessive precision'.

=head1 VERSION

Version 0.18

=cut

use 5.006;
use Data::Dumper;

use Moo;
use namespace::clean;

has error => (is => 'ro', default => sub { 'Excessive precision for this currency type' });

with 'Data::Money::BaseException';

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY>

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

Currently maintained by Mohammad S Anwar (MANWAR) C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Data-Money>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Cory Watson

This program is free software; you can redistribute it and/or modify it under the
terms of either: the GNU General Public License as published by the Free Software
Foundation; or the Artistic License.

See L<here|http://dev.perl.org/licenses> for more information.

=cut

1; # End of Data::Money::BaseException::ExcessivePrecision
