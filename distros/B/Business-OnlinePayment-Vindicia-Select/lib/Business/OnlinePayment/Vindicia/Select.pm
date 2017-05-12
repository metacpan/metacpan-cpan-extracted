package Business::OnlinePayment::Vindicia::Select;
use strict;
use warnings;

use Business::OnlinePayment;
use vars qw(@ISA $me $DEBUG $VERSION);
use HTTP::Tiny;
use XML::Writer;
use XML::Simple;
use Business::CreditCard qw(cardtype);
use Data::Dumper;
use Log::Scrubber qw(disable $SCRUBBER scrubber :Carp scrubber_add_scrubber);

@ISA     = qw(Business::OnlinePayment);
$me      = 'Business::OnlinePayment::Vindicia::Select';
$DEBUG   = 0;
$VERSION = '0.002';

=head1 NAME

Business::OnlinePayment::Vindicia::Select - Backend for Business::OnlinePayment

=head1 SYNOPSIS

This is a plugin for the Business::OnlinePayment interface.  Please refer to that docuementation for general usage.

  use Business::OnlinePayment;
  my $tx = Business::OnlinePayment->new(
     "Vindicia::Select",
     default_Origin => 'NEW', # or RECURRING
  );

  $tx->content(
      type           => 'CC',
      login          => 'testdrive',
      password       => '123qwe',
      action         => 'billTransactions',
      description    => 'FOO*Business::OnlinePayment test',
      amount         => '49.95',
      customer_id    => 'tfb',
      name           => 'Tofu Beast',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      card_number    => '4007000000027',
      expiration     => '09/02',
      cvv2           => '1234', #optional
      invoice_number => '54123',
      vindicia_nvp   => {
        custom => 'data',
        goes   => 'here',
      },
  );
  $tx->submit();

=head1 METHODS AND FUNCTIONS

See L<Business::OnlinePayment> for the complete list. The following methods either override the methods in L<Business::OnlinePayment> or provide additional functions.

=head2 result_code

Returns the response error code.  Will be empty if no code is returned, or if multiple codes can exist.

=head2 error_message

Returns the response error description text.  Will be empty if no code error is returned, or if multiple errors can exist.

=head2 server_request

Returns the complete request that was sent to the server.  The request has been stripped of card_num, cvv2, and password.  So it should be safe to log.

=cut

sub server_request {
    my ( $self, $val, $tf ) = @_;
    if ($val) {
        $self->{server_request} = scrubber $val;
        $self->server_request_dangerous($val,1) unless $tf;
    }
    return $self->{server_request};
}

=head2 server_request_dangerous

Returns the complete request that was sent to the server.  This could contain data that is NOT SAFE to log.  It should only be used in a test environment, or in a PCI compliant manner.

=cut

sub server_request_dangerous {
    my ( $self, $val, $tf ) = @_;
    if ($val) {
        $self->{server_request_dangerous} = $val;
        $self->server_request($val,1) unless $tf;
    }
    return $self->{server_request_dangerous};
}

=head2 server_response

Returns the complete response from the server.  The response has been stripped of card_num, cvv2, and password.  So it should be safe to log.

=cut

sub server_response {
    my ( $self, $val, $tf ) = @_;
    if ($val) {
        $self->{server_response} = scrubber $val;
        $self->server_response_dangerous($val,1) unless $tf;
    }
    return $self->{server_response};
}

=head2 server_response_dangerous

Returns the complete response from the server.  This could contain data that is NOT SAFE to log.  It should only be used in a test environment, or in a PCI compliant manner.

=cut

sub server_response_dangerous {
    my ( $self, $val, $tf ) = @_;
    if ($val) {
        $self->{server_response_dangerous} = $val;
        $self->server_response($val,1) unless $tf;
    }
    return $self->{server_response_dangerous};
}

=head1 Handling of content(%content) data:

=head2 action

The following actions are valid

  normal authorization
  authorization only
  post authorization
  credit
  void
  auth reversal

=head1 TESTING

The test suite runs using mocked data results.
All tests are run using MOCKED return values.
If you wish to run REAL tests then add these ENV variables.

 export PERL_BUSINESS_VINDICIA_USERNAME=your_test_user
 export PERL_BUSINESS_VINDICIA_PASSWORD=your_test_password

If you would like to create your own tests, or mock your own responses you can do the following

  use Business::OnlinePayment;
  my $tx = Business::OnlinePayment->new(
     "Vindicia::Select",
     default_Origin => 'NEW', # or RECURRING
  );
  push @{$client->{'mocked'}}, {
     action => 'billTransactions', # must match the action you call, or the script will die
     login => 'mocked', # must match the login credentials used, or the script will die
     resp => 'ok_duplicate', # or you can return a HASH of the actual data you want to mock
  };

