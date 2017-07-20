# Aspose.Storage Cloud SDK for Perl

This repository contains Aspose.Storage Cloud SDK for Perl source code. This SDK allows you to work with Aspose.Storage Cloud REST APIs in your Perl applications quickly and easily. 

<p align="center">
  <a title="Download complete Aspose.Storage for Cloud source code" href="https://github.com/asposetotal/Aspose_total_Cloud/archive/master.zip">
	<img src="https://raw.github.com/AsposeExamples/java-examples-dashboard/master/images/downloadZip-Button-Large.png" />
  </a>
</p>

##How to Use the SDK?
The complete source code is available in this repository folder, you can either directly use it in your project or use Maven. For more details, please visit our [documentation website](http://www.aspose.com/docs/display/totalcloud/Available+SDKs).

## Quick SDK Tutorial
```javascript

use lib 'lib';
use strict;
use warnings;
use AsposeStorageCloud::StorageApi;
use AsposeStorageCloud::ApiClient;
use AsposeStorageCloud::Configuration;
use AsposeStorageCloud::Object::DiscUsage;

$AsposeStorageCloud::Configuration::app_sid = 'XXX';
$AsposeStorageCloud::Configuration::api_key = 'XXX';

#Instantiate Aspose.Storage API SDK
my $storageApi = AsposeStorageCloud::StorageApi->new();

#invoke Aspose.Storage Cloud SDK API to get Disc Usage
my $response = $storageApi->GetDiscUsage();

print "\nUsedSize :: $response->{'DiscUsage'}->{'UsedSize'}";

```

##Contact Us
Your feedback is very important to us. Please feel free to contact us using our [Support Forums](https://www.aspose.com/community/forums/).
