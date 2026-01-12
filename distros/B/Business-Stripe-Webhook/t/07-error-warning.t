#!perl
use 5.010;
use strict;
use warnings;

use Test::More;

use Business::Stripe::Webhook;

my $payload = '{ "type": "invoice.paid", "object": "event" }';

my $warning_called = 0;
my $webhook_warn = Business::Stripe::Webhook->new(
    payload => $payload,
    warning => sub { $warning_called++ },
);
{
    local $ENV{'HTTP_STRIPE_SIGNATURE'};
    $webhook_warn->process();
}

is( $warning_called, 0, 'warning callback not invoked when signature check skipped' );

my $error_called = 0;
my $webhook_error = Business::Stripe::Webhook->new(
    payload        => $payload,
    signing_secret => 'whsec_test',
    error          => sub { $error_called++ },
);
{
    local $ENV{'HTTP_STRIPE_SIGNATURE'} = 't=123,v1=invalid';
    $webhook_error->process();
}

is( $error_called, 1, 'error callback invoked' );

my $stderr_error_output = '';
my $webhook_noerror = Business::Stripe::Webhook->new(
    payload        => $payload,
    signing_secret => 'whsec_test',
);
{
    local $ENV{'HTTP_STRIPE_SIGNATURE'} = 't=123,v1=invalid';
    open my $stderr, '>', \$stderr_error_output or die "open stderr: $!";
    local *STDERR = $stderr;
    $webhook_noerror->process();
}

like( $stderr_error_output, qr/Stripe Webhook Error: Invalid Stripe Signature/,
    'error emitted when no error callback provided' );

my $nowarn_callback_called = 0;
my $stderr_output = '';
my $webhook_nowarn = Business::Stripe::Webhook->new(
    payload => $payload,
    warning => 'nowarn',
);
{
    local $ENV{'HTTP_STRIPE_SIGNATURE'};
    open my $stderr, '>', \$stderr_output or die "open stderr: $!";
    local *STDERR = $stderr;
    $webhook_nowarn->process();
}

is( $nowarn_callback_called, 0, 'warning callback not invoked when nowarn' );
is( $stderr_output, '', 'no stderr output when warning nowarn' );

done_testing();
