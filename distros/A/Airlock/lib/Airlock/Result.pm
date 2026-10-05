package Airlock::Result;

# ABSTRACT: Outcome of an Airlock operation

use Moo;
use Types::Standard qw( ArrayRef Bool HashRef Str );
use namespace::autoclean;

our $VERSION = '0.001';


has ok => (
  is       => 'ro',
  isa      => Bool,
  required => 1
);


has status => (
  is       => 'ro',
  isa      => Str,
  required => 1
);


has data => (
  is      => 'ro',
  isa     => HashRef,
  default => sub { {} }
);


has missing => (
  is      => 'ro',
  isa     => ArrayRef[Str],
  default => sub { [] }
);


sub oauth {
  my ( $self ) = @_;
  return $self->ok ? [ 200, { %{ $self->data } } ] : [ 400, { error => $self->status } ];
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Airlock::Result - Outcome of an Airlock operation

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $result = $airlock->redeem( device_code => $device_code, client_id => $client_id );

    if ( $result->ok ) { my $token = $result->data->{access_token} }
    else               { warn $result->status }

    my ( $http_status, $json ) = @{ $result->oauth };

=head1 DESCRIPTION

Every L<Airlock> operation that can fail for an ordinary reason returns one of
these instead of throwing. Exceptions are kept for programming errors.

=head2 ok

True when the operation did what was asked.

=head2 status

What happened, as one word. On failure this is the OAuth error code where one
exists (C<authorization_pending>, C<slow_down>, C<access_denied>,
C<expired_token>, C<invalid_grant>, C<invalid_client>, C<invalid_scope>,
C<invalid_request>) or an Airlock reason (C<unknown_code>, C<factor_required>,
C<factor_unavailable>, C<factor_failed>, C<too_many_failures>,
C<reauth_required>).

=head2 data

The payload of a success: the device authorization response after C<open>, the
token response after C<redeem>.

=head2 missing

Names of the factors an approval still needs or that did not hold.

=head2 oauth

    my ( $http_status, $json ) = @{ $result->oauth };

The result as RFC 8628 wants it on the wire: 200 with the payload, or 400 with
C<error>.

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
