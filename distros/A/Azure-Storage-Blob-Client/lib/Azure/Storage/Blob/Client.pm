# ABSTRACT: Azure Storage Blob API client
package Azure::Storage::Blob::Client;
use Moose;
use Azure::Storage::Blob::Client::Caller;
use Azure::Storage::Blob::Client::Call::DeleteBlob;
use Azure::Storage::Blob::Client::Call::GetBlobProperties;
use Azure::Storage::Blob::Client::Call::ListBlobs;
use Azure::Storage::Blob::Client::Call::PutBlob;

our $VERSION = 0.05;

has caller => (
  is => 'ro',
  lazy => 1,
  default => sub {
    return Azure::Storage::Blob::Client::Caller->new();
  },
);
has account_name => (is => 'ro', isa => 'Str', required => 1);
has account_key => (is => 'ro', isa => 'Str', required => 1);
has api_version => (is => 'ro', isa => 'Str', default => '2018-03-28');

sub DeleteBlob {
  my ($self, %params) = @_;
  my $call_object = Azure::Storage::Blob::Client::Call::DeleteBlob->new(
    account_name => $self->account_name,
    api_version => $self->api_version,
    %params,
  );
  return $self->caller->request(
    $self->account_name,
    $self->account_key,
    $call_object,
  );
}

sub GetBlobProperties {
  my ($self, %params) = @_;
  my $call_object = Azure::Storage::Blob::Client::Call::GetBlobProperties->new(
    account_name => $self->account_name,
    api_version => $self->api_version,
    %params,
  );
  return $self->caller->request(
    $self->account_name,
    $self->account_key,
    $call_object,
  );
}

sub ListBlobs {
  my ($self, %params) = @_;
  my $call_object = Azure::Storage::Blob::Client::Call::ListBlobs->new(
    account_name => $self->account_name,
    api_version => $self->api_version,
    %params,
  );

  if ($call_object->auto_retrieve_paginated_results) {
    my $response = $self->caller->request(
      $self->account_name,
      $self->account_key,
      $call_object,
    );
    my $blob_list = $response->{Blobs} || [];

    while ($response->{NextMarker}) {
      $call_object = Azure::Storage::Blob::Client::Call::ListBlobs->new(
        account_name => $self->account_name,
        api_version => $self->api_version,
        %params,
        marker => $response->{NextMarker},
      );
      $response = $self->caller->request(
        $self->account_name,
        $self->account_key,
        $call_object,
      );
      push @$blob_list, @{ $response->{Blobs} };
    }

    return { Blobs => $blob_list };
  }
  else {
    return $self->caller->request(
      $self->account_name,
      $self->account_key,
      $call_object,
    );
  }
}

sub PutBlob {
  my ($self, %params) = @_;
  my $call_object = Azure::Storage::Blob::Client::Call::PutBlob->new(
    account_name => $self->account_name,
    api_version => $self->api_version,
    %params,
  );
  return $self->caller->request(
    $self->account_name,
    $self->account_key,
    $call_object,
  );
}

__PACKAGE__->meta->make_immutable();

1;

=head1 NAME

Azure::Storage::Blob::Client - Azure Storage Services Blob API client


=head1 SYNOPSIS

  my $client = Azure::Storage::Blob::Client->new(
    account_name => $storage_account_name,
    account_key => $storage_account_key,
    api_version => '2018-03-28',
  );

  my $blobs = $client->ListBlobs(
    container => $container,
    prefix => $blobI<prefix,
    # Makes the client transparently issue additional requests to retrieve
    # paginated results under the hood
    auto>retrieveI<paginated>results => 1,
  );

  my $blobI<properties = $client->GetBlobProperties(
    container => $container>name,
    blobI<name => $blob>name,
  );

  $client->PutBlob(
    container => $containerI<name,
    blob>type => 'BlockBlob',
    blobI<name => $blob>name,
    content => $content,
  );

  $client->DeleteBlob(
    container => $containerI<name,
    blob>name => $blob_name,
  );


=head1 DESCRIPTION

This distribution provides a client for the Blob API of the Azure Storage Services.

Azure Storage Services is composed of 4 APIs:
I< Blob service API
> File service API
I< Queue service API
> Table service API

(More info on Azure's docs: https://docs.microsoft.com/en-us/rest/api/storageservices/)
Azure::Storage::Blob::Client is a client solely for the Blob API.


=head1 CURRENT STATE OF DEVELOPMENT

Azure::Storage::Blob::Client is a partial implementation of the Azure Storage Blob API.
Implementing not-yet-supported API calls should be very straightforward though, as all the necessary scaffolding is in place.

PRs contributing the implementation of not-yet-supported API calls are more than welcome :)

(For a complete list of the Blob API calls, check the documentation: https://docs.microsoft.com/en-us/rest/api/storageservices/blob-service-rest-api)


=head1 METHODS


=head3 Constructor

Returns a new instance of Azure::Storage::Blob::Client.
 
 my $client = Azure::Storage::Blob::Client->new(
   account_name => $storage_account_name,
   account_key => $storage_account_key,
   api_version => '2018-03-28',
 );



=head3 ListBlobs

Lists all of the blobs in a container.
 
 my $blobs = $client->ListBlobs(
   container => $container,
   prefix => $blob_prefix,
   auto_retrieve_paginated_results => 1,
 );

B<autoI<retrieve>paginated_results>: When enabled, the client will transparently issue additional requests to retrieve paginated results under the hood.


=head3 GetBlobProperties

Returns all system properties and user-defined metadata on the blob.
 
 my $blob_properties = $client->GetBlobProperties(
   container => $container_name,
   blob_name => $blob_name,
 );



=head3 PutBlob

Creates a new block to be committed as part of a block blob.
 
 $client->PutBlob(
   container => $container_name,
   blob_type => 'BlockBlob',
   blob_name => $blob_name,
   content => $content,
 );



=head3 Delete Blob

Marks a blob for deletion.
 
 $client->DeleteBlob(
   container => $container_name,
   blob_name => $blob_name,
 );



=head1 Contributors && Kudos:

* Alexandr Ciornii (@chorny): For pointing out build dependencies were being installed for end-users.



=head1 AUTHOR

 
 Oriol Soriano
 oriol.soriano@capside.com



=head1 COPYRIGHT

Copyright (c) 2019 by CAPSiDE.


=head1 LICENSE

This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.

