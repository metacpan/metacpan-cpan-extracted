package Business::OnlinePayment::Ogone;
our $AUTHORITY = 'cpan:ESSELENS';
use parent 'Business::OnlinePayment::HTTPS';
use strict; # keep Perl::Critic happy over common::sense;
use common::sense;
use Carp;
use XML::Simple qw/:strict/;
use Digest::SHA qw/sha1_hex sha256_hex sha512_hex/;
use MIME::Base64;

# ABSTRACT: Online payment processing via Ogone
our $VERSION = 0.2;
our $API_VERSION = 4.9;

# Ogone config defaults and info ######################################################################################

our %defaults = (
    server => 'secure.ogone.com',
    port => 443,
);

our %info = (
    'info_compat'           => '0.01', # always 0.01 for now,
    'gateway_name'          => 'Ogone',
    'gateway_url'           => 'http://www.ogone.com/',
    'module_version'        => $VERSION,
    'supported_types'       => [ qw( CC ) ],
    'token_support'         => 0, #card storage/tokenization support
    'test_transaction'      => 1, #set true if ->test_transaction(1) works
    'supported_actions'     => [
        'Authorization Only',
        'Post Authorization',
        'Query',
        'Credit',
    ]
);

# Methods #############################################################################################################

sub _info { 
    return \%info;
}

sub set_defaults {
    my $self = shift;
    my %data = @_;
    $self->{$_} = $defaults{$_} for keys %defaults;

    $self->build_subs(qw/http_args result_xml/);
}


