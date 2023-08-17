package Business::Stripe::Subscription;

use HTTP::Tiny;
use JSON::PP;
use Data::Dumper;

use strict;
use warnings;

our $VERSION = '1.0';
$VERSION = eval $VERSION;

my $http = HTTP::Tiny->new;

# Create Subscription class object
sub new {
    my $class = shift;
    my %attrs = @_;

    $attrs{'currency'} //= 'GBP';

    $attrs{'error'} = '';

    $attrs{'cancel_url'}  //= "$ENV{'REQUEST_SCHEME'}://$ENV{'HTTP_HOST'}$ENV{'SCRIPT_NAME'}";
    $attrs{'success_url'} //= "$ENV{'REQUEST_SCHEME'}://$ENV{'HTTP_HOST'}$ENV{'SCRIPT_NAME'}";
    $attrs{'error'}         = 'cancel_url and success_url cannot be derived from the environment and need to be provided' unless ($attrs{'cancel_url'} and $attrs{'success_url'});

    # This is changed during testing only
    $attrs{'url'}         //= 'https://api.stripe.com/v1/';

    $attrs{'error'} = 'Secret API key provided as Public key' if $attrs{'api_public'} =~ /^sk_/;
    $attrs{'error'} = 'Public API key provided as Secret key' if $attrs{'api_secret'} =~ /^pk_/;
    $attrs{'error'} = 'Public API key provided is not a valid key' unless $attrs{'api_public'} =~ /^pk_/;
    $attrs{'error'} = 'Secret API key provided is not a valid key' unless $attrs{'api_secret'} =~ /^sk_/;
    $attrs{'error'} = 'Secret API key is missing' unless $attrs{'api_secret'};
    $attrs{'error'} = 'Public API key is missing' unless $attrs{'api_public'};

    return bless \%attrs, $class;
}

# Returns true if last operation was success
sub success {
    my $self = shift;
    return !$self->{'error'};
}

# Returns error if last operation failed
sub error {
    my $self = shift;
    return $self->{'error'};
}

# Create headers for calling Stripe API
sub _get_header {
    my $self = shift;
    return {
        'headers'   => {
            'Authorization'     => 'Bearer ' . $self->{'api_secret'},
            'Stripe-Version'    => '2022-11-15',
        },
        'agent'     => "Perl-Business::Stripe::Subscription-v$VERSION",
    };
}

# Create Stripe customer object
sub customer {
    my ($self, $customer) = @_;
    
    
    $self->{'error'} = '';
    $self->{'error'} = 'Name missing from Customer object'  unless $customer->{'name'};
    return undef if $self->{'error'};
    
    my $response = $http->post_form($self->{'url'} . 'customers', $customer, $self->_get_header);
    if ($response->{'success'}) {
        my $payload = decode_json($response->{'content'});
        if ($payload->{'object'} eq 'customer') {
            return $payload->{'id'};
        }
    }
    return undef;
}

# Create Stripe subsciption object
sub subscription {
    my ($self, $customer, $plan) = @_;
    
    $self->{'error'} = '';
    $self->{'error'} = 'Customer missing'          unless $customer;
    $self->{'error'} = 'Subscription plan missing' unless $plan;
    return undef if $self->{'error'};
    
    my $success_url = $self->{'success_url'};
    if ($self->{'append_customer'}) {
        if ($success_url =~ /\?/) {
            $success_url .= "&customer=$customer";
        } else {
            $success_url .= "?customer=$customer";
        }
    }

    my $session = {
        'success_url'                   => $success_url,
        'cancel_url'                    => $self->{'cancel_url'},
        'payment_method_types[0]'       => 'card',
        'mode'                          => 'subscription',
        'customer'                      => $customer,
        'line_items[0][price]'          => $plan,
        'line_items[0][quantity]'       => 1,
    };
    $session->{'subscription_data[trial_period_days]'} = $self->{'trial_days'} if $self->{'trial_days'};
    
    my $response = $http->post_form($self->{'url'} . 'checkout/sessions', $session, $self->_get_header);
    if ($response->{'success'}) {
        my $payload = decode_json($response->{'content'});
        if ($payload->{'object'} eq 'checkout.session') {
            return $payload->{'url'};
        }
    }
    $self->{'error'} = 'Failed to update checkout session';
    return undef;
}

