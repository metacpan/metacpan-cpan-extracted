package Business::PayPoint;
{
    $Business::PayPoint::VERSION = '0.01';
}

# ABSTRACT: PayPoint online payment

use strict;
use warnings;
use Carp 'croak';

#use Data::Dumper;
use XML::Writer;
use SOAP::Lite;    # +trace => 'all';
use URI::Escape qw/uri_escape/;

sub new {
    my $class = shift;
    my $args = @_ % 2 ? $_[0] : {@_};

    $args->{debug} ||= $ENV{PAYPOINT_DEBUG};
    SOAP::Trace->import('all') if $args->{debug};

    $SOAP::Constants::PREFIX_ENV = 'soap';
    $args->{soap} ||= SOAP::Lite->readable(1)
      ->proxy('https://www.secpay.com/java-bin/services/SECCardService?wsdl');

    bless $args, $class;
}

sub set_credentials {
    my ( $self, $mid, $vpn_pass, $remote_pass ) = @_;

    $self->{__mid}         = $mid;
    $self->{__vpn_pswd}    = $vpn_pass;
    $self->{__remote_pswd} = $remote_pass;
}

sub validateCardFull {
    my $self = shift;
    my $args = @_ % 2 ? $_[0] : {@_};

    my $ordered_keys = [
        'trans_id', 'ip',          'name',         'card_number',
        'amount',   'expiry_date', 'issue_number', 'start_date',
        'order',    'shipping',    'billing',      'options'
    ];
    $self->_request( 'validateCardFull', $ordered_keys, $args );
}

sub repeatCardFullAddr {
    my $self = shift;
    my $args = @_ % 2 ? $_[0] : {@_};

    my $ordered_keys = [
        'trans_id', 'amount', 'remote_pswd', 'new_trans_id',
        'exp_date', 'order',  'bill',        'ship',
        'options'
    ];
    $self->_request( 'repeatCardFullAddr', $ordered_keys, $args );
}

sub repeatCardFull {
    my $self = shift;
    my $args = @_ % 2 ? $_[0] : {@_};

    my $ordered_keys = [
        'trans_id', 'amount', 'remote_pswd', 'new_trans_id',
        'exp_date', 'order'
    ];
    $self->_request( 'repeatCardFull', $ordered_keys, $args );
}

sub refundCardFull {
    my $self = shift;
    my $args = @_ % 2 ? $_[0] : {@_};

    my $ordered_keys = [ 'trans_id', 'amount', 'remote_pswd', 'new_trans_id' ];
    $self->_request( 'refundCardFull', $ordered_keys, $args );
}

sub releaseCardFull {
    my $self = shift;
    my $args = @_ % 2 ? $_[0] : {@_};

    my $ordered_keys = [ 'trans_id', 'amount', 'remote_pswd', 'new_trans_id' ];
    $self->_request( 'releaseCardFull', $ordered_keys, $args );
}

sub getReport {
    my $self = shift;
    my $args = @_ % 2 ? $_[0] : {@_};

    my $ordered_keys = [
        'remote_pswd', 'report_type', 'cond_type', 'condition',
        'currency',    'predicate',   'html',      'showErrs'
    ];
    $self->_request( 'getReport', $ordered_keys, $args );
}

sub getTZReport {
    my $self = shift;
    my $args = @_ % 2 ? $_[0] : {@_};

    my $ordered_keys = [
        'remote_pswd', 'report_type', 'cond_type', 'condition',
        'currency',    'predicate',   'html',      'showErrs',
        'tz'
    ];
    $self->_request( 'getTZReport', $ordered_keys, $args );
}

sub threeDSecureEnrolmentRequest {
    my $self = shift;
    my $args = @_ % 2 ? $_[0] : {@_};

    my $ordered_keys = [
        'trans_id',                   'ip',
        'name',                       'card_number',
        'amount',                     'expiry_date',
        'issue_number',               'start_date',
        'order',                      'shipping',
        'billing',                    'options',
        'device_category',            'accept_headers',
        'user_agent',                 'mpi_merchant_name',
        'mpi_merchant_url',           'mpi_description',
        'purchaseRecurringFrequency', 'purchaseRecurringExpiry',
        'purchaseInstallments'
    ];
    $self->_request( 'threeDSecureEnrolmentRequest', $ordered_keys, $args );
}