sub submit {
    my $self = shift;
    my %data = $self->content();

    # do not allow submitting same object twice
    croak 'submitting same object twice is not allowed' if $self->{_dirty}; $self->{_dirty} = 1;

    # Turn the data into a format usable by the online processor
    croak 'no action parameter defined in content' unless exists $self->{_content}->{action};

    # Default currency to Euro
    $self->{_content}->{currency} ||= 'EUR';

    # Table to translate from Business::OnlinePayment::Ogone args to Ogone API args
    # The values of this hash are also used as a list of allowed args for the HTTP POST request, thus preventing information leakage
    my %ogone_api_args = (
        # credentials
        login   => 'USERID',
        password => 'PSWD',
        PSPID   => 'PSPID',
        
        # primary identifier
        invoice_number => 'orderID',
        
        # transaction identifiers (action = query)
        payid => 'PAYID',
        payidsub => 'PAYIDSUB',
        
        # credit card data
        card_number => 'CARDNO', 
        cvc => 'CVC',
        expiration => 'ED',
        alias => 'ALIAS',
        
        # financial data
        currency => 'Currency',
        amount => 'amount',
        
        # Ogone specific arguments
        operation => 'Operation',       # REN, DEL, DES, SAL, SAS, RFD, RFS
        eci => 'ECI',                   # defaults 7: e-commerce with ssl (9: recurring e-commerce)
        accepturl => 'accepturl',
        declineurl => 'declineurl',
        exceptionurl => 'exceptionurl',
        paramplus => 'paramplus',
        complus => 'complus',
        language => 'LANGUAGE',

        # Business::OnlinePayment common
        description => 'COM',
        name => 'CN',
        email => 'EMAIL',
        address => 'Owneraddress',
        zip => 'OwnerZip',
        city => 'ownertown',
        country => 'ownercty',
        phone => 'ownertelno',

        # client authentication (not used directly, only here as valid HTTP POST arg)
        SHASign => 'SHASign',           # see sha_key, sha_type
        
        # 3d secure arguments
        flag3d => 'FLAG3D',
        win3ds => 'win3ds',
        http_accept => 'HTTP_ACCEPT',
        http_user_agent => 'HTTP_USER_AGENT',

        # recurrent fields
        subscription_id => 'SUBSCRIPTION_ID',
        subscription_orderid => 'SUB_ORDERID',
        subscription_status => 'SUBSCRIPTION_STATUS',
        startdate => 'SUB_STARTDATE',
        enddate => 'SUB_ENDDATE',
        status => 'SUB_STATUS',
        period_unit => 'SUB_PERIOD_UNIT', # 'd', 'ww', 'm' (yes two 'w's) for resp daily weekly monthly
        period_moment => 'SUB_PERIOD_MOMENT', # Integer, the moment in time on which the payment is (0-7 when period_unit is ww, 1-31 for d, 1-12 for m?)
        period_number => 'SUB_PERIOD_NUMBER', 
    );

    # Only allow max of 2 digits after comma as we need to int ( $amount * 100 ) for Ogone
    croak 'max 2 digits after comma (or dot) allowed' if $self->{_content}->{amount} =~ m/[\,\.]\d{3}/;

    # Ogone has multiple users per login, defaults to login
    $self->{_content}->{PSPID}      ||= $self->{pspid} || $self->{PSPID} || $self->{login} || $self->{_content}->{login};

    # Login information, default to constructor values
    $self->{_content}->{login}      ||= $self->{login};
    $self->{_content}->{password}   ||= $self->{password};

    # Default Operation request for authorization (RES) for authorization only, (capture full and close) SAS for post authorization
    $self->{_content}->{operation}  ||= 'RES' if $self->{_content}->{action} =~ m/authorization only/;
    $self->{_content}->{operation}  ||= 'SAL' if $self->{_content}->{action} =~ m/normal authorization/;
    $self->{_content}->{operation}  ||= 'SAS' if $self->{_content}->{action} =~ m/post authorization/;

    # Default ECI is SSL e-commerce (7) or Recurring with e-commerce (9) if subscription_id exists
    $self->{_content}->{eci}        ||= $self->{_content}->{subscription_id} ? 9 : 7;

    # Remap the fields to their Ogone-API counterparts ie: cvc => CVC
    $self->remap_fields(%ogone_api_args);

    croak "no sha_key provided" if $self->{_content}->{sha_type} && ! $self->{_content}->{sha_key};
        
    # These fields are required by Businiess::OnlinePayment::Ogone
    my @args_basic  = (qw/login password PSPID action/);
    my @args_ccard  = (qw/card_number expiration cvc/);
    my @args_alias  = (qw/alias cvc/);
    my @args_recur  = (@args_basic, qw/name subscription_id subscription_orderid invoice_number amount currency startdate enddate period_unit period_moment period_number/, $self->{_content}->{card_numer} ? @args_ccard : @args_alias ), 
    my @args_new    = (@args_basic, qw/invoice_number amount currency/, $self->{_content}->{card_number} ? @args_ccard : @args_alias);
    my @args_post   = (@args_basic, qw/invoice_number/);
    my @query       = (@args_basic, qw/invoice_number/);

    # Poor man's given/when
    my %action_arguments = (
        qr/normal authorization/i    => \@args_new,
        qr/authorization only/i      => \@args_new,
        qr/post authorization/i      => \@args_post,
        qr/query/i                   => \@query,
        qr/recurrent authorization/i => \@args_recur
    );

    # Compile a list of required arguments
    my @args =  map { @{$action_arguments{$_}} }                # lookup value using regex, return dereffed arrayref
                grep { $self->{_content}->{action} =~ $_ }      # compare action input against regex key
                keys %action_arguments;                         # extract regular expressions

    croak 'unable to determine HTTP POST @args, is the action parameter one of ( authorization only | normal authorization | post authorization | query | recurrent authorization )' unless @args;

    # Enforce the field requirements by calling parent
    my @undefs = grep { ! defined $self->{_content}->{$_} } @args;
    
    croak "missing required args: ". join(',',@undefs) if scalar @undefs;

    # Your module should check to see if the  require_avs() function returns true, and turn on AVS checking if it does.
    if ( $self->require_avs() ) {
        $self->{_content}->{CHECK_AAV} = 1;
        $self->{_content}->{CAVV_3D} = 1;
    }

    # Define all possible arguments for http request
    my @all_http_args = (values %ogone_api_args);

    # Construct the HTTP POST parameters by selecting the ones which are defined from all_http_args
    my %http_req_args = map { $_ => $self->{_content}{$_} } 
                        grep { defined $self->{_content}{$_} } 
                        map { $ogone_api_args{$_} || $_ } @all_http_args;

    # Ogone accepts the amount as 100 fold in integer form.
    # # Adding 0.5 to amount to prevent "rounding" errors, see http://stackoverflow.com/a/1274692 or perldoc -q round
    $http_req_args{amount} = int(100 * $http_req_args{amount} + 0.5) if exists $http_req_args{amount};

    # Map normal fields to their SUB_ counterparts when recurrent authorization is used
    if($self->{_content}->{action} =~ m/recurrent authorization/) {
        $http_req_args{SUB_COMMENT} = $http_req_args{COM} if exists $http_req_args{COM};
        $http_req_args{SUB_AMOUNT} = $http_req_args{amount};
        $http_req_args{SUB_ORDERID} = $http_req_args{orderID};
    }

    # PSPID might be entered in lowercase (as per old documentation)
    $http_req_args{PSPID} = $self->{_content}{pspid} if defined $self->{_content}{pspid};

    # Calculate sha1 by default, but has to be enabled in the Ogone backend to have any effect
    my ($sha_type)  = ($self->{_content}->{sha_type} =~ m/^(1|256|512)$/);

    # Create a reference to the correct sha${sha_type}_hex function, default to SHA-1
    my $sha_hex = sub { my $type = shift; no strict; &{"sha".($type || 1)."_hex"}(@_); use strict; };

    # Algo: make a list of "KEY=value$passphrase" sort alphabetically
    my $signature = join('',
                         sort map { uc($_) . "=" . $http_req_args{$_} . ($self->{_content}{sha_key} || '') }
                         keys %http_req_args);

    $http_req_args{SHASign} = $sha_hex->($sha_type,$signature);

    # Construct the URL to query, taking into account the action and test_transaction values
    my %action_file = (
        qr/normal authorization/i  => 'orderdirect.asp',
        qr/authorization only/i    => 'orderdirect.asp',
        qr/recurrent authorization/i    => 'orderdirect.asp',
        qr/post authorization/i    => 'maintenancedirect.asp',
        qr/query/i                 => 'querydirect.asp',
    );

    my $uri_dir  = $self->test_transaction() ? 'test' : 'prod';
    my ($uri_file) =  map { $action_file{$_} }
                      grep { $self->{_content}->{action} =~ $_ }
                      keys %action_file;

    croak 'unable to determine URI path, is the action parameter one of ( authorization only | normal authorization | post authorization | query | recueent authorization)' unless $uri_file;
    
    # Construct the path to be used in https_post
    $self->{path} = '/ncol/'.$uri_dir.'/'.$uri_file;

    # Save the http args for later inspection
    $self->http_args(\%http_req_args);

    # Submit the transaction to the processor and collect a response.
    my ($page, $response_code, %reply_headers) = $self->https_post(%http_req_args);

    # Call server_response() with a copy of the entire unprocessed response
    $self->server_response([$response_code, \%reply_headers, $page]);

    my $xml = XMLin($page, ForceArray => [], KeyAttr => [] );

    # Store the result xml for later inspection
    $self->result_xml($xml);

    croak 'Ogone refused SHA digest' if $xml->{NCERRORPLUS} =~ m#^unknown order/1/s#;

    # Call is_success() with either a true or false value, indicating if the transaction was successful or not.
    if ( $response_code =~ m/^200/ ) {
        $self->is_success(0); # defaults to fail


        # croak 'incorrect credentials. WARNING: continuing with bad credentials will block your account s: '.$xml->{STATUS}.'{}'.$xml->{NCERROR} if $xml->{NCERROR} eq '50001119';

        if ( $xml->{STATUS} == 46 ) { $self->is_success(1) } # identification required
        if ( $xml->{STATUS} == 5  ) { $self->is_success(1) } # authorization accepted
        if ( $xml->{STATUS} == 9  ) { $self->is_success(1) } # payment accepted
        if ( $xml->{STATUS} == 91 ) { $self->is_success(1) } # partial payment accepted
        if ( $xml->{STATUS} == 61 ) { $self->is_success(1) } # Author. deletion waiting
        if ( $xml->{STATUS} == 2 ) { $self->failure_status('refused') } # authorization refused
        if ( $xml->{STATUS} == 0 && $xml->{NCERROR} eq '50001134' ) { $self->failure_status('declined') } # 3d secure wrong identification
        if ( $xml->{STATUS} == 0 && $xml->{NCERRORPLUS} =~ m/status \(91\)/ ) { 
            $self->failure_status('declined');
            $self->error_message('Operation only allowed on fully completed transactions (status may not be 91)'); }

    } else { 
        warn "remote server did not respond with HTTP 200 status code";
        $self->is_success(0) 
    }

    # Extract the base64 encoded HTML part
    if ( $xml->{STATUS} == 46 ) {
        my $html = decode_base64($xml->{HTML_ANSWER});
           # remove sillyness
           $html =~ s/
//g; 
           $html =~ s/ //g;

        # TODO: parse
        #open my $fh, '>', '/tmp/ogone_'.$self->{_content}->{win3ds}.'.html';
        #print $fh $html;
    }
  
    # Call result_code() with the servers result code
    $self->result_code($xml->{NCERROR});

    # If the transaction was successful, call authorization() with the authorization code the processor provided.
    if ( $self->is_success() ) {
        $self->authorization($xml->{PAYID});
    }

    # If the transaction was not successful, call error_message() with either the processor provided error message, or some error message to indicate why it failed.
    if ( not $self->is_success() and $xml->{NCERRORPLUS} ne '!' ) { # '!' == no errorplus
        $self->error_message($xml->{NCERRORPLUS});
    }
}

