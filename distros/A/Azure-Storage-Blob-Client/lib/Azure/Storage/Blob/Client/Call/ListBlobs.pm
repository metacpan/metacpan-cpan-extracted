package Azure::Storage::Blob::Client::Call::ListBlobs;
use Moose;
use Azure::Storage::Blob::Client::Meta::Attribute::Custom::Trait::URIParameter;
use Azure::Storage::Blob::Client::Meta::Attribute::Custom::Trait::HeaderParameter;
use XML::LibXML;

has operation => (is => 'ro', init_arg => undef, default => 'ListBlobs');
has endpoint => (is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  return sprintf(
    'https://%s.blob.core.windows.net/%s?restype=container&comp=list',
    $self->account_name,
    $self->container,
  );
});
has method => (is => 'ro', init_arg => undef, default => 'GET');

with 'Azure::Storage::Blob::Client::Call';

has account_name => (is => 'ro', isa => 'Str', required => 1);
has api_version => (is => 'ro', isa => 'Str', traits => ['HeaderParameter'], header_name => 'x-ms-version', required => 1);
has container => (is => 'ro', isa => 'Str', required => 1);
has prefix => (is => 'ro', isa => 'Str', traits => ['URIParameter'], required => 1);
has maxresults => (is => 'ro', isa => 'Str', traits => ['URIParameter'], required => 0);
has marker => (is => 'ro', isa => 'Str', traits => ['URIParameter'], required => 0);
has auto_retrieve_paginated_results => (is => 'ro', isa => 'Bool', default => 0);

sub parse_response {
  my ($self, $response) = @_;
  my $dom = XML::LibXML->load_xml(string => $response->content);

  return {
    Blobs => [
      map { $_->to_literal() } $dom->findnodes('/EnumerationResults/Blobs/Blob/Name')
    ],
    $dom->findnodes('/EnumerationResults/NextMarker')
      ? ( NextMarker => shift @{[ map { $_->to_literal() } $dom->findnodes('/EnumerationResults/NextMarker') ]} )
      : (),
  };
}

__PACKAGE__->meta->make_immutable();

1;
