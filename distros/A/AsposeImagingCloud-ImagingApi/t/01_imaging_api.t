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

use AsposeImagingCloud::ImagingApi;
use AsposeImagingCloud::ApiClient;
use AsposeImagingCloud::Configuration;

use_ok('AsposeImagingCloud::Configuration');
use_ok('AsposeImagingCloud::ApiClient');
use_ok('AsposeImagingCloud::ImagingApi');

$AsposeImagingCloud::Configuration::app_sid = 'XXX';
$AsposeImagingCloud::Configuration::api_key = 'XXX';

$AsposeImagingCloud::Configuration::debug = 1;

if(not defined $AsposeImagingCloud::Configuration::app_sid or $AsposeImagingCloud::Configuration::app_sid =~ /^XXX/i){
		done_testing();
    	exit;
  }else{
  	$AsposeStorageCloud::Configuration::app_sid = $AsposeImagingCloud::Configuration::app_sid
  }
    
if (not defined $AsposeImagingCloud::Configuration::api_key or $AsposeImagingCloud::Configuration::api_key =~ /^XXX/i){
	done_testing();
    exit;
}else{
	$AsposeStorageCloud::Configuration::api_key = $AsposeImagingCloud::Configuration::api_key;
}

my $data_path = './data/';

if (not -d $data_path){
	done_testing();
    exit;
}

if($AsposeImagingCloud::Configuration::debug){
	$AsposeStorageCloud::Configuration::debug = $AsposeImagingCloud::Configuration::debug;
}

my $storageApi = AsposeStorageCloud::StorageApi->new();
my $imagingApi = AsposeImagingCloud::ImagingApi->new();

