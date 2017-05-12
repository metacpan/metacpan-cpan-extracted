package Catalyst::Authentication::Credential::YubiKey;
use Catalyst::Exception;
use Auth::Yubikey_WebClient;
use Moose;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use namespace::autoclean;

=head1 NAME

Catalyst::Authentication::Credential::YubiKey - YubiKey authentication

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

Authenticate Catalyst apps with Yubico's YubiKey system.

Uses the Catalyst::Plugin::Authentication system.

  use Catalyst qw(
    ...
    Authentication
    ...
  );

  __PACKAGE__->config(
    'Plugin::Authentication' => {
      default => {
        credential => {
          class => 'YubiKey',

          # This is your API ID, from http://api.yubico.com/get-api-key/
          api_id => 666,

          # This is your API Key, as above:
          api_key => 'aaaaaaad34db33fzzzzzzzzzz/abc=',

          # This is the column in your store that contains the yubikey ID,
          # for mapping that ID to username or whatever.
          # It defaults to 'id' if not specified.
          id_for_store => 'id',
        },
        ...
      },
    },
  );

=head1 TODO

I am currently using Auth::Yubikey_WebClient as the underlying library for
querying Yubico's webservice. However it would be nice if that library was
improved to return more of the details, rather than just 'OK'.

Also would be good to support in-house authentication servers. (Since Yubico
have open-sourced theirs, and some people may be using such.)

=head1 METHODS

=cut

our $VERSION = '0.07';

has [qw/ api_key api_id /] => (
    isa => NonEmptySimpleStr,
    is => 'ro',
    required => 1
);

has id_for_store => (
    isa => NonEmptySimpleStr,
    is => 'ro',
    default => 'id'
);

=head2 BUILDARGS

Extracts the config

=cut

sub BUILDARGS {
    my ($class, $config, $app, $realm) = @_;
    unless ($config->{api_id} and $config->{api_key}) {
        Catalyst::Exception->throw(
            __PACKAGE__ . " credential for realm " . $realm->name . " missing api_id and api_key"
        );
    }
    return $config;
}

=head2 authenticate

Standard authentication method, as per Cat-Auth-Credential standard.

=cut

sub authenticate {
    my ($self, $c, $realm, $authinfo) = @_;
    my $otp = $authinfo->{otp};

    my $result = Auth::Yubikey_WebClient::yubikey_webclient(
        $otp, $self->api_id, $self->api_key
    );
    unless ($result eq 'OK') {
        $c->log->error("User auth failed: $result");
        return;
    }

    # The user ID is the first 2-12 characters.. but the next part is always
    # 32 characters.
    my $yubi_id = substr($otp, 0, -32);
    my $user = $realm->find_user({ $self->id_for_store => $yubi_id }, $c);
    unless ($user) {
        $c->log->error("Authenticated user, but could not locate in "
            ." our Store!");
        return;
    }
    return $user;
}

=head1 AUTHOR

Toby Corkindale, C<< <tjc at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-authentication-credential-yubikey at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Authentication-Credential-YubiKey>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Authentication::Credential::YubiKey

You can also look for information at:
http://github.com/TJC/Catalyst-Authentication-Credential-YubiKey

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Authentication-Credential-YubiKey>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Authentication-Credential-YubiKey>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Authentication-Credential-YubiKey>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Authentication-Credential-YubiKey/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010-2012 Toby Corkindale, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
1;
