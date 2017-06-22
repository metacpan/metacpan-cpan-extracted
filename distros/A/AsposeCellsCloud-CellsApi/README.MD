# Aspose.Cells Cloud SDK for Perl

This repository contains Aspose.Cells Cloud SDK for Perl source code. This SDK allows you to work with Aspose.Cells Cloud REST APIs in your Perl applications quickly and easily. 


<p align="center">
  <a title="Download complete Aspose.Cells for Cloud source code" href="https://github.com/asposecells/Aspose_Cells_Cloud/archive/master.zip">
	<img src="https://raw.github.com/AsposeExamples/java-examples-dashboard/master/images/downloadZip-Button-Large.png" />
  </a>
</p>


## How to use the SDK?
The complete source code is available in this repository folder, you can directly use it in your project. For more details, please visit our [documentation website](http://www.aspose.com/docs/display/cellscloud/Available+SDKs).


## Quick SDK Tutorial
```javascript

use lib 'lib';
use strict;
use warnings;
use File::Slurp; # From CPAN

use AsposeStorageCloud::StorageApi;
use AsposeStorageCloud::ApiClient;
use AsposeStorageCloud::Configuration;

use AsposeCellsCloud::CellsApi;
use AsposeCellsCloud::ApiClient;
use AsposeCellsCloud::Configuration;

use AsposeCellsCloud::Object::SaveOptions;

$AsposeCellsCloud::Configuration::app_sid = 'XXX';
$AsposeCellsCloud::Configuration::api_key = 'XXX';

$AsposeCellsCloud::Configuration::debug = 1;

$AsposeStorageCloud::Configuration::app_sid = $AsposeCellsCloud::Configuration::app_sid;
$AsposeStorageCloud::Configuration::api_key = $AsposeCellsCloud::Configuration::api_key;

#Instantiate Aspose.Storage API SDK 
my $storageApi = AsposeStorageCloud::StorageApi->new();

#Instantiate Aspose.Cells API SDK
my $cellsApi = AsposeCellsCloud::CellsApi->new();

my $data_path = '../data/';

#set input file name
my $name = 'Sample_Test_Book.xls';
my $newfilename = 'Sample_Test_Book.pdf';
my $format = 'pdf';
my @saveOptionsBody = AsposeCellsCloud::Object::SaveOptions->new('desiredPPI' => 300, 'jpegQuality'=>70, 'OnePagePerSheet'=>'True', 'SaveFormat'=>'pdf');

#upload file to aspose cloud storage 
my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);

#invoke Aspose.Cells Cloud SDK API to convert workbook to different file formats using cloud storage            		                           
$response = $cellsApi->PostDocumentSaveAs(name=> $name, newfilename=>$newfilename, format=>$format, body=>@saveOptionsBody);

if($response->{'Status'} eq 'OK'){
	my $destfilename = $response->{'SaveResult'}->{'DestDocument'}->{'Href'};
	print("\n FileName: " . $destfilename);
	#download updated Workbook from storage server 
	my $output_file = 'C:/temp/'. $destfilename;
	$response = $storageApi->GetDownload(Path => $destfilename);
	write_file($output_file, { binmode => ":raw" }, $response->{'Content'});
}

```

## Contact Us
Your feedback is very important to us. Please feel free to contact us using our [Support Forums](https://www.aspose.com/community/forums/).
