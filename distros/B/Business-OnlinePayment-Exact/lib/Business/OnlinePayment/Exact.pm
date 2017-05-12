package Business::OnlinePayment::Exact;

use 5.006001;
use strict;
use warnings;
use SOAP::Lite;
use Business::OnlinePayment;

our @ISA = qw(Business::OnlinePayment);
our @EXPORT_OK = ();
our @EXPORT = qw();

our $VERSION = '0.01';

sub set_defaults {
    my $self = shift;
    $self->build_subs(qw(proxy on_action uri tns types process encodingstyle
        order_number));
    $self->proxy('https://secure2.e-xact.com/vpos/process/vpos.asmx');
    $self->on_action('http://secure2.e-xact.com/vpos/process/Process');
    $self->uri('http://secure2.e-xact.com/vpos/process/');
    $self->tns('http://secure2.e-xact.com/vpos/process/');
    $self->types('http://secure2.e-xact.com/vpos/process/encodedTypes');
    $self->process('http://secure2.e-xact.com/vpos/process/Request');
    $self->encodingstyle('http://schemas.xmlsoap.org/soap/encoding/');
}

sub map_fields {
    my $self = shift;
    my %content = $self->content();
    my %actions = ('normal authorization' => '00',
                   'authorization only' => '01',
                   'credit' => '04',
                   'post authorization' => '02',
                   'void' => '13',
    );
    $content{'action'} = $actions{lc($content{'action'})};
    $content{'name'} = $content{'first_name'}.' '.$content{'last_name'} ||
        $content{'name'} if $content{'first_name'} and $content{'last_name'};
    $content{'expiration'} =~ /(\d\d)\D*(\d\d)/ if $content{'expiration'};
    $content{'expiration_month'} = $1 || $content{'expiration_month'};
    $content{'expiration_year'} = $2 || $content{'expiration_year'};
    $content{'expiration'} = $content{'expiration_month'}.
        $content{'expiration_year'} || $content{'expiration'};
    $self->content(%content);
}

sub remap_fields {
    my($self,%map) = @_;

    my %content = $self->content();
    foreach(keys %map) {
        $content{$map{$_}} = $content{$_};
    }
    $self->content(%content);
}

sub submit {
    my $self = shift;
    $self->map_fields;
    $self->remap_fields(
        login => 'ExactID',
        password => 'Password',
        action => 'Transaction_Type',
        amount => 'DollarAmount',
        customer_ip => 'Client_IP',
        order_number => 'Reference_No',
        name => 'CardHoldersName',
        address => 'VerificationStr1',
        email => 'Client_Email',
        card_number => 'Card_Number',
        expiration => 'Expiry_Date',
        referer => 'Customer_Ref', 
    );
    my %content = $self->content();
    #make data here
    my @data;
    foreach (keys %content) {
        push @data, SOAP::Data->name($_ => $content{$_})->type('string');
    }

    my $data = 
    SOAP::Data->attr({'xsi:type' => 'types:Transaction'})
        ->name('Transaction')->value(\SOAP::Data->value(@data));
    #figure out action
    #make request

    my $s = SOAP::Lite
    ->proxy($self->proxy)
    ->on_action(sub{return $self->on_action})
    ->uri($self->uri)
    ->readable(1);

    $s->serializer->register_ns($self->tns => 'tns');
    $s->serializer->register_ns($self->types => 'types');

    my $m = SOAP::Data->name('q1:Process')
        ->attr({'xmlns:q1' => $self->process,
        'soap:encodingStyle' => $self->encodingstyle});

    my $result = $s->call($m => $data);
    #get result
    if ($result->fault) {
        $self->is_success(0);
        $self->error_message($result->faultstring);
    }
    else {
        if ($result->valueof('//TransactionResult/Transaction_Approved') 
        eq '1' and $result->valueof('//TransactionResult/EXact_Resp_Code') 
        eq '00' and $result->valueof('//TransactionResult/Transaction_Error') 
        eq '0') {
            $self->is_success(1);
            $self->error_message(
                $result->valueof('//TransactionResult/EXact_Message'));
            $self->authorization(
                $result->valueof('//TransactionResult/Authorization_Num'));
            $self->order_number(
                $result->valueof('//TransactionResult/SequenceNo'));
            }
        else {
            $self->is_success(0);
            $self->error_message(
                $result->valueof('//TransactionResult/EXact_Message'));
        }

    }
}


1;
__END__
=head1 NAME

Business::OnlinePayment::Exact - Perl extension for doing credit card 
processing through the E-xact v7 Web Services API payment gateway.

=head1 SYNOPSIS

  use Business::OnlinePayment;
  my $tx = new Business::OnlinePayment('Exact');
  $tx->content(
    amount => '19.00',
    card_number => '4200000000000000',
    expiration => '0110',
    name => 'Some Guy',
    action => 'authorization only',
    login => 'A000XX-XX'
    password => 'password'
  );
  $tx->submit;
  if ($tx->is_success()) {
    my $ordernum = $tx->order_number;
    print "Got the cash";
  }
  else {
    print $tx->error_message;
  }

=head1 ABSTRACT

    This is a Business::OnlinePayment module for E-xact loosely based on
    Business::OnlinePayment::AuthorizeNet.  I've only used it for normal
    authorization so it may require some work to do pre auth, etc.


=head1 DESCRIPTION

    See synopsis.  It works like any other Business::OnlinePayment module.
    The following content keys are usefull:
    login
    password
    amount
    card_number
    expiration
    name
    referer
    email
    address
    order_number
    customer_ip
    action

    The following content keys are also available (but not really usefull):
    'first_name' and 'last_name' will combine to override 'name'
    'expiration_month' and 'expiration_year' will combine to override 
    'expiration'

    The 'authorization' method will return the bank authorization code, and the
    'order_number' method will contain the sequence number from E-xact.
    The content key 'referer' can be used to store any string data (20 bytes)
    and used to search for those transactions from the web interface.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Business::OnlinePayment
SOAP::Lite
"Exact Payment WebService Plug-In Programming Reference Guide v7"
(which can be found on www.e-xact.com with enough digging)

=head1 AUTHOR

mock, E<lt>mock@obscurity.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by mock

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
