package Azure::Storage::Blob::Client::Service::Signer;
use Moose;
use Digest::SHA qw(hmac_sha256_base64);
use MIME::Base64;

# Docs: https://docs.microsoft.com/en-us/rest/api/storageservices/authorize-with-shared-key
sub calculate_signature {
  my ($self, $request, $account_name, $account_key) = @_;
  my $signature_string =
    $request->method()                              ."\n".
    ($request->header('Content-Encoding')    || '') ."\n".
    ($request->header('Content-Language')    || '') ."\n".
    ($request->header('Content-Length')      || '') ."\n".
    ($request->header('Content-MD5')         || '') ."\n".
    ($request->header('Content-Type')        || '') ."\n".
    ($request->header('Date')                || '') ."\n".
    ($request->header('If-Modified-Since')   || '') ."\n".
    ($request->header('If-Math')             || '') ."\n".
    ($request->header('If-None-Match')       || '') ."\n".
    ($request->header('If-Unmodified-Since') || '') ."\n".
    ($request->header('Range')               || '') ."\n".
    $self->_canonicalized_headers_string($request).
    $self->_canonicalized_resource_string($request, $account_name);

  my $signature = Digest::SHA::hmac_sha256_base64(
    $signature_string,
    MIME::Base64::decode_base64($account_key),
  );

  return "$signature=";
}

sub _canonicalized_headers_string {
  my ($self, $request) = @_;

  return join("",
    map { sprintf("%s:%s\n", lc($_), $request->header($_)) }
    sort
    grep { $_ =~ /^x-ms/i }
    $request->header_field_names()
  );
}

sub _canonicalized_resource_string {
  my ($self, $request, $account_name) = @_;
  my %query_form = $request->uri->query_form;

  return
    "/" .
    $account_name .
    $request->uri->path .
    join("",
      map { "\n" . lc($_) . ":" . $query_form{$_} } # TODO: params with multiple values
      sort
      keys %query_form
    );
}

__PACKAGE__->meta->make_immutable();

1;
