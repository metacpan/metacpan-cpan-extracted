package Data::Money::Converter;

$Data::Money::Converter::VERSION   = '0.07';
$Data::Money::Converter::AUTHORITY = 'cpan:GPHAT';

=head1 NAME

Data::Money::Converter - Moo Role for Data::Money Converters.

=head1 VERSION

Version 0.07

=cut

use Moo::Role;
use namespace::clean;

requires 'convert';

=head1 DESCRIPTION

This simple  module provides a base for building currency conversion backends for
L<Data::Money>. You can use  this module either  as a basis for understanding the
common features or as a guide for implementing your own converter.

=head1 SYNOPSIS

    package MoneyConverter;

    use Moo;
    use namespace::clean;
    with 'Data::Money::Converter';

    sub convert {
        my ($self, $money, $code) = @_;

        return $money->clone(
            value => $money->value * 2,
            code  => $code
        );
    }

    1;

=head1 METHODS

This role requires that you  implement  a C<convert> method. It should expect two
arguments: an isntance of L<Data::Money> and a 3-character currency code. It does
not do any checking of the code as not all conversion implementations may support
all codes.  It is recommended that you consult L<Locale::Currency>.

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

Currently maintained by Mohammad S Anwar (MANWAR) C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Data-Money-Converter>

=head1 SEE ALSO

L<Data::Money>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cory G Watson.

This program is free software; you can redistribute it and/or modify it under the
terms of either: the GNU General Public License as published by the Free Software
Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Data::Money::Converter
