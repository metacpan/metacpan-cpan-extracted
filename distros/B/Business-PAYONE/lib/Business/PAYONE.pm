package Business::PAYONE {
    use Mojo::UserAgent;
    use Digest::SHA qw/hmac_sha256 hmac_sha256_hex hmac_sha256_base64/;
    use Crypt::Mac::HMAC qw( hmac_b64 );
    use DateTime;
    use DateTime::Format::HTTP;
    use Data::Dump qw/dump/;
    use Moo;
    use Carp qw/confess croak/;
    use namespace::clean;
    use version;
    use v5.36;

    our $VERSION = qv("v0.3.0");

    has ua => (
        is => 'ro',
        default => sub { Mojo::UserAgent->new() },
    );

    has endpoint_host => (
        is => 'ro',
    );

    has PSPID => (
        is => 'ro',
    );

    has api_key => (
        is => 'ro',
    );

    has api_secret => (
        is => 'ro',
    );

    has tid => ( is => 'ro' );
    has kSig => ( is => 'ro' );

    sub BUILD {
        my ($self, $args) = @_;
    }

    sub CreateHostedCheckout {
        my ($self, $args) = @_;

        my $auth = $self->_create_autorization({
            method   => 'POST',
            endpoint => 'hostedcheckouts',
        });

        my $amount = sprintf("%.0f", int ($args->{amount} * 100));
        confess 'Invalid-amount' if $amount !~ m/^\d+$/;
        confess 'Invalid-currencyCode' if !$args->{currencyCode};
        confess 'Invalid-merchantReference' if !$args->{merchantReference};

        my $reqargs = {
            order         => {
                references => {
                    merchantReference => $args->{merchantReference},
                },
                amountOfMoney => {
                    amount       => $amount,
                    currencyCode => $args->{currencyCode},
                },
            },
            hostedCheckoutSpecificInput => {
                showResultPage => \1,
                returnUrl      => ''.$args->{returnUrl},
            },
            cardPaymentMethodSpecificInput => {
                authorizationMode => 'SALE', # Capture
            },
            redirectPaymentMethodSpecificInput => {
                requiresApproval => \0,
                redirectionData => {
                    returnUrl => ''.$args->{returnUrl},
                },
            }
        };

        # use Data::Dump qw/dump/; die dump($reqargs);

        my $res = $self->ua->post(
            $auth->{endpoint_uri},
            # 'http://redbaron.italpro.net:3000',
            {
                'Content-type' => $auth->{h_content_type},
                'Date' => $auth->{h_date},
                'Authorization' => $auth->{authorization},
            } =>
            json => $reqargs
        )->result;
        confess $res->message .': ' . dump($res->json) if !$res->is_success;

        # confess Data::Dump::dump($res->json);

        return $res->json;
    }

    sub GetHostedCheckoutStatus {
        my ($self, $args) = @_;

        confess 'Invalid-checkoutId' if !$args->{checkoutId};

        my $auth = $self->_create_autorization({
            method    => 'GET',
            endpoint  => 'hostedcheckouts',
            url_extra => '/'.$args->{checkoutId},
        });

        # die $auth->{endpoint_uri};

        my $res = $self->ua->get(
            $auth->{endpoint_uri},
            {
                'Content-type' => $auth->{h_content_type},
                'Date' => $auth->{h_date},
                'Authorization' => $auth->{authorization},
            }
        )->result;
        confess $res->message .': ' . dump($res->json) if !$res->is_success;

        # confess Data::Dump::dump($res->json);

        return $res->json;
    }

    sub _create_autorization($self, $args) {
        my $now = DateTime->now(time_zone => 'UTC');

        my $request_method = $args->{method};
        confess 'Invalid-method' if $args->{method} !~ m/^(POST|GET)$/xs;

        my $endpoint_path = '/v2/'.$self->PSPID.'/hostedcheckouts'.$args->{url_extra};
        my $h_content_type = $request_method eq 'POST' ? 'application/json; charset=utf-8' : '';
        my $h_date = DateTime::Format::HTTP->format_datetime($now);
        my $string_to_hash = $request_method . "\n" . $h_content_type . "\n" . $h_date . "\n" . $endpoint_path . "\n";
        my $signature = hmac_b64('SHA256', $self->api_secret, $string_to_hash);
        my $authorization = "GCS v1HMAC:" . $self->api_key . ":" . $signature;

        return {
            h_date         => $h_date,
            h_content_type => $h_content_type,
            authorization  => $authorization,
            endpoint_uri   => $self->endpoint_host . $endpoint_path,
        };
    }
}

1;

=head1 NAME

Business::PAYONE - Perl library for PAYONE online payment system

=head1 SYNOPSIS

    user Business::PAYONE;
    my $po = Business::PAYONE->new({
        endpoint_host   => 'https://payment.preprod.payone.com',
        PSPID           => 'MyPSPID',
        api_key         => 'xxxxxxxxxxxxxxxxxx',
        api_secret      => 'yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy',
    });

    # Create hosted checkout
    my $pores = $po->CreateHostedCheckout({
        amount              => 290.40,
        currencyCode        => 'EUR',
        merchantReference   => 'XD542SS',
        returnUrl           => 'https://my_site_postpay_page/',
    });

    # Store the checkoutid we need later to retrieve transaction result
    my $payone_checkoutid = $pores->{hostedCheckoutId};

    # Get the URL and then redirect user to it for payment
    my $redirect_url = $pores->{redirectUrl};
    # Do redirection...

    # Then when user comes back to returnURL...

    # Verifiy transaction
    my $pores = $po->GetHostedCheckoutStatus({
        checkoutId => $payone_checkoutid,
    });
    my $status = $pores->{status};

    if ( $status eq 'PAYMENT_CREATED' && $pores->{createdPaymentOutput}->{payment}->{status} eq 'CAPTURED' ) {
        # Success
    }

=head1 DESCRIPTION

This is HIGHLY EXPERIMENTAL and in the works, do not use for now. It currently only support I<HostedCheckout> (partially).

I plan to work on this module if there is interest.

=head1 REPOSITORY

GitHub repository: L<https://github.com/mc7244/Business-PAYONE>

=head1 AUTHOR

Michele Beltrame, C<mb@blendgroup.it>

=head1 LICENSE

This library is free software under the Artistic License 2.0.

=cut
