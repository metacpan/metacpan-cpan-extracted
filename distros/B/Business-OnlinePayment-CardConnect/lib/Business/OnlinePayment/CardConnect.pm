package Business::OnlinePayment::CardConnect;
use warnings;
use strict;

use Business::OnlinePayment;
use Business::OnlinePayment::HTTPS;
use vars qw(@ISA $me $DEBUG);
use URI::Escape;
use HTTP::Tiny;
use JSON qw(to_json from_json);
use Business::CreditCard qw(cardtype);
use Data::Dumper;
use Carp qw(croak);
use Log::Scrubber qw(disable $SCRUBBER scrubber :Carp scrubber_add_scrubber);

@ISA     = qw(Business::OnlinePayment::HTTPS);
$me      = 'Business::OnlinePayment::CardConnect';
$DEBUG   = 0;
our $VERSION = '0.004'; # VERSION

# PODNAME: Business::OnlinePayment::CardConnect

# ABSTRACT: Business::OnlinePayment::CardConnect - CardConnect Backend for Business::OnlinePayment

=head1 SYNOPSIS

This is a plugin for the Business::OnlinePayment interface.  Please refer to that documentation for general usage, and here for CardConnect specific usage.

In order to use this module, you will need to have an account set up with CardConnect L<https://cardconnect.com>

  use Business::OnlinePayment;
  my $tx = Business::OnlinePayment->new("CardConnect");

  $tx->content(
      type           => 'CC',
      login          => 'testdrive',
      password       => '123qwe',
      action         => 'Normal Authorization',
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
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 METHODS AND FUNCTIONS

See L<Business::OnlinePayment> for the complete list. The following methods either override the methods in L<Business::OnlinePayment> or provide additional functions.

=head2 result_code

Returns the response error code.

=head2 error_message

Returns the response error description text.

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

In order to run the provided test suite, you will first need to apply and get your account setup with CyberSource.  Then you can use the test account information they give you to run the test suite. The scripts will look for three environment variables to connect: BOP_USERNAME, BOP_PASSWORD, BOP_MERCHANTID

=head1 FUNCTIONS

=head2 _info

Return the introspection hash for BOP 3.x

=cut

=head2 _info

Return the introspection hash for BOP 3.x

=cut

sub _info {
    return {
        info_compat       => '0.01',
        gateway_name      => 'CyberSource - SOAP Toolkit API',
        gateway_url       => 'http://www.cybersource.com',
        module_version    => $Business::OnlinePayment::CardConnect::VERSION,
        supported_types   => ['CC','ECHECK'],
        supported_actions => {
            CC => [
                'Normal Authorization',
                'Post Authorization',
                'Authorization Only',
                'Credit',
                'Void',
                'Auth Reversal',
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

    $self->build_subs( # built only for backwards compatibily with old cybersource moose version
        qw( response_code response_headers response_page login password require_avs )
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
  $self->test_transaction(1); # currently not different from live

  #Read current value
  $val = $self->test_transaction();

=cut

sub test_transaction {
    my $self = shift;
    my $testMode = shift;
    if (! defined $testMode) { $testMode = $self->{'test_transaction'} || 0; }

    $self->require_avs(0);
    $self->verify_SSL(0);
    $self->port('6443');
    $self->path('/cardconnect/rest/auth');
    $self->server('fts.cardconnect.com');
    $self->SUPER::test_transaction($testMode);
}

=head2 submit

Submit your transaction to cybersource

=cut

sub submit {
    my ($self) = @_;
    local $SCRUBBER=1;
    $self->_cardconnect_init;
    my %content = $self->content();

    my $action_map = {
        'Normal Authorization' => 'auth', # this method auto detects when capture is needed
        'Authorization Only' => 'auth',
        'Post Authorization' => 'capture',
        'Void' => 'void',
        'Auth Reversal' => 'void',
        'Credit' => 'refund',
    };
    my $action = $action_map->{$content{'action'}} || die "Unsupported action: ".$content{'action'};
    die 'Amount must contain a decimal' if defined $content{'amount'} && $content{'amount'} !~ /\./;

    my $method = '_cardconnect_'.$action;
    return $self->$method();
}

sub _cardconnect_void {
    my ($self) = @_;
    my %content = $self->content();

    my $post_data = {
        retref =>  $content{'order_number'},
        merchid => $content{'merchantid'},
    };

    my $page = $self->_do_put_request( 'void', $post_data );
    my $response = $page->{'content_json'};

    $self->is_success($response->{'respstat'} eq 'A' ? $response : undef);
    $self->result_code($response->{'respstat'});
    $self->order_number($response->{'retref'});
    $self->error_message($response->{'resptext'});

    return $response;
}

sub _cardconnect_refund {
    my ($self) = @_;
    my %content = $self->content();

    my $post_data = {
        retref  => $content{'order_number'},
        merchid => $content{'merchantid'},
    };
    $post_data->{'amount'} = $content{'amount'} if defined $content{'amount'};

    my $page = $self->_do_put_request( 'capture', $post_data );
    my $response = $page->{'content_json'};

    $self->is_success($response->{'respstat'} eq 'A' ? $response : undef);
    $self->result_code($response->{'respstat'});
    $self->order_number($response->{'retref'});
    $self->error_message($response->{'resptext'});
    $self->order_number($response->{'retref'});
    $self->error_message($response->{'resptext'});
    $self->card_token($response->{'token'});

    return $response;
}

sub _cardconnect_capture {
    my ($self) = @_;
    my %content = $self->content();

    my $post_data = {
        retref =>  $content{'order_number'},
        merchid => $content{'merchantid'},
    };
    $post_data->{'amount'} = $content{'amount'} if defined $content{'amount'};
    $self->_cardconnect_add_level2($post_data);

    my $page = $self->_do_put_request( 'capture', $post_data );
    my $response = $page->{'content_json'};

    $self->is_success($response->{'respstat'} eq 'A' ? $response : undef);
    $self->result_code($response->{'respstat'});
    $self->order_number($response->{'retref'});
    $self->error_message($response->{'resptext'});
    $self->order_number($response->{'retref'});
    $self->error_message($response->{'resptext'});
    $self->card_token($response->{'token'});

    return $response;
}

sub _cardconnect_add_level2 {
    my ($self,$post_data) = @_;
    my %content = $self->content();
    $post_data->{'ponumber'} = $content{'po_number'} if defined $content{'po_number'};
    $post_data->{'shiptozip'} = $content{'ship_zip'} if defined $content{'ship_zip'};
    $post_data->{'taxamnt'} = $content{'tax'} if defined $content{'tax'};
    if ( defined $content{'products'} && scalar( @{ $content{'products'} } ) < 100 ) {
        my @products;
        my $lineno = 0;
        foreach my $productOrig ( @{ $content{'products'} } ) {
            $lineno++;
            my $item = {
                "discamnt"    => $productOrig->{'discount'},
                "unitcost"    => $productOrig->{'cost'},
                "lineno"      => $lineno,
                "description" => $productOrig->{'description'},
                "taxamnt"     => $productOrig->{'tax'},
                "quantity"    => $productOrig->{'quantity'},
                "netamnt"     => $productOrig->{'amount'},
                #"upc"         => "UPC-1",
                #"material"    => "MATERIAL-1"
            };
            push @products, $item;
        }
    }
}

sub _cardconnect_auth {
    my ($self) = @_;
    my %content = $self->content();

    my $post_data = {};
    if ($content{'routing_code'} && $content{'account_number'}) {
        $post_data = {
            accttype => 'ECHK',
            account  => $content{'account_number'},
            bankaba  => $content{'routing_code'},
            merchid  => $content{'merchantid'},
            name     => $content{'first_name'}.' '.$content{'last_name'},
            amount   => $content{'amount'},
            currency => $content{'currency'} || "USD",
        }
    } elsif ($content{'card_number'}) {
        $content{'expiration'} =~ s/\///; # CardConnect doesn't want the / between MM and YY
        $post_data = {
            merchid  => $content{'merchantid'},
            orderid  => $content{'invoice_number'},

            account  => $content{'card_number'},
            expiry   => $content{'expiration'},
            cvv2     => $content{'cvv2'},

            amount   => $content{'amount'},
            currency => $content{'currency'} || "USD",
            name     => $content{'first_name'}.' '.$content{'last_name'},
            address  => $content{'address'},
            city     => $content{'city'},
            region   => $content{'state'},
            country  => $content{'country'},
            postal   => $content{'zip'},
            email    => $content{'email'},
            ecomind  => "E",
            track    => undef,
            tokenize => "Y",
            userfields => [
                { description => $content{'description'} },
            ],
        };
        $self->_cardconnect_add_level2($post_data);
    } else {
        die 'Unsupported payment method';
    }
    $post_data->{'capture'} = "Y" if $content{'action'} eq 'Normal Authorization';

    my $page = $self->_do_put_request( 'auth', $post_data );
    my $response = $page->{'content_json'};

    $self->is_success($response->{'respstat'} eq 'A' ? $response : undef);
    $self->result_code($response->{'respstat'});
    $self->authorization($response->{'authcode'});
    $self->order_number($response->{'retref'});
    $self->error_message($response->{'resptext'});
    $self->card_token($response->{'token'});
    $self->avs_code($response->{'avsresp'});
    $self->cvv2_response($response->{'cvvresp'});

    return $response;
}

sub _do_put_request {
    my ($self, $action, $post_data) = @_;
    my %content = $self->content(); # needed for basic auth
    my $options = {
        headers => {
            'Content-Type' => 'application/json',
        },
        content => to_json $post_data,
    };
    $self->login($content{'login'});
    $self->password($content{'password'});
    my $url= 'https://'.uri_escape($content{'login'}).':'.uri_escape($content{'password'}).'@fts.cardconnect.com:6443/cardconnect/rest/'.$action;
    $self->server_request( $url."\n\n".$options->{'content'} );
    warn $self->server_request if $DEBUG;
    my $page = HTTP::Tiny->new->request('PUT', $url, $options);
    $self->server_response( $page );
    warn Dumper $self->server_response if $DEBUG;
    if ($page->{'status'} eq '200') {
        $page->{'content_json'} = eval { from_json $page->{'content'}; }
    } elsif ($page->{'status'} eq '401') {
        $page->{'content_json'} = {
            respstat => 'U',
            resptext => 'This request requires authentication.',
        };
    } else {
        $page->{'content_json'} = {
            respstat => 'U',
            resptext => 'Unknown response from payment gateway.',
        };
    }
    my $e = $@;
    die "Could not process JSON: ".$e if ($e);
    $self->response_code($page->{'status'});
    $self->response_headers($page->{'headers'});
    $self->response_page($page->{'content'});
    return $page;
}

sub _default_scrubber {
    my $cc = shift;
    my $del = substr($cc,0,6).('X'x(length($cc)-10)).substr($cc,-4,4); # show first 6 and last 4
    return $del;
}

sub _cardconnect_scrubber_add_card {
    my ( $self, $cc ) = @_;
    return if ! $cc;
    my $scrubber = $self->{_scrubber};
    scrubber_add_scrubber({quotemeta($cc)=>&{$scrubber}($cc)});
}

sub _cardconnect_init {
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
            quotemeta($ptr->{'ftp_password'}||'')=>'DELETED',
            ($ptr->{'cvv2'} ? '(?<=[^\d])'.quotemeta($ptr->{'cvv2'}).'(?=[^\d])' : '')=>'DELETED',
            });
        $self->_cardconnect_scrubber_add_card($ptr->{'card_number'});
    }
}

1;
