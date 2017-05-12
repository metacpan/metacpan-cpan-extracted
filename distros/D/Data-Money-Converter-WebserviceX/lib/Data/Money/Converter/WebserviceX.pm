package Data::Money::Converter::WebserviceX;

$Data::Money::Converter::WebserviceX::VERSION   = '0.07';
$Data::Money::Converter::WebserviceX::AUTHORITY = 'gphat';

=head1 NAME

Data::Money::Converter::WebserviceX - WebserviceX currency conversion implementation.

=head1 VERSION

Version v0.07

=head1 SYNOPSIS

    use strict; use warnings;
    use Data::Money;
    use Data::Money::Converter::WebserviceX;

    my $curr = Data::Money->new(value => 10, code => 'USD');
    my $conv = Data::Money::Converter::WebserviceX->new;
    my $newc = $conv->convert($curr, 'GBP');

    print $newc->value, "\n";

=cut

use Moo;
use namespace::clean;

use Data::Dumper;
use Locale::Currency;
use Finance::Currency::Convert::WebserviceX;

with 'Data::Money::Converter';

has  '_converter'          => (is => 'lazy');
has  'valid_currency_code' => (is => 'ro', default => sub {
    return {
        map { uc($_) => uc($_) } Locale::Currency::all_currency_codes()
    };
});

sub _build__converter {
    return Finance::Currency::Convert::WebserviceX->new;
}

=head1 METHODS

=head2 convert($money, $code)

Convert C<$money>, which is an object of type L<Data::Money> to currency C<$code>
and returns an object of type L<Data::Money>.The C<$code> has to be a valid three
letter codes.

=cut

sub convert {
    my ($self, $curr, $code) = @_;

    #die "[$code]",Dumper($self->{valid_currency_code});
    die "ERROR: $code is not a valid currency code.\n"
        unless ($self->{valid_currency_code}{uc($code)});

    return $curr->clone(
        code  => $code,
        value => $self->_converter->convert($curr->value, $curr->code, $code),
    );
}

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

Currently maintained by Mohammad S Anwar (MANWAR) C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Data-Money-Converter-WebserviceX>

=head1 SEE ALSO

=over 4

=item L<Data::Money>

=item L<Data::Money::Converter>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cory G Watson.

This program is free software; you can redistribute it and/or modify it under the
terms of either: the GNU General Public License as published by the Free Software
Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Data::Money::Converter::WebserviceX
