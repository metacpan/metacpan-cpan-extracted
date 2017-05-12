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

use AsposeOcrCloud::OcrApi;
use AsposeOcrCloud::ApiClient;
use AsposeOcrCloud::Configuration;

use_ok('AsposeOcrCloud::Configuration');
use_ok('AsposeOcrCloud::ApiClient');
use_ok('AsposeOcrCloud::OcrApi');

$AsposeOcrCloud::Configuration::app_sid = 'XXX';
$AsposeOcrCloud::Configuration::api_key = 'XXX';

$AsposeOcrCloud::Configuration::debug = 1;

if(not defined $AsposeOcrCloud::Configuration::app_sid or $AsposeOcrCloud::Configuration::app_sid =~ /^XXX/i){
		done_testing();
    	exit;
  }else{
  	$AsposeStorageCloud::Configuration::app_sid = $AsposeOcrCloud::Configuration::app_sid
  }
    
if (not defined $AsposeOcrCloud::Configuration::api_key or $AsposeOcrCloud::Configuration::api_key =~ /^XXX/i){
	done_testing();
    exit;
}else{
	$AsposeStorageCloud::Configuration::api_key = $AsposeOcrCloud::Configuration::api_key;
}

my $data_path = './data/';

if (not -d $data_path){
	done_testing();
    exit;
}

if($AsposeOcrCloud::Configuration::debug){
	$AsposeStorageCloud::Configuration::debug = $AsposeOcrCloud::Configuration::debug;
}

my $storageApi = AsposeStorageCloud::StorageApi->new();
my $ocrApi = AsposeOcrCloud::OcrApi->new();

subtest 'testPostOcrFromUrlOrContent' => sub {
	my $name = 'Sampleocr.bmp';
	my $language = 'english';
 	my $response = $ocrApi->PostOcrFromUrlOrContent(language => $language, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeOcrCloud::Object::OCRResponse');
};


subtest 'testGetRecognizeDocument' => sub {
	my $name = 'Sampleocr.bmp';
	my $language = 'english';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	$response = $ocrApi->GetRecognizeDocument(name => $name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeOcrCloud::Object::OCRResponse');
};

done_testing();