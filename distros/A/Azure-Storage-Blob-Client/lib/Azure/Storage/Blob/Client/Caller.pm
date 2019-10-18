package Azure::Storage::Blob::Client::Caller;
use Moose;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Tiny;
use HTTP::Request;
use HTTP::Headers;
use HTTP::Date;
use Digest::SHA qw(hmac_sha256_base64);
use MIME::Base64;
use Encode;

use Azure::Storage::Blob::Client::Service::Signer;
use Azure::Storage::Blob::Client::Exception;

has user_agent => (
  is => 'ro',
  lazy => 1,
  default => sub { return LWP::UserAgent->new() },
);

has signer => (
  is => 'ro',
  isa => 'Azure::Storage::Blob::Client::Service::Signer',
  lazy => 1,
  default => sub { Azure::Storage::Blob::Client::Service::Signer->new() },
);

sub request {
  my ($self, $account_name, $account_key, $call_object) = @_;

  my $request = $self->_prepare_request($account_name, $account_key, $call_object);
  my $response = $self->user_agent->request($request);
  $self->_handle_storage_account_api_exceptions($response);

  return $call_object->parse_response($response);
}

sub _prepare_request {
  my ($self, $account_name, $account_key, $call_object) = @_;

  if (
    $call_object->operation ne 'DeleteBlob' and
    $call_object->operation ne 'GetBlobProperties' and
    $call_object->operation ne 'ListBlobs' and
    $call_object->operation ne 'PutBlob'
  ) {
    die 'Unimplemented.';
  }

  my $url_encoded_parameters = HTTP::Tiny->new->www_form_urlencode(
    $call_object->serialize_uri_parameters(),
  );
  my $url = $url_encoded_parameters
    ? sprintf("%s&%s", $call_object->endpoint, $url_encoded_parameters)
    : $call_object->endpoint;

  my $body = $self->_build_body_content($call_object);
  my $headers = $self->_build_headers($call_object, $body);
  my $request = HTTP::Request->new($call_object->method, $url, $headers, $body);
  $self->_sign_request($request, $account_name, $account_key, $call_object);

  return $request;
}

sub _handle_storage_account_api_exceptions {
  my ($self, $response) = @_;

  return unless ($response->code >= 400);

  if ($response->header('x-ms-error-code')) {
    Azure::Storage::Blob::Client::Exception->throw({
      code => $response->header('x-ms-error-code'),
      message => $response->message,
    });
  }
  else {
    Azure::Storage::Blob::Client::Exception->throw({
      code => 'UnknownAzureStorageAPIError',
      message => 'Unknown Azure Storage Blob API error (x-ms-error-code not found in the '
                .' response). Response: '.Dumper($response),
    });
  }
}

sub _build_body_content {
  my ($self, $call_object) = @_;

  return join('',
    values %{ $call_object->serialize_body_parameters() }
  );
}

sub _build_headers {
  my ($self, $call_object, $body) = @_;

  return HTTP::Headers->new(
    'Date'=> HTTP::Date::time2str(),
    $body ? ('Content-Length' => length(Encode::encode_utf8($body))) : (),
    %{ $call_object->serialize_header_parameters() },
  );
}

sub _sign_request {
  my ($self, $request, $account_name, $account_key, $call_object) = @_;
  $request->header('Authorization',
    sprintf(
      "SharedKey %s:%s",
      $call_object->account_name,
      $self->signer->calculate_signature(
        $request,
        $account_name,
        $account_key,
      ),
    ),
  );
}

__PACKAGE__->meta->make_immutable();

1;