# Retrieve subscription object from Stripe
sub get_subscription {
    my ($self, $subscription) = @_;
    
    if (!$subscription) {
        $self->{'error'} = 'Subscription missing';
        $self->_error('Subscription missing');
        return undef;
    }

    return $http->get("https://api.stripe.com/v1/subscriptions/$subscription", $self->_get_header);
}

# Cancel subscription at end of current period
sub cancel {
    my ($self, $subscription, $cancel) = @_;
    
    $self->{'error'} = '';
    $self->{'error'} = 'Subscription missing' unless $subscription;
    return undef if $self->{'error'};
    
    $cancel = 1 unless defined $cancel;
    my $state = $cancel ? 'true' : 'false';
    
    my $vars = {
        'cancel_at_period_end'  => $state,
    };
    
    my $response = $http->post_form("https://api.stripe.com/v1/subscriptions/$subscription", $vars, $self->_get_header);

    if ($response->{'success'}) {
        return $cancel;
    }
    $self->{'error'} = 'Failed to set cancellation';
    return undef;
}

# Cancel subscription immediately
sub cancel_now {
    my ($self, $subscription) = @_;

    $self->{'error'} = '';
    $self->{'error'} = 'Subscription missing' unless $subscription;
    return undef if $self->{'error'};
    
    my $response = $http->delete("https://api.stripe.com/v1/subscriptions/$subscription",  $self->_get_header);
        
    if ($response->{'success'}) {
        return $response->{'content'}->{'id'} eq $subscription;
    }
    $self->{'error'} = 'Cancellation failed';
    return undef;
}

# Change subscripotion to a different price plan
sub update {
    my ($self, $subscription, $plan) = @_;
    
    $self->{'error'} = '';
    $self->{'error'} = 'Subscription missing'      unless $subscription;
    $self->{'error'} = 'Subscription plan missing' unless $plan;
    return undef if $self->{'error'};
    
    my $res = $http->post_form("https://api.stripe.com/v1/subscriptions/$subscription", {}, $self->_get_header);
    my $payload = decode_json($res->{'content'});

    # Don't change to the same plan
    if ($payload->{'items'}->{'data'}[0]->{'price'}->{'id'} eq $plan) {
        $self->{'error'} = 'Cannot change to the same price plan';
        return 0;
    }

    my $vars = {
        'items[0][id]'             => $payload->{'items'}->{'data'}[0]->{'id'},
        'items[0][price]'          => $plan,
        'proration_behavior'       => 'create_prorations',
        'cancel_at_period_end'     => 'false',
    };

    my $response = $http->post_form("https://api.stripe.com/v1/subscriptions/$subscription", $vars, $self->_get_header);
    
    if ($response->{'success'}) {
        return $response->{'content'}->{'id'} eq $subscription;
    }
    $self->{'error'} = 'Update failed';
    return undef;
}

# Update card details
sub new_card {
    my ($self, $customer, $subscription) = @_;
    
    $self->{'error'} = '';
    $self->{'error'} = 'Customer missing'       unless $customer;
    $self->{'error'} = 'Subscription missing'   unless $subscription;
    return undef if $self->{'error'};

    my $session = {
        'success_url'                                   => $self->{'success_url'},
        'cancel_url'                                    => $self->{'cancel_url'},
        'payment_method_types[0]'                       => 'card',
        'mode'                                          => 'setup',
        'customer'                                      => $customer,
        'setup_intent_data[metadata][subscription_id]'  => $subscription,
    };
    
    my $response = $http->post_form($self->{'url'} . 'checkout/sessions', $session, $self->_get_header);
    if ($response->{'success'}) {
        return decode_json $response->{'content'};
    }
    
    $self->{'error'} = 'Failed to obtain card update URL';
    return undef;
}

