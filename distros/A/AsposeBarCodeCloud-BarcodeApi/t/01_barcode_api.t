use lib '../lib';
use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON;
use File::Slurp; # From CPAN

use AsposeStorageCloud::StorageApi;
use AsposeStorageCloud::ApiClient;
use AsposeStorageCloud::Configuration;

use AsposeBarCodeCloud::BarcodeApi;
use AsposeBarCodeCloud::ApiClient;
use AsposeBarCodeCloud::Configuration;

use AsposeBarCodeCloud::Object::BarcodeBuilder;
use AsposeBarCodeCloud::Object::BarcodeBuildersList;
use AsposeBarCodeCloud::Object::BarcodeReader;

use_ok('AsposeBarCodeCloud::Configuration');
use_ok('AsposeBarCodeCloud::ApiClient');
use_ok('AsposeBarCodeCloud::BarcodeApi');


$AsposeBarCodeCloud::Configuration::app_sid = 'XXX';
$AsposeBarCodeCloud::Configuration::api_key = 'XXX';

$AsposeBarCodeCloud::Configuration::debug = 1;

if(not defined $AsposeBarCodeCloud::Configuration::app_sid or $AsposeBarCodeCloud::Configuration::app_sid =~ /^XXX/i){
		done_testing();
    	exit;
  }else{
  	$AsposeStorageCloud::Configuration::app_sid = $AsposeBarCodeCloud::Configuration::app_sid
  }
    
if (not defined $AsposeBarCodeCloud::Configuration::api_key or $AsposeBarCodeCloud::Configuration::api_key =~ /^XXX/i){
	done_testing();
    exit;
}else{
	$AsposeStorageCloud::Configuration::api_key = $AsposeBarCodeCloud::Configuration::api_key;
}

my $data_path = './data/';

if (not -d $data_path){
	done_testing();
    exit;
}

if($AsposeBarCodeCloud::Configuration::debug){
	$AsposeStorageCloud::Configuration::debug = $AsposeBarCodeCloud::Configuration::debug;
}

my $storageApi = AsposeStorageCloud::StorageApi->new();
my $barcodeApi = AsposeBarCodeCloud::BarcodeApi->new();


subtest 'testGetBarcodeGenerate' => sub {
	my $text = 'Aspose for cloud';
	my $type = 'qr';
	my $format = 'png';
 	my $response = $barcodeApi->GetBarcodeGenerate(text => $text, type => $type, format => $format);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostGenerateMultiple' => sub {
	my $format = 'png';
	my @bar1 = AsposeBarCodeCloud::Object::BarcodeBuilder->new('TypeOfBarcode' => 'qr', 'Text' => 'NewBarCode');
	my @bar2 = AsposeBarCodeCloud::Object::BarcodeBuilder->new('TypeOfBarcode' => 'qr', 'Text' => 'Aspose');
	my @barbuilders = AsposeBarCodeCloud::Object::BarcodeBuildersList->new('BarcodeBuilders' => [@bar1, @bar2], 'XStep' => 10, 'YStep' => 10);
 	my $response = $barcodeApi->PostGenerateMultiple(format => $format, body=>@barbuilders);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostBarcodeRecognizeFromUrlorContent' => sub {
	my $url = 'http://www.barcoding.com/images/Barcodes/code93.gif';
 	my $response = $barcodeApi->PostBarcodeRecognizeFromUrlorContent(url => $url);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeBarCodeCloud::Object::BarcodeResponseList');
};

subtest 'testPutBarcodeGenerateFile' => sub {
	my $name = 'testbar.png';
	my $type = 'qr';
	my $text = 'Aspose.Barcode for Cloud';
 	my $response = $barcodeApi->PutBarcodeGenerateFile(name => $name, type => $type, text => $text);
 	is($response->{'Status'}, "OK");
};

subtest 'testPutGenerateMultiple' => sub {
	my $name = 'newfile.png';
	my $file = 'sample.txt';
	my $response = $barcodeApi->PutGenerateMultiple(name => $name, file => $data_path.$file);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetBarcodeRecognize' => sub {
	my $name = 'sample-barcode.jpeg';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $barcodeApi->GetBarcodeRecognize(name => $name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeBarCodeCloud::Object::BarcodeResponseList');
};

subtest 'testPutBarcodeRecognizeFromBody' => sub {
	my $name = 'sample-barcode.jpeg';
	my @barcodeReaderBody = AsposeBarCodeCloud::Object::BarcodeReader->new('StripFNC' => 'TRUE', 'ChecksumValidation' => 'OFF');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $barcodeApi->PutBarcodeRecognizeFromBody(name => $name, body =>@barcodeReaderBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeBarCodeCloud::Object::BarcodeResponseList');
};


done_testing();