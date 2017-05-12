package Authen::OATH::KeyURI;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

use base 'Class::Accessor::Fast';
use Params::Validate qw(SCALAR);
use URI;
use Convert::Base32 qw(encode_base32);

__PACKAGE__->mk_accessors(qw(
    scheme
    type
    accountname
    secret
    issuer
    algorithm
    digits
    counter
    period
    uri
    is_encoded
));

sub new {
    my $class = shift;
    my @args = @_ == 1 ? %{$_[0]} : @_;
    my %params = Params::Validate::validate_with(
        params => \@args, 
        spec => {
            scheme      => {
                type     => SCALAR,
                default  => q{otpauth},
                optional => 1,
            },
            type        => {
                type     => SCALAR,
                default  => q{totp},
                optional => 1,
            },
            accountname => {
                type     => SCALAR,
            },
            secret      => {
                type     => SCALAR,
            },
            issuer      => {
                type     => SCALAR,
                optional => 1,
            },
            algorithm   => {
                type     => SCALAR,
                optional => 1,
            },
            digits      => {
                type     => SCALAR,
                optional => 1,
            },
            counter     => {
                type     => SCALAR,
                optional => 1,
            },
            period      => {
                type     => SCALAR,
                optional => 1,
            },
            is_encoded  => {
                type     => SCALAR,
                default  => 0,
                optional => 1,
            },
        },
        allow_extra => 0,
    );

    my $self = bless \%params, $class;

    # TODO: more varidation
 
    return $self;
}

sub as_string {
    my $self = shift;
    $self->_generate_uri();
    return $self->uri->as_string;
}

sub as_uri {
    my $self = shift;
    $self->_generate_uri();
    return $self->uri;
}

sub _generate_uri {
    my $self = shift;

    # 1. Scheme
    my $uri = URI->new;
    $uri->scheme($self->scheme);

    # 2. Type and Label
    my $label = 
        ($self->issuer) ? 
            $self->issuer . q{:} . $self->accountname :
            $self->accountname;
    $uri->path(q{//} . $self->type . q{/} . $label);

    # 3. Parameters
    my $params = {
        secret => ($self->is_encoded) ? $self->secret : encode_base32($self->secret),
    };
    $params->{issuer}     = $self->issuer    if $self->issuer;
    $params->{algorithm } = $self->algorithm if $self->algorithm ;
    $params->{digits}     = $self->digits    if $self->digits;

    # hotp only
    $params->{counter}    = $self->counter 
        if ($self->counter && $self->type eq q{hotp});
    # totp only
    $params->{period}     = $self->period
        if ($self->period && $self->type eq q{totp});

    $uri->query_form($params);

    $self->uri($uri);
}

1;
__END__

=encoding utf-8

=head1 NAME

Authen::OATH::KeyURI - Key URI generator for mobile multi factor authenticator app

=head1 SYNOPSIS

    use Authen::OATH::KeyURI;

    # constructor
    my $keyURI = Authen::OATH::KeyURI->new(
        ## required params
        accountname => q{alice@gmail.com},
        secret       => q{example secret}, # raw secret
        issuer      => q{Example},
        ## optional params
        # scheme      => q{otpauth},
        # type        => q{totp},
        # algorithm   => q{SHA1},
        # digits      => 6,
        # counter     => 1,
        # period      => 30,
    );

    # output
    # format : otpauth://TYPE/LABEL?PARAMETERS
    print $keyURI->as_string();
    # otpauth://totp/Example:alice@google.com?secret=mv4gc3lqnrssa43fmnzgk5a&issuer=Example

    # constructor with encoded secret
    my $keyURI = Authen::OATH::KeyURI->new(
        ## required params
        accountname => q{alice@gmail.com},
        secret       => q{mv4gc3lqnrssa43fmnzgk5a}, # base32 encoded secret
        issuer      => q{Example},
        is_encoded  => 1,
    );

    # output
    # format : otpauth://TYPE/LABEL?PARAMETERS
    print $keyURI->as_string();
    # otpauth://totp/Example:alice@google.com?secret=mv4gc3lqnrssa43fmnzgk5a&issuer=Example

=head1 DESCRIPTION

Authen::OATH::KeyURI generates a setting URL for software OTP authenticator.

Please refer to a document of Google for the details of parameter.

L<https://code.google.com/p/google-authenticator/wiki/KeyUriFormat>

=head1 LICENSE

Copyright (C) ritou.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ritou E<lt>ritou.06@gmail.comE<gt>

=cut

