package Catalyst::Plugin::Authentication::Store::HTTP::Backend;
use strict;
use warnings;

use Catalyst::Plugin::Authentication::Store::HTTP::User;

=head1 NAME

Catalyst::Plugin::Authentication::Store::HTTP::Backend - HTTP authentication storage backend

=head1 SYNOPSIS

See L<Catalyst::Plugin::Authentication::Store::HTTP>.

=head1 DESCRIPTION

HTTP authentication storage backend

=head1 METHODS

=head2 new

=cut

sub new {
    my ($class, $config) = @_;

    bless {%$config}, $class;
}

=head2 get_user

=cut

sub get_user {
    my ($self, $id) = @_;

    my $user = {
        id         => $id,
        auth_url   => $self->{auth_url},
        domain     => $self->{domain},
        keep_alive => $self->{keep_alive} || 0,
        ntlm       => $self->{ntlm} || 0,
    };

    return bless $user, 'Catalyst::Plugin::Authentication::Store::HTTP::User';
}

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;

