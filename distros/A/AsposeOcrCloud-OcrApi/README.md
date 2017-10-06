Aspose.OCR Cloud SDK for Perl


This repository contains Aspose.OCR Cloud SDK for Perl source code. This SDK allows you to work with Aspose.OCR Cloud REST APIs in your perl applications quickly and easily. 

<p align="center">
  <a title="Download complete Aspose.OCR for Cloud source code" href="https://github.com/asposeocr/Aspose_ocr_Cloud/archive/master.zip">
	<img src="https://raw.github.com/AsposeExamples/java-examples-dashboard/master/images/downloadZip-Button-Large.png" />
  </a>
</p>

## How to use the SDK?

The complete source code is available in this repository folder. For more details, please visit our [documentation](http://www.aspose.com/docs/display/ocrcloud/Available+SDKs).

Quick SDK Tutorial


use lib 'lib';
use strict;
use warnings;

use AsposeOcrCloud::OcrApi;
use AsposeOcrCloud::ApiClient;
use AsposeOcrCloud::Configuration;

$AsposeOcrCloud::Configuration::app_sid = 'XXX';
$AsposeOcrCloud::Configuration::api_key = 'XXX';

$AsposeOcrCloud::Configuration::debug = 1;

#Instantiate Aspose.OCR API SDK
my $ocrApi = AsposeOcrCloud::OcrApi->new();

my $data_path = '../data/';

#set input file name
my $url = 'https://dl.dropboxusercontent.com/s/zj35mqdouoxy3rs/Sampleocr.bmp';
my $language = 'english';

#invoke Aspose.OCR Cloud SDK API to extract image text from local file                             
my $response = $ocrApi->PostOcrFromUrlOrContent(url=> $url, language=> $language);

if($response->{'Status'} eq 'OK'){
    print "\n Text :: " . $response->{'Text'};
   }

##Contact Us
Your feedback is very important to us. Please feel free to contact us using our [Support Forums](https://www.aspose.com/community/forums/).