42;
__END__

=head1 NAME

Business::OnlinePayment::Ogone - Online payment processing via Ogone

=head1 SYNOPSYS

    use common::sense;
    use Data::Dumper;
    use Business::OnlinePayment;

    my $tx = new Business::OnlinePayment('Ogone', pspid => 'fred', 
                                                  login => 'bedrock_api',
                                                  password => 'fl1nst0ne' );

    $tx->test_transaction(1); # remove when migrating to production env

    $tx->content(
        alias => 'Customer 1',          # store (or use) an alias to the card_number (optional)
        card_number => 4111111111111111,# you can use this number for testing
        expiration => 12/15,            # for testing: like MM/YY, but in the future
        cvc => 432,                     # for testing: anything like /d{3}/
        invoice_number => 54321,        # primary transaction identifier
        amount => 23.4,                 # only 2 decimals after . allowed
        currency => 'EUR',              # optional currency (EUR, USD, GBP, CHF, ...)
        sha_type => 512,                # optional SHA checksum (1, 256, 512)
        sha_key => 'a_secret_key',      # the key with which to salt (required if sha_type is defined)
        address => 'Somestreet 234',    # optional customer address
        city => 'Brussels',             # optional customer city
        zip => 1000                     # optional customer zip code
        country => 'BE',                # optional customer country (iso?)
    );

    eval    { $tx->submit() };
    if ($@) { die 'failed to submit to remote because: '.$@ };

    if ( $tx->is_success() ) {
        print 'transaction successful\n';
        print Dumper({
            ogone_ncerror   => $tx->result_code,
            ogone_payid     => $tx->authorization });

    } else {
        print 'transaction unsuccessful: remote has raised an error\n';
        print Dumper({
            ogone_ncerrorplus   => $tx->error_message,
            http_post_args      => $tx->http_args,
            ogone_xml_response  => $tx->result_xml,
            ogone_raw_response  => $tx->server_response });
    }


