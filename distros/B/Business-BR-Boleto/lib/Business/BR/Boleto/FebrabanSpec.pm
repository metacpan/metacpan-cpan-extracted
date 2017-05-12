package Business::BR::Boleto::FebrabanSpec;
$Business::BR::Boleto::FebrabanSpec::VERSION = '0.000002';
use Moo;

use Business::BR::Boleto::Utils qw{ mod11 };

has 'codigo_banco' => (
    is       => 'ro',
    required => 1,
);

has 'codigo_moeda' => (
    is      => 'ro',
    default => sub { '9' },
);

has 'dv_codigo_barras' => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;

        return mod11( $self->codigo_banco
              . $self->codigo_moeda
              . $self->fator_vencimento
              . $self->valor_nominal
              . $self->campo_livre );
    },
);

has 'fator_vencimento' => (
    is       => 'ro',
    required => 1,
);

has 'valor_nominal' => (
    is       => 'ro',
    required => 1,
);

has 'campo_livre' => (
    is       => 'ro',
    required => 1,
);

sub codigo_barras {
    my ($self) = @_;

    return
        $self->codigo_banco
      . $self->codigo_moeda
      . $self->dv_codigo_barras
      . $self->fator_vencimento
      . $self->valor_nominal
      . $self->campo_livre;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::BR::Boleto::FebrabanSpec

=head1 VERSION

version 0.000002

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