=head1 FUNCTIONS

=head2 _info

Return the introspection hash for BOP 3.x

=cut

sub _info {
    return {
        info_compat       => '0.01',
        gateway_name      => 'Vindicia Select - SOAP API',
        gateway_url       => 'http://www.vindicia.com',
        module_version    => $VERSION,
        supported_types   => ['CC','ECHECK'],
        supported_actions => {
            CC => [

                #non-standard bop actions
                'billTransactions',
                'fetchBillingResults',
                'fetchByMerchantTransactionId',
                'refundTransactions',
            ],
        },
    };
}

=head2 set_defaults

Used by BOP to set default values during "new"

=cut

sub set_defaults {
    my $self = shift;
    my %opts = @_;

    $self->build_subs(
        qw( order_number md5 avs_code cvv2_response card_token cavv_response failure_status verify_SSL )
    );

    $self->test_transaction(0);
    $self->{_scrubber} = \&_default_scrubber;
}

=head2 test_transaction

Get/set the server used for processing transactions.  Possible values are Live, Certification, and Sandbox
Default: Live

  #Live
  $self->test_transaction(0);

  #Test
  $self->test_transaction(1);

  #Read current value
  $val = $self->test_transaction();

=cut

sub test_transaction {
    my $self = shift;
    my $testMode = shift;
    if (! defined $testMode) { $testMode = $self->{'test_transaction'} || 0; }

    $self->require_avs(0);
    $self->verify_SSL(0);
    $self->port('443');
    $self->path('v1.1/soap.pl'); #https://soap.prodtest.sj.vindicia.com/v1.1/soap.pl
    if (lc($testMode) eq 'sandbox' || lc($testMode) eq 'test' || $testMode eq '1') {
        $self->server('soap.prodtest.sj.vindicia.com');
        $self->{'test_transaction'} = 1;
    } else {
        $self->server('soap.vindicia.com');
        $self->{'test_transaction'} = 0;
    }
    return $self->{'test_transaction'};
}

=head2 submit

Do a bop-ish action on vindicia

=cut

sub submit {
    my ($self) = @_;

    local $SCRUBBER=1;
    $self->_tx_init;

    my %content = $self->content();
    my $action = $content{'action'};
    die 'unsupported action' unless grep { $action eq $_ } @{$self->_info()->{'supported_actions'}->{'CC'}};
    $self->$action();
}

=head2 billTransactions

Send a batch of transactions to vindica for collection

is_success means the call was successful, it does NOT mean all of your transactions were accepted
In order to verify your transaction you need to look at result->{'response'} for an ARRAY of potential
errors, if no errors exist the result will not have a response array

=cut

sub billTransactions {
    my ($self) = @_;
    local $SCRUBBER=1;
    $self->_tx_init;
    my %content = $self->content();

    my $transactions = [];
    if ($content{'card_number'}) {
        # make it so you can submit a single transaction using the normal
        # BOP content system, this is OPTIONAL
        $self->_add_trans($transactions,\%content);
    }
    foreach my $trans (@{$content{'transactions'}}) {
        # Additional transactions may be submitted using a transactions array
        # It should follow the same rules that the normal %content hash does
        # for transactional data
        $self->_add_trans($transactions,$trans);
    }

    my $ret = $self->_call_soap('billTransactions', 'transactions', $transactions);
    $self->is_success($ret->{'return'}->{'returnString'} && $ret->{'return'}->{'returnString'} eq 'OK' ? 1 : 0);
    $self->order_number($ret->{'return'}->{'soapId'});

    # make everyone's life easier my making sure this is always an array
    $ret->{'response'} = [$ret->{'response'}] if exists $ret->{'response'} && ref $ret->{'response'} ne 'ARRAY';

    $ret;
}

