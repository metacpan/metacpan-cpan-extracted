package Catalyst::Plugin::Authentication::Store::HTTP::User;
use strict;
use warnings;
use base qw/Catalyst::Plugin::Authentication::User Class::Accessor::Fast/;

use Catalyst::Plugin::Authentication::Store::HTTP::UserAgent;

__PACKAGE__->mk_accessors(qw/id store/);

use overload q{""} => sub { shift->id }, fallback => 1;

=head1 NAME

Catalyst::Plugin::Authentication::Store::HTTP::User - HTTP authentication storage user class

=head1 SYNOPSIS

See L<Catalyst::Plugin::Authentication::Store::HTTP>.

=head1 DESCRIPTION

HTTP authentication storage user class

=head1 METHODS

=head2 supported_features

=cut

sub supported_features {
    return {
        password => { self_check => 1, },
        session  => 1,
    };
}

=head2 check_password

=cut

sub check_password {
    my ($self, $password) = @_;

    my $ua =
      Catalyst::Plugin::Authentication::Store::HTTP::UserAgent->new(
        keep_alive => ($self->{keep_alive} ? 1 : 0));
    my $req = HTTP::Request->new(HEAD => $self->{auth_url});

    # set the credentials for the request.
    # if there is a domain set then prepend this onto the user id
    $ua->credentials(
        ($self->{domain} ? join("\\", $self->{domain}, $self->id) : $self->id),
        $password
    );

    my $res = $ua->request($req);

    $res->is_success;
}

=head2 for_session

=cut

sub for_session {
    shift;
}

=head2 from_session

=cut

sub from_session {
    my ($self, $c, $user) = @_;

    $user;
}

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut

1;
