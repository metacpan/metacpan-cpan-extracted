package Business::OnlinePayment::ElavonVirtualMerchant;
use base qw(Business::OnlinePayment::viaKLIX);

use strict;
use vars qw( $VERSION %maxlength );

$VERSION = '0.03';
$VERSION = eval $VERSION;

=head1 NAME

Business::OnlinePayment::ElavonVirtualMerchant - Elavon Virtual Merchant backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment::ElavonVirtualMerchant;

  my $tx = new Business::OnlinePayment("ElavonVirtualMerchant", { default_ssl_userid => 'whatever' });
    $tx->content(
        type           => 'VISA',
        login          => 'testdrive',
        password       => '', #password or transaction key
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        customer_id    => 'jsk',
        first_name     => 'Jason',
        last_name      => 'Kohles',
        address        => '123 Anystreet',
        city           => 'Anywhere',
        state          => 'UT',
        zip            => '84058',
        card_number    => '4007000000027',
        expiration     => '09/02',
        cvv2           => '1234', #optional
    );
    $tx->submit();

    if($tx->is_success()) {
        print "Card processed successfully: ".$tx->authorization."\n";
    } else {
        print "Card was rejected: ".$tx->error_message."\n";
    }

=head1 DESCRIPTION

This module lets you use the Elavon (formerly Nova Information Systems) Virtual Merchant real-time payment gateway, a successor to viaKlix, from an application that uses the Business::OnlinePayment interface.

You need an account with Elavon.  Elavon uses a three-part set of credentials to allow you to configure multiple 'virtual terminals'.  Since Business::OnlinePayment only passes a login and password with each transaction, you must pass the third item, the user_id, to the constructor.

Elavon offers a number of transaction types, including electronic gift card operations and 'PINless debit'.  Of these, only credit card transactions fit the Business::OnlinePayment model.

Since the Virtual Merchant API is just a newer version of the viaKlix API, this module subclasses Business::OnlinePayment::viaKlix.

This module does not use Elavon's XML encoding as this doesn't appear to offer any benefit over the standard encoding.

=head1 SUBROUTINES

=head2 set_defaults

Sets defaults for the Virtual Merchant gateway URL.

=cut

sub set_defaults {
    my $self = shift;
    my %opts = @_;

    $self->SUPER::set_defaults(%opts);
    # standard B::OP methods/data
    $self->server("www.myvirtualmerchant.com");
    $self->port("443");
    $self->path("/VirtualMerchant/process.do");

}

=head2 _map_fields

Converts credit card types and transaction types from the Business::OnlinePayment values to Elavon's.

=cut

sub _map_fields {
    my ($self) = @_;

    my %content = $self->content();

    #ACTION MAP
    my %actions = (
        'normal authorization' => 'CCSALE',  # Authorization/Settle transaction
        'credit'               => 'CCCREDIT', # Credit (refund)
    );

    $content{'ssl_transaction_type'} = $actions{ lc( $content{'action'} ) }
      || $content{'action'};

    # TYPE MAP
    my %types = (
        'visa'             => 'CC',
        'mastercard'       => 'CC',
        'american express' => 'CC',
        'discover'         => 'CC',
        'cc'               => 'CC',
    );

    $content{'type'} = $types{ lc( $content{'type'} ) } || $content{'type'};

    $self->transaction_type( $content{'type'} );

    # stuff it back into %content
    $self->content(%content);
}

=head2 submit

Maps data from Business::OnlinePayment name space to Elavon's, checks that all required fields
for the transaction type are present, and submits the transaction.  Saves the results.

=cut

%maxlength = (
        ssl_description        => 255,
        ssl_invoice_number     => 25,
        ssl_customer_code      => 17,

        ssl_first_name         => 20,
        ssl_last_name          => 30,
        ssl_company            => 50,
        ssl_avs_address        => 30,
        ssl_city               => 30,
        ssl_phone              => 20,

        ssl_ship_to_first_name => 20,
        ssl_ship_to_last_name  => 30,
        ssl_ship_to_company    => 50,
        ssl_ship_to_address1   => 30,
        ssl_ship_to_city       => 30,
        ssl_ship_to_phone      => 20, #though we don't map anything to this...
);