sub _add_trans {
    my ($self,$transactions,$content) = @_;
    my $trans = {
        subscriptionId           => $content->{'subscription_number'},
        paymentMethodId          => $content->{'card_token'},
        merchantTransactionId    => $content->{'invoice_number'},
        customerId               => $content->{'customer_number'},
        divisionNumber           => $content->{'division_number'},
        authCode                 => $content->{'authorization'},
        paymentMethodIsTokenized => 0,
        status                   => 'Failed', #we shouldn't be here unless we already failed
        timestamp                => $content->{'timestamp'},
        amount                   => $content->{'amount'},
        currency                 => $content->{'currency'} || 'USD',
        creditCardAccount        => $content->{'card_number'},
    };
    if ($content->{'vindicia_nvp'} && ref $content->{'vindicia_nvp'} eq 'HASH') {
        # A common vindica_nvp would be "vin:Divison"
        push @{$trans->{'nameValues'}}, {
            name => $_,
            value => $content->{'vindicia_nvp'}->{$_},
        } foreach grep { !ref $content->{'vindicia_nvp'}->{$_} or die "Invalid vindicia_nvp format" } keys %{$content->{'vindicia_nvp'}};
    }
    push @$transactions, $trans;
};

=head2 fetchBillingResults

Lookup changes in a time period

  $tx->content(
      login           => 'testdrive',
      password        => '123qwe',
      action          => 'fetchBillingResults',
      start_timestamp => '2012-09-11T21:34:32.265Z',
      end_timestamp   => '2012-09-11T22:34:32.265Z',
      page            => '0',   # optional, defaults to zero
      page_size       => '100', # optional, defaults to 100
  );
  my $response = $tx->submit();

=cut

