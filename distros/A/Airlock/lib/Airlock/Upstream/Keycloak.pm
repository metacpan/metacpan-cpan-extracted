package Airlock::Upstream::Keycloak;

# ABSTRACT: Use a Keycloak login as the subject of an Airlock approval

use Moo;
use Airlock::Factor::Upstream;
use Carp qw( croak );
use Types::Standard qw( ArrayRef Str );
use namespace::autoclean;

our $VERSION = '0.001';


has mfa_amr => (
  is      => 'ro',
  isa     => ArrayRef[Str],
  default => sub { [qw( mfa otp hwk )] }
);


has mfa_acr => (
  is      => 'ro',
  isa     => ArrayRef[Str],
  default => sub { [] }
);


sub factor_class { 'Airlock::Factor::Upstream' }

sub subject {
  my ( $self, $claims ) = @_;
  croak __PACKAGE__.'->subject needs claims with a sub'
    unless ref $claims eq 'HASH' && defined $claims->{sub} && length $claims->{sub};
  my $amr = $claims->{amr};
  return {
    id        => $claims->{sub},
    amr       => ref $amr eq 'ARRAY' ? [@$amr] : defined $amr ? [ split ' ', $amr ] : [],
    acr       => $claims->{acr},
    auth_time => $claims->{auth_time}
  };
}


sub factor {
  my ( $self, %arg ) = @_;
  return $self->factor_class->new( accept_amr => $self->mfa_amr, accept_acr => $self->mfa_acr, %arg );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Airlock::Upstream::Keycloak - Use a Keycloak login as the subject of an Airlock approval

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $keycloak = Airlock::Upstream::Keycloak->new;

    my $airlock = Airlock->new(
      policy  => { always => ['upstream'] },
      factors => [ $keycloak->factor( max_age => 300 ) ],
      ...
    );

    # in the approval action, with the claims of the person's ID token
    my $result = $airlock->approve( $code, subject => $keycloak->subject($claims) );

=head1 DESCRIPTION

When the host application logs people in through Keycloak, this class turns
the token claims into the subject L<Airlock> wants, and builds the
L<Airlock::Factor::Upstream> that recognises a Keycloak login with a second
factor.

A Keycloak realm in its default configuration does not report a second factor
in the token: with Keycloak 26.8.0 a password login and a login with TOTP both
carry C<acr=1> and no C<amr>. Two settings change that:

=over 4

=item *

the client, or a client scope it uses, has the protocol mapper
I<Authentication Method Reference (AMR)> (C<oidc-amr-mapper>);

=item *

the steps of the authentication flow carry a reference value
(C<default.reference.value>, with C<default.reference.maxAge>), for example
C<pwd> on the password form and C<otp> on the OTP form.

=back

A login with TOTP then carries C<< amr => [ 'pwd', 'otp' ] >>, which the
default L</mfa_amr> recognises. F<t/keycloak/setup.pl> in the distribution does
the second part through the Admin REST API, and F<t/90-live-keycloak.t> checks
the whole chain against a running Keycloak.

=head2 mfa_amr

C<amr> values that mean a second factor was used.

=head2 mfa_acr

C<acr> values that mean a second factor was used.

=head2 subject

    my $subject = $keycloak->subject($claims);

The Airlock subject for a set of token claims: C<id> from C<sub>, and C<amr>,
C<acr> and C<auth_time> as Keycloak sent them. Croaks without C<sub>.

=head2 factor

    my $factor = $keycloak->factor( max_age => 300 );

An L<Airlock::Factor::Upstream> that holds for a Keycloak login with a second
factor. Takes its options.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-airlock/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
