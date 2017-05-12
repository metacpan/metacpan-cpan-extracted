package Plack::Handler::Arriba;

use strict;

# ABSTRACT: Plack adapter for Arriba

use Arriba::Server;

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub run {
    my ($self, $app) = @_;

    Arriba::Server->new->run($app, {%$self});
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Plack::Handler::Arriba - Plack adapter for Arriba

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    plackup -s Arriba --listen :5443 --listen-ssl 5443 --enable-spdy \
        --ssl-cert-file cert.pem --ssl-key-file key.pem app.psgi

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Arriba|Arriba>

=back

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
