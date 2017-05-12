package Business::BR::Boleto::Codigo;
$Business::BR::Boleto::Codigo::VERSION = '0.000002';
use Moo;

has 'numero' => (
    is       => 'ro',
    required => 1,
);

has 'dv' => (
    is       => 'ro',
    required => 0,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::BR::Boleto::Codigo

=head1 VERSION

version 0.000002

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
