# Aspose.BarCode Cloud SDK for Perl

This repository contains Aspose.BarCode Cloud SDK for Perl source code. This SDK allows you to work with Aspose.BarCode Cloud REST APIs in your perl applications quickly and easily. 
<p align="center">
  <a title="Download complete Aspose.BarCode for Cloud source code" href="https://github.com/asposebarcode/Aspose_BarCode_Cloud/archive/master.zip">
	<img src="https://raw.github.com/AsposeExamples/java-examples-dashboard/master/images/downloadZip-Button-Large.png" />
  </a>
</p>

##How to use the SDK?
The complete source code is available in this repository folder. For more details, please visit our [documentation website](http://www.aspose.com/docs/display/barcodecloud/Available+SDKs).



## Quick SDK Tutorial


use lib 'lib';
use strict;
use warnings;
use File::Slurp; # From CPAN

use AsposeBarCodeCloud::BarcodeApi;
use AsposeBarCodeCloud::ApiClient;
use AsposeBarCodeCloud::Configuration;

$AsposeBarCodeCloud::Configuration::app_sid = 'XXX';
$AsposeBarCodeCloud::Configuration::api_key = 'XXX';

$AsposeBarCodeCloud::Configuration::debug = 1;


my $barcodeApi = AsposeBarCodeCloud::BarcodeApi->new();

my $data_path = '../../../Data/';


my $name = 'sample-barcode';
my $text = 'Aspose.BarCode for Cloud';
my $type = 'datamatrix';
my $format = 'png';

#invoke Aspose.BarCode Cloud SDK API to create barcode and save image to a stream           
my $response = $barcodeApi->GetBarcodeGenerate(text => $text, type => $type, format => $format);

if($response->{'Status'} eq 'OK'){
	#download generated barcode from api response 
	my $output_file = 'C:/temp/'. $name . '.' . $format;	
	write_file($output_file, { binmode => ":raw" }, $response->{'Content'});
}


##Contact Us
Your feedback is very important to us. Please feel free to contact us using our [Support Forums](https://www.aspose.com/community/forums/).
