package Airlock::Factor;

# ABSTRACT: Role for a second factor that secures an Airlock approval

use Types::Standard qw( Str );
use Moo::Role;

our $VERSION = '0.001';


requires 'verify';


has name => (
  is       => 'ro',
  isa      => Str,
  required => 1
);


has amr => (
  is       => 'ro',
  isa      => Str,
  required => 1
);


sub commit { 1 }


sub needs_proof { 1 }


sub available_for { 1 }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Airlock::Factor - Role for a second factor that secures an Airlock approval

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    package My::Factor;
    use Moo;
    with 'Airlock::Factor';

    sub verify {
      my ( $self, $subject, $proof ) = @_;
      return $proof eq 'open sesame' ? 1 : 0;
    }

=head1 DESCRIPTION

A factor answers one question: does this proof, from this subject, hold?
L<Airlock::Policy> decides which factors an approval needs; L<Airlock> asks
each of them and only then lets the request through.

=head2 verify

    $factor->verify( $subject, $proof )

Required of the consumer. Returns true when the proof holds. Must not throw
for a wrong proof.

=head2 name

Required. The name a policy refers to, and the key under which the proof
arrives in C<< approve( proofs => { ... } ) >>.

=head2 amr

Required. The Authentication Method Reference (RFC 8176) this factor adds to
the grant once it has verified, for example C<otp>.

=head2 commit

    $factor->commit( $subject, $proof )

Called once every factor of an approval has verified. A factor whose proof may
be used only once records that here, not in C<verify>, so that a proof is not
used up when another factor fails. Returns true; a false return fails the
approval.

=head2 needs_proof

True when the person has to supply something. A factor that only looks at the
subject returns false and is checked without a proof.

=head2 available_for

    $factor->available_for($subject)

True when the subject can use this factor at all, for example has enrolled.

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
