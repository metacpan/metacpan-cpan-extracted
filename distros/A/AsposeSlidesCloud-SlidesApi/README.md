# Aspose.Slides Cloud SDK for Perl

This repository contains Aspose.Slides Cloud SDK for Perl source code. This SDK allows you to work with Aspose.Slides Cloud REST APIs in your perl applications quickly and easily. 

<p align="center">
  <a title="Download complete Aspose.Slides for Cloud source code" href="https://github.com/asposeslides/Aspose_slides_Cloud/archive/master.zip">
	<img src="https://raw.github.com/AsposeExamples/java-examples-dashboard/master/images/downloadZip-Button-Large.png" />
  </a>
</p>

## How to Use the SDK?

The complete source code is available in this repository folder. For more details, please visit our [documentation website](https://docs.aspose.com/display/slidescloud/Available+SDKs).

## Quick SDK Tutorial

```javascript
use lib 'lib';
use strict;
use warnings;
use AsposeStorageCloud::StorageApi;
use AsposeStorageCloud::ApiClient;
use AsposeStorageCloud::Configuration;

use AsposeSlidesCloud::SlidesApi;
use AsposeSlidesCloud::ApiClient;
use AsposeSlidesCloud::Configuration;

$AsposeSlidesCloud::Configuration::app_sid = 'XXX';
$AsposeSlidesCloud::Configuration::api_key = 'XXX';

$AsposeSlidesCloud::Configuration::debug = 1;
$AsposeStorageCloud::Configuration::app_sid = $AsposeSlidesCloud::Configuration::app_sid;
$AsposeStorageCloud::Configuration::api_key = $AsposeSlidesCloud::Configuration::api_key;

#Instantiate Aspose.Storage API SDK 
my $storageApi = AsposeStorageCloud::StorageApi->new();

#Instantiate Aspose.Slides API SDK
my $slidesApi = AsposeSlidesCloud::SlidesApi->new();

my $data_path = '../data/';

#set input file name
my $filename = "sample";
my $name = $filename . ".pptx";
my $format = "tiff";

#upload file to aspose cloud storage 
my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);

#invoke Aspose.Slides Cloud SDK API to save a presentation to different other formats       
$response = $slidesApi->GetSlidesDocumentWithFormat(name => $name, format => $format);

if($response->{'Status'} eq 'OK'){
	#save converted format file from response 
	my $output_file = 'C:/temp/'. $filename . '.' . $format;	
	write_file($output_file, { binmode => ":raw" }, $response->{'Content'});
}
```
## Contact Us

Your feedback is very important to us. Please feel free to contact us using our [Support Forums](https://www.aspose.com/community/forums/).

