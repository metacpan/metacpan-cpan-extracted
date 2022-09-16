package Business::Stripe::WebCheckout;

# TODO - Pre  release
#
# TODO - Post release
#
# 12-04-21 - Improve obtaining success/cancel URLs from environment
# 14-04-21 - Add P&P
# 16-04-21 - Properly implement live testing without real Stripe keys
#

use HTTP::Tiny;
use JSON::PP;
use Data::Dumper;

use strict;
use warnings;

our $VERSION = '1.3';
$VERSION = eval $VERSION;

sub new {
    my $class = shift;
    my %attrs = @_;

    my @products;
    $attrs{'trolley'} = \@products;

    $attrs{'currency'} //= 'GBP';

    $attrs{'error'} = '';

    $attrs{'cancel-url'}  //= "$ENV{'REQUEST_SCHEME'}://$ENV{'HTTP_HOST'}$ENV{'SCRIPT_NAME'}";
    $attrs{'success-url'} //= "$ENV{'REQUEST_SCHEME'}://$ENV{'HTTP_HOST'}$ENV{'SCRIPT_NAME'}";
    $attrs{'error'}         = 'cancel-url and success-url cannot be derived from the environment and need to be provided' unless ($attrs{'cancel-url'} and $attrs{'success-url'});

    # This is changed during testing only
    $attrs{'url'}         //= 'https://api.stripe.com/v1/checkout/sessions';

    $attrs{'error'} = 'Public API key provided is not a valid key' if $attrs{'api-public'} and $attrs{'api-public'} !~ /^pk_/;
    $attrs{'error'} = 'Secret API key provided is not a valid key' unless $attrs{'api-secret'} =~ /^sk_/;
    $attrs{'error'} = 'Secret API key provided as Public key' if $attrs{'api-public'} and $attrs{'api-public'} =~ /^sk_/;
    $attrs{'error'} = 'Public API key provided as Secret key' if $attrs{'api-secret'} =~ /^pk_/;
    $attrs{'error'} = 'Secret API key is too short' unless length $attrs{'api-secret'} > 100;
    $attrs{'error'} = 'Secret API key is missing' unless $attrs{'api-secret'};

    return bless \%attrs, $class;
}

sub success {
    my $self = shift;
    return !$self->{'error'};
}

sub error {
    my $self = shift;
    return $self->{'error'};
}

sub add_product {
    my ($self, %product) = @_;
    $self->{'error'} = '';

    unless ($product{'price'} > 0 and $product{'price'} !~ /\./) {
        $self->{'error'} = 'Invalid price.  Price is an integer of the lowest currency unit';
        return;
    }
    unless ($product{'qty'} > 0 and $product{'qty'} !~ /\./) {
        $self->{'error'} = 'Invalid qty.  Qty is a positive integer';
        return;
    }

    unless ($product{'name'}) {
        $self->{'error'} = 'No product name supplied';
        return;
    }
    $self->{'intent'} = undef;
    # Update existing Product by ID
    foreach my $prod(@{$self->{'trolley'}}) {
        if ($prod->{'id'} eq $product{'id'}) {
            foreach my $field('name', 'description', 'qty', 'price') {
                $prod->{$field} = $product{$field};
            }
            return scalar @{$self->{'trolley'}};
        }
    }

    my $new_product;
    foreach my $field('id', 'name', 'description', 'qty', 'price') {
        $new_product->{$field} = $product{$field};
    }
    push @{$self->{'trolley'}}, $new_product;
}

sub list_products {
    my $self = shift;
    my @products;
    foreach my $prod(@{$self->{'trolley'}}) {
        push @products, $prod->{'id'};
    }
    return @products;
}

sub get_product {
    my ($self, $id) = @_;
    $self->{'error'} = '';

    unless ($id) {
        $self->{'error'} = 'Product ID missing';
        return;
    }

    foreach my $prod(@{$self->{'trolley'}}) {
        if ($prod->{'id'} eq $id) {
            return $prod;
        }
    }
    $self->{'error'} = "Product ID $id not found";
}