subtest 'testPostImageBmp' => sub {
	my $name = 'sample.bmp';
	my $bitsPerPixel = 24;
	my $horizontalResolution = 300;
	my $verticalResolution = 300;
 	my $response = $imagingApi->PostImageBmp(bitsPerPixel => $bitsPerPixel, horizontalResolution => $horizontalResolution, verticalResolution => $verticalResolution, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostCropImage' => sub {
	my $name = 'aspose.jpg';
	my $format = 'png';
	my $x = 30;
	my $y = 40;
	my $width = 100;
	my $height = 100;
 	my $response = $imagingApi->PostCropImage(format => $format, x => $x, y => $y, width => $width, height => $height, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostImageGif' => sub {
	my $name = 'sample.gif';
	my $backgroundColorIndex = 255;
	my $colorResolution = 7;
	my $pixelAspectRatio = 10;
 	my $response = $imagingApi->PostImageGif(backgroundColorIndex => $backgroundColorIndex, colorResolution => $colorResolution, pixelAspectRatio => $pixelAspectRatio, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostImageJpg' => sub {
	my $name = 'aspose.jpg';
	my $quality = 100;
	my $compressionType = 'progressive';
 	my $response = $imagingApi->PostImageJpg(name => $name, quality => $quality, compressionType => $compressionType, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostImagePng' => sub {
	my $name = 'aspose_imaging_for_cloud.png';
	my $fromScratch = 'True';	
 	my $response = $imagingApi->PostImagePng(fromScratch => $fromScratch, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostImagePsd' => sub {
	my $name = 'sample.psd';
	my $channelsCount = 3;
	my $compressionMethod = 'rle';	
 	my $response = $imagingApi->PostImagePsd(channelsCount => $channelsCount, compressionMethod => $compressionMethod,  file => $data_path.$name);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostChangeImageScale' => sub {
	my $name = 'aspose_imaging_for_cloud.png';
	my $format = 'jpg';
	my $newWidth = 200;
	my $newHeight = 200;		
 	my $response = $imagingApi->PostChangeImageScale(format => $format, newWidth => $newWidth, newHeight => $newHeight, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostImageRotateFlip' => sub {
	my $name = 'aspose.jpg';
	my $format = 'png';
	my $method = 'Rotate180FlipX';
 	my $response = $imagingApi->PostImageRotateFlip(format => $format, method => $method, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostImageSaveAs' => sub {
	my $name = 'aspose.jpg';
	my $format = 'png';
 	my $response = $imagingApi->PostImageSaveAs(format => $format, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostProcessTiff' => sub {
	my $name = 'demo.tif';
	my $compression = 'ccittfax3';
	my $resolutionUnit = 'inch';
	my $bitDepth = 1;
 	my $response = $imagingApi->PostProcessTiff(compression => $compression, resolutionUnit => $resolutionUnit, bitDepth => $bitDepth, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
};


subtest 'testPostTiffAppend' => sub {
	my $name = 'sample.tif';
	my $appendFile = 'TestDemo.tif';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $storageApi->PutCreate(Path => $appendFile, file => $data_path.$appendFile);
 	is($response->{'Status'}, "OK");
	
	$response = $imagingApi->PostTiffAppend(name => $name, appendFile => $appendFile);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetTiffToFax' => sub {
	my $name = 'TestDemo.tif';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
	$response = $imagingApi->GetTiffToFax(name => $name);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetImageBmp' => sub {
	my $name = 'sample.bmp';
	my $bitsPerPixel = 24;
	my $horizontalResolution = 300;
	my $verticalResolution = 300;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
	$response = $imagingApi->GetImageBmp(name=> $name, bitsPerPixel => $bitsPerPixel, horizontalResolution => $horizontalResolution, verticalResolution => $verticalResolution);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetCropImage' => sub {
	my $name = 'aspose.jpg';
	my $format = 'png';
	my $x = 30;
	my $y = 40;
	my $width = 100;
	my $height = 100;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $imagingApi->GetCropImage(name=> $name, format => $format, x => $x, y => $y, width => $width, height => $height);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetImageFrame' => sub {
	my $name = 'sample-multi.tif';
	my $frameId = 1;

	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $imagingApi->GetImageFrameProperties(name=> $name, frameId => $frameId);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetImageFrameProperties' => sub {
	my $name = 'TestDemo.tif';
	my $frameId = 0;

	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $imagingApi->GetImageFrameProperties(name=> $name, frameId => $frameId);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeImagingCloud::Object::ImagingResponse');
};

subtest 'testGetImageGif' => sub {
	my $name = 'sample.gif';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $imagingApi->GetImageGif(name=> $name);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetImageJpg' => sub {
	my $name = 'aspose.jpg';
	my $quality = 100;
	my $compressionType = 'progressive';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $imagingApi->GetImageJpg(name => $name, quality => $quality, compressionType => $compressionType);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetImagePng' => sub {
	my $name = 'aspose_imaging_for_cloud.png';
	my $fromScratch = 'True';	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $imagingApi->GetImagePng(name => $name, fromScratch => $fromScratch);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetImageProperties' => sub {
	my $name = 'demo.tif';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $imagingApi->GetImageProperties(name => $name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeImagingCloud::Object::ImagingResponse');
};

subtest 'testGetImagePsd' => sub {
	my $name = 'sample.psd';
	my $channelsCount = 3;
	my $compressionMethod = 'rle';	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $imagingApi->GetImagePsd(name => $name, channelsCount => $channelsCount, compressionMethod => $compressionMethod);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetChangeImageScale' => sub {
	my $name = 'aspose_imaging_for_cloud.png';
	my $format = 'jpg';
	my $newWidth = 200;
	my $newHeight = 200;		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $imagingApi->GetChangeImageScale(name => $name, format => $format, newWidth => $newWidth, newHeight => $newHeight);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetImageRotateFlip' => sub {
	my $name = 'aspose.jpg';
	my $format = 'png';
	my $method = 'Rotate180FlipX';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $imagingApi->GetImageRotateFlip(name => $name, format => $format, method => $method);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetImageSaveAs' => sub {
	my $name = 'aspose.jpg';
	my $format = 'png';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $imagingApi->GetImageSaveAs(name => $name, format => $format);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetUpdatedImage' => sub {
	my $name = 'TestDemo.tif';
	my $format = 'png';
	my $x = 96;
	my $y = 96;
	my $newWidth = 300;
	my $newHeight = 300;
	my $rectWidth = 200;
	my $rectHeight = 200;
	my $rotateFlipMethod='';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $imagingApi->GetUpdatedImage(name=> $name, format => $format, x => $x, y => $y, newWidth => $newWidth, newHeight => $newHeight, rectWidth => $rectWidth, rectHeight => $rectHeight, rotateFlipMethod => $rotateFlipMethod);
 	is($response->{'Status'}, "OK");
};

done_testing();