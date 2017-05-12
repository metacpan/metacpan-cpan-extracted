package Business::BR::Boleto::Utils;
$Business::BR::Boleto::Utils::VERSION = '0.000002';
use Moo;
extends 'Exporter';

our @EXPORT_OK = qw{
  mod10 mod11
  fator_vencimento
};

use List::Util qw{ sum };

use DateTime;
use Const::Fast;

const our $SEGUNDOS_POR_DIA => 86400;
const our $DATA_BASE_FATOR  => DateTime->new(
    year      => 1997,
    month     => 10,
    day       => 7,
    hour      => 0,
    minute    => 0,
    second    => 0,
    time_zone => 'America/Sao_Paulo',
);

sub mod10 {
    my $number = shift || '';

    $number =~ s/\D+//g;

    my @digits = reverse split //, $number;

    my $sum = 0;
    for my $i ( 0 .. $#digits ) {
        $sum += sum( split //, $i % 2 ? $digits[$i] : 2 * $digits[$i] );
    }

    my $mod = $sum % 10;

    return $mod ? 10 - $mod : 0;
}

sub mod11 {
    my $number = shift || '';

    $number =~ s/\D+//g;

    my @digits = reverse split //, $number;

    my $sum = 0;
    foreach my $i ( 0 .. $#digits ) {
        $sum += $digits[$i] * ( 2 + $i % 8 );
    }

    my $mod = $sum % 11;
    my $res = $mod > 1 && $mod < 11 ? 11 - $mod : 1;

    return wantarray ? ( $res, $mod ) : $res;
}

sub fator_vencimento {
    my $data_fator = shift;

    $data_fator->truncate( to => 'day' );

    my $delta = $data_fator->subtract_datetime_absolute($DATA_BASE_FATOR);

    return int( 0.5 + $delta->seconds / $SEGUNDOS_POR_DIA );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::BR::Boleto::Utils

=head1 VERSION

version 0.000002

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
