
package Clio::Server;
BEGIN {
  $Clio::Server::AUTHORITY = 'cpan:AJGB';
}
{
  $Clio::Server::VERSION = '0.02';
}
# ABSTRACT: Base abstract class for Clio::Server::* implementations

use strict;
use Moo;
use Carp qw( croak );
use Clio::Server::ClientsManager;

with 'Clio::Role::HasContext';



has 'host' => (
    is => 'ro',
);


has 'port' => (
    is => 'ro',
);


has 'clients_manager' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_clients_manager',
);

sub _build_clients_manager {
    my $self = shift;

    return Clio::Server::ClientsManager->new(
        c => $self->c,
    );
};


sub start { croak "Abstract method!\n"; }

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Clio::Server - Base abstract class for Clio::Server::* implementations

=head1 VERSION

version 0.02

=head1 DESCRIPTION

Base abstract class for I<Clio::Server::*> implementations.

Consumes the L<Clio::Role::HasContext>.

=head1 ATTRIBUTES

=head2 host

Server host.

=head2 port

Server port.

=head2 clients_manager

Holds L<Clio::Server::ClientsManager>.

=head1 METHODS

=head2 start

Abstract method to start server.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