sub threeDSecureAuthorisationRequest {
    my $self = shift;
    my $args = @_ % 2 ? $_[0] : {@_};

    my $ordered_keys = [ 'trans_id', 'md', 'paRes', 'options' ];
    $self->_request( 'threeDSecureAuthorisationRequest', $ordered_keys, $args );
}

sub performTransactionViaAlternatePaymentMethod {
    my $self = shift;
    my $args = @_ % 2 ? $_[0] : {@_};

    my $ordered_keys = [
        'paymentOrganisation', 'paymentMethod',
        'paymentType',         'paymentRequestType',
        'trans_id',            'amount',
        'currency',            'options'
    ];
    $self->_request( 'performTransactionViaAlternatePaymentMethod',
        $ordered_keys, $args );
}

sub _request {
    my ( $self, $method, $ordered_keys, $args ) = @_;

    unless ( $self->{__mid} ) {
        return { valid => 'false', message => 'credentials is not setup yet' };
    }

    my @requests = ( vpn_pswd => $self->{__vpn_pswd}, mid => $self->{__mid} );
    foreach my $k (@$ordered_keys) {
        if ( $k eq 'amount' ) {
            push @requests, ( amount => sprintf( '%.2f', $args->{amount} ) );
        }
        elsif ( $k eq 'remote_pswd' ) {
            push @requests, ( remote_pswd => $self->{__remote_pswd} || '' );
        }
        else {
            push @requests, ( $k => $args->{$k} || '' );
        }
    }

    my $xml;
    my $writer = new XML::Writer( OUTPUT => \$xml );
    $writer->startTag('XX');
    while (1) {
        last unless @requests;
        $writer->dataElement( shift @requests, shift @requests );
    }
    $writer->endTag('XX');

    $xml =~ s/\<\/?XX\>//g;    # remove placeholder

    my $som = $self->{soap}->call( $method, SOAP::Data->type( 'xml' => $xml ) );
    if ( $som->fault ) {
        return { valid => 'false', message => $som->faultstring };
    }
    my $result = $som->result;
    unless ($result) {
        return { valid => 'false', message => 'Unknown Error' };
    }

# ?valid=true&trans_id=tran0001&code=A&auth_code=9999&message=TEST AUTH&amount=50.0&test_status=true
# valid=false&trans_id=tran0001&code=P:C&message=Luhn Check Failed&correct=false

    $result =~ s/^\?//;
    my @p = split( '&', $result );
    my %result = map { split(/=/) } @p;
    return %result;
}

1;

__END__

=pod

=head1 NAME

Business::PayPoint - PayPoint online payment

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Business::PayPoint;

    my $bp = Business::PayPoint->new();
    $bp->set_credentials($mid, $vpn_pass, $remote_pass);

=head1 DESCRIPTION

L<https://www.paypoint.net/assets/guides/Gateway_Freedom.pdf>

=head2 METHODS

=head3 set_credentials

    $bp->set_credentials($mid, $vpn_pass, $remote_pass);
    # $bp->set_credentials('secpay', 'secpay', 'secpay');

=head3 validateCardFull

    my %result = $bp->validateCardFull(
        'trans_id' => 'tran0001',
        'ip' => '127.0.0.1',
        'name' => 'Mr Cardholder',
        'card_number' => '4444333322221111',
        'amount' => '50.00',
        'expiry_date' => '0115',
        'billing' => "name=Fred+Bloggs,company=Online+Shop+Ltd,addr_1=Dotcom+House,addr_2=London+Road,city=Townville,state=Countyshire,post_code=AB1+C23,tel=01234+567+890,fax=09876+543+210,email=somebody%40secpay.com,url=http%3A%2F%2Fwww.somedomain.com",
        'options' => 'test_status=true,dups=false,card_type=Visa,cv2=123'
    );

=head3 repeatCardFullAddr

=head3 repeatCardFull

=head3 refundCardFull

=head3 releaseCardFull

=head3 getReport

    my %report = $bp->getReport(
        report_type => 'XML-Report',
        cond_type   => 'TransId',
        condition   => $trans_id,
        currency    => 'GBP',
        predicate   => '',
        html        => 'false',
        showErrs    => 'false'
    );

=head3 getTZReport

=head3 threeDSecureEnrolmentRequest

=head3 threeDSecureAuthorisationRequest

=head3 performTransactionViaAlternatePaymentMethod

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