sub fetchBillingResults {
    my ($self) = @_;
    local $SCRUBBER=1;
    $self->_tx_init;
    my %content = $self->content();
    my $ret = $self->_call_soap('fetchBillingResults',
        'timestamp',    $content{'start_timestamp'},
        'endTimestamp', $content{'end_timestamp'},
        'page',        ($content{'page'}//0),
        'pageSize',    ($content{'page_size'}//100),
    );
    $self->is_success($ret->{'return'}->{'returnString'} && $ret->{'return'}->{'returnString'} eq 'OK' ? 1 : 0);
    $self->order_number($ret->{'return'}->{'soapId'});

    # make everyone's life easier my making sure this is always an array
    $ret->{'transactions'} = [$ret->{'transactions'}] if exists $ret->{'transactions'} && ref $ret->{'transactions'} ne 'ARRAY';

    $ret;
}

=head2 fetchByMerchantTransactionId

Lookup a specific transaction in vindicia

  $tx->content(
      login           => 'testdrive',
      password        => '123qwe',
      action          => 'fetchByMerchantTransactionId',
      invoice_number  => 'abc123',
  );
  my $response = $tx->submit();

=cut

sub fetchByMerchantTransactionId {
    my ($self) = @_;
    local $SCRUBBER=1;
    $self->_tx_init;
    my %content = $self->content();
    my $ret = $self->_call_soap('fetchByMerchantTransactionId', 'merchantTransactionId', $content{'invoice_number'});
    $self->is_success($ret->{'transaction'} ? 1 : 0);
    $self->order_number($ret->{'return'}->{'soapId'});
    $ret;
}

=head2 refundTransactions

Cancel or refund (sadly you can't choose one) a transaction.

  $tx->content(
      login           => 'testdrive',
      password        => '123qwe',
      action          => 'refundTransactions',
      invoice_number  => 'abc123',
  );
  my $response = $tx->submit();

=cut

sub refundTransactions {
    my ($self) = @_;
    local $SCRUBBER=1;
    $self->_tx_init;
    my %content = $self->content();

    my @refunds;
    push @refunds, $content{'invoice_number'} if exists $content{'invoice_number'};
    # TODO, do we even care to send more than one?

    my $ret = $self->_call_soap('refundTransactions', 'refunds', \@refunds);
    $self->is_success($ret->{'return'}->{'returnString'} && $ret->{'return'}->{'returnString'} eq 'OK' ? 1 : 0);
    $self->order_number($ret->{'return'}->{'soapId'});

    # make everyone's life easier my making sure this is always an array
    $ret->{'response'} = [$ret->{'response'}] if exists $ret->{'response'} && ref $ret->{'response'} ne 'ARRAY';

    # Important note: Vindica does NOT return an error message if the invoice_number is not found.... it simply ignores that invoice

    $ret;
}

sub _call_soap {
    my $self = shift;
    my $action = shift;
    my @pairs = @_;
    my %content = $self->content();

    my $post_data;
    my $writer = new XML::Writer(
        OUTPUT      => \$post_data,
        DATA_MODE   => 1,
        DATA_INDENT => 2,
        ENCODING    => 'UTF-8',
    );

    $writer->xmlDecl();
    $writer->startTag('SOAP-ENV:Envelope',
        "xmlns:ns0" => "http://soap.vindicia.com/v1_1/Select",
        "xmlns:ns1" => "http://schemas.xmlsoap.org/soap/envelope/",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xmlns:SOAP-ENV" => "http://schemas.xmlsoap.org/soap/envelope/",
    );
      $writer->startTag('ns1:Body');
        $writer->startTag("ns0:$action");
          $writer->startTag('auth');
            $writer->dataElement('version', '1.1' );
            $writer->dataElement('login', $content{'login'} );
            $writer->dataElement('password', $content{'password'});
            $writer->dataElement('userAgent', "$me $VERSION" );
          $writer->endTag('auth');
          while (scalar @pairs) {
              my $item = shift @pairs;
              my $value = shift @pairs;
              $self->_xmlwrite( $writer, $item, $value );
          }
        $writer->endTag("ns0:$action");
      $writer->endTag('ns1:Body');
    $writer->endTag('SOAP-ENV:Envelope');
    $writer->end();

    $self->server_request( $post_data );

    if (ref $self->{'mocked'} eq 'ARRAY' && scalar @{$self->{'mocked'}}) {
        my $mock = shift @{$self->{'mocked'}};
        die "Unexpected mock action" unless $mock->{'action'} eq $action;
        die "Unexpected mock login" unless $mock->{'login'} eq $content{'login'};
        my $resp = ((ref $mock->{'resp'}) ? $mock->{'resp'} : $self->_common_mock($action,$mock->{'resp'}));
        $self->server_response( "MOCKED\n\n".Dumper $resp );
        return $resp;
    }

    my $url = 'https://'.$self->server.'/'.$self->path;
    my $verify_ssl = 1;
    my $response = HTTP::Tiny->new( verify_SSL=>$verify_ssl )->request('POST', $url, {
        headers => {
            'Content-Type' => 'text/xml;charset=UTF-8',
            'SOAPAction' => "http://soap.vindicia.com/v1_1/Select#$action",
        },
        content => $post_data,
    } );
    $self->server_response( $response->{'content'} );
    my $resp = eval { XMLin($response->{'content'})->{'soap:Body'}->{$action.'Response'} } || {};
    $resp = $self->_resp_simplify($resp);
#use Data::Dumper; warn Dumper $post_data,$response->{'content'},$resp;
    $resp;
}

sub _resp_simplify {
    my ($self,$resp) = @_;
    delete $resp->{'xmlns'};
    foreach my $t (keys %$resp) {
        if (ref $resp->{$t} eq 'ARRAY') {
            $resp->{$t} = $self->_resp_simplify_array($resp->{$t});
        } elsif (ref $resp->{$t} eq 'HASH') {
            $resp->{$t} = $self->_resp_simplify_hash($resp->{$t});
        }
    }
    $resp;
}

sub _resp_simplify_array {
    my ($self,$resp) = @_;
    foreach my $value (@$resp) {
        $self->_resp_simplify_hash($value);
    }
    $resp;
}

sub _resp_simplify_hash {
    my ($self,$resp) = @_;
    delete $resp->{'xsi:type'};
    delete $resp->{'xmlns'};
    foreach my $t (keys %{$resp}) {
        if ($t eq 'nameValues') {
            my $arr = $resp->{$t};
            $arr = [$arr] unless ref $arr eq 'ARRAY';
            my $hash = {};
            foreach my $t2 (@$arr) {
                my $n = $t2->{'name'}->{'content'};
                my $v = $t2->{'value'}->{'content'};
                if (!exists $hash->{$n}) {
                    $hash->{$n} = $v;
                } elsif (ref $hash->{$n}) {
                    push @{$hash->{$n}}, $v;
                } else {
                    $hash->{$n} = [$hash->{$n},$v];
                }
            }
            $resp->{$t} = $hash;
        } elsif (ref $resp->{$t} eq 'HASH' && (exists $resp->{$t}->{'content'} || exists $resp->{$t}->{'xmlns'})) {
            $resp->{$t} = $resp->{$t}->{'content'};
        }
    }
    $resp;
}

sub _default_scrubber {
    my $cc = shift;
    my $del = 'DELETED';
    if (length($cc) > 11) {
        $del = substr($cc,0,6).('X'x(length($cc)-10)).substr($cc,-4,4); # show first 6 and last 4
    } elsif (length($cc) > 5) {
        $del = substr($cc,0,2).('X'x(length($cc)-4)).substr($cc,-2,2); # show first 2 and last 2
    } else {
        $del = ('X'x(length($cc)-2)).substr($cc,-2,2); # show last 2
    }
    return $del;
}

sub _scrubber_add_card {
    my ( $self, $cc ) = @_;
    return if ! $cc;
    my $scrubber = $self->{_scrubber};
    scrubber_add_scrubber({quotemeta($cc)=>&{$scrubber}($cc)});
}

sub _tx_init {
    my ( $self, $opts ) = @_;

    # initialize/reset the reporting methods
    $self->is_success(0);
    $self->server_request('');
    $self->server_response('');
    $self->error_message('');

    # some calls are passed via the content method, others are direct arguments... this way we cover both
    my %content = $self->content();
    foreach my $ptr (\%content,$opts) {
        next if ! $ptr;
        scrubber_init({
            quotemeta($ptr->{'password'}||'')=>'DELETED',
            ($ptr->{'cvv2'} ? '(?<=[^\d])'.quotemeta($ptr->{'cvv2'}).'(?=[^\d])' : '')=>'DELETED',
            });
        $self->_scrubber_add_card($ptr->{'card_number'});
        $self->_scrubber_add_card($ptr->{'account_number'});
    }
}

sub _xmlwrite {
    my ( $self, $writer, $item, $value ) = @_;
    if ( ref($value) eq 'HASH' ) {
        my $attr = $value->{'attr'} ? $value->{'attr'} : {};
        $writer->startTag( $item, %{$attr} );
        foreach ( keys(%$value) ) {
            next if $_ eq 'attr';
            $self->_xmlwrite( $writer, $_, $value->{$_} );
        }
        $writer->endTag($item);
    } elsif ( ref($value) eq 'ARRAY' ) {
        foreach ( @{$value} ) {
            $self->_xmlwrite( $writer, $item, $_ );
        }
    } else {
        $writer->startTag($item);
        $writer->characters($value);
        $writer->endTag($item);
    }
}

our $common_mock = {
    billTransactions => {
        ok => {
              'return' => {
                            'returnString' => 'OK',
                            'returnCode' => '200',
                            'soapId' => 'aaaaaa4817abcba350f9bded7024a44d9e03b42b',
                          },
        },
        ok_duplicate => {
              'return' => {
                            'returnString' => 'OK',
                            'returnCode' => '200',
                            'soapId' => 'aaaaaa4817abcba350f9bded7024a44d9e03b42b',
                          },
              'response' => [
                              {
                                'code' => '400',
                                'merchantTransactionId' => 'TEST-1477512979.48453-3',
                                'description' => 'Billing has already been attempted for Transaction ID TEST-1477512979.48453-3'
                              },
                            ],
        },
    },
    fetchBillingResults => {
        ok => {
              'return' => {
                            'returnString' => 'OK',
                            'returnCode' => '200',
                            'soapId' => 'aaaaaa4817abcba350f9bded7024a44d9e03b42b',
                          },
        },
    },
    refundTransactions => {
        ok => {
              'return' => {
                            'returnString' => 'OK',
                            'returnCode' => '200',
                            'soapId' => 'aaaaaa4817abcba350f9bded7024a44d9e03b42b',
                          },
        },
    },
    fetchByMerchantTransactionId => {
        ok => {
          'return' => {
                        'returnCode' => '200',
                        'returnString' => 'OK',
                        'soapId' => 'aaaaaa727eca030a16ddad54e4eaf8088a5fa322'
                      },
          'transaction' => {
                           'currency' => 'USD',
                           'authCode' => '123456',
                           'selectTransactionId' => 'TEST-1477513825.95777',
                           'amount' => '9000',
                           'subscriptionId' => 'TEST-1477513825.95775',
                           'paymentMethodIsTokenized' => '0',
                           'creditCardAccountHash' => 'aaaaaa96f35af3876fc509665b3dc23a0930aab1',
                           'nameValues' => {
                                           'vin:BillingCycle' => '0',
                                           'vin:RetryNumber' => '0'
                                         },
                           'paymentMethodId' => '1',
                           'divisionNumber' => '1',
                           'subscriptionStartDate' => '2016-10-26T13:30:26-07:00',
                           'creditCardAccount' => '411111XXXXXX1111',
                           'status' => 'Failed',
                           'VID' => 'aaaaaa5286ba2a8199a651d9f7afbee9a015fbb2',
                           'customerId' => '123',
                           'timestamp' => '2012-09-11T15:34:32-07:00',
                           'merchantTransactionId' => 'TEST-1477513825.95777'
                         }
        },
    },
};
sub _common_mock {
    my ($self,$action,$label) = @_;
    return $common_mock->{$action}->{$label} || die 'Mock label not found, label: '.$label."\n";
}

1;