sub delete_product {
    my ($self, $id) = @_;
    $self->{'error'} = '';

    unless ($id) {
        $self->{'error'} = 'Product ID missing';
        return;
    }

    for (my $i = 0; $i < scalar @{$self->{'trolley'}}; $i++) {
        if (${$self->{'trolley'}}[$i]->{'id'} eq $id) {
            $self->{'intent'} = undef;
            splice @{$self->{'trolley'}}, $i, 1;
            return scalar @{$self->{'trolley'}};
        }
    }
    $self->{'error'} = "Product ID $id not found";
}

# Private method called internally by get_intent and get_intent_id
# Attempts to obtain a new session intent from Stripe
# Returns existing session if it exists and Trolley hasn't changed
sub _create_intent {
    my $self = shift;

    if ($self->{'intent'}) {
        return $self->{'intent'};
    }

    $self->{'reference'} //= __PACKAGE__;

    my $http = HTTP::Tiny->new;
    my $headers = {
        'Authorization' => 'Bearer ' . $self->{'api-secret'},
        'Stripe-Version'    => '2020-08-27',
    };

    # Update URL and headers during stripe-live tests
    if ($self->{'url'} =~ /^https:\/\/www\.boddison\.com/) {
        $headers->{'BODTEST'} = __PACKAGE__ . " v$VERSION";
        $headers->{'Authorization'} = undef,
        $self->{'url'} .= '?fail' if $self->{'api-test-fail'};
    }

    my $vars = {
        'headers'           => $headers,
        'agent'             => 'Perl-WebCheckout/$VERSION',
    };
    my $payload = {
        'cancel_url'                => $self->{'cancel-url'},
        'success_url'               => $self->{'success-url'},
        'payment_method_types[0]'   => 'card',
        'mode'                      => 'payment',
        'client_reference_id'       => $self->{'reference'},
    };
    $payload->{'customer_email'} = $self->{'email'} if $self->{'email'};
    if ($self->{'getShipping'}) {
        $payload->{'shipping_address_collection[allowed_countries][0]'} = $self->{'getShipping'};
    }

    my $i = 0;
    foreach my $prod(@{$self->{'trolley'}}) {
        $payload->{"line_items[$i][currency]"}      = $self->{'currency'};
        $payload->{"line_items[$i][name]"}          = $prod->{'name'};
        $payload->{"line_items[$i][description]"}   = $prod->{'description'} if $prod->{'description'};
        $payload->{"line_items[$i][quantity]"}      = $prod->{'qty'};
        $payload->{"line_items[$i][amount]"}        = $prod->{'price'};
        $i++;
    }

    my $response = $http->post_form($self->{'url'}, $payload, $vars);

    $self->{'error'} = '';
    if ($response->{'success'}) {
        $self->{'intent'} = $response->{'content'};
    } else {
        my $content = $response->{'content'};
        eval {
            $content = decode_json($response->{'content'});
        };
        if ($@) {
            $self->{'error'} = $content;
        } else {
            $self->{'error'} = $content->{'error'}->{'message'};
        }
    }
}

sub get_intent {
    my ($self, %attrs) = @_;

    $self->{'reference'} = $attrs{'reference'} if $attrs{'reference'};
    $self->{'email'} = $attrs{'email'} if $attrs{'email'};

    $self->{'error'} = '';
    return $self->_create_intent;
}

sub get_intent_id {
    my ($self, %attrs) = @_;

    $self->{'reference'} = $attrs{'reference'} if $attrs{'reference'};
    $self->{'email'} = $attrs{'email'} if $attrs{'email'};

    $self->{'error'} = '';
    my $intent = $self->_create_intent;
    if ($self->{'error'}) {
        return $intent;
    } else {
        return decode_json($intent)->{'id'};
    }
}

