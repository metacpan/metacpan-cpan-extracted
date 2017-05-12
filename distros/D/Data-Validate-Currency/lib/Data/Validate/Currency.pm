package Data::Validate::Currency;

use strict;
use warnings;

use Carp qw(croak);
use Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw( is_currency );

our $VERSION = '0.1.0'; # VERSION 0.1.0
#ABSTRACT: Module to validate if data is valid currency

=pod

=encoding utf8

=head1 NAME

    Data::Validate::Currency - Module to validate if string is a valid currency format

=head1 SYNOPSIS

    use strict;
    use warnings;

    use Data::Validate::Currency qw( is_currency );

    my $currency_string = '$1,000.00';
    my $currency_validation = is_currency($currency_string);

    print "Is a valid currency string\n" if $currency_validation;

=head1 DESCRIPTION

    Module that takes a string and returns a true or false value if the string
    is a valid currency. Supports the comma as thousands-separator format,
    2 and 3 digit decimals. Dollar sign is optional.

=head1 METHODS

=head2 is_currency

    use strict;
    use warnings;
    use Data::Validate::Currency qw(is_currency);

    my $currency_string = '$1,000.00';
    my $currency_validation = is_currency($currency_string);

Returns 1 if it is valid currency format, 0 if it is not. Dollar sign optional.

=head1 Author

Daniel Culver, C<< perlsufi@cpan.org >>

=head1 ACKNOWLEDGEMENTS

Eris Caffee, C<< eris-caffee@eldalin.com >>
- A majority of the credit goes to Eris for the final regex.

Robert Stone, C<< drzigman@cpan.org >>
- Robert initially started the regex.

HostGator

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

sub is_currency {

    my $string = shift || croak "is_currency requires a currency string";

    if ( $string =~
        /^\${0,1}\d{1,3}(\,\d{3})*\.\d{2,3}$|^\${0,1}\d+\.\d{2,3}$/ ) {
        return 1;
    }
    else {
        return 0;
    }
}

1;