=head1 DESCRIPTION

This module interfaces Business::OnlinePayment with L<Ogone|http://www.ogone.com>, a European Payment Provider.
It is based on the Ogone L<DirectLink API|http://www.ogone.com/en/Solutions/Payment%20Processing/DirectLink.aspx>.

Ogone accepted credit cards: American Express, MasterCard, VISA, AIRPLUS, Aurore, Billy, Cofinoga, Diners Club, JCB,
Laser, Privilège, Solo, MaestroUK, UATP

=head2 Features

=over 4

=item * code is documented and hopefully quite readable

=item * prevents submitting your transaction twice

=item * accepts EUR and US currencies (defaults to Euro)

=item * allows creation of VISA Alias mitigating the need to store them temporary (RES -> SAL)

=item * allows creation of Recurrent VISA bills (Subscriptions)

=item * close coupling to native API, easy to crossreference

=item * allows Ogone's native operations: RES, REN, DEL, DES, SAL, SAS, RFD, RFS

=item * uses SHASign to protect your request's integrity

=item * implements SHA-1, SHA-256 and SHA-512 signing

=item * allows switching between test and production environments

=item * low-fat is_success() check, Ogone::Status has more details

=item * no dependency on Ogone::Status if memory is a constraint

=back

=head1 PROGRAM FLOW

You have a choice when implementing credit card processing. You can pocess the money transfer in one or more steps.
If you choose to go with one step, customers will be billed directly.

=over 4

=item B<action> => 'Normal Authorization' (with B<operation> => 'SAL' (default))

=item B<action> => 'Authorization Only' (with B<operation> => 'RES' (default)) then B<action> => 'Post Authorization' (with B<operation> => 'SAS' (default))

