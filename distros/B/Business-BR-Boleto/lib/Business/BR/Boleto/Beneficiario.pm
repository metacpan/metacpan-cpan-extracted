package Business::BR::Boleto::Beneficiario;
$Business::BR::Boleto::Beneficiario::VERSION = '0.000002';
use Moo;
use Business::BR::Boleto::Codigo;

has 'agencia' => (
    is       => 'ro',
    required => 1,
);

has 'conta' => (
    is       => 'ro',
    required => 1,
);

sub BUILDARGS {
    my ( $class, $args ) = @_;

    $args->{agencia} = Business::BR::Boleto::Codigo->new( $args->{agencia} );
    $args->{conta}   = Business::BR::Boleto::Codigo->new( $args->{conta} );

    return $args;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::BR::Boleto::Beneficiario

=head1 VERSION

version 0.000002

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
