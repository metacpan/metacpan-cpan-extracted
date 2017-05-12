package Amazon::CloudFront::SignedURL;
use strict;
use warnings;
use Carp;
use Crypt::OpenSSL::RSA;
use Data::Validator;
use MIME::Base64;
use Mouse;
use URI;

our $VERSION = "0.03";

my $validator = Data::Validator->new(
    resource => { isa => 'Str', },
    expires  => {
        isa => 'Int',
        xor => [qw(policy)],
    },
    policy => { isa => 'Str', },
);

has private_key_string => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    trigger  => sub {
        $_[0]->clear_private_key;
    },
);

has private_key => (
    is         => 'ro',
    isa        => 'Crypt::OpenSSL::RSA',
    lazy_build => 1,
);

has key_pair_id => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

sub _build_private_key {
    my $private_key;
    eval { $private_key = Crypt::OpenSSL::RSA->new_private_key( $_[0]->private_key_string() ); };
    if ($@) {
        croak "Private Key Error: Maybe your key is invalid. ($@)";
    }
    $private_key->use_sha1_hash();
    return $private_key;
}

sub generate {
    my $self = shift;
    my $args = $validator->validate(@_);

    my $resource = $args->{resource};
    my $policy   = exists $args->{policy} ? $args->{policy} : undef;
    my $expires  = exists $args->{expires} ? $args->{expires} : undef;

    if ($policy) {
        $policy =~ s/ //g;
    }
    else {
        $policy = sprintf( qq/{"Statement":[{"Resource":"%s","Condition":{"DateLessThan":{"AWS:EpochTime":%d}}}]}/,
            $resource, $expires );
    }
    my $encoded_policy = $self->_encode_url_safe_base64($policy);
    my $signature      = $self->_sign($policy);

    return $self->_create_url( $resource, $expires, $encoded_policy, $signature );
}

sub _encode_url_safe_base64 {
    my ( $self, $str ) = @_;
    my $encoded = encode_base64($str);
    $encoded =~ s/\r|\n//g;
    $encoded =~ tr|+=/|-_~|;
    return $encoded;
}

sub _sign {
    my ( $self, $str ) = @_;
    my $signature = $self->_encode_url_safe_base64( $self->private_key->sign($str) );
    return $signature;
}

sub _create_url {
    my ( $self, $resource, $expires, $policy, $signature ) = @_;
    my $uri = URI->new($resource);
    if ($expires) {
        $uri->query_form(
            'Expires'     => $expires,
            'Signature'   => $signature,
            'Key-Pair-Id' => $self->key_pair_id(),
        );
    }
    else {
        $uri->query_form(
            'Policy'      => $policy,
            'Signature'   => $signature,
            'Key-Pair-Id' => $self->key_pair_id(),
        );
    }
    return $uri->as_string;
}

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
__END__

=encoding utf-8

=head1 NAME

Amazon::CloudFront::SignedURL - A module to generate AWS CloudFront signed URLs.

=head1 SYNOPSIS

    use Amazon::CloudFront::SignedURL;

    my $signed_url = Amazon::CloudFront::SignedURL->new(
        private_key_string => {PRIVATE_KEY},
        key_pair_id        => {KEY_PAIR_ID}
    );

    # create signed url with canned policy
    $signed_url->generate( resource => {RESOURCE_PATH}, expires => {EXPIRES} );

    # create signed url with custom policy
    $signed_url->generate( resource => {RESOURCE_PATH}, policy => {CUSTOM_POLICY} );

=head1 DESCRIPTION

Amazon::CloudFront::SignedURL generates AWS CloudFront signed URLs.

=head1 METHODS

=over 4

=item C<Amazon::CloudFront::SignedURL-E<gt>new(\%args: HashRef)>

Creates a new instance.

Arguments can be:

=over 4

=item * private_key_string

The private key strings.

=item * key_pair_id

The AWS Portal assigned key pair identifier.

=back

=item C<$signed_url-E<gt>generate(\%args: HashRef)>

Generate a signed URL.

Arguments can be:

=over 4

=item * resource

The URL or stream. (required)

=item * expires

The Unix epoch time when the URL is to expire. (xor policy)

=item * policy

The CloudFront policy document. (xor expires)

=back

=back

=head1 LICENSE

Copyright (C) zoncoen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

zoncoen E<lt>zoncoen@gmail.comE<gt>

=cut

