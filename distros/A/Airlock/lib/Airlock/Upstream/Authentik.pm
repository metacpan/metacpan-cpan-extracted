package Airlock::Upstream::Authentik;

# ABSTRACT: Use an authentik login as the subject of an Airlock approval

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


sub reauth_params {
  my ( $self, %arg ) = @_;
  croak __PACKAGE__.'->reauth_params cannot use a max_age of 0: authentik ignores it. '
    .'Leave max_age out for prompt=login, or give the seconds the factor uses.'
    if exists $arg{max_age} && defined $arg{max_age} && !$arg{max_age};
  return {
    ( defined $arg{max_age} ? ( max_age => $arg{max_age} ) : ( prompt => 'login' ) ),
    @{ $self->mfa_acr } ? ( acr_values => join ' ', @{ $self->mfa_acr } ) : ()
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

Airlock::Upstream::Authentik - Use an authentik login as the subject of an Airlock approval

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $authentik = Airlock::Upstream::Authentik->new;

    my $airlock = Airlock->new(
      policy  => { always => ['upstream'] },
      factors => [ $authentik->factor( max_age => 300 ) ],
      ...
    );

    # in the approval action, with the claims of the person's ID token
    my $result = $airlock->approve( $code, subject => $authentik->subject($claims) );

=head1 DESCRIPTION

When the host application logs people in through authentik, this class turns
the token claims into the subject L<Airlock> wants, and builds the
L<Airlock::Factor::Upstream> that recognises an authentik login with a second
factor.

Unlike L<Airlock::Upstream::Keycloak>, there is nothing to configure in
authentik first. These are the claims of authentik 2026.8.3, observed through
the whole chain in F<t/91-live-authentik.t>, with the default flows and no
mapper added:

=over 4

=item *

A password login carries C<< amr => ['pwd'] >>, a login with TOTP
C<< amr => [ 'pwd', 'mfa' ] >>. The default L</mfa_amr> recognises C<mfa>, so
the factor tells the two apart out of the box.

=item *

C<acr> is C<goauthentik.io/providers/oauth2/default> for both, and is of no
use here. L</mfa_acr> is therefore empty, and C<acr_values> in an
authorization request does not change it either.

=item *

C<auth_time> is the moment the B<session> began, not the moment the token was
minted, and it survives both a refresh and further authorization requests.
That is what L<Airlock::Factor::Upstream/max_age> wants: it measures how old
the authentication is, not how fresh the token is. A token minted now from a
session that is ten minutes old is correctly refused by
C<< max_age => 300 >>.

=item *

C<amr> and C<auth_time> are the same in the ID token and the access token.
(Introspection would say the same, but it needs a confidential client; the
public one the test uses gets C<< { active: false } >> and nothing else.)

=back

Two qualifications on C<auth_time>, both read in authentik's source rather
than provoked here. A client-credentials or token-exchange grant sets it to
the minting time, not to a login — harmless for this factor, which refuses
anything without an C<amr>, but it is not the session's time there. And when
authentik finds no login event for a session, it falls back to the current
time, so an old authentication can look new: that direction B<fails open>, and
C<max_age> cannot catch it.

=head2 Asking for a fresh authentication

L<Airlock::Factor::Upstream/reauth_params> returns C<< max_age => 0 >>, which
is what OpenID Connect says for "authenticate this person again". B<authentik
2026.8.3 throws that one value away>: its authorization endpoint only looks at
C<max_age> when it is true, and zero is not, so a code comes back at once with
the C<auth_time> of the old session.

Every other value works. Measured against a session six seconds old:

    no parameter     a code, no new login
    max_age=0        a code, no new login      <- what reauth_params sends
    max_age=1        sent back to log in
    max_age=2        sent back to log in
    max_age=3600     a code, no new login      (the session is younger)
    prompt=login     sent back to log in

So the escape hatch is not broken here, it is one value off. L</reauth_params>
gives the parameters that do work on authentik; use them in place of the
factor's.

=head2 reauth_params

    my $params = $authentik->reauth_params;         # { prompt => 'login' }
    my $params = $authentik->reauth_params( max_age => 300 );

What to add to the authorization request to send someone back for a fresh
login. C<prompt=login> is plain OpenID Connect, authentik honours it, and
unlike C<max_age> it does not depend on how old the session happens to be.

With C<max_age> it asks for an authentication no older than that many seconds
instead — the same number you gave the factor, so the two agree on what counts
as too old. A C<max_age> of 0 is refused rather than sent, because authentik
would ignore it.

=head2 Requiring the second factor in authentik

Nothing here forces anyone to use TOTP; it reports what happened. To make
authentik insist, set C<not_configured_action> on the Authenticator Validation
stage of the authentication flow from C<skip> to C<deny> (a person without a
configured authenticator is refused) or to C<configure> (they are sent through
the setup stage first, which also needs C<configuration_stages>).
F<t/authentik/setup.pl> does neither; it builds the test fixtures and leaves
the stage alone, because the live test wants both kinds of login.

=head2 mfa_amr

C<amr> values that mean a second factor was used. authentik writes C<mfa>,
which the default covers.

=head2 mfa_acr

C<acr> values that mean a second factor was used. Empty, and worth leaving
empty: authentik sends one constant C<acr> whatever happened.

=head2 subject

    my $subject = $authentik->subject($claims);

The Airlock subject for a set of token claims: C<id> from C<sub>, and C<amr>,
C<acr> and C<auth_time> as authentik sent them. Croaks without C<sub>.

C<sub> is the provider's C<sub_mode>, by default a hash of the user's id, so
it differs between two applications of one authentik. That is fine for Airlock,
which only compares it with itself, but it is not a user id to store.

=head2 factor

    my $factor = $authentik->factor( max_age => 300 );

An L<Airlock::Factor::Upstream> that holds for an authentik login with a
second factor. Takes its options.

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
