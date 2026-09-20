# ABSTRACT: Role providing the --compact output option

package App::karr::Role::CompactOutput;
our $VERSION = '0.601';
use Moo::Role;
use MooX::Options;


option compact => (
  is => 'ro',
  doc => 'Compact output',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::CompactOutput - Role providing the --compact output option

=head1 VERSION

version 0.601

=head1 DESCRIPTION

Declares C<--compact>, the terse plaintext rendering, for the commands that
actually render one. It is composed by exactly nine commands: C<board>,
C<config>, C<context>, C<dashboard>, C<list>, C<log>, C<metrics>, C<pick> and
C<show>.

C<--compact> used to sit beside C<--json> in L<App::karr::Role::Output>, which
every command with an alternate rendering composes, so all twenty-two of them
advertised C<--compact: Compact output> in C<--help> while only a handful read
the option. On the other thirteen it was accepted and silently thrown away, and
an option that is documented, accepted and then ignored is an answer that looks
like obedience (#254 has the census; #225 and #226 are the same failure on other
options). Splitting the option out of that role is what makes
C<karr move 1 done --compact> answer C<Unknown option: compact> with the usage
and exit C<2>, which is the loud refusal the exit-code contract (ADR 0002) asks
for.

C<--json> stays in L<App::karr::Role::Output> and keeps its own consumers: the
two options are separate questions, and a command may well answer one and not
the other. Where both are composed, C<--json> wins -- the machine-readable
rendering is a payload, not a layout, so it is never reshaped by C<--compact>.

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
