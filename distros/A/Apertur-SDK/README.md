# Apertur::SDK

Official Perl SDK for the [Apertur](https://apertur.ca) API. Supports API key and OAuth token authentication, session management, image uploads (plain and encrypted), long polling, webhook verification, and full resource CRUD.

## Installation

Requires Perl 5.26+ and is installed via standard CPAN tooling.

```bash
cpanm Apertur::SDK
```

Or from source:

```bash
perl Makefile.PL
make
make test
make install
```

## Quick Start

Create a client, open an upload session, and upload an image in a few lines. See the [API documentation](https://docs.apertur.ca) for a full overview.

```perl
use Apertur::SDK;

my $client = Apertur::SDK->new(api_key => 'aptr_live_...');

my $session = $client->sessions->create(label => 'My shoot');
my $image   = $client->upload->image($session->{uuid}, '/path/to/photo.jpg');

print "Uploaded: $image->{id}\n";
```

## Authentication

The client accepts either a long-lived API key or a short-lived OAuth bearer token. Only one is required. See [Authentication documentation](https://docs.apertur.ca/authentication).

```perl
use Apertur::SDK;

# API key
my $client = Apertur::SDK->new(api_key => 'aptr_live_...');

# OAuth token (e.g. obtained via your auth server)
my $client = Apertur::SDK->new(oauth_token => $access_token);

# Custom base URL (sandbox)
my $client = Apertur::SDK->new(
    api_key  => 'aptr_live_...',
    base_url => 'https://sandbox.api.aptr.ca',
);
```

Keys prefixed with `aptr_test_` automatically target the sandbox environment.

## Sessions

Upload sessions scope every image upload. You can create a session with optional settings, retrieve it, protect it with a password, and check delivery status. See [Sessions documentation](https://docs.apertur.ca/upload-sessions).

```perl
use Apertur::SDK;

my $client = Apertur::SDK->new(api_key => 'aptr_live_...');

# Create a session
my $session = $client->sessions->create(
    label     => 'Wedding reception',
    password  => 's3cr3t',
    maxImages => 200,
);

# Retrieve session details
my $details = $client->sessions->get($session->{uuid});

# Verify a password-protected session before uploading
my $result = $client->sessions->verify_password($session->{uuid}, 's3cr3t');

# Check per-destination delivery status. Returns:
#   { status => 'pending|active|completed|expired',
#     files => [...], lastChanged => '<ISO 8601>' }
my $status = $client->sessions->delivery_status($session->{uuid});

# Long-poll: server holds the response up to 5 min until something changes.
# Passing poll_from automatically widens the per-request timeout to 360 s.
$status = $client->sessions->delivery_status(
    $session->{uuid},
    poll_from => $status->{lastChanged},
);
```

## Uploading Images

Upload a plain image using a file path or a scalar reference with raw bytes. For end-to-end encrypted uploads, use `image_encrypted` with the server's RSA public key. See [Upload documentation](https://docs.apertur.ca/upload-sessions).

```perl
use Apertur::SDK;

my $client = Apertur::SDK->new(api_key => 'aptr_live_...');
my $uuid   = 'session-uuid-here';

# Upload from a file path
my $image = $client->upload->image($uuid, '/tmp/photo.jpg',
    filename => 'photo.jpg',
    mimeType => 'image/jpeg',
    source   => 'my-app',
);

# Upload from raw bytes
my $bytes = read_file_bytes('/tmp/photo.jpg');
my $image = $client->upload->image($uuid, \$bytes);

# Upload to a password-protected session
my $image = $client->upload->image($uuid, '/tmp/photo.jpg',
    password => 's3cr3t',
);

# Encrypted upload
my $server_key = $client->encryption->get_server_key();
my $image = $client->upload->image_encrypted(
    $uuid, '/tmp/photo.jpg', $server_key->{publicKey},
    filename => 'photo.jpg',
    mimeType => 'image/jpeg',
);
```

## Long Polling

Poll a session for new images, download each one, and acknowledge receipt to advance the queue. The `poll_and_process` helper loops automatically and calls your handler for every image. See [Long Polling documentation](https://docs.apertur.ca/long-polling).

```perl
use Apertur::SDK;

my $client = Apertur::SDK->new(api_key => 'aptr_live_...');
my $uuid   = 'session-uuid-here';

# Manual poll / download / ack cycle
my $result = $client->polling->list($uuid);
for my $image (@{ $result->{images} }) {
    my $data = $client->polling->download($uuid, $image->{id});
    open my $fh, '>:raw', "/tmp/$image->{id}.jpg" or die $!;
    print $fh $data;
    close $fh;
    $client->polling->ack($uuid, $image->{id});
}

# Automatic loop with 60-second timeout and 3-second interval
$client->polling->poll_and_process(
    $uuid,
    sub {
        my ($image, $data) = @_;
        open my $fh, '>:raw', "/tmp/$image->{id}.jpg" or die $!;
        print $fh $data;
        close $fh;
        print "Saved $image->{id}\n";
    },
    interval => 3,
    timeout  => 60,
);
```

## Receiving Webhooks

Apertur signs every webhook payload so you can verify it was not tampered with. Three verification methods are available. See [Webhooks documentation](https://docs.apertur.ca/webhooks).

```perl
use Apertur::SDK::Signature qw(
    verify_webhook_signature
    verify_event_signature
    verify_svix_signature
);

# Image delivery webhook
my $valid = verify_webhook_signature($body, $signature, $secret);

# Event webhook (HMAC method)
my $valid = verify_event_signature($body, $timestamp, $signature, $secret);

# Event webhook (Svix method)
my $valid = verify_svix_signature($body, $svix_id, $timestamp, $signature, $secret);
```

## Destinations

Destinations define where uploaded images are delivered. See [Destinations documentation](https://docs.apertur.ca/destinations).

```perl
use Apertur::SDK;

my $client     = Apertur::SDK->new(api_key => 'aptr_live_...');
my $project_id = 'proj_...';

my $list = $client->destinations->list($project_id);

my $dest = $client->destinations->create($project_id,
    type   => 's3',
    label  => 'Primary S3 bucket',
    config => { bucket => 'my-bucket', region => 'us-east-1' },
);

my $updated = $client->destinations->update($project_id, $dest->{id},
    label => 'Primary S3 bucket (updated)',
);

my $test_result = $client->destinations->test($project_id, $dest->{id});

$client->destinations->delete($project_id, $dest->{id});
```

## API Keys

API keys are scoped to a project and optionally restricted to specific destinations. See [API Keys documentation](https://docs.apertur.ca/api-keys).

```perl
use Apertur::SDK;

my $client     = Apertur::SDK->new(api_key => 'aptr_live_...');
my $project_id = 'proj_...';

my $keys = $client->keys->list($project_id);

my $key = $client->keys->create($project_id, label => 'Mobile app key');

$client->keys->update($project_id, $key->{id}, label => 'Mobile app key v2');

$client->keys->set_destinations($key->{id}, ['dest_abc', 'dest_def'], 1);

$client->keys->delete($project_id, $key->{id});
```

## Event Webhooks

Event webhooks push real-time notifications to your endpoint. See [Event Webhooks documentation](https://docs.apertur.ca/event-webhooks).

```perl
use Apertur::SDK;

my $client     = Apertur::SDK->new(api_key => 'aptr_live_...');
my $project_id = 'proj_...';

my $webhooks = $client->webhooks->list($project_id);

my $webhook = $client->webhooks->create($project_id,
    url    => 'https://example.com/webhooks/apertur',
    events => ['image.uploaded', 'session.completed'],
);

$client->webhooks->update($project_id, $webhook->{id},
    events => ['image.uploaded'],
);

$client->webhooks->test($project_id, $webhook->{id});

my $deliveries = $client->webhooks->deliveries($project_id, $webhook->{id},
    page  => 1,
    limit => 25,
);

$client->webhooks->retry_delivery($project_id, $webhook->{id},
    $deliveries->{data}[0]{id},
);

$client->webhooks->delete($project_id, $webhook->{id});
```

## Encryption

Apertur supports end-to-end encrypted uploads using RSA-OAEP + AES-256-GCM. Requires optional dependencies `Crypt::OpenSSL::RSA` and `CryptX`. See [Encryption documentation](https://docs.apertur.ca/encryption).

```perl
use Apertur::SDK;

my $client = Apertur::SDK->new(api_key => 'aptr_live_...');

my $server_key = $client->encryption->get_server_key();

my $image = $client->upload->image_encrypted(
    'session-uuid-here',
    '/tmp/photo.jpg',
    $server_key->{publicKey},
    filename => 'photo.jpg',
    mimeType => 'image/jpeg',
);

print "Uploaded: $image->{id}\n";
```

## Error Handling

All API errors throw typed exceptions that inherit from `Apertur::SDK::Error`. Catch the specific subclass you care about, or catch the base class as a fallback. See [Error Handling documentation](https://docs.apertur.ca/errors).

```perl
use Apertur::SDK;
use Apertur::SDK::Error;
use Apertur::SDK::Error::Authentication;
use Apertur::SDK::Error::NotFound;
use Apertur::SDK::Error::RateLimit;
use Apertur::SDK::Error::Validation;

my $client = Apertur::SDK->new(api_key => 'aptr_live_...');

eval {
    my $session = $client->sessions->create(label => 'My shoot');
    my $image   = $client->upload->image($session->{uuid}, '/tmp/photo.jpg');
};
if (my $err = $@) {
    if (ref $err && $err->isa('Apertur::SDK::Error::Authentication')) {
        warn "Auth failed: " . $err->message . "\n";
    }
    elsif (ref $err && $err->isa('Apertur::SDK::Error::NotFound')) {
        warn "Not found: " . $err->message . "\n";
    }
    elsif (ref $err && $err->isa('Apertur::SDK::Error::RateLimit')) {
        my $retry = $err->retry_after // '?';
        warn "Rate limited. Retry after ${retry}s\n";
    }
    elsif (ref $err && $err->isa('Apertur::SDK::Error::Validation')) {
        warn "Validation error: " . $err->message . "\n";
    }
    elsif (ref $err && $err->isa('Apertur::SDK::Error')) {
        warn "API error " . $err->status_code . ": " . $err->message . "\n";
    }
    else {
        die $err;
    }
}
```

## API Reference

Full API reference, guides, and changelog are available at [docs.apertur.ca](https://docs.apertur.ca).

## License

This package is open-source software licensed under the [MIT license](https://opensource.org/licenses/MIT).