=back

=head1 METHODS

=head2 new()

Not used directly. Creates a new instance. It's possible to pass credential infomation in the constructor.

    my $tx = new Business::OnlinePayment('Ogone', pspid => 'fred', login => 'bedrock_api', password => 'fl1nst0ne');

=head2 content()

This method takes a lot of parameters to prepare the transaction to be submitted. Depending on these parameters the
payment processor will act on them in different ways, you can consider it a sort of dispatch table. The main actors are
C<action>, C<alias>, C<win3ds>.

=head3 content() internal parameter mappings

        # credentials
        login   => 'USERID',
        password => 'PSWD',
        PSPID   => 'PSPID',
        
        # primary identifier
        invoice_number => 'orderID',
        
        # transaction identifiers (action = query)
        payid => 'PAYID',
        payidsub => 'PAYIDSUB',
        
        # credit card data
        card_number => 'CARDNO', 
        cvc => 'CVC',
        expiration => 'ED',
        alias => 'ALIAS',
        
        # financial data
        currency => 'Currency',
        amount => 'amount',
        
        # Ogone specific arguments
        operation => 'Operation',       # REN, DEL, DES, SAL, SAS, RFD, RFS
        eci => 'ECI',                   # defaults 7: e-commerce with ssl (9: recurring e-commerce)
        accepturl => 'accepturl',
        declineurl => 'declineurl',
        exceptionurl => 'exceptionurl',
        paramplus => 'paramplus',
        complus => 'complus',
        language => 'LANGUAGE',

        # Business::OnlinePayment common
        description => 'COM',
        name => 'CN',
        email => 'EMAIL',
        address => 'Owneraddress',
        zip => 'OwnerZip',
        city => 'ownertown',
        country => 'ownercty',
        phone => 'ownertelno',

        # client authentication (not used directly, only here as valid HTTP POST arg)
        SHASign => 'SHASign',           # see sha_key, sha_type
        
        # 3d secure arguments
        flag3d => 'FLAG3D',
        win3ds => 'win3ds',
        http_accept => 'HTTP_ACCEPT',
        http_user_agent => 'HTTP_USER_AGENT',

        # recurrent fields
        subscription_id => 'SUBSCRIPTION_ID',
        subscription_orderid => 'SUB_ORDERID',
        subscription_status => 'SUBSCRIPTION_STATUS',
        startdate => 'SUB_STARTDATE',
        enddate => 'SUB_ENDDATE',
        status => 'SUB_STATUS',
        period_unit => 'SUB_PERIOD_UNIT', # 'd', 'ww', 'm' (yes two 'w's) for resp daily weekly monthly
        period_moment => 'SUB_PERIOD_MOMENT', # Integer, the moment in time on which the payment is (0-7 when period_unit is ww, 1-31 for d, 1-12 for m?)
        period_number => 'SUB_PERIOD_NUMBER', 

=head3 content() required parameters

Depending on what action you are triggering a number of parameters are required. You can use the following pseudo perl
code as a reference to what exactly is required depending on the parameters.

    my @args_basic  = qw/login password PSPID action/;
    my @args_ccard  = qw/card_number expiration cvc/;
    my @args_alias  = qw/alias cvc/;
    my @args_recur  = (@args_basic, qw/name subscription_id subscription_orderid invoice_number amount currency startdate enddate period_unit period_moment period_number/, has_cc_number() ? @args_ccard : @args_alias ), 
    my @args_new    = @args_basic, qw/invoice_number amount currency/, has_cc_number() ? @args_ccard : @args_alias;
    my @args_post   = @args_basic, qw/invoice_number/;
    my @query       = @args_basic, qw/invoice_number/;

    for ($action) {
        qr/authorization only/i      => required_arguments( @args_new ),
        qr/normal authorization/i    => required_arguments( @args_new ),
        qr/post authorization/i      => required_arguments( @args_post ),
        qr/query/i                   => required_arguments( @query ),
    }

=head2 content() examples

=head3 example B<authorization only> request: requests a claim on an amount of money [RES] (and creates an alias)

    my %auth = ( pspid => 'fred', login => 'bedrock_api', password => 'fl1nst0ne' );

    my $id = $session->get('orderid');
    my $res = new Business::OnlinePayment('Ogone', %auth);

    $res->content( invoice_number => $id, action => 'authorization only', alias => 'wilma flinstone',  ... );
    $res->submit();

    if ( $res->is_success() ) {
        $dbh->do('insert into tx_status_log (id,status) values (?,?)',undef,$id,"RES OK");
    };

