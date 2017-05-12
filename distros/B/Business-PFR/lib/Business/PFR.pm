package Business::PFR;
{
  $Business::PFR::VERSION = '1.0.1';
}

use strict;
use warnings FATAL => 'all';
use utf8;

# ABSTRACT: validate Russian pension fund number

use Carp;





sub new {
    my ($class, %params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{_maybe_pfr} = delete $params{value};

    croak "Incorrect constructor usage. Stopped" if %params;

    return $self;
}


sub is_valid {
    my ($self, @params) = @_;

    croak "Incorrect usage. Stopped" if @params;

    if (not defined $self->{_is_valid}) {
        $self->{_is_valid} = $self->_check_is_valid();
    }

    return $self->{_is_valid};
}

sub _check_is_valid {
    my ($self) = @_;

    return 0 if not defined $self->{_maybe_pfr};

    my $is_valid;

    my $maybe_pfr = $self->{_maybe_pfr};

    if ($maybe_pfr =~ /^(\d)(\d)(\d)-(\d)(\d)(\d)-(\d)(\d)(\d) (\d{2})$/a) {

        my $sum =
            $1 * 9
            + $2 * 8
            + $3 * 7
            + $4 * 6
            + $5 * 5
            + $6 * 4
            + $7 * 3
            + $8 * 2
            + $9 * 1
            ;

        if ( $self->_get_check_digit($sum) eq $10) {
            $is_valid = 1;
        } else {
            $is_valid = 0;
        }

    } else {
        $is_valid = 0;
    }

    return $is_valid;
}

sub _get_check_digit {
    my ($self, $sum) = @_;

    return '00' if $sum == 100;

    return sprintf("%02d", $sum % 101);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::PFR - validate Russian pension fund number

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

    my $bp = Business::PFR->new(
        value => '112-233-445 95',
    );

    $bp->is_valid();

=head1 DESCRIPTION

This module checks if the Russian pension fund number PFR (ПФР) is valid.

The algorithm is taken from the document:
L<http://www.pfrf.ru/userdata/rabotodatelyam/persuchet/otchet_per/pravila_proverki_3.doc>

Business::PFR version numbers uses Semantic Versioning standart.
Please visit L<http://semver.org/> to find out all about this great thing.

=head2 ALGORITHM (in Russian language)

Алгоритм формирования контрольного числа Страхового номера

Проверка контрольного числа Страхового номера проводится только для номеров
больше номера 001-001-998

Контрольное число Страхового номера рассчитывается следующим образом:

=over

=item * каждая цифра Страхового номера умножается на номер своей позиции (позиции отсчитываются с конца)

=item * полученные произведения суммируются

=item * сумма делится на 101

=item * последние две цифры остатка от деления является Контрольным числом.

=back

Например: Указан страховой номер 112-233-445 95

Проверяем правильность контрольного числа:

    цифры номера    1 1 2 2 3 3 4 4 5
    номер позиции   9 8 7 6 5 4 3 2 1

    1х9+1х8+2х7+2х6+3х5+3х4+4х3+4х2+5х1=95

    95 / !101! =95

Контрольное число=95 - указано верно

Некоторые частные случаи:

    99 / !101! = 99
    100 / !101! = 00
    101 / !101! = 00
    102 / !101! = 01

=head1 METHODS

=head2 new

    my $bp = Business::PFR->new(
        value => '112-233-445 95',
    );

=head2 is_valid

Returns true or false value for PFR number in the object.

True value means that PFR is coorect.

    $bp->is_valid();

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
