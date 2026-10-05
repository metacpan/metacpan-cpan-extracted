package Airlock::Factor::Callback;

# ABSTRACT: Second factor checked by the host application

use Moo;
with 'Airlock::Factor';
use Types::Standard qw( CodeRef );
use namespace::autoclean;

our $VERSION = '0.001';


has _verify => (
  is       => 'ro',
  isa      => CodeRef,
  init_arg => 'verify',
  required => 1
);


has _available => (
  is        => 'ro',
  isa       => CodeRef,
  init_arg  => 'available',
  predicate => '_has_available'
);


sub verify {
  my ( $self, $subject, $proof ) = @_;
  return $self->_verify->( $subject, $proof ) ? 1 : 0;
}

sub available_for {
  my ( $self, $subject ) = @_;
  return 1 unless $self->_has_available;
  return $self->_available->($subject) ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Airlock::Factor::Callback - Second factor checked by the host application

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $factor = Airlock::Factor::Callback->new(
      name   => 'totp',
      amr    => 'otp',
      verify => sub {
        my ( $subject, $proof ) = @_;
        return $directory->check_totp( $subject->{id}, $proof );
      },
    );

=head1 DESCRIPTION

For a host application that already has a second factor somewhere else, for
example in its directory server. Airlock hands over subject and proof and
takes the answer.

=head2 verify

Required. Coderef called with the subject and the proof; returns true when the
proof holds.

=head2 available

Optional. Coderef called with the subject; returns true when the subject can
use this factor. Without it the factor is available to everyone.

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
