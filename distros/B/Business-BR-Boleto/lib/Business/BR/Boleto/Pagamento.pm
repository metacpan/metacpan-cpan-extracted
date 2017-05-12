package Business::BR::Boleto::Pagamento;
$Business::BR::Boleto::Pagamento::VERSION = '0.000002';
use Moo;
use DateTime;

has 'data_documento' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $hoje = DateTime->today;

        return $hoje;
    },
);

has 'data_vencimento' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;

        my $copia = $self->data_documento->clone;

        return $copia->truncate( to => 'day' )->add( days => 5 );
    },
);

has 'numero_documento' => (
    is      => 'ro',
    default => sub { '' },
);

has 'nosso_numero' => (
    is       => 'ro',
    required => 1,
);

has 'quantidade' => (
    is      => 'ro',
    default => sub { '' },
);

has 'valor' => (
    is      => 'ro',
    default => sub { '' },
);

has 'valor_documento' => (
    is       => 'ro',
    required => 1,
);

has 'especie' => (
    is      => 'ro',
    default => sub { 'DM' },
);

has 'moeda' => (
    is      => 'ro',
    default => sub { 'R$' },
);

has 'aceite' => (
    is      => 'ro',
    default => sub { 'N' },
);

has 'local_pagamento' => (
    is      => 'ro',
    default => 'Pagável em qualquer banco até o vencimento',
);

has 'instrucoes' => (
    is      => 'ro',
    default => sub { '' },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::BR::Boleto::Pagamento

=head1 VERSION

version 0.000002

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
