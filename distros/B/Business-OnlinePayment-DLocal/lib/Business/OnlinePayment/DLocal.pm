package Business::OnlinePayment::DLocal;
use strict;
use warnings;

use Business::OnlinePayment;
use Business::OnlinePayment::HTTPS;
use Digest::SHA qw(hmac_sha256_hex);
use HTTP::Tiny;
use URI::Escape;
use XML::Simple;
use JSON;
use vars qw(@ISA $me $VERSION);
use Log::Scrubber qw(disable $SCRUBBER scrubber :Carp scrubber_add_scrubber);
@ISA     = qw(Business::OnlinePayment::HTTPS);
$me      = 'Business::OnlinePayment::DLocal';

our $VERSION = '0.006'; # VERSION
# PODNAME: Business::OnlinePayment::DLocal
# ABSTRACT: Business::OnlinePayment::DLocal - DLocal (astropay) backend for Business::OnlinePayment


sub _info {
    return {
        info_compat       => '0.01',
        gateway_name      => 'DLocal',
        gateway_url       => 'http://www.dlocal.com',
        module_version    => $VERSION,
        supported_types   => ['CC'],
        supported_actions => {
            CC => [
                'Tokenize',
                'Normal Authorization',
                'Post Authorization',
                'Authorization Only',
                'Credit',
                'Auth Reversal',
                'PayStatus',
                'RefundStatus',
                'CurrencyExchange',
            ],
        },
    };
}


sub test_transaction {
    my $self = shift;
    my $testMode = shift;
    if (! defined $testMode) { $testMode = $self->{'test_transaction'} || 0; }
    $self->{'test_transaction'} = $testMode;
    if($testMode) {
        $self->server('sandbox.dlocal.com');
        $self->port('443');
        $self->path('/api_curl/cc/sale');
    } else {
        $self->server('api.dlocal.com');
        $self->port('443');
        $self->path('/api_curl/cc/sale');
    }
    return $self->{'test_transaction'};
}


sub field_map {
    return (
        # DLOCAL #        => # BOP #
        'x_login'         => 'login',           # reports_login
        'x_trans_key'     => 'password',        # reports_key
        'x_secret_key'    => 'password2',
        'x_version'       => 'version',
        'x_country'       => 'country',
        'x_invoice'       => 'invoice_number',
        'x_document'      => 'order_number',
        'x_refund'        => 'order_number',
        'x_amount'        => 'amount',
        'x_currency'      => 'currency',
        'x_description'   => 'description',
        'x_device_id'     => 'device_id',
        'x_cpf'           => 'cpf',             # govt id number
        'x_name'          => 'name',            # needs a joiner of this in map fields
        'x_email'         => 'email',
        'cc_number'       => 'card_number',
        'cc_exp_month'    => 'expirationMM',    # needs to be broken in two
        'cc_exp_year'     => 'expirationYY',
        'cc_cvv'          => 'cvv2',
        'cc_token'        => 'card_token',
        'x_bank'          => 'bank',            # looks to be card, but others... different key
        'cc_issuer'       => 'issuer',          # same
        'cc_installments' => 'installments',    # similar breakout one-shot vs a number
        'cc_descriptor'   => 'descriptor',
        'x_ip'            => 'customer_ip',
        'x_confirm'       => 'confirm',         # a confirmation URL if passed, similar to paypal IPN
        'x_bdate'         => 'birthdate',       # WTF is this needed
        'x_iduser'        => 'customer_id',
        'x_address'       => 'address',
        'x_zip'           => 'zip',
        'x_city'          => 'city',
        'x_state'         => 'state',
        'x_phone'         => 'phone',
        'x_merchant_id'   => 'merch_id',       # sub-merchant id, lmk if you ever use this, no normal BOP standard here

        'x_auth_id'      => 'order_number',

        control         => 'control',
        type            => 'type',
    );
}