# Set default card
sub set_card {
    my ($self, $customer, $subscription, $session) = @_;
    
    $self->{'error'} = '';
    $self->{'error'} = 'Customer missing'           unless $customer;
    $self->{'error'} = 'Subscription missing'       unless $subscription;
    $self->{'error'} = 'Checkout session missing'   unless $session;
    return undef if $self->{'error'};
    
    my $response = $http->get($self->{'url'} . "checkout/sessions/$session", $self->_get_header);
    my $json = decode_json $response->{'content'};

    if (!$json->{'setup_intent'}) {
        $self->{'error'} = 'Failed to get setup intent card';
        return undef;
    }
    
    $response = $http->get($self->{'url'} . "setup_intents/" . $json->{'setup_intent'}, $self->_get_header);

    if ($response->{'success'}) {
        $json = decode_json $response->{'content'};
        
        my $payload = {
            'default_payment_method'    => $json->{'payment_method'},
        };
        
        $response = $http->post_form($self->{'url'} . "subscriptions/$subscription", $payload, $self->_get_header);
        
        if ($response->{'success'}) {
            return 1;
        }
    }

    $self->{'error'} = 'Failed to set default card';
    return undef;
}

1;

__END__
 
=pod
 
=encoding UTF-8
 
=head1 NAME
 
L<Business::Stripe::Subscription> - Simple way to implement subscriptions using Stripe hosted checkout

=head1

Version 1.0
 
=head1 SYNOPSIS
 
  use Business::Stripe::Subscription;
 
  my $stripe = Business::Stripe::Subscription->new(
      'api_secret'  => 'sk_test_00000000000000000000000000',
      'success_url' => 'https://www.example.com/yippee.html',
      'cancel_url'  => 'https://www.example.com/cancelled.html',
  );
  
  my $cus_vars = {
      'name'        => 'Andrew Test',
      'email'       => 'atest@example.com',
  };
  
  my $customer_id  = $stripe->customer($cus_vars);
  
  $checkout_url;
  if ($stripe->success) {
      $checkout = $stripe->subscription($customer_id, 'price_00000000000000000000000');
  } else {
      die $stripe->error;
  }
  
  print "Location: $checkout_url\n\n";
  exit;
  
=head1 DESCRIPTION

A simple to use interface to Stripe subscriptions using the hosted checkout.

=head2 Keys
 
Stripe provides four API Keys.  A Secret and Publishable Key for both testing and for live transactions.  When calling the B<new> method it is necessary to provide the Secret Key.  The Publishable Key is not used by this module.
 
See L<https://stripe.com/docs/keys>
 
=head2 Workflow
 
The basic workflow for L<Business::Stripe::Subscription> is to initially create an instance of the module with the Secret Key. If using a currency other than GBP this should also be set at this time.
 
  my $stripe = Business::Stripe::Subscription->new(
      'api-secret' => 'sk_test_00000000000000000000000000',
      'currency'   => 'USD',
  );
 
Next, a B<Customer> is created unless this has been done previously.
 
  my $customer = $stripe->customer(
      'name'    => 'Andrew Test',
      'email'   => 'atest@example.com,
  );

To create the subscription, the B<customer> and Price Plan (from Stripe) are used to get a URL for the Stripe hosted checkout.

  my $url = $stripe->subscription($customer, 'price_00000000000000000000000');
  
Sending the user to the URL will take them to the Stripe hosted checkout.  From there, they will return to the B<success_url> or B<cancel_url> depending on the outcome of the transaction.
 
=head1 METHODS

=head2 new
 
  Business::Stripe::Subscription->new('api-secret' => 'sk_test_00000000000000000000000000');
 
The constructor method.  The Secret Key is required.
 
The following parameters may be provided:
 
=over 4
 
=item *
 
C<api_secret> - B<required> The Secret Key.
 
=item *
 
C<success-url>
 
=item *
 
C<cancel-url> - The callback URL that Stripe returns to once the payment subscription has completed either successfully or otherwise.  If these are not explicitly included, the current script URL is used.  Normally these need setting but can be omitted for testing or if the Stripe payment dashboard is being relied on to confirm successful payments.
 
=item *
 
C<currency> - The currency to use for the transaction.  The default is British Pounds Stirling (GBP).
 
