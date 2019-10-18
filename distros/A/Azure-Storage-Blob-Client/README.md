# NAME
Azure::Storage::Blob::Client - Azure Storage Services Blob API client

# SYNOPSIS
```
my $client = Azure::Storage::Blob::Client->new(
  account_name => $storage_account_name,
  account_key => $storage_account_key,
  api_version => '2018-03-28',
);

my $blobs = $client->ListBlobs(
  container => $container,
  prefix => $blob_prefix,
  # Makes the client transparently issue additional requests to retrieve
  # paginated results under the hood
  auto_retrieve_paginated_results => 1,
);

my $blob_properties = $client->GetBlobProperties(
  container => $container_name,
  blob_name => $blob_name,
);

$client->PutBlob(
  container => $container_name,
  blob_type => 'BlockBlob',
  blob_name => $blob_name,
  content => $content,
);

$client->DeleteBlob(
  container => $container_name,
  blob_name => $blob_name,
);
```

# DESCRIPTION
This distribution provides a client for the Blob API of the Azure Storage Services.

Azure Storage Services is composed of 4 APIs:
* Blob service API
* File service API
* Queue service API
* Table service API  

(More info on Azure's docs: https://docs.microsoft.com/en-us/rest/api/storageservices/)
Azure::Storage::Blob::Client is a client solely for the Blob API.

# CURRENT STATE OF DEVELOPMENT
Azure::Storage::Blob::Client is a partial implementation of the Azure Storage Blob API.
Implementing not-yet-supported API calls should be very straightforward though, as all the necessary scaffolding is in place.

PRs contributing the implementation of not-yet-supported API calls are more than welcome :)

(For a complete list of the Blob API calls, check the documentation: https://docs.microsoft.com/en-us/rest/api/storageservices/blob-service-rest-api)

# METHODS

### Constructor
Returns a new instance of Azure::Storage::Blob::Client.
```
my $client = Azure::Storage::Blob::Client->new(
  account_name => $storage_account_name,
  account_key => $storage_account_key,
  api_version => '2018-03-28',
);
```

### ListBlobs
Lists all of the blobs in a container.
```
my $blobs = $client->ListBlobs(
  container => $container,
  prefix => $blob_prefix,
  auto_retrieve_paginated_results => 1,
);
```
**auto_retrieve_paginated_results**: When enabled, the client will transparently issue additional requests to retrieve paginated results under the hood.

### GetBlobProperties
Returns all system properties and user-defined metadata on the blob.
```
my $blob_properties = $client->GetBlobProperties(
  container => $container_name,
  blob_name => $blob_name,
);
```
### PutBlob
Creates a new block to be committed as part of a block blob.
```
$client->PutBlob(
  container => $container_name,
  blob_type => 'BlockBlob',
  blob_name => $blob_name,
  content => $content,
);
```

### Delete Blob
Marks a blob for deletion.
```
$client->DeleteBlob(
  container => $container_name,
  blob_name => $blob_name,
);
```

# AUTHOR
```
Oriol Soriano
oriol.soriano@capside.com
```

# COPYRIGHT
Copyright (c) 2019 by CAPSiDE.

# LICENSE
This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.
