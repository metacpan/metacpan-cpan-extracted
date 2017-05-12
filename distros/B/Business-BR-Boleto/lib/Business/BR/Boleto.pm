package Business::BR::Boleto;
$Business::BR::Boleto::VERSION = '0.000002';
use Moo;
use Carp;

use MAD::Loader qw{ load_and_new };

use Business::BR::Boleto::Banco;
use Business::BR::Boleto::Cedente;
use Business::BR::Boleto::Sacado;
use Business::BR::Boleto::Avalista;
use Business::BR::Boleto::Pagamento;
use Business::BR::Boleto::FebrabanSpec;

use Business::BR::Boleto::Utils qw{ mod10 fator_vencimento };

has 'banco' => (
    is  => 'ro',
    isa => sub {
        Carp::croak 'Banco inválido'
          unless $_[0]->does('Business::BR::Boleto::Role::Banco');
    },
);

has 'cedente' => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        Carp::croak 'Cendente inválido'
          unless $_[0]->isa('Business::BR::Boleto::Cedente');
    },
);

has 'sacado' => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        Carp::croak 'Sacado inválido'
          unless $_[0]->isa('Business::BR::Boleto::Sacado');
    },
);

has 'avalista' => (
    is      => 'ro',
    default => sub {
        Business::BR::Boleto::Avalista->new(
            nome      => '',
            endereco  => '',
            documento => '',
        );
    },
);

has 'pagamento' => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        Carp::croak 'Dados de pagamento inválidos'
          unless $_[0]->isa('Business::BR::Boleto::Pagamento');
    },
);

has 'febraban' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;

        my $banco = $self->banco->codigo;
        my $fator = fator_vencimento( $self->pagamento->data_vencimento );
        my $valor = int( 100 * $self->pagamento->valor_documento );
        my $campo_livre =
          $self->banco->campo_livre( $self->cedente, $self->pagamento );

        my $spec = Business::BR::Boleto::FebrabanSpec->new(
            codigo_banco     => $banco,
            fator_vencimento => $fator,
            valor_nominal    => sprintf( '%010d', $valor ),
            campo_livre      => $campo_livre,
        );
    },
);

sub codigo_barras {
    my ($self) = @_;

    return
        ''
      . $self->febraban->codigo_banco
      . $self->febraban->codigo_moeda
      . $self->febraban->dv_codigo_barras
      . $self->febraban->fator_vencimento
      . $self->febraban->valor_nominal
      . $self->febraban->campo_livre;
}

sub linha_digitavel {
    my ($self) = @_;

    my $banco       = $self->febraban->codigo_banco;
    my $moeda       = $self->febraban->codigo_moeda;
    my $campo_livre = $self->febraban->campo_livre;
    my $dv          = $self->febraban->dv_codigo_barras;
    my $fator       = $self->febraban->fator_vencimento;
    my $valor       = $self->febraban->valor_nominal;

    my ( $campo1, $campo2, $campo3, $dac, $campo5 );

    $campo1 = $banco . $moeda . substr $campo_livre, 0, 5;
    $campo1 .= mod10($campo1);
    $campo1 =~ s/(.{5})(.{5})/$1.$2/;

    $campo2 = substr $campo_livre, 5, 10;
    $campo2 .= mod10($campo2);
    $campo2 =~ s/(.{5})(.{6})/$1.$2/;

    $campo3 = substr $campo_livre, 15, 10;
    $campo3 .= mod10($campo3);
    $campo3 =~ s/(.{5})(.{6})/$1.$2/;

    $campo5 = $fator . $valor;

    return join ' ', $campo1, $campo2, $campo3, $dv, $campo5;
}

sub BUILDARGS {
    my ( $class, %args ) = @_;

    $args{banco} = load_and_new(
        module => $args{banco},
        prefix => 'Business::BR::Boleto::Banco',
        args   => [],
    );

    $args{cedente}   = Business::BR::Boleto::Cedente->new( $args{cedente} );
    $args{sacado}    = Business::BR::Boleto::Sacado->new( $args{sacado} );
    $args{pagamento} = Business::BR::Boleto::Pagamento->new( $args{pagamento} );

    $args{avalista} = Business::BR::Boleto::Avalista->new( $args{avalista} )
      if $args{avalista};

    return \%args;
}

1;

# ABSTRACT: A system to generate Brazilian Boletos

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::BR::Boleto - A system to generate Brazilian Boletos

=head1 VERSION

version 0.000002

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
