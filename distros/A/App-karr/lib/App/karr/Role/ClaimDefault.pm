# ABSTRACT: Default a command's claim name from KARR_CLAIM when the flag is omitted

package App::karr::Role::ClaimDefault;
our $VERSION = '0.601';
use Moo::Role;
# Loaded without importing, and every call below is qualified. A Moo::Role
# composes every sub in its package into its consumers, imported ones included
# (#38), so an imported from_octets_from_env would land as a method on every
# command that takes a claim.
use App::karr::Encoding ();


sub env_claim {
  my ($self) = @_;
  my $raw = $ENV{KARR_CLAIM};
  return undef unless defined $raw && length $raw;
  return App::karr::Encoding::from_octets_from_env($raw);
}


sub has_env_claim {
  my ($self) = @_;
  return ( defined $ENV{KARR_CLAIM} && length $ENV{KARR_CLAIM} ) ? 1 : 0;
}


sub resolved_claim {
  my ($self) = @_;
  return $self->claim if defined $self->claim && length $self->claim;
  return $self->env_claim;
}


sub resolved_claimed_by {
  my ($self) = @_;
  return $self->claimed_by if defined $self->claimed_by && length $self->claimed_by;
  return $self->env_claim;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::ClaimDefault - Default a command's claim name from KARR_CLAIM when the flag is omitted

=head1 VERSION

version 0.601

=head1 DESCRIPTION

The one place the C<--claim> default is resolved. ADR 0005 carries the claim
name per process in the C<KARR_CLAIM> environment variable: every command that
takes C<--claim> (L<App::karr::Cmd::Move>, L<App::karr::Cmd::Handoff>,
L<App::karr::Cmd::Pick>, L<App::karr::Cmd::Edit>, L<App::karr::Cmd::Create>) and
C<karr list --claimed-by> (L<App::karr::Cmd::List>) defaults to C<$KARR_CLAIM>
when the flag is omitted. An explicit value on the command line always wins;
there is no silent fallback to anything else. C<create> is the one narrower
consumer: it reads the default only when C<--status> names a column that
requires a claim (ticket #286), so a card filed for whoever picks it next
stays unclaimed.

The seven C<option claim> / C<option claimed_by> declarations differ in wording
and in whether they were C<required> (pick and handoff were), so they are left
where they are; what is shared is only the resolution -- L</resolved_claim> and
L</resolved_claimed_by> -- so no command reads C<$ENV{KARR_CLAIM}> or decodes it
itself.

C<KARR_CLAIM> crosses the character/octet boundary like every environment value
(CLAUDE.md, "characters inside, octets only at the edges"):
L<App::karr::Encoding/from_octets_from_env> decodes it here, the mirror of the
C<to_octets_for_env> path L<App::karr::Foundation::Runner> writes it through.

=head2 env_claim

    my $name = $self->env_claim;   # decoded KARR_CLAIM, or undef

The claim name from C<KARR_CLAIM>, decoded to a character string, or C<undef>
when the variable is unset or empty.

=head2 has_env_claim

    ... if $self->has_env_claim;

True when C<KARR_CLAIM> holds a non-empty value. A presence test, so it does
not decode -- the value never crosses the boundary here, only its emptiness is
asked.

=head2 resolved_claim

    my $claim = $self->resolved_claim;

The effective claim for a command that declares C<option claim>: the explicit
C<--claim> value when one was given, otherwise L</env_claim>. Used everywhere a
command used to read C<< $self->claim >> for claiming.

=head2 resolved_claimed_by

    my $owner = $self->resolved_claimed_by;

The C<list --claimed-by> counterpart of L</resolved_claim>, reading
C<option claimed_by>: the explicit filter value, otherwise L</env_claim>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