=head3 example B<post authorization> request: transfers an amount of money [SAL].

    my $sal = new Business::OnlinePayment('Ogone', %auth);

    $sal->content( invoice_number => $is, action => 'post authorization', ...);
    $res->submit();

    if ( $res->is_success() ) {
        $dbh->do('insert into tx_status_log (id,status) values (?,?)',undef,$id,"SAL OK");
    };

=head3 example with B<alias> (ie: no card number used)

    my $res = new Business::OnlinePayment('Ogone',%auth);

    $res->content(alias => 'wilma_flinstone', cvc => 123, ...);
    $res->submit();

    if ( $res->is_success() ) {
        $dbh->do('insert into tx_status_log (id,status) values (?,?)',undef,$id,"RES OK");
    };

=head3 example with B<recurrent> transaction using an alias

    my $res = new Business::OnlinePayment('Ogone',%auth);
    
    $res->content(  action => 'recurrent authorization',
                    alias => 'wilma_finstone',
                    name => 'Wilma Flinstone', 
                    cvc => '423',
                    amount => '42',
                    description => "monthly subscription to bedrock magazine",
                    subscription_id => 12312312
                    invoice_number => 9123,
                    subscription_orderid => 123112,
                    startdate => '2012-01-01',
                    enddate => '2013-01-01',
                    status => 1,
                    period_unit => 'm',
                    period_moment => 1,
                    period_number => 1,
                    ... );

    $res->submit();
);


=head3 Optional parameters 


=head3 Configuration parameters

=over 4

=item sha_type

=item flag3d

=item win3ds

=back

=head1 STATE DIAGRAMS

=head2 Authorization Only

         Client                                 Ogone HTTPS      Bank
      ------------------------------------------------------------------------

      1    +---|Authorization Only| orderID=1----------->. [RES]
                                                         |
      2    *<---STATUS=5 ---------0000-------------------'

=over 4

=item B<1> submit authorization only request usin RES operation with orderID=1. This will reserve the money on the credit card.

=item B<2> STATUS=5 indicates the authorization succeeded.

=back
  
