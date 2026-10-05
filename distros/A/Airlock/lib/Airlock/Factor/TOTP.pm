package Airlock::Factor::TOTP;

# ABSTRACT: Time-based one-time password (RFC 6238) as an Airlock factor

use Moo;
with 'Airlock::Factor';
use Airlock::Code;
use Carp qw( croak );
use Crypt::URandom qw( urandom );
use Digest::SHA qw( hmac_sha1 );
use Types::Standard qw( CodeRef Int );
use namespace::autoclean;

our $VERSION = '0.001';


has '+name' => ( default => 'totp' );
has '+amr'  => ( default => 'otp' );

has _secret => (
  is       => 'ro',
  isa      => CodeRef,
  init_arg => 'secret',
  required => 1
);


has _last_step => (
  is       => 'ro',
  isa      => CodeRef,
  init_arg => 'last_step',
  required => 1
);


has _accept_step => (
  is       => 'ro',
  isa      => CodeRef,
  init_arg => 'accept_step',
  required => 1
);


has digits => (
  is      => 'ro',
  isa     => Int,
  default => 6
);


has period => (
  is      => 'ro',
  isa     => Int,
  default => 30
);


has window => (
  is      => 'ro',
  isa     => Int,
  default => 1
);


has now => (
  is      => 'ro',
  isa     => CodeRef,
  default => sub { sub { time } }
);


sub code_class { 'Airlock::Code' }

sub code_at {
  my ( $self, $secret, $step ) = @_;
  my $counter = pack 'NN', int( $step / 4294967296 ), $step % 4294967296;
  my $mac     = hmac_sha1( $counter, $secret );
  my $offset  = ord( substr $mac, -1 ) & 0x0f;
  my $number  = unpack( 'N', substr $mac, $offset, 4 ) & 0x7fffffff;
  return sprintf '%0'.$self->digits.'d', $number % ( 10**$self->digits );
}


sub available_for {
  my ( $self, $subject ) = @_;
  my $secret = $self->_secret->($subject);
  return defined $secret && length $secret ? 1 : 0;
}

# The time step this proof is valid for, or nothing. Every step of the window
# is computed whether or not an earlier one matched.
sub _step {
  my ( $self, $subject, $proof ) = @_;
  return unless defined $proof;
  $proof =~ s/\s//g;
  return unless $proof =~ /\A[0-9]+\z/ && length $proof == $self->digits;
  my $secret = $self->_secret->($subject);
  return unless defined $secret && length $secret;
  my $current = int( $self->now->() / $self->period );
  my $hit;
  for my $step ( $current - $self->window .. $current + $self->window ) {
    next unless $self->code_class->equals( $self->code_at( $secret, $step ), $proof );
    $hit = $step;
  }
  return unless defined $hit;
  my $last = $self->_last_step->($subject);
  return if defined $last && $hit <= $last;
  return $hit;
}

sub verify {
  my ( $self, $subject, $proof ) = @_;
  return defined $self->_step( $subject, $proof ) ? 1 : 0;
}

sub commit {
  my ( $self, $subject, $proof ) = @_;
  my $step = $self->_step( $subject, $proof );
  return 0 unless defined $step;
  return $self->_accept_step->( $subject, $step ) ? 1 : 0;
}


sub generate_secret { urandom(20) }


sub base32 {
  my ( $self, $bytes ) = @_;
  my @alphabet = ( 'A' .. 'Z', '2' .. '7' );
  my $bits     = unpack 'B*', $bytes;
  $bits .= '0' x ( ( 5 - length($bits) % 5 ) % 5 );
  return join '', map { $alphabet[ oct '0b'.$_ ] } $bits =~ /(.{5})/g;
}


sub otpauth_uri {
  my ( $self, %arg ) = @_;
  for (qw( secret account issuer )) {
    croak __PACKAGE__.'->otpauth_uri needs '.$_ unless defined $arg{$_} && length $arg{$_};
  }
  return 'otpauth://totp/'.$self->_escape( $arg{issuer} ).':'.$self->_escape( $arg{account} )
    .'?secret='.$self->base32( $arg{secret} )
    .'&issuer='.$self->_escape( $arg{issuer} )
    .'&algorithm=SHA1&digits='.$self->digits.'&period='.$self->period;
}


sub _escape {
  my ( $self, $text ) = @_;
  utf8::encode($text) if utf8::is_utf8($text);
  $text =~ s/([^A-Za-z0-9\-._~])/sprintf '%%%02X', ord $1/ge;
  return $text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Airlock::Factor::TOTP - Time-based one-time password (RFC 6238) as an Airlock factor

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $totp = Airlock::Factor::TOTP->new(
      secret      => sub { my ( $subject ) = @_; $db->totp_secret( $subject->{id} ) },
      last_step   => sub { my ( $subject ) = @_; $db->totp_step( $subject->{id} ) },
      accept_step => sub { my ( $subject, $step ) = @_; $db->set_totp_step( $subject->{id}, $step ) },
    );

    # enrolment
    my $secret = $totp->generate_secret;
    my $uri    = $totp->otpauth_uri( secret => $secret, account => 'getty@example.org', issuer => 'Mothership' );

=head1 DESCRIPTION

TOTP with HMAC-SHA1, which is what authenticator apps implement. Airlock stores
nothing itself: the secret and the last accepted time step come from the host
application through three coderefs.

A code is accepted once. C<last_step> and C<accept_step> are what make that
true, which is why both are required.

=head2 secret

Required. Coderef called with the subject; returns the raw secret bytes, or
nothing (or an empty string) when the subject has not enrolled.

=head2 last_step

Required. Coderef called with the subject; returns the last accepted time
step, or nothing when there is none yet.

=head2 accept_step

Required. Coderef called with the subject and the time step that is being
accepted. It stores the step, so the same code cannot be used again, and
returns true. Where two requests can arrive at once, store only if the new
step is greater than the stored one and return false otherwise; the approval
then fails instead of accepting one code twice.

=head2 digits

Length of a code. Default 6.

=head2 period

Seconds per time step. Default 30.

=head2 window

Time steps accepted before and after the current one, for clock drift.
Default 1.

=head2 now

Coderef returning the current epoch. For tests.

=head2 code_at

    my $code = $totp->code_at( $secret, int( time / 30 ) );

The code for a secret at a time step.

=head2 commit

    $totp->verify( $subject, $proof ) && $totp->commit( $subject, $proof )

Uses the code up. L<Airlock> calls this after every factor has verified; code
that uses this class on its own has to call it after C<verify>.

=head2 generate_secret

    my $secret = $totp->generate_secret;

Twenty random bytes for a new enrolment.

=head2 base32

    my $text = $totp->base32($secret);

RFC 4648 base32 without padding, the form authenticator apps take.

=head2 otpauth_uri

    my $uri = $totp->otpauth_uri( secret => $secret, account => 'getty@example.org', issuer => 'Mothership' );

The C<otpauth://> URI for enrolment. Feed it to L<Airlock::QR>.

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
