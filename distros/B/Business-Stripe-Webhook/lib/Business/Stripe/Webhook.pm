package Business::Stripe::Webhook;

use JSON::PP;
use Digest::SHA qw(hmac_sha256_hex);
use Time::Piece;
use HTTP::Tiny;

use strict;
use warnings;

our $VERSION = '1.12';
$VERSION = eval $VERSION;

sub new {
    my $class = shift;
    my %vars = @_;

    $vars{'error'}      = '';

    $vars{'reply'}      =  {
        'status'        => 'noaction',
        'sent_to'       => [ ],
        'sent_to_all'   => 'false',
    };
    
    if (exists $vars{'payload'}) {
        $vars{'webhook'} = eval { decode_json($vars{'payload'});};
        $vars{'error'}   = 'Missing payload data' unless $vars{'webhook'};
    } else {
        # Obtaining  payload from STDIN only 
        # exists for backward  compatability
        # This option is deprecated and will
        # be  removed  in  a  future version
        if (exists $ENV{'GATEWAY_INTERFACE'}) {
            read(STDIN, $vars{'payload'}, $ENV{'CONTENT_LENGTH'});
            $vars{'webhook'} = decode_json($vars{'payload'}) if $vars{'payload'};
            $vars{'error'}   = 'No payload data' unless $vars{'webhook'};
        } else {
            $vars{'error'}   = 'Looks like this is not a web request!';
        }
    }
    
    return bless \%vars, $class;
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

# Deal with webhook calls
sub process {
    my $self = shift;

    $self->{'error'} = '';
    
    if (!defined $self->{'payload'}) {
        $self->_error("No payload to process");
        return undef;
    }

    if (!$ENV{'HTTP_STRIPE_SIGNATURE'}) {
        $self->_warning('Stripe-Signature HTTP heading missing - the request is not from Stripe');
        return undef;        
    }
    
    if ($self->{'signing_secret'}) {
        my $sig = $self->check_signature;
        return undef unless defined $sig;
        if (!$sig) {
            $self->_error('Invalid Stripe Signature');
            return undef;
        }
    }
    
    my $hook_type = $self->{'webhook'}->{'type'};

    if (!$hook_type) {
        $self->_error("Invalid webhook payload");
        return undef;
    }
    
    $hook_type =~ s/\./-/g;
    if (exists $self->{$hook_type}) {
        $self->{'reply'}->{'status'} = 'success';
        push @{$self->{'reply'}->{'sent_to'}}, $hook_type; 
        &{$self->{$hook_type}}($self->{'webhook'});
    }
   
    if (exists $self->{'all-webhooks'}) {
        $self->{'reply'}->{'sent_to_all'} = 'true';
        &{$self->{'all-webhooks'}}($self->{'webhook'});
    }

    $self->{'reply'}->{'type'} = $self->{'webhook'}->{'type'};
    
    return $self->{'reply'};
}

# Check for correct Stripe Signature
sub check_signature {
    my $self = shift;
    
    $self->{'error'} = '';

    if (!$self->{'signing_secret'}) {
        $self->_warning('No signing secret has been supplied');
        return undef;        
    }
    if (!$ENV{'HTTP_STRIPE_SIGNATURE'}) {
        $self->_warning('Stripe-Signature HTTP heading missing');
        return undef;        
    }
    
    my %sig_head = ($ENV{'HTTP_STRIPE_SIGNATURE'} . ',') =~ /(\S+?)=(\S+?),/g;
    my $signed_payload = $sig_head{'t'} . '.' . $self->{'payload'};
    
    if (!defined $sig_head{'v1'}) {
        $self->_error("No v1");
        return undef;
    }
    
    if (hmac_sha256_hex($signed_payload, $self->{'signing_secret'}) eq $sig_head{'v1'}) {
        return 1;
    }
    return 0;
}

# Send reply to Stripe
sub reply {
    my $self = shift;
    my %keys = @_;
    
    $self->{'reply'}->{'timestamp'} = localtime->datetime;
    if ($self->{'error'}) {
        $self->{'reply'}->{'error'}  = $self->{'error'};
        $self->{'reply'}->{'status'} = 'failed';
    }
    
    foreach my $key(keys %keys) {
        $self->{'reply'}->{$key} = $keys{$key};
    }
    
    print "Content-type: application/json\n\n";
    print encode_json $self->{'reply'};
    return;
}

# Retrieve subscription object from Stripe
sub get_subscription {
    my ($self, $subscription, $secret) = @_;
    
    if (!$subscription) {
        $self->{'error'} = 'Subscription missing';
        $self->_error('Subscription missing');
        return undef;
    }
    
    $self->{'api_secret'} = $secret if defined $secret;
    
    if (!$self->{'api_secret'}) {
        $self->{'error'} = 'No Secret Key supplied to fetch subscription';
        return undef;
    }
    
    my $headers = {
        'headers'   => {
            'Authorization'     => 'Bearer ' . $self->{'api_secret'},
            'Stripe-Version'    => '2022-11-15',
        },
        'agent'     => "Perl-Business::Stripe::Webhook-v$VERSION",
    };
    
    my $http = HTTP::Tiny->new;
    return $http->get("https://api.stripe.com/v1/subscriptions/$subscription", $headers);
}

sub _error {
    my ($self, $message) = @_;
    
    $self->{'error'} = $message;
    if (defined &{$self->{'error'}}) {
        &{$self->{'error'}}($message);
    } else {
        STDERR->print("Stripe Webhook Error: $message\n");
    }
}
    
sub _warning {
    my ($self, $message) = @_;
    
    return if $self->{'warning'} and $self->{'warning'} =~ /^nowarn/i;
    $self->{'error'} = $message;
    if (defined $self->{'warning'}) {
        &{$self->{'warning'}}($message);
    } else {
        STDERR->print("Stripe Webhook Warning: $message\n");
    }
}


__END__


=pod

=encoding UTF-8

=head1 NAME

Business::Stripe::Webhook - A Perl module for handling webhooks sent by Stripe

=head1 VERSION

Version 1.12

=head1 SYNOPSIS

  use Stripe::Webhook;
  
  my $payload;
  read(STDIN, $payload, $ENV{'CONTENT_LENGTH'});

  my $webhook = Stripe::Webhook->new(
      signing_secret                => 'whsec_...',
      api_secret                    => 'sk_test_...',
      payload                       => $payload,
      invoice-paid                  => \&update_invoice,
      checkout-session-completed    => \&update_session,
  );
  
  die $webhook->error unless $webhook->success;

  my $result = $webhook->process();
  
  if ($webhook->success()) {
      $webhook->reply(status => 'OK');
  } else {
      $webhook->reply(error => $webhook->error());
  }
  
  sub update_invoice {
      # Process paid invoice
      ...
  }
  
  sub update_session {
      # Process checkout
      ...
  }
  
=head1 DESCRIPTION

L<Business::Stripe::Webhook> is a Perl module that provides an interface for handling webhooks sent by Stripe. It provides a simple way to verify the signature of the webhook, and allows the user to define a number of methods for processing specific types of webhooks.

This module is designed to run on a webserver as that is where Stripe webhooks would typically be sent.  It reads the payload sent from Stripe from C<STDIN> because Stripe sends an HTTP C<POST> request.  Ensure that no other module is reading from C<STDIN> or L<Business::Stripe::Webhook> will not get the correct input.

=head2 Workflow

The typical workflow for L<Business::Stripe::Webhook> is to initally create an instance of the module and to define one or more Stripe events to listen for.  This is done by providing references to your subroutines as part of the C<new> method.  Note that the webhook events you want to listen for need to be enabled in the Stripe Dashboard.

  my $webhook = Stripe::Webhook->new(
      invoice-paid => \&sub_to_handle_paid_invoice,
  );

The Stripe event names have a fullstop replaced with a minus sign.  So, C<invoice.paid> becomes C<invoice-paid>.

Next is to process the L<webhook|https://stripe.com/docs/webhooks> from L<Stripe|https://stripe.com/>.

  my $result = $webhook->process();

This will call the subroutines that were defined when the module was created and pass them the event object from Stripe.

Finally, a reply is sent back to L<Stripe|https://stripe.com/>.

  print reply(status => 'OK');

This produces a fully formed HTTP Response complete with headers as required by Stripe.

=head2 Reply time

Stripe requires a timely reply to webhook calls.  Therefore, if you need to carry out any lengthy processing after the webhook has been sent, this should be done B<after> calling the C<reply> method and flushing C<STDOUT>

  use Stripe::Webhook;
  
  my $webhook = Stripe::Webhook->new(
      signing_secret    => 'whsec_...',
      payload           => $payload,
      invoice-paid      => \&update_invoice,
  );

  $webhook->process();
  
  # Send reply for unhandled webhooks
  $webhook->reply();
  
  sub invoice-paid {
      # Send reply quickly and flush buffer
      print $webhook->reply();
      select()->flush();
      
      # Process paid invoice which will take time then do not return
      ...
      exit;
  }
      

=head2 Errors and Warnings

By default, any errors or warnings are sent to C<STDERR>.  These can be altered to instead go to your own subroutine to handle errors and/or warnings by defining these when create the object.

  my $webhook = Stripe::Webhook->new(
      invoice-paid => \&sub_to_handle_paid_invoice,
      error        => \&my_error_handler,
      warning      => \&my_warning_handler,
  );

Additionally, warnings can be turned off by setting the C<warning> parameter to C<nowarn>.  Errors cannot be turned off.

=head1 METHODS

=head2 new

Creates a new Stripe::Webhook object.

  my $webhook = Stripe::Webhook->new(
      signing_secret => 'whsec_...',
      payload        => $payload,
  );

This method takes one or more parameters:

=over

=item *

B<signing_secret>: The webhook signing secret provided by Stripe. If omitted, the Stripe Signature will not be checked.

=item *

B<payload>: A JSON string.  Required (I<see below>). The JSON object from Stripe.

=item *

B<api_secret>: The Stripe secret API Key - see L<https://stripe.com/docs/keys>. Optional but will be required if the C<get_subscription> method is needed.

=item *

B<I<stripe-event>>: One or more callbacks to the subroutines to handle the webhooks events sent by Stripe.  See L<https://stripe.com/docs/api/events/list>.

To listen for an event, change the fullstop in the Stripe event name to a minus sign and use that as the parameter.  The events you define should match the events you ask Stripe to send.  Any events Stripe sends that do not have a callback defined will be ignored (unless C<all-webhooks> is defined).

Stripe event C<invoice.paid> becomes C<invoice-paid>
Stripe event C<invoice.payment_failed> becomes C<invoice-payment_failed>

=item *

B<all-webhooks>: A callback subroutine which will be called for every event received from Stripe even if a callback subroutine for that event has not been defined.

=item *

B<error>: A callback subroutine to handle errors.  If not defined, errors are sent to C<STDERR>.

=item *

B<warning>: A callback subroutine to handle warnings.  If not defined, warnings are sent to C<STDERR>.  If set to C<nowarn>, warnings are ignored.


=back

Previous versions on L<Business::Stripe::Webhook> allowed the B<payload> parameter to be omitted.  In this case, the module would read C<STDIN> to obtain the JSON string.  This continues to work for backward compatability only but will be removed from furture versions.

=head2 success

Returns true if the last operation was successful, or false otherwise.

  if ($webhook->success()) {
      ...
  }

=head2 error

Returns the error message from the last operation, or an empty string if there was no error.

  my $error = $webhook->error();

=head2 process

This method processes the webhook sent from Stripe.  It checks the Stripe Signature if a C<signing_secret> parameter has been included and calls the defined subroutine to handle the Stripe event.  Each subroutine is passed a JSON decoded Event Object from Stripe.

  my $result = $webhook->process();

This method takes no parameters.

Normally, the return value can be ignored.  Returns C<undef> if there was an error or warning.

=head2 check_signature

Checks the signature of the webhook to verify that it was sent by Stripe.

  my $sig_ok = $webhook->check_signature();

This method takes no parameters.

Normally, this method does not need to be called.  It is called by the C<process> method if a C<signing_secret> parameter was included when the object was created.

=head2 reply

Sends a reply to Stripe.

  print reply(status => 'OK');

It takes one or more optional parameters.

Parameters passed to this method are then passed through to Stripe.  These are available in the Stripe Dashboard and are especially useful for troubleshooting during development.

The following parameters are always passed to Stripe:

=over

=item *

B<status>: C<noaction> if the event did not have a handler, C<success> if the event was handled or C<failed> if it wasn't

=item *

B<sent_to>: An array containing the names of the callback subroutines that handled the event.

=item *

B<sent_to_all>: C<true> or C<false> to indicate if the C<all-webhooks> parameter was set

=item *

B<timestamp>: The server time at which the webhook was handled

=back

=head2 get_subscription

Retrieves a subscription object from Stripe.  This is required to retrieve information such as the end of the current subscription period or whether the subscription is set to cancel after the current period.

  my $response = $webhook->get_subscription($subscription_id, $secret_key);

This method takes two parameters:

=over

=item *

B<$subscription_id>: The ID of the subscription to retrieve. Required.

=item *

B<$secret_key>: The secret API key to use to retrieve the subscription. Optional.

This is usually supplied when the object is created but can be supplied when calling this method.  If the API Key has alreay been supplied, this paramter will override the previous key.

=back

An L<HTTP::Tiny> response is returned representing the Subscription Object from Stripe - see L<https://perldoc.perl.org/HTTP::Tiny#request> 

Note: times sent from Stripe are in seconds since the epoch.  If adding them to a database which would be a typical scenario, use the SQL C<FROM_UNIXTIME> function:

  $dbh->do("UPDATE table SET currentPeriodEnd = FROM_UNIXTIME( ? ) WHERE idSubscription = ?", undef, $response->{'current_period_end'}, $response->{'subscription'});

=head1 EXAMPLES

Here's an example of how to use the module to handle a webhook:

  use Business::Stripe::Webhook;
  
  my $payload;
  read(STDIN, $payload, $ENV{'CONTENT_LENGTH'});
  
  my $webhook = Business::Stripe::Webhook->new(
      signing_secret => 'whsec_...',
      payload        => $payload,
      invoice-paid   => \&pay_invoice,
  );
  
  $webhook->process();
  
  print $webhook->reply;
  
  sub pay_invoice {
      my $event = $_[0];
      my $subscription = $event->{'data'}->{'object'}->{'subscription'};
  }
  

Here's an example of how to use the module to retrieve a subscription object:

  use Business::Stripe::Webhook;
  use JSON::PP;
  
  my $webhook = Business::Stripe::Webhook->new(
      api_secret => 'sk_...',
  );
  
  my $response = $webhook->get_subscription('sub_...');
  
  if ($response->{'success'}) {
      my $subscription = decode_json($response->{'content'});
      ...
  } else {
      my $error = $response->{'content'};
      ...
  }

=head1 SEE ALSO

L<Stripe Subscriptions API|https://stripe.com/docs/api/subscriptions>

L<Business::Stripe::Subscription>
 
L<Business::Stripe::WebCheckout>

=head1 AUTHOR

Ian Boddison <ian at boddison.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-business-stripe-webhook at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=bug-business-stripe-webhook>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::Stripe::Webhook

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-Stripe-Webhook>

=item * Search CPAN

L<https://metacpan.org/release/Business::Stripe::Webhook>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to the help and support provided by members of Perl Monks L<https://perlmonks.org/>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Ian Boddison.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

