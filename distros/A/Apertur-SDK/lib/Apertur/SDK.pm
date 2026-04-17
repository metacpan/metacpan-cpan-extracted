package Apertur::SDK;

use strict;
use warnings;

our $VERSION = '0.01';

use Apertur::SDK::HTTPClient;
use Apertur::SDK::Resource::Sessions;
use Apertur::SDK::Resource::Upload;
use Apertur::SDK::Resource::Uploads;
use Apertur::SDK::Resource::Polling;
use Apertur::SDK::Resource::Destinations;
use Apertur::SDK::Resource::Keys;
use Apertur::SDK::Resource::Webhooks;
use Apertur::SDK::Resource::Encryption;
use Apertur::SDK::Resource::Stats;

use constant DEFAULT_BASE_URL => 'https://api.aptr.ca';
use constant SANDBOX_BASE_URL => 'https://sandbox.api.aptr.ca';

sub new {
    my ($class, %args) = @_;

    die "Either api_key or oauth_token must be provided\n"
        unless $args{api_key} || $args{oauth_token};

    # Resolve environment from key prefix or explicit config
    my $token = $args{api_key} // $args{oauth_token} // '';
    my $detected_env = ($token =~ /^aptr_test_/) ? 'test' : 'live';
    my $env = $args{env} // $detected_env;

    # Auto-select sandbox URL for test keys unless base_url is explicitly set
    my $default_url = $env eq 'test' ? SANDBOX_BASE_URL : DEFAULT_BASE_URL;
    my $base_url = $args{base_url} // $default_url;

    my $http = Apertur::SDK::HTTPClient->new(
        base_url    => $base_url,
        api_key     => $args{api_key},
        oauth_token => $args{oauth_token},
    );

    return bless {
        env          => $env,
        _http        => $http,
        sessions     => Apertur::SDK::Resource::Sessions->new(http => $http),
        upload       => Apertur::SDK::Resource::Upload->new(http => $http),
        uploads      => Apertur::SDK::Resource::Uploads->new(http => $http),
        polling      => Apertur::SDK::Resource::Polling->new(http => $http),
        destinations => Apertur::SDK::Resource::Destinations->new(http => $http),
        keys         => Apertur::SDK::Resource::Keys->new(http => $http),
        webhooks     => Apertur::SDK::Resource::Webhooks->new(http => $http),
        encryption   => Apertur::SDK::Resource::Encryption->new(http => $http),
        stats        => Apertur::SDK::Resource::Stats->new(http => $http),
    }, $class;
}

sub env          { return $_[0]->{env} }
sub sessions     { return $_[0]->{sessions} }
sub upload       { return $_[0]->{upload} }
sub uploads      { return $_[0]->{uploads} }
sub polling      { return $_[0]->{polling} }
sub destinations { return $_[0]->{destinations} }
sub keys         { return $_[0]->{keys} }
sub webhooks     { return $_[0]->{webhooks} }
sub encryption   { return $_[0]->{encryption} }
sub stats        { return $_[0]->{stats} }

1;

__END__

=head1 NAME

Apertur::SDK - Official Perl SDK for the Apertur API

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Apertur::SDK;

    my $client = Apertur::SDK->new(api_key => 'aptr_live_...');

    # Create an upload session
    my $session = $client->sessions->create(label => 'My shoot');

    # Upload an image
    my $image = $client->upload->image($session->{uuid}, '/path/to/photo.jpg');
    print "Uploaded: $image->{id}\n";

    # Long polling
    $client->polling->poll_and_process(
        $session->{uuid},
        sub {
            my ($image, $data) = @_;
            open my $fh, '>:raw', "/tmp/$image->{id}.jpg" or die $!;
            print $fh $data;
            close $fh;
        },
        interval => 3,
        timeout  => 60,
    );

=head1 DESCRIPTION

Official Perl SDK for the L<Apertur|https://apertur.ca> API. Supports
API key and OAuth token authentication, session management, image
uploads (plain and encrypted), long polling, webhook signature
verification, and full resource CRUD for destinations, API keys,
webhooks, and encryption keys.

=head1 CONSTRUCTOR

=over 4

=item B<new(%args)>

Creates a new Apertur SDK client. At least one of C<api_key> or
C<oauth_token> must be provided.

    my $client = Apertur::SDK->new(
        api_key  => 'aptr_live_...',   # or aptr_test_...
        base_url => 'https://...',     # optional, auto-detected
        env      => 'live',            # optional, auto-detected from key prefix
    );

The environment (C<live> or C<test>) is automatically detected from
the API key prefix. Test keys (C<aptr_test_...>) default to the
sandbox URL C<https://sandbox.api.aptr.ca>.

=back

=head1 RESOURCE ACCESSORS

=over 4

=item B<sessions> - L<Apertur::SDK::Resource::Sessions>

=item B<upload> - L<Apertur::SDK::Resource::Upload>

=item B<uploads> - L<Apertur::SDK::Resource::Uploads>

=item B<polling> - L<Apertur::SDK::Resource::Polling>

=item B<destinations> - L<Apertur::SDK::Resource::Destinations>

=item B<keys> - L<Apertur::SDK::Resource::Keys>

=item B<webhooks> - L<Apertur::SDK::Resource::Webhooks>

=item B<encryption> - L<Apertur::SDK::Resource::Encryption>

=item B<stats> - L<Apertur::SDK::Resource::Stats>

=back

=head1 AUTHENTICATION

The client accepts either a long-lived API key or a short-lived OAuth
bearer token. Keys prefixed with C<aptr_test_> automatically target the
sandbox environment.

    # API key
    my $client = Apertur::SDK->new(api_key => 'aptr_live_...');

    # OAuth token
    my $client = Apertur::SDK->new(oauth_token => $access_token);

=head1 ERROR HANDLING

All API errors throw typed L<Apertur::SDK::Error> objects:

    use Apertur::SDK;
    use Apertur::SDK::Error::Authentication;
    use Apertur::SDK::Error::NotFound;
    use Apertur::SDK::Error::RateLimit;
    use Apertur::SDK::Error::Validation;

    eval {
        my $session = $client->sessions->create(label => 'test');
    };
    if (my $err = $@) {
        if (ref $err && $err->isa('Apertur::SDK::Error::RateLimit')) {
            warn "Rate limited, retry after: " . ($err->retry_after // '?') . "s";
        }
        elsif (ref $err && $err->isa('Apertur::SDK::Error')) {
            warn "API error: " . $err->message;
        }
        else {
            die $err;
        }
    }

=head1 WEBHOOK VERIFICATION

    use Apertur::SDK::Signature qw(
        verify_webhook_signature
        verify_event_signature
        verify_svix_signature
    );

    my $valid = verify_webhook_signature($body, $signature, $secret);

=head1 ENCRYPTION

    use Apertur::SDK::Crypto qw(encrypt_image);

    my $result = encrypt_image($image_bytes, $pem_key);

Encryption requires optional dependencies C<Crypt::OpenSSL::RSA> and
C<CryptX>. These are loaded at runtime only when encryption functions
are called.

=head1 DEPENDENCIES

=over 4

=item L<LWP::UserAgent>

=item L<JSON>

=item L<HTTP::Request::Common>

=item L<Digest::SHA>

=item L<MIME::Base64>

=back

Optional (for encryption only):

=over 4

=item L<Crypt::OpenSSL::RSA>

=item L<CryptX>

=back

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<https://apertur.ca>, L<https://docs.apertur.ca>

=cut