=head2 Post Authorization

         Client                                 Ogone HTTPS      Bank
      ------------------------------------------------------------------------

      1    +---|Post Authorization| orderID=1----------->. [SAL] 
                                                         |
      2    *<---STATUS=91 PAYID=.. PAYIDSUB=.. ----------+ (processing)
                                                         |
      3                                                  `------->.
                                                                  | (processed) +$
      4                                     STATUS=9 .<-----------'

=over 4

=item B<1> some time later, you wish to receive/transfer the money to you. You issue a C<post authorize> request (defaults to C<SAL>)

=item B<2> STATUS=91 indicates the payment is being processed. PAYID and PAYIDSUB are references that identify the current operation on the transaction.

=item B<3> Ogone handles processing with your bank

=item B<4> money has been put into your account. STATUS is set to 9

=back
 
=head2 Refund

         Client                                 Ogone HTTPS      Bank
      ------------------------------------------------------------------------

      1 .->+---|Query| orderID or PAYID,PAYIDSUB= -->. 
        |                                            |       
        |  .<----------------------------------------'                   
        |  |
      2 STATUS == 9   
           |
      3    `---|Refund| orderID or PAYID,PAYIDSUB= ->. [RFD]
                                                     |
      4    *<-- STATUS=81 ---------------------------+ (processing)
                                                     |
      5                                              `----------->.
                                                                  | (processed) -$
      6                                     STATUS=8 .<-----------'


=over 4

=item B<1> We want to refund a transaction. To check the transaction is refundable, we must first query it.

=item B<2> Refunds are only possible once a transaction is completed (STATUS = 9) (e.g. not while it is processing = 91), thus loop until so.

=item B<3> Request refund using orderID or PAYID and PAYISUB to identify refundable operation.

=item B<4> STATUS=81 indicates the refund is being processed

=item B<5> Ogone handles processing with your bank

=item B<6> Money has been taken from your account. STATUS is set to 8

=back


=head1 TODO

=over 4

=item * Parse 3d-secure HTML 

=item * use SHA1 passwd hashing see: L<https://secure.ogone.com/ncol/test/hash_pswd.aspi>

=back

=head1 TESTING

To test this module you will need to set your credentials in the environment. Put the following in a file in your hoe directory e.g. F<~/.ogone>
The password is not the same as the PSPID password, you will need to enter the API users' password.

    export OGONE_PSPID=bob
    export OGONE_USERID=bob_api
    export OGONE_PSWD=foobar
    
Limit access to the F<~/.ogone> file

    chmod 600 ~/.ogone

Then load this file into your env en perform the testcases:

    source ~/.ogone
    perl -I lib/ t/*.t


=head1 INTERACTIVE SESSION

    [fred@triceratops ~/business-online-payment-ogone] $ curl -L http://cpanmin.us | perl - --self-upgrade
    [fred@triceratops ~/business-online-payment-ogone] $ cpanm -S Devel::REPL
    [fred@triceratops ~/business-online-payment-ogone] $ re.pl

    001:0> use lib './lib';
    002:0> use Business::OnlinePayment::Ogone;
    003:0> my $tx = new Business::OnlinePayment('Ogone', pspid => 'fred', login => 'bedrock_api', password => 'fl1nst0ne');

    bless( {
      login => "bedrock_api",
      passwprd => "fl1nst0ne",
      port => 443,
      processor => "Ogone",
      pspid => "fred",
      server => "secure.ogone.com"
    }, 'Business::OnlinePayment::Ogone' )

    004:0> 



=head1 REMOTE SIDE DOCUMENTATION

=head2 Backend

=over 4

=item Ogone Test Backend L<https://secure.ogone.com/ncol/test/frame_ogone.asp> 

=item Ogone Prod Backend L<https://secure.ogone.com/ncol/prod/frame_ogone.asp> 

=back

=head2 Online Documentation

=over 4

=item Homepage L<http://www.ogone.com>

=item Ogone DirectLink integration guide L<https://secure.ogone.com/ncol/Ogone_DirectLink_EN.pdf>

=item Ogone Alias Manager Option integration guide L<https://secure.ogone.com/ncol/Ogone_Alias_EN.pdf>

=item Ogone Status Code list L<https://secure.ogone.com/ncol/paymentinfos1.asp>

=back

=head2 Bugs, inacuracies and quircks

=head3 Security risk: B<password encryption> 

Ogone claims to encrypt your password where in fact in only hashes it using the SHA-1
algorithm. I suppose someone else wrote the accompanying texts, because the url states hash_pwsd.  

Ofcourse hashing your password is a good thing. An intruder can only steal the hashed password and use it for the
specified service until the password is changed and the hash becomes invalid. The advantage is the intruder could never
'read' your real typed in password should you have used it on other services.

But Ogone has made the hashing straight without a salt, which is a serious issue if you take rainbow tables into
account. Using the rainbow table technique on an unsalted string allows an attacker to reverse engineer the password
rather quickly.

Login into your test environment and goto L<https://secure.ogone.com/ncol/test/hash_pswd.asp> to verify.

    echo -n yourpass | sha1sum

=head3 Refunds: not possible right after transaction.

It takes a while to approve your transaction. You will need to wait for its status to drop from 91 to 9.
If your account type allows it, it's possible to refund by using another transaction. It was however not tested.

=head2 Support Helpdesk

Ogone's support helpdesk will answer promptly within a day, also for test accounts. You will need
to contact them if you would like to add some features like for example 3d-secure. Most of my
helpdesk request have been resolved in matter of days.

=head2 Credentials

You need to create a subaccount to access the API.  Use that subaccount as the USERID or login.
You will need to login with the password of the api user.

If you try to submit requests with a bad username or password your account can get blocked.
To unblock your account you should go into the users panel and reactivate the account.

=head2 Configuration Parameters

Configure the L<Ogone Test Backend|https://secure.ogone.com/ncol/test/frame_ogone.asp> or
L<Ogone Prod Backend|https://secure.ogone.com/ncol/prod/frame_ogone.asp> using the following settings:


=head3 Technical information > Your technical settings > Global security parameters 

=over 1

=item Compose string: Each parameter

=item Hash algorithm: same as C<$sha_type>

=item Character encoding: UTF-8

=back

=head3 Technical information > Your technical settings > Global security parameters 

=over 1

=item SHA-IN Pass phrase: same as C<$sha_key>

=back



