package Business::BR::Boleto::Cedente;
$Business::BR::Boleto::Cedente::VERSION = '0.000002';
use Moo;
extends 'Business::BR::Boleto::Pessoa';

use Carp;

has 'agencia' => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        Carp::croak 'Agência do cendente inválida'
          unless ref $_[0] eq 'HASH' && exists $_[0]->{numero};
    },
);

has 'conta' => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        Carp::croak 'Conta do cendente inválida'
          unless ref $_[0] eq 'HASH' && exists $_[0]->{numero};
    },
);

has 'carteira' => (
    is       => 'ro',
    required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::BR::Boleto::Cedente

=head1 VERSION

version 0.000002

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