This should be a 3 letter currency code supported by Stripe (see L<https://stripe.com/docs/currencies>).
 
=item *
 
C<trial_days> - the number of days trial before payments are started.  Stripe will still confirm card details at the start of the trial but will not charge the card until the trial period has finished.
 
=back
 
Returns a Business::Stripe::Subscription even if creation has failed.  The B<success> method should always be checked to ensure success.
 
  my $stripe = Business::Stripe::Subscription->new(
      'api-secret' => 'sk_test_00000000000000000000000000',
  );
  if ($stripe->success) {
      # ...carry on...
  } else {
      # ...deal with error...
      print $stripe->error;
  }
 
=head2 success
 
=head2 success

    if ($stripe->success) {
        # Payment was successful
    }

This method is used to check if the last method call was successful. It returns a boolean value indicating whether the method call was successful or not.

=head2 error

    die $stripe->error;

This method is used to retrieve the error message if the last method call was not successful. It returns the error message as a string.

=head2 customer

    my $customer_id = $stripe->customer(
        'name' => 'Andrew Test',
        'email' => 'atest@example.com',
    );

This method is used to create or retrieve a customer in Stripe. It takes a hash of customer information as input and returns the customer ID.

The following parameters are supported:

=over 4

=item *

C<name> - The customer's full name.

=item *

C<email> - The customer's email address.

=back

If a customer with the same email address already exists in Stripe, the existing customer ID will be returned. Otherwise, a new customer will be created and the customer ID will be returned.

=head2 subscription

    my $checkout_url = $stripe->subscription($customer_id, 'price_00000000000000000000000');

This method is used to create a subscription for a customer in Stripe. It takes the customer ID and the price plan ID as input and returns the URL for the Stripe hosted checkout.

The following parameters are supported:

=over 4

=item *

C<customer_id> - The customer ID obtained from the B<customer> method.

=item *

C<price_plan_id> - The ID of the price plan in Stripe.

=back

The price plan ID can be obtained from the Stripe Dashboard or by using the Stripe API to retrieve the available price plans.

=head2 get_subscription

    my $response = $stripe->get_subscription($subscription_id);

Retrieves the L<subscription object|https://stripe.com/docs/api/subscriptions> from L<Stripe|https://www.stripe.com>.

=over 4

=item *

C<subscription_id> - The subscription to retrieve

=back

Returns an L<HTTP::Tiny> response representing the Stripe subscription - see L<https://perldoc.perl.org/HTTP::Tiny#request>

=head2 cancel

    $stripe->cancel($subscription_id, $state);

Restores the subscription or cancels it t the end of the current billing period.

=over 4

=item *

C<subscription_id> - the subscription to cancel or restore

C<state> - (optional) if 0 the subscription is restored, otherwise it is cancelled

=back

Cancels the subscription at the end of the current billing period.  If C<state> is supplied and set to B<0>, the subscription is restored provided it has not already reached the end of the billing period.

=head2 cancel_now

    $stripe->cancel_now($subscription_id);

Cancels a subscription immediately

=over 4

=item *

C<subscription_id> - the subscription to cancel

=back

=head2 update

    $stripe->update($subscription_id, 'price_00000000000000000000000');

Updates a subscription to a new price plan.

The following parameters are supported:

=over 4

=item *

C<subscription_id> - The Stripe Subscription ID..

=item *

C<price_plan_id> - The ID of the price plan to change to.

=back

Note that if the subscription has been set to L<cancel>, it will be restored if the subscription plan is succesfully updated.

=head2  new_card

    my $url = $stripe->new_card($customer_id, $sunscription_id);

Get the URL to send a customer to a L<Stripe|http://www.stripe.com> hosted checkout to add a new card to their account.

The following parameters are supported:

=over 4

=item *

C<customer_id> - The customer ID obtained from the B<customer> method.

=item *

C<subscription_id> - The subscription to add the new card to.

=back

Returns a URL string to send the customer to so they can add a new card to their account.  Note that this does not set the new card as the one to be charged for future subscription payments.  See L<set_card>.

=head2 set_card

    $stripe->set_card($customer_id, $subscription_id, $session_id);

Set default card for future subscription payments.

=over 4

=item *

C<customer_id> - the customer to set the card for

=item *

C<subscription_id> - the subscription to update

=item *

C<session_id> - the session ID obtained from L<new_card>

=back

=head1 SEE ALSO

L<Stripe Subscriptions API|https://stripe.com/docs/api/subscriptions>

L<Business::Stripe::Webhook>
 
L<Business::Stripe::WebCheckout>

=head1 AUTHOR

Ian Boddison <ian at boddison.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-business-stripe-subscription at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=bug-business-stripe-subscription>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::Stripe::Subscription

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-Stripe-Subscription>

=item * Search CPAN

L<https://metacpan.org/release/Business::Stripe::Subscription>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to the help and support provided by members of Perl Monks L<https://perlmonks.org/>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Ian Boddison.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
