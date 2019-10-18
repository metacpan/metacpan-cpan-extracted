package Azure::Storage::Blob::Client::Call::PutBlob;
use Moose;
use Azure::Storage::Blob::Client::Meta::Attribute::Custom::Trait::BodyParameter;
use Azure::Storage::Blob::Client::Meta::Attribute::Custom::Trait::HeaderParameter;

has operation => (is => 'ro', init_arg => undef, default => 'PutBlob');
has endpoint => (is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  return sprintf(
    'https://%s.blob.core.windows.net/%s/%s',
    $self->account_name,
    $self->container,
    $self->blob_name,
  );
});
has method => (is => 'ro', init_arg => undef, default => 'PUT');

with 'Azure::Storage::Blob::Client::Call';

has account_name => (is => 'ro', isa => 'Str', required => 1);
has api_version => (is => 'ro', isa => 'Str', traits => ['HeaderParameter'], header_name => 'x-ms-version', required => 1);
has container => (is => 'ro', isa => 'Str', required => 1);
has blob_name => (is => 'ro', isa => 'Str', required => 1);
has blob_type => (is => 'ro', isa => 'Str', traits => ['HeaderParameter'], header_name => 'x-ms-blob-type', required => 1);
has content => (is => 'ro', isa => 'Str', traits => ['BodyParameter'], required => 1);

sub parse_response {
  my ($self, $response) = @_;
  return $response;
}

__PACKAGE__->meta->make_immutable();

1;