sub content {
    my $self = shift;
    my %content = $self->SUPER::content(@_);

    # Adjust common %content BOP format to what DLOCAL needs
    if ($content{'expiration'} && $content{'expiration'} =~ /^(\d\d)\/?(\d\d)/) {
        $content{'expirationMM'} //= $1;
        $content{'expirationYY'} //= '20'.$2;
    }
    if (! exists $content{'name'}) {
        $content{'name'} = $content{'first_name'}//'';
        $content{'name'} .= ' ' if length($content{'name'});
        $content{'name'} .= $content{'last_name'} if length($content{'last_name'}//'');
    }
    $content{'version'} //= $self->api_version;
    $content{'type'} = 'json';

    return %content;
}


sub submit {
    my $self = shift;
    my %content = $self->content();
    die 'Missing action' unless $content{'action'};

    my $action;
    foreach (@{$self->_info()->{'supported_actions'}->{'CC'}}) {
        if (lc($_) eq lc($content{'action'})) {
            $action = lc('_'.$_);
            $action =~ s/ /\_/g;
        }
    }
    if ($action && $self->can($action)) {
        return $self->$action(\%content);
    } else {
        die 'Unsupported action';
    }
}


sub _normal_authorization { shift->_authorization_only(@_); }


sub _authorization_only {
    my ($self,$content) = @_;

    if ($content->{'card_token'}) {
        # tokens fail if you try and send these as well
        my %remap_fields = $self->field_map();
        foreach ('x_country','x_cpf','x_name','x_email','cc_number','cc_exp_month','cc_exp_year','cc_cvv') {
            delete $content->{$remap_fields{$_}};
        }
    }

    my $config = {
        url => 'https://'.$self->server.'/api_curl/cc/'.(lc($content->{'action'})eq 'normal authorization' ? 'sale' : 'auth'),
        control => ['x_invoice','x_amount','x_currency','x_email','cc_number','cc_exp_month','cc_cvv','cc_exp_year','x_cpf','x_country','cc_token'],
        post_data => ['x_login','x_trans_key','x_version','x_invoice','x_amount','x_currency','x_description','x_device_id','x_country',
                    'x_phone','x_address','x_cpf','x_name','x_email','cc_number','cc_exp_month','cc_exp_year','cc_cvv','cc_token','control','type'],
    };

    my $res = $self->_send_request($config,$content);
    $self->error_message( $res->{'desc'} );
    $self->result_code( $res->{'error_code'} );
    $self->is_success( defined $res->{'result'} && $res->{'result'} =~ /^9|11$/ ? 1 : 0 );
    $self->order_number( $res->{'x_document'} // $res->{'x_auth_id'} ); # sale vs auth
    $res;
}


sub _post_authorization{
    my ($self,$content) = @_;

    my $config = {
        url => 'https://'.$self->server.'/api_curl/cc/capture',
        control => ['x_invoice','x_auth_id','x_amount','x_currency'],
        post_data => ['x_login','x_trans_key','x_version','x_invoice','x_amount','x_currency','x_auth_id','control','type'],
    };

    my $res = $self->_send_request($config,$content);
    $self->error_message( $res->{'desc'} );
    $self->result_code( $res->{'error_code'} );
    $self->is_success( defined $res->{'result'} && $res->{'result'} =~ /^9|11$/ ? 1 : 0 );
    $self->order_number( $res->{'x_document'} // $res->{'x_auth_id'} ); # sale vs auth
    $res;
}


sub _tokenize {
    my ($self,$content) = @_;

    my $config = {
        url => 'https://'.$self->server.'/api_curl/cc/save',
        control => ['x_email','cc_number','cc_exp_month','cc_cvv','cc_exp_year','x_cpf','x_country'],
        post_data => ['x_login','x_trans_key','x_version','x_country','x_cpf','x_name','x_email','cc_number','cc_exp_month','cc_exp_year','cc_cvv','control','type'],
    };

    my $res = $self->_send_request($config,$content);
    $self->error_message( $res->{'desc'} );
    $self->result_code( $res->{'error_code'} );
    $self->is_success( $res->{'cc_token'} ? 1 : 0 );
    $self->card_token( $res->{'cc_token'} );
    $res;
}


sub _credit {
    my ($self,$content) = @_;

    my $config = {
        url => 'https://'.$self->server.'/api_curl/cc/refund',
        control => ['x_document','x_invoice','x_amount','x_currency'],
        post_data => ['x_login','x_trans_key','x_version','x_invoice','x_document','x_amount','x_currency','control','type'],
    };

    my $res = $self->_send_request($config,$content);
    $self->error_message( $res->{'desc'} );
    $self->result_code( $res->{'error_code'} );
    $self->is_success( defined $res->{'result'} && $res->{'result'} eq '1' ? 1 : 0 );
    $self->order_number( $res->{'x_document'} );
    $res;
}


sub _paystatus {
    my ($self,$content) = @_;

    my $config = {
        url => 'https://'.$self->server.'/api_curl/query/paystatus',
        control => [], # not used
        post_data => ['x_login','x_trans_key','x_version','x_invoice','x_document','type'],
    };

    # query api uses different credentials
    local $content->{'login'} = $content->{'reports_login'};
    local $content->{'password'} = $content->{'reports_key'};

    my $res = $self->_send_request($config,$content);
    $self->error_message( $res->{'desc'} );
    $self->result_code( $res->{'error_code'} );
    $self->is_success( defined $res->{'result'} ); # any result is a positive think for a query call
    $self->order_number( $res->{'x_document'} );
    $res;
}


sub _refundstatus {
    my ($self,$content) = @_;

    my $config = {
        url => 'https://'.$self->server.'/api_curl/query/refundstatus',
        control => [], # not used
        post_data => ['x_login','x_trans_key','x_version','x_refund','type'],
    };

    # query api uses different credentials
    local $content->{'login'} = $content->{'reports_login'};
    local $content->{'password'} = $content->{'reports_key'};

    my $res = $self->_send_request($config,$content);
    $self->error_message( $res->{'desc'} );
    $self->result_code( $res->{'error_code'} );
    $self->is_success( defined $res->{'result'} ); # any result is a positive think for a query call
    $self->order_number( $res->{'x_document'} );
    $res;
}


sub _currencyexchange {
    my ($self,$content) = @_;

    my $config = {
        url => 'https://'.$self->server.'/api_curl/query/currencyexchange',
        control => [], # not used
        post_data => ['x_login','x_trans_key','x_country','type'],
    };

    # query api uses different credentials
    local $content->{'login'} = $content->{'reports_login'};
    local $content->{'password'} = $content->{'reports_key'};

    my $res = $self->_send_request($config,$content);
    if ($res =~ /^\d+(:?\.\d+)$/ && $res > 0 ) {
        $self->is_success( 1 );
        $self->order_number( $res );
    } else {
        $self->is_success( 0 );
        $self->order_number( undef );
    }
    $res;
}


sub _send_request {
    my ($self,$config,$content) = @_;
    my %content = %$content;
    my %remap_fields = $self->field_map();

    $self->_dlocal_scrubber_add_card($content{'card_number'});
    scrubber_add_scrubber({'cc_cvv='.$content{'cvv2'}=>'cc_cvv=DELETED'}) if defined $content{'cvv2'};

    my $message = '';
    foreach my $key ( @{$config->{'control'}} ) { $message .= $content{$remap_fields{$key}}//''; }
    local $content{'control'} = uc(hmac_sha256_hex(pack('A*',$message), pack('A*',$content{'password2'})));

    my $post_data;
    foreach my $key ( @{$config->{'post_data'}} ) {
        $post_data .= uri_escape($key).'='.uri_escape($content{$remap_fields{$key}}).'&' if $content{$remap_fields{$key}};
    }
    my $url = $config->{'url'};
    $self->server_request( $url.'?'.$post_data ); # yeah it's in GET, but it's easy to read that way
    my $verify_ssl = 1;

    my $response;
    if (ref $self->{'mocked'} eq 'ARRAY' && scalar @{$self->{'mocked'}}) {
        my $mock = shift @{$self->{'mocked'}};
        die "Unexpected mock action" unless lc($mock->{'action'}) eq lc($content->{'action'});
        die "Unexpected mock login" unless $mock->{'login'} eq $content{'login'};
        $response->{'content'} = $mock->{'resp'};
    } else {
        $response = HTTP::Tiny->new( verify_SSL=>$verify_ssl )->request('POST', $url, {
            headers => {
                'Content-Length' => length($post_data),
                'Content-Type' => 'application/x-www-form-urlencoded',
                'Accept' => 'application/json',
            },
            content => $post_data,
        } );
    }
    $self->server_response( $response->{'content'} );
    my $c = substr($response->{'content'},0,1);
    my $res = $c eq '{' ? decode_json( $response->{'content'} )
        : $c eq '<' ? $self->_parse_xml_response( $response->{'content'}, $response->{'status'} ) # just in case
        : $response->{'content'}; # return raw (for currencyexchange)
    $res;
}


sub _parse_xml_response {
    my ( $self, $page, $status_code ) = @_;
    my $response = {};
    if ( $status_code =~ /^200/ ) {
        if ( ! eval { $response = XMLin($page); } ) {
            die "XML PARSING FAILURE: $@";
        }
    }
    else {
        $status_code =~ s/[\r\n\s]+$//; # remove newline so you can see the error in a linux console
        if ( $status_code =~ /^(?:900|599)/ ) { $status_code .= ' - verify DLocal has whitelisted your IP'; }
        die "CONNECTION FAILURE: $status_code";
    }
    return $response;
}


sub server_request {
    my ( $self, $val, $tf ) = @_;
    if ($val) {
        $self->{server_request} = scrubber $val;
        $self->server_request_dangerous($val,1) unless $tf;
    }
    return $self->{server_request};
}


sub server_request_dangerous {
    my ( $self, $val, $tf ) = @_;
    if ($val) {
        $self->{server_request_dangerous} = $val;
        $self->server_request($val,1) unless $tf;
    }
    return $self->{server_request_dangerous};
}


sub server_response {
    my ( $self, $val, $tf ) = @_;
    if ($val) {
        $self->{server_response} = scrubber $val;
        $self->server_response_dangerous($val,1) unless $tf;
    }
    return $self->{server_response};
}


sub server_response_dangerous {
    my ( $self, $val, $tf ) = @_;
    if ($val) {
        $self->{server_response_dangerous} = $val;
        $self->server_response($val,1) unless $tf;
    }
    return $self->{server_response_dangerous};
}



sub set_defaults {
    my $self = shift;
    my %opts = @_;

    $self->build_subs(
        qw( order_number card_token api_version )
    );

    $self->test_transaction(0);

    if ( $opts{debug} ) {
        $self->debug( $opts{debug} );
        delete $opts{debug};
    }

    ## load in the defaults
    my %_defaults = ();
    foreach my $key ( keys %opts ) {
        $key =~ /^default_(\w*)$/ or next;
        $_defaults{$1} = $opts{$key};
        delete $opts{$key};
    }

    $self->{_scrubber} = \&_default_scrubber;
    if( defined $_defaults{'Scrubber'} ) {
        my $code = $_defaults{'Scrubber'};
        if( ref($code) ne 'CODE' ) {
            warn('default_Scrubber is not a code ref');
        }
        else {
            $self->{_scrubber} = $code;
        }
    }

    $self->api_version('4.0')                   unless $self->api_version;
}

sub _default_scrubber {
    my $cc = shift;
    my $del = substr($cc,0,6).('X'x(length($cc)-10)).substr($cc,-4,4); # show first 6 and last 4
    return $del;
}

sub _dlocal_scrubber_add_card {
    my ( $self, $cc ) = @_;
    return if ! $cc;
    my $scrubber = $self->{_scrubber};
    scrubber_add_scrubber({$cc=>&{$scrubber}($cc)});
}

1;

__END__

=pod

=head1 NAME

Business::OnlinePayment::DLocal - Business::OnlinePayment::DLocal - DLocal (astropay) backend for Business::OnlinePayment

=head1 VERSION

version 0.006

=head1 METHODS

=head2 test_transaction

Get/set the server used for processing transactions.  Possible values are Live, Certification, and Sandbox
Default: Live

  #Live
  $self->test_transaction(0);

  #Certification
  $self->test_transaction(1);

=head2 field_map

Hash to map BOP standard names into the DLocal names

=head2 content

Manpilate the content to prepare for submittal

=head2 submit

Submit the content to the API

=head2 _normal_authorization

Maps a normal_authorization call to _authorization_only

=head2 _authorization_only

Perform an auth_only. warning, this feature is only available in certain countries, and requires configuration from DLocal on your account. Unless you know you need to use this, please stay with the SALE

=head2 _post_authorization

Perform a Post authorization (Capture). Same caveats as Auth only.

=head2 _tokenize

Submit a credit card number to DLocal for tokenization, allowing for subsequent calls to be tokenized, and not require PAN storage

=head2 _credit

Perform a refund

=head2 _paystatus

Check the status of a payment that previously returned a PENDING state. Requires that you have provided the interface user/token in addition to the normal API ones.

=head2 _refundstatus

Check the status of a refund.

=head2 _currencyexchange

Get a current currency exchange value for price display

=head2 _send_request

Formats your content and request data to actually transmit data

=head2 _parse_xml_response

Parsing if an XML response was received. Now that type=>'json' exists, will be phased out

=head2 server_request

Returns the complete request that was sent to the server.  The request has been stripped of card_num, cvv2, and password.  So it should be safe to log.

=head2 server_request_dangerous

Returns the complete request that was sent to the server.  This could contain data that is NOT SAFE to log.  It should only be used in a test environment, or in a PCI compliant manner.

=head2 server_response

Returns the complete response from the server.  The response has been stripped of card_num, cvv2, and password.  So it should be safe to log.

=head2 server_response_dangerous

Returns the complete response from the server.  This could contain data that is NOT SAFE to log.  It should only be used in a test environment, or in a PCI compliant manner.

=head2 set_defaults

Setup default values

=head1 AUTHOR

Jason (Jayce^) Hall <jayce@lug-nut.com>

=head1 CONTRIBUTOR

=for stopwords Jason Terry

Jason Terry <jterry@bluehost.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jason (Jayce^) Hall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
