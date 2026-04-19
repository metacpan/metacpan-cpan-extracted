package Apertur::SDK::HTTPClient;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Request::Common qw(POST);
use JSON qw(encode_json decode_json);

use Apertur::SDK::Error;
use Apertur::SDK::Error::Authentication;
use Apertur::SDK::Error::NotFound;
use Apertur::SDK::Error::RateLimit;
use Apertur::SDK::Error::Validation;

sub new {
    my ($class, %args) = @_;
    my $base_url = $args{base_url};
    $base_url =~ s{/+$}{};

    my $auth_header = '';
    if ($args{api_key}) {
        $auth_header = "Bearer $args{api_key}";
    }
    elsif ($args{oauth_token}) {
        $auth_header = "Bearer $args{oauth_token}";
    }

    my $ua = LWP::UserAgent->new(
        agent   => 'Apertur-SDK-Perl/0.01',
        timeout => 30,
    );

    return bless {
        base_url    => $base_url,
        auth_header => $auth_header,
        ua          => $ua,
    }, $class;
}

sub request {
    my ($self, $method, $path, %opts) = @_;

    my $url = $self->{base_url} . $path;
    my $headers = $opts{headers} || {};

    $headers->{'Authorization'} = $self->{auth_header}
        if $self->{auth_header};

    my $req;
    if ($opts{multipart}) {
        # Multipart form upload
        $req = POST(
            $url,
            Content_Type => 'form-data',
            Content      => $opts{multipart},
        );
        # Apply auth header on top of the multipart request
        $req->header('Authorization' => $headers->{'Authorization'})
            if $headers->{'Authorization'};
        # Apply any extra headers
        for my $key (keys %$headers) {
            next if $key eq 'Authorization';
            $req->header($key => $headers->{$key});
        }
    }
    else {
        $req = HTTP::Request->new(uc($method), $url);
        for my $key (keys %$headers) {
            $req->header($key => $headers->{$key});
        }
        if (defined $opts{body}) {
            $req->content_type($headers->{'Content-Type'} // 'application/json');
            $req->content($opts{body});
        }
    }

    my $res;
    if (defined $opts{timeout}) {
        my $prev = $self->{ua}->timeout;
        $self->{ua}->timeout($opts{timeout});
        $res = eval { $self->{ua}->request($req) };
        my $err = $@;
        $self->{ua}->timeout($prev);
        die $err if $err;
    }
    else {
        $res = $self->{ua}->request($req);
    }
    my $status = $res->code;

    if ($status >= 400) {
        $self->_handle_error($res);
    }

    if ($status == 204) {
        return undef;
    }

    return decode_json($res->decoded_content);
}

sub request_raw {
    my ($self, $method, $path, %opts) = @_;

    my $url = $self->{base_url} . $path;
    my $headers = $opts{headers} || {};

    $headers->{'Authorization'} = $self->{auth_header}
        if $self->{auth_header};

    my $req = HTTP::Request->new(uc($method), $url);
    for my $key (keys %$headers) {
        $req->header($key => $headers->{$key});
    }

    my $res = $self->{ua}->request($req);
    my $status = $res->code;

    if ($status >= 400) {
        $self->_handle_error($res);
    }

    return $res->content;
}

sub _handle_error {
    my ($self, $res) = @_;
    my $status = $res->code;

    my $body = {};
    eval {
        $body = decode_json($res->decoded_content);
    };
    if ($@) {
        $body = { message => "HTTP $status" };
    }

    my $message = $body->{message} || "HTTP $status";
    my $code    = $body->{code};

    if ($status == 401) {
        Apertur::SDK::Error::Authentication->throw(message => $message);
    }
    elsif ($status == 404) {
        Apertur::SDK::Error::NotFound->throw(message => $message);
    }
    elsif ($status == 429) {
        my $retry_after = $res->header('Retry-After');
        $retry_after = defined $retry_after ? int($retry_after) : undef;
        Apertur::SDK::Error::RateLimit->throw(
            message     => $message,
            retry_after => $retry_after,
        );
    }
    elsif ($status == 400) {
        Apertur::SDK::Error::Validation->throw(message => $message);
    }
    else {
        Apertur::SDK::Error->throw(
            status_code => $status,
            code        => $code,
            message     => $message,
        );
    }
}

1;

__END__

=head1 NAME

Apertur::SDK::HTTPClient - HTTP wrapper for the Apertur API

=head1 SYNOPSIS

    use Apertur::SDK::HTTPClient;

    my $http = Apertur::SDK::HTTPClient->new(
        base_url => 'https://api.aptr.ca',
        api_key  => 'aptr_live_...',
    );

    my $data = $http->request('GET', '/api/v1/stats');
    my $raw  = $http->request_raw('GET', '/api/v1/upload-sessions/uuid/qr');

=head1 DESCRIPTION

Low-level HTTP client used internally by all Apertur SDK resource classes.
Handles JSON serialisation, bearer token authentication, multipart uploads,
and maps HTTP error responses to typed exception objects.

=head1 METHODS

=over 4

=item B<new(%args)>

Constructor. Accepts C<base_url>, C<api_key>, and C<oauth_token>.

=item B<request($method, $path, %opts)>

Sends a JSON API request and returns the decoded response as a hashref
or arrayref. Returns C<undef> for 204 No Content responses.

Options: C<body> (JSON string), C<headers> (hashref), C<multipart>
(arrayref for HTTP::Request::Common multipart POST), C<timeout> (per-request
override in seconds for the underlying LWP::UserAgent timeout).

=item B<request_raw($method, $path, %opts)>

Sends a request and returns the raw response body as a byte string.

=back

=cut
