#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(hmac_sha256_hex);

use Business::Stripe::Webhook;

my $count = 0; 
print "\n";

my $payload;
read(DATA, $payload, 10000);

my $webhook_fail   = Business::Stripe::Webhook->new(
    signing_secret  => 'whsec_...',
    'payload'       => $payload,
    'invoice-paid'  => \&pay_invoice,
);

my $got_warn = 0;
eval {
    $webhook_fail->process();
} or do {
    $got_warn = 1;
};

ok( $got_warn, "Signature warning generated");

ok( !$webhook_fail->success, "Signature error" );

my $signing_secret = 'whsec_12345ABCDEFGHIJKLM';
$ENV{'HTTP_STRIPE_SIGNATURE'} = 't=1685897094,v1=54e5192b196409f1ee7098db99bb4f6243fa1d069160b9c3b813ec96cc220658';

my $payload_pass = '{ "test": "test payload and signature", "type": "invoice.paid", "object": "event" }';

# Generate v1 Signature for testing
if (1 == 0) {
    my %sig_head = ($ENV{'HTTP_STRIPE_SIGNATURE'} . ',') =~ /(\S+?)=(\S+?),/g;
    my $signed_payload = $sig_head{'t'} . '.' . $payload_pass;
    print("\n\nv1 Signature for testing:\n" . hmac_sha256_hex($signed_payload, $signing_secret) . "\n\n");
}

my $webhook_pass   = Business::Stripe::Webhook->new(
    signing_secret  => $signing_secret,
    'payload'       => $payload_pass,
    'invoice-paid'  => \&pay_invoice,
);

$webhook_pass->process();

ok( $webhook_pass->success, "Signature pass" );

sub pay_invoice {
    is( $_[0]->{'object'}, 'event', "pay.invoice handled - " . ++$count );
}

done_testing($count + 3);

__DATA__
{
  "id": "evt_1NFK32EfkkexSbWLZb6LoEap",
  "object": "event",
  "api_version": "2020-08-27",
  "data": {
    "object": {
      "id": "in_1NFK30EfkkfpSbWLeMoI8HzB",
      "object": "invoice",
      "account_country": "GB",
      "account_name": "Test Account",
      "account_tax_ids": null,
      "amount_due": 0,
      "amount_paid": 0,
      "amount_remaining": 0,
      "amount_shipping": 0,
      "application": null,
      "application_fee_amount": null,
      "attempt_count": 0,
      "attempted": true,
      "auto_advance": false,
      "automatic_tax": {
        "enabled": false,
        "status": null
      },
      "billing_reason": "subscription_create",
      "charge": null,
      "collection_method": "charge_automatically",
      "created": 1685897094,
      "currency": "gbp",
      "custom_fields": null,
      "customer": "cus_O1MkgyuDNTaGf3",
      "customer_address": null,
      "customer_email": "name@example.com",
      "customer_name": "Andrew Test",
      "customer_phone": null,
      "customer_shipping": null,
      "customer_tax_exempt": "none",
      "customer_tax_ids": [
      ],
      "default_payment_method": null,
      "default_source": null,
      "default_tax_rates": [
      ],
      "description": null,
      "discount": null,
      "discounts": [
      ],
      "due_date": null,
      "ending_balance": 0,
      "footer": null,
      "from_invoice": null,
      "hosted_invoice_url": "https://invoice.stripe.com/i/acct_1JJ14BEfqlexSbWL/test_xxxx",
      "invoice_pdf": "https://pay.stripe.com/invoice/acct_1JJ14CFetfgnWL/test_xxxx",
      "last_finalization_error": null,
      "latest_revision": null,
      "lines": {
        "object": "list",
        "data": [
          {
            "id": "il_1NFK30EfkkexSbWLJ6LdYb1Y",
            "object": "line_item",
            "amount": 0,
            "amount_excluding_tax": 0,
            "currency": "gbp",
            "description": "Test Product",
            "discount_amounts": [
            ],
            "discountable": true,
            "discounts": [
            ],
            "livemode": true,
            "metadata": {
            },
            "period": {
              "end": 1687106694,
              "start": 1685897094
            },
            "plan": {
              "id": "price_1JNHCVEfkkexGeDFOzIaBHMd",
              "object": "plan",
              "active": true,
              "aggregate_usage": null,
              "amount": 349,
              "amount_decimal": "349",
              "billing_scheme": "per_unit",
              "created": 1628687431,
              "currency": "gbp",
              "interval": "month",
              "interval_count": 1,
              "livemode": true,
              "metadata": {
              },
              "nickname": null,
              "product": "prod_K1JqFYpEGX0FPb",
              "tiers_mode": null,
              "transform_usage": null,
              "trial_period_days": null,
              "usage_type": "licensed"
            },
            "price": {
              "id": "price_1JNHCVEfkkebGHYeRzIaBHMd",
              "object": "price",
              "active": true,
              "billing_scheme": "per_unit",
              "created": 1628687431,
              "currency": "gbp",
              "custom_unit_amount": null,
              "livemode": true,
              "lookup_key": null,
              "metadata": {
              },
              "nickname": null,
              "product": "prod_K1JqFPeRGX0FPb",
              "recurring": {
                "aggregate_usage": null,
                "interval": "month",
                "interval_count": 1,
                "trial_period_days": null,
                "usage_type": "licensed"
              },
              "tax_behavior": "unspecified",
              "tiers_mode": null,
              "transform_quantity": null,
              "type": "recurring",
              "unit_amount": 349,
              "unit_amount_decimal": "349"
            },
            "proration": false,
            "proration_details": {
              "credited_items": null
            },
            "quantity": 1,
            "subscription": "sub_1NFK30EfkkkuYfrtJsNaPsAQ",
            "subscription_item": "si_O1MmKuDb87YgrS",
            "tax_amounts": [
            ],
            "tax_rates": [
            ],
            "type": "subscription",
            "unit_amount_excluding_tax": "0"
          }
        ],
        "has_more": false,
        "total_count": 1,
        "url": "/v1/invoices/in_xxx/lines"
      },
      "livemode": true,
      "metadata": {
      },
      "next_payment_attempt": null,
      "number": "2C0F4DFD-0200",
      "on_behalf_of": null,
      "paid": true,
      "paid_out_of_band": false,
      "payment_intent": null,
      "payment_settings": {
        "default_mandate": null,
        "payment_method_options": null,
        "payment_method_types": null
      },
      "period_end": 1685897094,
      "period_start": 1685897094,
      "post_payment_credit_notes_amount": 0,
      "pre_payment_credit_notes_amount": 0,
      "quote": null,
      "receipt_number": null,
      "rendering_options": null,
      "shipping_cost": null,
      "shipping_details": null,
      "starting_balance": 0,
      "statement_descriptor": null,
      "status": "paid",
      "status_transitions": {
        "finalized_at": 1685897094,
        "marked_uncollectible_at": null,
        "paid_at": 1685897094,
        "voided_at": null
      },
      "subscription": "sub_1NFK30EprfOuSbWLJsNaPsAQ",
      "subtotal": 0,
      "subtotal_excluding_tax": 0,
      "tax": null,
      "test_clock": null,
      "total": 0,
      "total_discount_amounts": [
      ],
      "total_excluding_tax": 0,
      "total_tax_amounts": [
      ],
      "transfer_data": null,
      "webhooks_delivered_at": 1685897094
    }
  },
  "livemode": true,
  "pending_webhooks": 1,
  "request": {
    "id": null,
    "idempotency_key": null
  },
  "type": "invoice.paid"
}
  