sub get_ids {
    my ($self, %attrs) = @_;

    $self->{'public-key'} = $attrs{'public-key'} if $attrs{'public-key'};

    $self->{'error'} = '';
    unless ($self->{'api-public'}) {
        $self->{'error'} = 'Required Public API Key missing';
        return;
    }

    $self->{'reference'} = $attrs{'reference'} if $attrs{'reference'};
    $self->{'email'} = $attrs{'email'} if $attrs{'email'};

    my $intent_id = $self->get_intent_id;

    my %result;
    if ($self->{'error'}) {
        $result{'status'}  = 'error';
        $result{'message'} = $self->{'error'};
    } else {
        $result{'status'}  = 'success';
        $result{'api-key'} = $self->{'api-public'};
        $result{'session'} = $intent_id;
    }

    $attrs{'format'} = 'text' unless $attrs{'format'};
    return encode_json(\%result) if lc($attrs{'format'}) eq 'json';
    return $result{'message'} || "$result{'api-key'}:$result{'session'}";
}

sub checkout {
    my $self = shift;

    my $data = $self->get_ids( 'format' => 'text', @_);

    return if $self->{'error'};

    my ($key, $session) = split /:/, $data;

    unless ($key and $session) {
        $self->{'error'} = 'Error getting key and session';
        return;
    }

return <<"END_HTML";
Content-type: text/html

<html>
<head>
<script src="https://js.stripe.com/v3/"></script>
<script>
var stripe = Stripe('$key');
var result = stripe.redirectToCheckout({sessionId: '$session'});
if (result.error) {
    alert(result.error.message);
}
</script>
</head>
<body>
END_HTML

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::Stripe::WebCheckout - Simple way to implement payments using Stripe hosted checkout

=head1 SYNOPSIS

  use Business::Stripe::WebCheckout;

  my $stripe = Business::Stripe::WebCheckout->new(
      'api-secret'  => 'sk_test_00000000000000000000000000',
  );

  # Note price is in lowest currency unit (i.e pence or cents not pounds or dollars)
  $stripe->add_product(
      'id'      => 1,
      'name'    => 'My product',
      'qty'     => 4,
      'price'   => 250,
  );

  foreach my $id($stripe->list_products) {
      print "$id is " . $stripe->get_product($id)->{'name'} . "\n";
  }

  $stripe->checkout(
      'api-public'  => 'pk_test_00000000000000000000000000',
  );

=head1 DESCRIPTION

A simple to use interface to the Stripe payment gateway utilising the Stripe hosted checkout.  The only dependencies are the core modules L<HTTP::Tiny> and L<JSON::PP>.

L<Business::Stripe::WebCheckout> has a Trolley into which products are loaded.  Once the Trolley is full of the product(s) to be paid for, this is passed to the Stripe hosted checkout either using Javascript provided by Stripe (see L<https://stripe.com/docs/payments/accept-a-payment?integration=checkout>), Javascript provided in this document or the B<checkout> utility method that allows a server side script to send the user to Stripe invisibly.

At present L<Business::Stripe::WebCheckout> only handles simple, one-off payments.  Manipulation of customers, handling subscriptions and user hosted checkout is not supported.  However, this implementation makes payment for a single item or group of items simple to implement.

In August 2022 Stripe released a new version of their API.  Currently this module uses the previous version C<2020-08-27>.  The module overrides the setting in the Stripe dashboard so this requires no user input.  For the simple cases this module is intended for, this presents no problems and it is only pointed out to try and prevent confusion for anyone trying to cross reference the module calls with the Stripe API documentation.  The latest version of the API introduces some additional functionality which may be incorporated into this module in the future.

=head2 Keys

Stripe provides four API Keys.  A Secret and a Publishable (called Public within L<Business::Stripe::WebCheckout>) for both testing and for live transactions.  When calling the B<new> method it is necessary to provide the Secret Key.  Before calling the B<checkout> method to redirect the user to the Stripe hosted checkout, the Public Key is also required so this is usually provided to the B<new> method.

See L<https://stripe.com/docs/keys>

=head2 Workflow

The basic workflow for L<Business::Stripe::WebCheckout> is to initially create an instance of the module with at minimum the Secret Key. If using a currency other than GBP this should also be set at this time.

  my $stripe = Business::Stripe::WebCheckout->new(
      'api-public' => 'pk_test_00000000000000000000000000',
      'api-secret' => 'sk_test_00000000000000000000000000',
      'currency'   => 'USD',
  );

Next, products are assembled in the Trolley.  There are methods to add, update, remove and list the products in the Trolley.

  $stripe->add_product(
      'id'      => 1,
      'name'    => 'My product',
      'qty'     => 4,
      'price'   => 250,
  );
  my @products = $stripe->list_products;

Once the Trolley contains all the products, the user is redirected to the Stripe hosted checkout where they pay for the Trolley.  Once this happens, Stripe returns to your site using one of the URLs provided depending on whether the payment was successful or not.  Where no return URLs are provided, the script URL is used although in practice this is not usually sufficient and return URLs will be needed.

  $stripe->checkout;

Examples of other ways of redirecting the user to the Stripe hosted checkout and listed in the B<Examples> section.

=head1 METHODS

=head2 new

  Business::Stripe::WebCheckout->new('api-secret' => 'sk_test_00000000000000000000000000');

The constructor method.  The Secret Key is required.

The following parameters may be provided:

=over 4

=item *

C<api-secret> - B<required> The Secret Key.

=item *

C<api-public> - The Public Key.
This would normally be provided to the B<new> method but can be left until sending the user to the Stripe hosted checkout.

=item *

C<success-url>

=item *

C<cancel-url> - The callback URL that Stripe returns to once the payment transaction has completed either successfully or otherwise.  If these are not explicitly included, the current script URL is used.  Normally these need setting but can be omitted for testing or if the Stripe payment dashboard is being relied on to confirm successful payments.

=item *

C<currency> - The currency to use for the transaction.  The default is British Pounds Stirling (GBP).

This should be a 3 letter currency code supported by Stripe (see L<https://stripe.com/docs/currencies>).

=item *

C<reference> - The reference to use for the transaction

Defaults to "Business::Stripe::WebCheckout" as this is required by Stripe.

=item *

C<email> - If provided, this pre-fills the user's email address in the Stripe hosted checkout.  If provided, this is then non editable during checkout.

=item *

C<getShipping> - If provided, this forces Stripe to capture the customer's shipping address during checkout.  This should be the country code for the customer's shipping location (see L<https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2>).

=back

Returns a Business::Stripe::WebCheckout even if creation has failed.  The B<success> method should always be checked to ensure success.

  my $stripe = Business::Stripe::WebCheckout->new(
      'api-secret' => 'sk_test_00000000000000000000000000',
      'api-public' => 'pk_test_00000000000000000000000000',
  );
  if ($stripe->success) {
      # ...carry on...
  } else {
      # ...deal with error...
      print $stripe->error;
  }

=head2 success

Returns true if the last method call was successful

=head2 error

Returns the last error message or an empty string if B<success> returned true

=head1 Trolley Methods

=head2 add_product

Adds a product to the Trolley.  Or update the product if an existing B<id> is provided.

A product consists of the following hash entries

=over 4

=item *

C<id> - B<required>
A unique ID for the product.
This is not passed to Stripe and is only used by L<Business::Stripe::WebCheckout> to identify current products.

If B<add_product> is called with an existing ID, that product is updated.

=item *

C<name> - B<required>
The name of the product as it will be passed to Stripe.

=item *

C<description> - B<optional>
A one line decsription of the product as it will be passed to Stripe.  This is typically used to specify options such as colour.

=item *

C<qty> - B<required>
The number of the product to add to the Trolly.

=item *

C<price> - B<required>
The price of the product in the lowest currency unit.  For example - E<pound>2.50 would be 250 as it is 250 pence;  $10 would be 1000 as it is 1000 cents.

Note that special rules apply to Hungarian Forint (HUF) and Ugandan Shilling (UGX) - see L<https://stripe.com/docs/currencies>

=back

On success, returns the number of products in the Trolley

=head2 delete_product(id)

Delete the product with the specified id

On success, returns the number of products in the Trolley

=head2 list_products

Returns an array contining the IDs of the products in the Trolley

=head2 get_product(id)

On success, returns a hash with the product details.  Each key of the hash corresponds to items listed for B<add_product>

=head1 Checkout Methods

=head3 parameters

The C<get_intent>, C<get_intent_id>, C<get_ids> and C<checkout> methods all take the following optional parameters.  See C<new> for their descriptions.

=over 4

=item *

C<reference>

=item *

C<email>

=back

=head2 get_intent

This method will not normally need calling.

Returns the full session intent from Stripe if successful or the Stripe error otherwise.

=head2 get_intent_id

Returns the intend_id that needs passing to the Stripe hosted checkout if successful or the Stripe error otherwise.

=head2 get_ids

In addition to the parameters listed above, this method also accepts the following optional parameters

=over 4

=item *

C<public-api> - See C<new>

=item *

C<format> - The format of the returned information.  Current options are JSON or text.  The default is text.

=back

Provides the Public Key and Intent Session ID as these are the two pieces of information required by the Javascript provided by Stripe and the Javacsript provided here.  If text output is used (the default) the Public Key and Intent Session ID are provided as a colon separated string.

=head2 checkout

A simple implementation of redirecting the user to the Stripe hosted checkout.

Calling this method provides a fully formed HTML document including the Content-Type header that can be sent to the users browser.  The HTML document contains all the Javascript required to sent the user to the Stripe hosted checkout transparently.  Unless you are building a checkout with entirely AJAX calls, you will almost certainly want to use this method.

=head1 EXAMPLES

=head2 1 - Using the Stripe provided Javascript

See L<https://stripe.com/docs/payments/accept-a-payment?integration=checkout>

=head3 Javascript

  <html>
    <head>
      <title>Buy cool new product</title>
      <script src="https://js.stripe.com/v3/"></script>
    </head>
    <body>
      <button id="checkout-button">Checkout</button>

      <script type="text/javascript">
        // Create an instance of the Stripe object with your publishable API key
        var stripe = Stripe('pk_test_00000000000000000000000000');
        var checkoutButton = document.getElementById('checkout-button');

        checkoutButton.addEventListener('click', function() {
          // Create a new Checkout Session using the server-side endpoint you
          // created in step 3.
          fetch('https://example.com/cgi-bin/trolley.pl', {
            method: 'POST',
          })
          .then(function(response) {
            return response.json();
          })
          .then(function(session) {
            return stripe.redirectToCheckout({ sessionId: session.id });
          })
          .then(function(result) {
            // If `redirectToCheckout` fails due to a browser or network
            // error, you should display the localized error message to your
            // customer using `error.message`.
            if (result.error) {
              alert(result.error.message);
            }
          })
          .catch(function(error) {
            console.error('Error:', error);
          });
        });
      </script>
    </body>
  </html>

=head3 Perl trolley.pl

  use Business::Stripe::WebCheckout;
  use strict;

  my $stripe = Business::Stripe::WebCheckout->new(
    'api-public'    => 'pk_test_00000000000000000000000000',
    'api-secret'    => 'sk_test_00000000000000000000000000',
    'success-url'   => 'https://www.example.com/yippee.html',
    'cancel-url'    => 'https://www.example.com/ohdear.html',
    'reference'     => 'My Payment',
  );

  $stripe->add_product(
    'id'          => 'test',
    'name'        => 'Expensive Thingy',
    'description' => 'Special edition version',
    'qty'         => 1,
    'price'       => 50000,
  );

  print "Content-Type: text/json\n\n";
  print $stripe->get_intent;


=head2 2 - Simpler Javascript using XHR without exposing Public Key

=head3 Javascript

  <html>
  <head>
  <script src="https://js.stripe.com/v3/"></script>
  <script>
  var xhr=new XMLHttpRequest();
  function buyNow() {
      xhr.open("POST", "https://www.example.com/cgi-bin/trolley.pl", true);
      xhr.onreadystatechange=function() {
      if (xhr.readyState == 4 && xhr.status == 200) {
                  var keys = xhr.response.split(':');
                  var stripe = Stripe(keys[0]);
                  var result = stripe.redirectToCheckout({ sessionId: keys[1] });
                  if (result.error) {
                          alert(result.error.message);
                  }
          }
      }
      xhr.send();
  }
  </script>
  </head>
  <body>
  <input type="button" value="Buy Now!" onClick="buyNow();">
  </body>
  </html>

=head3 Perl - trolley.pl

  use Business::Stripe::WebCheckout;
  use strict;

  my $stripe = Business::Stripe::WebCheckout->new(
    'api-public'    => 'pk_test_00000000000000000000000000',
    'api-secret'    => 'sk_test_00000000000000000000000000',
    'success-url'   => 'https://www.example.com/yippee.html',
    'cancel-url'    => 'https://www.example.com/ohdear.html',
    'reference'     => 'My Payment',
  );

  $stripe->add_product(
    'id'          => 'test',
    'name'        => 'Expensive Thingy',
    'description' => 'Special edition version',
    'qty'         => 1,
    'price'       => 50000,
  );

  print "Content-Type: text/text\n\n";
  print $stripe->get_ids;

=head2 3 - Simpest method (no Javascript required)

=head3 HTML

  <html>
  <head>
  <title>Simple Checkout</title>
  </head>
  <body>
  <form method="post" action="https://www.example.com/cgi-bin/trolley.pl">
  <input type="submit" value="Buy Now!">
  </form>
  </body>
  </html>

=head3 Perl - trolley.pl

  use Business::Stripe::WebCheckout;
  use strict;

  my $stripe = Business::Stripe::WebCheckout->new(
    'api-public'    => 'pk_test_00000000000000000000000000',
    'api-secret'    => 'sk_test_00000000000000000000000000',
    'success-url'   => 'https://www.example.com/yippee.html',
    'cancel-url'    => 'https://www.example.com/ohdear.html',
    'reference'     => 'My Payment',
  );

  $stripe->add_product(
    'id'          => 'test',
    'name'        => 'Expensive Thingy',
    'description' => 'Special edition version',
    'qty'         => 1,
    'price'       => 50000,
  );

  if ($stripe->success) {
     print $stripe->checkout;
  } else {
     # handle errors...
  }

This last example prints out a fully formed HTML document to the browser containing only the C<head> section.  The HTML contains the Javascript necessary to pass the use to the Stripe hosted checkout.  The HTML is complete with Content-Type header.  If other headers are required, such as Set-Cookie headers, they can be included immediately before calling C<checkout>.

  print "Set-cookie: MyCookie=$order_number; path=/\n";
  $stripe->checkout;


=head1 SEE ALSO

L<Net::Stripe>, L<Net::Stripe::Simple>, L<Business::Stripe>

=head1 AUTHOR

=over 4

=item *

Ian Boddison <ian@boddison.com>

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-business-stripe-webcheckout at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-Stripe-WebCheckout>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::Stripe::WebCheckout


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-Stripe-WebCheckout>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Business-Stripe-WebCheckout>

=item * Search CPAN

L<https://metacpan.org/release/Business-Stripe-WebCheckout>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to the help and support provided by members of Perl Monks L<https://perlmonks.org/>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2021 by Ian Boddison.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
