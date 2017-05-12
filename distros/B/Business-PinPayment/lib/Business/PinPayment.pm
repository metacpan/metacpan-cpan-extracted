package Business::PinPayment;
use strict;
use warnings;
use Net::SSL;
use HTTP::Request;
use LWP::UserAgent;
use JSON;

our $VERSION = '0.04';

# build 4.1

sub new {
  my ($class, %args) = (@_);
  my $self = bless {}, $class;
  $args{config} ||= {};
  
  $self->{config} = {
    api_version => '1', # the '1' in the API endpoint host names, e.g. https://test-api.pin.net.au/1/charges
    api_key => undef, # Secret API Key
    api => 'charges', # 'customers', 'refunds'
    amount => '100', # 100 cents. Must be greater or equal to $1.00
    currency => 'AUD', # 'USD', 'NZD', or 'SGD'
    description => 'charges',
    email => 'tester@work.com.au',
    ip_address => undef,
    charge_token => undef, # for refunds API
    card_token => undef,
    customer_token => undef,
    card => {
      number => '5520000000000000',
      expiry_month => '05',
      expiry_year => '2014',
      cvc => '123',
      name => 'John Smith',
      address_line1 => '1 Test St',
      address_line2 => undef,
      address_city => 'Sydney',
      address_postcode => '2000',
      address_state => 'NSW',
      address_country => 'Australia'
    }
  };

  foreach my $key (qw(api_key api amount currency description email ip_address charge_token card_token customer_token)) {
    next unless defined $args{config}->{$key};
    $self->{config}->{$key} = $args{config}->{$key};
  }

  if ($self->{config}->{card_token} || $self->{config}->{customer_token}) {
    delete $self->{config}->{card};
  }
  else {
    foreach my $key (qw(number expiry_month expiry_year cvc name address_line1 address_line2 address_city address_postcode address_state address_country)) {
      next unless defined $args{config}->{card}->{$key};
      $self->{config}->{card}->{$key} = $args{config}->{card}->{$key};
    }
  }

  my $url;
  my $live = $args{live};

  my $api = delete ($self->{config}->{api});
  my $api_version = delete ($self->{config}->{api_version});
  my $api_key = delete ($self->{config}->{api_key});

  unless ($api_key) {
    $self->{error} = 'Missing Secret API Key';
    return $self;
  }

  if ($live) {
    $url = 'https://api.pin.net.au/' . $api_version;
  }
  else {
    $url = 'https://test-api.pin.net.au/' . $api_version
  }

  if ($api eq 'refunds' && $self->{config}->{charge_token}) {
    $url .= '/charges/' . $self->{config}->{charge_token} .'/' .$api;
  }
  else {
    $url .= '/' . $api;
  }

  my $ua = LWP::UserAgent->new();
  my $p = HTTP::Request->new(POST => $url);
  $p->content_type('application/json');
  $p->authorization_basic($api_key);

  my $json_request = to_json( $self->{config}, {utf8 => 1} );
  $p->content($json_request) unless $api eq 'refunds';
  $self->{response} = $ua->request($p);
  
  my $json_response;
  
  if ($self->{response}->content) {
    $json_response = from_json( $self->{response}->content, {utf8 => 1} );
    $self->{json_response} = $json_response;  
  }

  if ($json_response) {
    if ($json_response->{response}->{success}) {
      $self->{successful} = 1;
      $self->{id} = $json_response->{response}->{token};
      $self->{status} = $json_response->{response}->{status_message};
    }
    elsif ($json_response->{response}->{token}) {
      $self->{successful} = 1;
      $self->{id} = $json_response->{response}->{token};
      $self->{status} = $json_response->{response}->{status_message} || ''; # customers has non status message
    }
    elsif (exists $json_response->{error}) {
      $self->{status} = $json_response->{error};

      my @errors = ($json_response->{error_description} . '.');
      if (exists $json_response->{messages}) {
        foreach my $message (@{$json_response->{messages}}) {
          push (@errors, $message->{message} . '.');
        }
      }
      $self->{error} = join (' ', @errors);
    }
    elsif (exists $json_response->{messages}) {
      $self->{error} = $json_response->{messages}->[0]->{message};
      $self->{status} = $json_response->{messages}->[0]->{code};
    }
  }
  else {
    $self->{error} = $self->{response}->status_line;
  }
  
  return $self;
}

sub card_token {
  my $self = shift;
  return $self->{json_response}->{response}->{card}->{token} || '';
}

sub json_response {
  my $self = shift;
  return $self->{json_response} || {};
}

sub response {
  my $self = shift;
  return $self->{response} || '';
}

sub successful {
  my $self = shift;
  return $self->{successful} || undef;
}

sub error {
  my $self = shift;
  return $self->{error} || '';
}

sub id {
  my $self = shift;
  return $self->{id} || ''; # charge or customer token depending on the API
}

sub status {
  my $self = shift;
  return $self->{status} || '';
}

1;

__END__

=head1 NAME

Business::PinPayment - Interface for Pin Payment API

