package Business::BR::Boleto::Role::Banco;
$Business::BR::Boleto::Role::Banco::VERSION = '0.000002';
use Moo::Role;
use File::ShareDir qw{ module_file };

requires qw{ nome codigo campo_livre pre_render };

sub logo {
    my ($self) = @_;

    my $class = ref $self;
    return module_file( ref($self), 'logo.png' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::BR::Boleto::Role::Banco

=head1 VERSION

version 0.000002

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
