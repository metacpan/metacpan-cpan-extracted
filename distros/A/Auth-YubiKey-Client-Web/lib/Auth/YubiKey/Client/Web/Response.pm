package Auth::YubiKey::Client::Web::Response;
{
  $Auth::YubiKey::Client::Web::Response::DIST = 'Auth-YubiKey-Client-Web';
}
$Auth::YubiKey::Client::Web::Response::VERSION = '0.0.2';
use Moo;
use Digest::HMAC_SHA1 'hmac_sha1';
use MIME::Base64;


has request_apikey => (
    is          => 'ro',
    required    => 1,
);

has request_otp => (
    is          => 'ro',
    required    => 1,
);

has request_nonce => (
    is          => 'ro',
    required    => 1,
);

has request_response => (
    is          => 'ro',
    required    => 1,
);

has h => (
    is          => 'rw'
);

has t => (
    is          => 'rw'
);

has otp => (
    is          => 'rw'
);

has nonce => (
    is          => 'rw'
);

has sl => (
    is          => 'rw'
);

has status => (
    is          => 'rw'
);

has public_id => (
    is          => 'rw',
);

has datastring => (
    is          => 'rw',
);


sub BUILDARGS {
    my ( $class, @args ) = @_;
    unshift @args, "attr1" if @args % 2 == 1;

    # store response keys (for later verifying the response signature 'h'
    my %response_for;

    # run through the response blob; extract key=val data
    # - add key, val to @args for object initialisation
    # - store the key, val for later building and verifying the signature
    foreach my $line (split(/\n/,{@args}->{request_response})) {
        if ($line =~ /=/) {
            $line =~ s/\s//g;
            my ($key,$val) = split(/=/,$line,2);
            $response_for{$key}=$val;
            push @args, $key, $val;
        }
    }

    # store the generated response line
    push @args, 'datastring', _build_datastring(\%response_for);

    return {@args};
}

sub _build_datastring {
    my $response_for = shift;
    my @response_blobs;

    foreach my $key (sort keys %{$response_for}) {
        next if $key eq 'h'; # don't include the signature itself
        push @response_blobs,
            sprintf('%s=%s',
                $key,
                $response_for->{$key}
            )
        ;
    }
    
    return join('&', @response_blobs);
}

sub BUILD {
    my $self = shift;

    return if $self->status eq 'NO_SUCH_CLIENT';

    if ($self->otp ne $self->request_otp) {
        $self->status('ERR_MSG_OTP');
        return;
    }

    if ($self->nonce ne $self->request_nonce) {
        $self->status('ERR_MSG_NONCE');
        return;
    }

    my $hmac = encode_base64(
        hmac_sha1(
            $self->datastring,
            decode_base64($self->request_apikey)
        )
    );
    chomp $hmac;

    if ($self->h ne $hmac) {
        $self->status('ERR_SIGNATURE_MISMATCH');
        return;
    }

    # Since the rest of the OTP is always 32 characters, the method to extract
    # the identity is to remove 32 characters from the end and then use the
    # remaining string, which should be 2-16 characters, as the YubiKey
    # identity.
    $self->public_id(
        substr $self->otp, 0, -32
    );
}


sub is_success {
    my $self = shift;
    return !!($self->status eq 'OK');
}

sub is_error {
    my $self = shift;
    return !!($self->status ne 'OK');
}

sub parse_response {
    my $self = shift;
    my $response = shift;
}

1;
# ABSTRACT: Response object when using the Yubico Web API

=pod

=encoding UTF-8

=head1 NAME

Auth::YubiKey::Client::Web::Response - Response object when using the Yubico Web API

=head1 VERSION

version 0.0.2

=head1 CLASS ATTRIBUTES

=head2 request_apikey

=head2 request_otp

=head2 request_nonce

=head2 request_response

=head2 h

=head2 t

=head2 otp

=head2 nonce

=head2 sl

=head2 status

=head2 public_id

=head2 datastring

=head1 PRIVATE METHODS

=head2 BUILDARGS

=head2 BUILD

=head1 METHODS

=head2 is_success

=head2 is_error

=head2 parse_response

Nothing implemented.

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
# vim: ts=8 sts=4 et sw=4 sr sta