sub submit {
    my ($self) = @_;

    $self->_map_fields();

    my %content = $self->content;

    my %required;
    $required{CC_CCSALE} =  [ qw( ssl_transaction_type ssl_merchant_id ssl_pin
                                ssl_amount ssl_card_number ssl_exp_date
                                ssl_cvv2cvc2_indicator 
                              ) ];
    $required{CC_CCCREDIT} = $required{CC_CCSALE};
    my %optional;
    $optional{CC_CCSALE} =  [ qw( ssl_user_id ssl_salestax ssl_cvv2cvc2
                                ssl_description ssl_invoice_number
                                ssl_customer_code ssl_company ssl_first_name
                                ssl_last_name ssl_avs_address ssl_address2
                                ssl_city ssl_state ssl_avs_zip ssl_country
                                ssl_phone ssl_email ssl_ship_to_company
                                ssl_ship_to_first_name ssl_ship_to_last_name
                                ssl_ship_to_address1 ssl_ship_to_city
                                ssl_ship_to_state ssl_ship_to_zip
                                ssl_ship_to_country
                              ) ];
    $optional{CC_CCCREDIT} = $optional{CC_CCSALE};

    my $type_action = $self->transaction_type(). '_'. $content{ssl_transaction_type};
    unless ( exists($required{$type_action}) ) {
      $self->error_message("Elavon can't handle transaction type: ".
        "$content{action} on " . $self->transaction_type() );
      $self->is_success(0);
      return;
    }

    my $expdate_mmyy = $self->expdate_mmyy( $content{"expiration"} );
    my $zip          = $content{'zip'};
    $zip =~ s/[^[:alnum:]]//g;

    my $cvv2indicator = $content{"cvv2"} ? 1 : 9; # 1 = Present, 9 = Not Present

    $self->_revmap_fields(

        ssl_merchant_id        => 'login',
        ssl_pin                => 'password',

        ssl_amount             => 'amount',
        ssl_card_number        => 'card_number',
        ssl_exp_date           => \$expdate_mmyy,    # MMYY from 'expiration'
        ssl_cvv2cvc2_indicator => \$cvv2indicator,
        ssl_cvv2cvc2           => 'cvv2',
        ssl_description        => 'description',
        ssl_invoice_number     => 'invoice_number',
        ssl_customer_code      => 'customer_id',

        ssl_first_name         => 'first_name',
        ssl_last_name          => 'last_name',
        ssl_company            => 'company',
        ssl_avs_address        => 'address',
        ssl_city               => 'city',
        ssl_state              => 'state',
        ssl_avs_zip            => \$zip,          # 'zip' with non-alnums removed
        ssl_country            => 'country',
        ssl_phone              => 'phone',
        ssl_email              => 'email',

        ssl_ship_to_first_name => 'ship_first_name',
        ssl_ship_to_last_name  => 'ship_last_name',
        ssl_ship_to_company    => 'ship_company',
        ssl_ship_to_address1   => 'ship_address',
        ssl_ship_to_city       => 'ship_city',
        ssl_ship_to_state      => 'ship_state',
        ssl_ship_to_zip        => 'ship_zip',
        ssl_ship_to_country    => 'ship_country',

    );

    my %params = $self->get_fields( @{$required{$type_action}},
                                    @{$optional{$type_action}},
                                  );

    $params{$_} = substr($params{$_},0,$maxlength{$_})
      foreach grep exists($maxlength{$_}), keys %params;

    foreach ( keys ( %{($self->{_defaults})} ) ) {
      $params{$_} = $self->{_defaults}->{$_} unless exists($params{$_});
    }

    $params{ssl_test_mode}='true' if $self->test_transaction;
    
    $params{ssl_show_form}='false';
    $params{ssl_result_format}='ASCII';

    $self->required_fields(@{$required{$type_action}});
    
    warn join("\n", map{ "$_ => $params{$_}" } keys(%params)) if $self->debug > 1;
    my ( $page, $resp, %resp_headers ) = 
      $self->https_post( %params );

    $self->response_code( $resp );
    $self->response_page( $page );
    $self->response_headers( \%resp_headers );

    warn "$page\n" if $self->debug > 1;
    # $page should contain key/value pairs

    my $status ='';
    my %results = map { s/\s*$//; split '=', $_, 2 } grep { /=/ } split '^', $page;

    # AVS and CVS values may be set on success or failure
    $self->avs_code( $results{ssl_avs_response} );
    $self->cvv2_response( $results{ ssl_cvv2_response } );
    $self->result_code( $status = $results{ errorCode } || $results{ ssl_result } );
    $self->order_number( $results{ ssl_txn_id } );
    $self->authorization( $results{ ssl_approval_code } );
    $self->error_message( $results{ errorMessage } || $results{ ssl_result_message } );


    if ( $resp =~ /^(HTTP\S+ )?200/ && $status eq "0" ) {
        $self->is_success(1);
    } else {
        $self->is_success(0);
    }
}

1;
__END__

=head1 SEE ALSO

Business::OnlinePayment, Business::OnlinePayment::viaKlix, Elavon Virtual Merchant Developers' Guide

=head1 AUTHOR

Richard Siddall, E<lt>elavon@elirion.netE<gt>

=head1 BUGS

Duplicates code to handle deprecated 'type' codes.

Method for passing raw card track data is not documented by Elavon.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Richard Siddall.  This module is largely based on Business::OnlinePayment::viaKlix by Jeff Finucane.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

