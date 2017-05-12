package Business::BR::Boleto::Banco::Itau;
$Business::BR::Boleto::Banco::Itau::VERSION = '0.000001';
use Moo;
with 'Business::BR::Boleto::Role::Banco';

use Business::BR::Boleto::Utils qw{ mod10 mod11 };

sub nome       { 'Itau' }
sub codigo     { '341' }
sub pre_render { }

sub campo_livre {
    my ( $self, $cedente, $pagamento ) = @_;

    my $campo_livre = '';

    my $nosso_numero = sprintf '%08d', $pagamento->nosso_numero;
    my $carteira     = sprintf '%03d', $cedente->carteira;
    my $agencia      = sprintf '%04d', $cedente->agencia->{numero};
    my $conta        = sprintf '%05d', $cedente->conta->{numero};

    my $dac_nn = mod10( $agencia . $conta . $carteira . $nosso_numero );
    my $dac_ac = mod11( $agencia . $conta );

    return
        $carteira
      . $nosso_numero
      . $dac_nn
      . $agencia
      . $conta
      . $dac_ac . '000';
}

1;

#ABSTRACT: Implementação das particularidades de boletos do Banco Itau

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::BR::Boleto::Banco::Itau - ImplementaÃ§Ã£o das particularidades de boletos do Banco Itau

=head1 VERSION

version 0.000001

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
