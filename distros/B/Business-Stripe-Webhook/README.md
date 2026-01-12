# Business-Stripe-Webhook

Business::Stripe::Webhook is a Perl module that helps you verify and process Stripe webhook events, with a simple callback-based workflow.

## Installation

To install this module, run:

```sh
perl Makefile.PL
make
make test
make install
```

## Basic usage

```perl
use Business::Stripe::Webhook;

my $payload;
read(STDIN, $payload, $ENV{'CONTENT_LENGTH'});

my $webhook = Business::Stripe::Webhook->new(
    signing_secret => 'whsec_...',
    payload        => $payload,
    invoice-paid   => \&handle_invoice_paid,
);

die $webhook->error unless $webhook->success;

$webhook->process();
print $webhook->reply(status => 'OK');

sub handle_invoice_paid {
    my ($event) = @_;
    # ... handle event ...
}
```

## License

This project is released under the MIT (Expat) license.

## Contributing & support

GitHub pull requests are the preferred way to report bugs or propose changes. Please open a PR in the repository where you found this module.

If a PR is not possible, you can use RT (CPAN's request tracker) as a legacy option:

- https://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-Stripe-Webhook
