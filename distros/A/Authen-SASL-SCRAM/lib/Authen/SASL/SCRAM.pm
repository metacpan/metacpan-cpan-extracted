
use strict;
use warnings;

use Feature::Compat::Try;

package Authen::SASL::SCRAM;

=head1 NAME

Authen::SASL::SCRAM - SCRAM support for Authen::SASL

=head1 VERSION

0.04

=head1 SYNOPSIS

   # with Authen::SASL::SCRAM installed
   use Authen::SASL;

   my $client = Authen::SASL->new(
        username => 'user',
        password => 'pass',
        mechanism => 'SCRAM-SHA-512 SCRAM-SHA-256 SCRAM-SHA-1 PLAIN'
   );
   # authenticates using SCRAM SHA hash or PLAIN


   my $salt = 'your-precious-salt';
   # $server_key and $stored_key need to be looked up from a user store
   my $server_key = 'server-key-stored-for-this-user';
   my $stored_key = 'key-stored-for-this-user';
   my $server => Authen::SASL->new(
       mechanism => 'SCRAM-SHA-1', # selected mechanism
       callback => {
            getsecret => sub {
                 my $username = shift;
                 return ($salt, $stored_key, $server_key, $iterations);
            },
       }
   );


=head1 DESCRIPTION

The C<Authen::SASL::SCRAM> distribution adds L<Authen::SASL> support for
SCRAM authentication using the mechanisms listed below by wrapping
L<Authen::SCRAM>.

=over

=item SHA-1 (SCRAM-SHA-1)

=item SHA-256 (SCRAM-SHA-256)

=item SHA-512 (SCRAM-SHA-512)

=back

The *-PLUS variants are not supported at this time.

=cut

use Authen::SASL;

use parent qw(Authen::SASL::Perl);

use Authen::SCRAM::Client;
use Authen::SCRAM::Server;


our @VERSION = '0.04';

my %secflags = (
  noplaintext => 1,
  noanonymous => 1,
);

sub _secflags {
  shift;
  scalar grep { $secflags{$_} } @_;
}


sub client_start {
    my $self = shift;

    $self->{need_step} = 2;
    $self->{error}     = undef;

    my $user = $self->_call('user');
    return $self->set_error( 'Username is required' )
        unless defined $user;

    my $pass = $self->_call('pass');
    return $self->set_error( 'Password is required' )
        unless defined $pass;

    $self->{_client}   = Authen::SCRAM::Client->new(
        digest   => $self->digest,
        username => $user,
        password => $pass,
        );

    return $self->{_client}->first_msg();
}

sub client_step {
    my $self = shift;
    my $challenge = shift;

    $self->{need_step}--;
    if ($self->{need_step} == 1) {
        try {
            return $self->{_client}->final_msg( $challenge );
        }
        catch ($e) {
            return $self->set_error( 'Challenge failed (step 1)' );
        }
    }
    else {
        try {
            return $self->{_client}->validate( $challenge );
        }
        catch ($e) {
            return $self->set_error( 'Response failed (step 2)' );
        }
    }
}

sub mechanism {
    my $self = shift;
    return 'SCRAM-' . $self->digest;
}


sub server_start {
    my $self = shift;
    my $client_first = shift;

    $self->{need_step} = 1;
    $self->{_server}   = Authen::SCRAM::Server->new(
        digest        => $self->digest,
        credential_cb => $self->callback('getsecret')
        );

    try {
        return $self->{_server}->first_msg( $client_first );
    }
    catch ($e) {
        return $self->set_error( 'Client initiation failed' );
    }
}

sub server_step {
    my $self = shift;
    my $client_final = shift;

    $self->{need_step}--;
    try {
        my $rv = $self->{_server}->final_msg( $client_final );
        $self->property( 'authname', $self->{_server}->authorization_id );
        return $rv;
    }
    catch ($e) {
        return $self->set_error( 'Client finalization failed' );
    }
}

=head1 BUGS

Please report bugs via
L<https://github.com/ehuelsmann/authen-sasl-scram/issues>.

=head1 SEE ALSO

L<Authen::SASL>, L<Authen::SCRAM>

=head1 AUTHOR

Erik Huelsmann <ehuels@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2023 Erik Huelsmann. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

1;