=head1 SYNOPSIS

  use Business::PinPayment;

  # Run a test charge of $1.00
  my $test = Business::PinPayment->new(config => {api_key => 'T3sTS3cret-ap1key'});
  if ($test->successful()) {
    print 'Test Successful';
  }
  else {
    print $test->error();
  }

  # Run a live one
  my $live = Business::PinPayment->new(
    live => 1,
    config => {
      api_key => 'L1veS3cret-ap1key',
      amount => '100',
      currency => 'AUD',
      description => 'charges',
      email => 'tester@work.com.au',
      card => {
        number => '5520000000000000',
        expiry_month => '05',
        expiry_year => '2014',
        cvc => '123',
        name => 'John Smith',
        address_line1 => '1 Test St',
        address_city => 'Sydney',
        address_postcode => '2000',
        address_state => 'NSW',
        address_country => 'Australia'
      }
    }
  );

=head1 DESCRIPTION

An interface to the Pin Payment API.

=head1 METHODS

=head2 C<new>

Instantiates a new PinPayment object. By default, it runs a test transaction with the given API key.

=over

=item C<config>

A hashref of parameters accepted by the PinPayment API . See L<https://pin.net.au/docs/api>. Default values:

  api_version => '1', # the '1' in the API endpoint host names, e.g. https://test-api.pin.net.au/1/charges
  api_key => undef, # Secret API Key
  api => 'charges', # 'customers', 'refunds'
  amount => '100', # 100 cents. Must be greater or equal to $1.00
  currency => 'AUD', # 'USD', 'NZD', or 'SGD'
  description => 'charges',
  email => 'tester@work.com.au',
  ip_address => undef,
  charge_token => undef, # for refunds API
  card_token => undef,
  customer_token => undef,
  card => {
    number => '5520000000000000',
    expiry_month => '05',
    expiry_year => '2014',
    cvc => '123',
    name => 'John Smith',
    address_line1 => '1 Test St',
    address_line2 => undef,
    address_city => 'Sydney',
    address_postcode => '2000',
    address_state => 'NSW',
    address_country => 'Australia',
  }


The following script performs a test charge and then refunds it. It then creates a test customer, charges the created customer via the customer token (ID) and card token.

  # You may need to disable SSL host name verification for testing
  $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

  my $test_api_key = 'L1veS3cret-ap1key';

  # Test charge for $1.00
  my $charge = Business::PinPayment->new(
    config => {
      api_key => $test_api_key,
      card => {
        number => '5520000000000000',
        expiry_month => '05',
        expiry_year => '2014',
        cvc => '123',
        name => 'John Smith',
        address_line1 => '1 Test St',
        address_city => 'Sydney',
        address_postcode => '2000',
        address_state => 'NSW',
        address_country => 'Australia'
      }
    }
  );

  if ($charge->successful()) {
    print 'Charge Token: ' . $charge->id() . "\n";

    # Refund the charge
    my $refund = Business::PinPayment->new(
      config => {
        api => 'refunds',
        api_key => $test_api_key,
        charge_token => $charge->id()
      }
    );

    if ($refund->successful()) {
      print 'Refund Token: ' . $refund->id() . "\n";
    }
    else {
      print 'Refund Error: ' . $refund->error() . "\n";
    }
  }
  else {
    print 'Charge Error: ' . $charge->error() . "\n";
  }

  # Create a customer
  my $customer = Business::PinPayment->new(
    config => {
      api => 'customers',
      api_key => $test_api_key,
      card => {
        number => '5520000000000000',
        expiry_month => '05',
        expiry_year => '2014',
        cvc => '123',
        name => 'John Smith',
        address_line1 => '1 Test St',
        address_city => 'Sydney',
        address_postcode => '2000',
        address_state => 'NSW',
        address_country => 'Australia'
      }
    }
  );

  if ($customer->successful()) {
    print 'Customer Token: ' . $customer->id() . "\n";

    # Charge the customer $1.00
    my $charge_customer = Business::PinPayment->new(
      config => {
        api => 'charges',
        api_key => $test_api_key,
        customer_token => $customer->id()
      },
    );

    if ($charge_customer->successful()) {
      print 'Charge Customer Token: ' . $charge_customer->id() . "\n";
    }
    else {
      print 'Charge Customer Error: ' . $charge_customer->error() . "\n";
    }

    # Charge the customer's card token $1.00
    my $charge_card = Business::PinPayment->new(
      config => {
        api => 'charges',
        api_key => $test_api_key,
        card_token => $customer->card_token(),
      },
    );

    if ($charge_card->successful()) {
      print 'Charge Card Token: ' . $charge_card->id() . "\n";
    }
    else {
      print 'Charge Card Error: ' . $charge_card->error() . "\n";
    }
  }
  else {
    print 'Customer Error: ' . $charge->error() . "\n";
  }


=item C<live>

Use the live URL when set to 1.

=back

=head2 C<successful>

Returns true if the transaction is successful.

=head2 C<error>

Returns the error message.

=head2 C<response>

Returns the response of the L<HTTP::Request> object.

=head2 C<json_response>

Returns a hashref of the JSON response content.

=head2 C<id>

Returns the transaction 'token'.

=head2 C<status>

Returns the successful 'status_message', error message or code.

=head2 C<card_token>

Returns the 'card_token'.

=head1 SEE ALSO

L<HTTP::Request>, L<LWP::UserAgent>, L<https://pin.net.au>

=head1 AUTHOR

Xufeng (Danny) Liang (danny.glue@gmail.com)

=head1 COPYRIGHT & LICENSE

Copyright 2013 Xufeng (Danny) Liang, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut