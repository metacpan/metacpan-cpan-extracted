package Amazon::CreatorsAPI;
use strict;
use warnings;
use Carp qw/croak/;
use JSON qw//;
use HTTP::Tiny;
use Amazon::CreatorsAPI::Auth;
use Class::Accessor::Lite (
    ro  => [qw/
        credential_id
        credential_secret
        credential_version
        partner_tag
        marketplace
        ua
        auth_manager
        operation_endpoint
    /],
);

our $VERSION = '0.01';

our $JSON = JSON->new;

sub new {
    my $class              = shift;
    my $credential_id      = shift or croak 'credential_id is required';
    my $credential_secret  = shift or croak 'credential_secret is required';
    my $credential_version = shift or croak 'credential_version is required';
    my $opt                = shift || +{};

    if (!$opt->{ua}) {
        $opt->{ua} = HTTP::Tiny->new;
    }

    bless +{
        credential_id      => $credential_id,
        credential_secret  => $credential_secret,
        credential_version => $credential_version,
        partner_tag        => $opt->{partner_tag} || '',
        marketplace        => $opt->{marketplace} || 'www.amazon.com',
        ua                 => $opt->{ua},
        auth_manager       => Amazon::CreatorsAPI::Auth->new(
            $credential_id,
            $credential_secret,
            $credential_version,
            $opt,
        ),
        operation_endpoint => $opt->{operation_endpoint} || 'https://creatorsapi.amazon/catalog/v1',
    }, $class;
}

sub get_browse_nodes {
    return shift->operation('getBrowseNodes', @_);
}

sub get_items {
    return shift->operation('getItems', @_);
}

sub get_variations {
    return shift->operation('getVariations', @_);
}

sub search_items {
    return shift->operation('searchItems', @_);
}

sub operation {
    my $self      = shift;
    my $operation = shift || '';
    my $params    = shift || +{};

    my $res = $self->ua->request(
        'POST',
        $self->operation_endpoint . '/' . $operation,
        {
            'headers' => {
                'Authorization' => $self->_auth_header,
                'Content-Type' => 'application/json',
                'x-marketplace' => $self->marketplace,
            },
            'content' => $JSON->encode({
                partnerTag => $self->partner_tag,
                marketplace => $self->marketplace,
                %{$params},
            }),
        },
    );

    if (!$res->{success}) {
        croak "failed $operation status:$res->{status} "
            . ($res->{reason} || 'reason_unknown')
            . ", $res->{content}";
    }

    my $res_data = +{};
    eval {
        $res_data = $JSON->decode($res->{content});
    };
    if (my $e = $@) {
        croak "could not JSON decode, $e : " . $res->{content};
    }

    return $res_data;
}

sub _auth_header {
    my $self = shift;

    my $am = $self->auth_manager;
    my $token = $am->get_access_token;

    return "Bearer $token" . (
        !$am->is_lwa ? ', Version ' . $self->credential_version : ''
    );
}

1;

__END__

=encoding UTF-8

=head1 NAME

Amazon::CreatorsAPI - The Amazon Creators API Helper


=head1 SYNOPSIS

    use Amazon::CreatorsAPI;
    use Data::Dumper;

    my $api = Amazon::CreatorsAPI->new(
        "{credential_id}",
        "{credential_secret}",
        "{credential_version}",
        {
            partner_tag => "{partner_tag}",
            marketplace => '{www.amazon.com}',
        },
    );

    my $res = $api->search_items({
        keywords => "{search_keyword}",
        resources => [
            'itemInfo.title',
        ],
    });

    print Dumper($res);


=head1 DESCRIPTION

What is the Amazon Creators API?

https://affiliate-program.amazon.com/creatorsapi/docs/en-us/introduction

See B<example/> directory of this module.

L<https://github.com/bayashi/Amazon-CreatorsAPI/tree/main/example>


=head1 METHODS

=head2 new

constructor

=head2 get_browse_nodes($api_params)

=head2 get_items($api_params)

=head2 get_variations($api_params)

=head2 search_items($api_params)

=head2 operation($operation, $api_params)

C<operation> method is the low level interface to call Amazon Creators API for operations not yet wrapped by helper methods in this module.

Amazon Creator API Reference: https://affiliate-program.amazon.com/creatorsapi/docs/en-us/api-reference

Locale Reference: https://affiliate-program.amazon.com/creatorsapi/docs/en-us/locale-reference


=head1 REPOSITORY

=begin html

<a href="https://github.com/bayashi/Amazon-CreatorsAPI/blob/main/README.md"><img src="https://img.shields.io/badge/Version-0.01-green?style=flat"></a> <a href="https://github.com/bayashi/Amazon-CreatorsAPI/blob/main/LICENSE"><img src="https://img.shields.io/badge/LICENSE-Artistic%202.0-GREEN.png"></a> <a href="https://github.com/bayashi/Amazon-CreatorsAPI/actions"><img src="https://github.com/bayashi/Amazon-CreatorsAPI/workflows/main/badge.svg"/></a>

=end html

Amazon::CreatorsAPI is hosted on github: L<http://github.com/bayashi/Amazon-CreatorsAPI>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi


=head1 LICENSE

C<Amazon::CreatorsAPI> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
