package Authen::SASL::Perl::NTLM;
# ABSTRACT: NTLM authentication plugin for Authen::SASL
$Authen::SASL::Perl::NTLM::VERSION = '0.003';
use 5.006;
use strict;
use warnings;

use Authen::NTLM ();
use MIME::Base64 ();

use parent qw(Authen::SASL::Perl);

# do we need these?
# sub _order { 1 }
# sub _secflags { 0 };

sub mechanism { 'NTLM' } ## no critic (RequireFinalReturn)

#
# Initialises the NTLM object and sets the domain, host, user, and password.
#
sub client_start {
    my ($self) = @_;

    $self->{need_step} = 1;
    $self->{error}     = undef;
    $self->{stage}     = 0;

    my $user = $self->_call('user');

    # Check for the domain in the username
    my $domain;
    ( $domain, $user ) = split m{ \\ }xms, $user
      if index( $user, q{\\} ) > -1;

    $self->{ntlm} = Authen::NTLM->new(
        host     => $self->host,
        domain   => $domain,
        user     => $user,
        password => $self->_call('pass'),
    );

    return q{};
}

#
# If C<$challenge> is undefined, it will return a NTLM type 1 request
# message.
# Otherwise, C<$challenge> is assumed to be a NTLM type 2 challenge from
# which the NTLM type 3 response will be generated and returned.
#
sub client_step {
    my ( $self, $challenge ) = @_;

    if ( defined $challenge ) {
        # The challenge has been decoded but Authen::NTLM expects it encoded
        $challenge = MIME::Base64::encode_base64($challenge);

        # Empty challenge string needs to be undef if we want
        # Authen::NTLM::challenge() to generate a type 1 message
        $challenge = undef if $challenge eq q{};
    }

    my $stage = ++$self->{stage};
    if ( $stage == 1 ) {
        $self->set_error('Challenge must not be given for type 1 request')
          if $challenge;
    }
    elsif ( $stage == 2 ) {
        $self->set_success; # no more steps
        $self->set_error('No challenge was given for type 2 request')
          if !$challenge;
    }
    else {
        $self->set_error('Invalid step');
    }
    return q{} if $self->error;

    my $response = $self->{ntlm}->challenge($challenge);

    # The caller expects the response to be unencoded but
    # Authen::NTLM::challenge() has already encoded it
    return MIME::Base64::decode_base64($response);
}

1;

__END__

=pod

=head1 NAME

Authen::SASL::Perl::NTLM - NTLM authentication plugin for Authen::SASL

=for html
<a href="https://travis-ci.org/stevenl/Authen-SASL-Perl-NTLM"><img src="https://travis-ci.org/stevenl/Authen-SASL-Perl-NTLM.svg?branch=master" alt="Build Status"></a>
<a href='https://coveralls.io/r/stevenl/Authen-SASL-Perl-NTLM?branch=master'><img src='https://coveralls.io/repos/stevenl/Authen-SASL-Perl-NTLM/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Authen::SASL qw(Perl);

    $sasl = Authen::SASL->new(
        mechanism => 'NTLM',
        callback  => {
            user => $username, # or "$domain\\$username"
            pass => $password,
        },
    );

    $client = $sasl->client_new(...);
    $client->client_start;
    $client->client_step('');
    $client->client_step($challenge);

=head1 DESCRIPTION

This module is a plugin for the L<Authen::SASL> framework that implements the
client procedures to do NTLM authentication.

Most users will probably only need this module indirectly, when you use
another module that depends on Authen::SASL with NTLM authentication.
E.g. connecting to an MS Exchange Server using Email::Sender, which
depends on Net::SMTP(S) which in turn depends on Authen::SASL.

You may see this when you get the following error message:

    No SASL mechanism found

(Unfortunately, Authen::SASL currently doesn't tell you which SASL mechanism
is missing.)

=head1 CALLBACK

The callbacks used are:

=head2 Client

=over 4

=item user

The username to be used for authentication. The domain may optionally be
specified as part of the C<user> string in the format C<"$domain\\$username">.

=item pass

The user's password to be used for authentication.

=back

=head2 Server

This module does not support server-side authentication.

=head1 SEE ALSO

L<Authen::SASL>, L<Authen::SASL::Perl>.

=for Pod::Coverage mechanism client_start client_step

=head1 AUTHOR

Steven Lee <stevenwh.lee@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steven Lee.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
