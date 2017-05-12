package Business::OnlinePayment::AuthorizeNet::AIM;

use strict;
use Carp;
use Business::OnlinePayment::HTTPS;
use Business::OnlinePayment::AuthorizeNet;
use Business::OnlinePayment::AuthorizeNet::AIM::ErrorCodes '%ERRORS';
use Text::CSV_XS;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

@ISA = qw(Business::OnlinePayment::AuthorizeNet Business::OnlinePayment::HTTPS);
$VERSION = '3.23';

sub set_defaults {
    my $self = shift;

    $self->server('secure.authorize.net') unless $self->server;
    $self->port('443') unless $self->port;
    $self->path('/gateway/transact.dll') unless $self->path;

    $self->build_subs(qw( order_number md5 avs_code cvv2_response
                          cavv_response
                     ));
}

sub map_fields {
    my($self) = @_;

    my %content = $self->content();

    # ACTION MAP
    my %actions = ('normal authorization' => 'AUTH_CAPTURE',
                   'authorization only'   => 'AUTH_ONLY',
                   'credit'               => 'CREDIT',
                   'post authorization'   => 'PRIOR_AUTH_CAPTURE',
                   'void'                 => 'VOID',
                  );
    $content{'action'} = $actions{lc($content{'action'} || '')} || $content{'action'};

    # TYPE MAP
    my %types = ('visa'               => 'CC',
                 'mastercard'         => 'CC',
                 'american express'   => 'CC',
                 'discover'           => 'CC',
                 'check'              => 'ECHECK',
                );
    $content{'type'} = $types{lc($content{'type'} || '')} || $content{'type'};
    $self->transaction_type($content{'type'});

    # ACCOUNT TYPE MAP
    my %account_types = ('personal checking'   => 'CHECKING',
                         'personal savings'    => 'SAVINGS',
                         'business checking'   => 'CHECKING',
                         'business savings'    => 'SAVINGS',
                        );
    $content{'account_type'} = $account_types{lc($content{'account_type'} || '')}
                               || $content{'account_type'};

    if (length $content{'password'} == 15) {
        $content{'transaction_key'} = delete $content{'password'};
    }

    # stuff it back into %content
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

sub get_fields {
    my($self,@fields) = @_;

    my %content = $self->content();
    my %new = ();
    foreach( grep defined $content{$_}, @fields) { $new{$_} = $content{$_}; }
    return %new;
}

sub submit {
    my($self) = @_;

    $self->map_fields();
    $self->remap_fields(
        type              => 'x_Method',
        login             => 'x_Login',
        password          => 'x_Password',
        transaction_key   => 'x_Tran_Key',
        action            => 'x_Type',
        description       => 'x_Description',
        amount            => 'x_Amount',
        currency          => 'x_Currency_Code',
        invoice_number    => 'x_Invoice_Num',
	order_number      => 'x_Trans_ID',
	auth_code         => 'x_Auth_Code',
        customer_id       => 'x_Cust_ID',
        customer_ip       => 'x_Customer_IP',
        last_name         => 'x_Last_Name',
        first_name        => 'x_First_Name',
        company           => 'x_Company',
        address           => 'x_Address',
        city              => 'x_City',
        state             => 'x_State',
        zip               => 'x_Zip',
        country           => 'x_Country',
        ship_last_name    => 'x_Ship_To_Last_Name',
        ship_first_name   => 'x_Ship_To_First_Name',
        ship_company      => 'x_Ship_To_Company',
        ship_address      => 'x_Ship_To_Address',
        ship_city         => 'x_Ship_To_City',
        ship_state        => 'x_Ship_To_State',
        ship_zip          => 'x_Ship_To_Zip',
        ship_country      => 'x_Ship_To_Country',
        tax               => 'x_Tax',
        freight           => 'x_Freight',
        duty              => 'x_Duty',
        tax_exempt        => 'x_Tax_Exempt',
        po_number         => 'x_Po_Num',
        phone             => 'x_Phone',
        fax               => 'x_Fax',
        email             => 'x_Email',
        email_customer    => 'x_Email_Customer',
        card_number       => 'x_Card_Num',
        expiration        => 'x_Exp_Date',
        cvv2              => 'x_Card_Code',
        check_type        => 'x_Echeck_Type',
	account_name      => 'x_Bank_Acct_Name',
        account_number    => 'x_Bank_Acct_Num',
        account_type      => 'x_Bank_Acct_Type',
        bank_name         => 'x_Bank_Name',
        routing_code      => 'x_Bank_ABA_Code',
        check_number      => 'x_Bank_Check_Number',
        customer_org      => 'x_Customer_Organization_Type', 
        customer_ssn      => 'x_Customer_Tax_ID',
        license_num       => 'x_Drivers_License_Num',
        license_state     => 'x_Drivers_License_State',
        license_dob       => 'x_Drivers_License_DOB',
        recurring_billing => 'x_Recurring_Billing',
        duplicate_window  => 'x_Duplicate_Window',
        track1            => 'x_Track1',
        track2            => 'x_Track2',
    );

    my $auth_type = $self->{_content}->{transaction_key}
                      ? 'transaction_key'
                      : 'password';

    my @required_fields = ( qw(type action login), $auth_type );

    unless ( $self->{_content}->{action} eq 'VOID' ) {

      if ($self->transaction_type() eq "ECHECK") {

        push @required_fields, qw(
          amount routing_code account_number account_type bank_name
          account_name
        );

        if (defined $self->{_content}->{customer_org} and
            length  $self->{_content}->{customer_org}
        ) {
          push @required_fields, qw( customer_org customer_ssn );
        }
        elsif ( defined $self->{_content}->{license_num} and
                length  $self->{_content}->{license_num}
        ) {
          push @required_fields, qw(license_num license_state license_dob);
        }

      } elsif ($self->transaction_type() eq 'CC' ) {

        if ( $self->{_content}->{action} eq 'PRIOR_AUTH_CAPTURE' ) {
          if ( $self->{_content}->{order_number} ) {
            push @required_fields, qw( amount order_number );
          } else {
            push @required_fields, qw( amount card_number expiration );
          }
        } elsif ( $self->{_content}->{action} eq 'CREDIT' ) {
          push @required_fields, qw( amount order_number card_number );
        } else {
          push @required_fields, qw(
            amount last_name first_name card_number expiration
          );
        }
      } else {
        Carp::croak( "AuthorizeNet can't handle transaction type: ".
                     $self->transaction_type() );
      }

    }

    $self->required_fields(@required_fields);

    my %post_data = $self->get_fields(qw/
        x_Login x_Password x_Tran_Key x_Invoice_Num
        x_Description x_Amount x_Cust_ID x_Method x_Type x_Card_Num x_Exp_Date
        x_Card_Code x_Auth_Code x_Echeck_Type x_Bank_Acct_Num
        x_Bank_Account_Name x_Bank_ABA_Code x_Bank_Name x_Bank_Acct_Type
        x_Bank_Check_Number
        x_Customer_Organization_Type x_Customer_Tax_ID x_Customer_IP
        x_Drivers_License_Num x_Drivers_License_State x_Drivers_License_DOB
        x_Last_Name x_First_Name x_Company
        x_Address x_City x_State x_Zip
        x_Country
        x_Ship_To_Last_Name x_Ship_To_First_Name x_Ship_To_Company
        x_Ship_To_Address x_Ship_To_City x_Ship_To_State x_Ship_To_Zip
        x_Ship_To_Country
        x_Tax x_Freight x_Duty x_Tax_Exempt x_Po_Num
        x_Phone x_Fax x_Email x_Email_Customer x_Country
        x_Currency_Code x_Trans_ID x_Duplicate_Window x_Track1 x_Track2/);

    $post_data{'x_Test_Request'} = $self->test_transaction() ? 'TRUE' : 'FALSE';

    #deal with perl-style bool
    if (    $post_data{'x_Email_Customer'}
         && $post_data{'x_Email_Customer'} !~ /^FALSE$/i ) {
      $post_data{'x_Email_Customer'} = 'TRUE';
    } elsif ( exists $post_data{'x_Email_Customer'} ) {
      $post_data{'x_Email_Customer'} = 'FALSE';
    }

    my $data_string = join("", values %post_data);

    my $encap_character;
    # The first set of characters here are recommended by authorize.net in their
    #   encapsulating character example.
    # The second set we made up hoping they will work if the first fail.
    # The third chr(31) is the binary 'unit separator' and is our final last
    #   ditch effort to find something not in the input.
    foreach my $char( qw( | " ' : ; / \ - * ), '#', qw( ^ + < > [ ] ~), chr(31) ){
      if( index($data_string, $char) == -1 ){ # found one.
        $encap_character = $char;
        last;
      }
    }

    if(!$encap_character){
      $self->is_success(0);
      $self->error_message(
			   "DEBUG: Input contains all encapsulating characters."
			   . " Please remove | or ^ from your input if possible."
			  );
      return;
    }

    $post_data{'x_ADC_Delim_Data'} = 'TRUE';
    $post_data{'x_delim_char'} = ',';
    $post_data{'x_encap_char'} = $encap_character;
    $post_data{'x_ADC_URL'} = 'FALSE';
    $post_data{'x_Version'} = '3.1';

    my $opt = defined( $self->{_content}->{referer} )
                ? { 'headers' => { 'Referer' => $self->{_content}->{referer} } }
                : {};

    my($page, $server_response, %headers) =
      $self->https_post( $opt, \%post_data );

    #escape NULL (binary 0x00) values
    $page =~ s/\x00/\^0/g;

    #trim 'ip_addr="1.2.3.4"' added by eProcessingNetwork Authorize.Net compat
    $page =~ s/,ip_addr="[\d\.]+"$//;

    my $csv = new Text::CSV_XS({ binary=>1, escape_char=>'', quote_char => $encap_character });
    $csv->parse($page);
    my @col = $csv->fields();

    $self->server_response($page);
    $self->avs_code($col[5]);
    $self->order_number($col[6]);
    $self->md5($col[37]);
    $self->cvv2_response($col[38]);
    $self->cavv_response($col[39]);

    if($col[0] eq "1" ) { # Authorized/Pending/Test
        $self->is_success(1);
        $self->result_code($col[0]);
        if ($col[4] =~ /^(.*)\s+(\d+)$/) { #eProcessingNetwork extra bits..
          $self->authorization($2);
        } else {
          $self->authorization($col[4]);
        }
    } else {
        $self->is_success(0);
        $self->result_code($col[2]);
        $self->error_message($col[3]);
        if ( $self->result_code ) {
          my $addl = $ERRORS{ $self->result_code };
          $self->error_message( $self->error_message. ' - '. $addl->{notes})
            if $addl && ref($addl) eq 'HASH' && $addl->{notes};
        } else { #additional logging information
          #$page =~ s/\x00/\^0/g;
          $self->error_message($col[3].
            " DEBUG: No x_response_code from server, ".
            "(HTTPS response: $server_response) ".
            "(HTTPS headers: ".
              join(", ", map { "$_ => ". $headers{$_} } keys %headers ). ") ".
            "(Raw HTTPS content: $page)"
          );
        }
    }
}

1;
__END__

=head1 NAME

Business::OnlinePayment::AuthorizeNet::AIM - AuthorizeNet AIM backend for Business::OnlinePayment

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment> L<Business::OnlinePayment::AuthorizeNet>.

=cut

