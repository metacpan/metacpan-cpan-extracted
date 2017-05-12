use lib '../lib';
use strict;
use warnings;
use Test::More;
use Test::Exception;


use AsposeStorageCloud::StorageApi;
use AsposeStorageCloud::ApiClient;
use AsposeStorageCloud::Configuration;
use AsposeStorageCloud::Object::DiscUsage;
use AsposeStorageCloud::Object::FileExist;
use AsposeStorageCloud::Object::ResponseMessage;
use AsposeStorageCloud::Object::FileVersion;
use File::Slurp; # From CPAN

use_ok('AsposeStorageCloud::Configuration');
use_ok('AsposeStorageCloud::ApiClient');
use_ok('AsposeStorageCloud::StorageApi');

$AsposeStorageCloud::Configuration::app_sid = 'XXX';
$AsposeStorageCloud::Configuration::api_key = 'XXX';

if(not defined $AsposeStorageCloud::Configuration::app_sid or $AsposeStorageCloud::Configuration::app_sid =~ /^XXX/i){
		done_testing();
    	exit;
  }
    
if (not defined $AsposeStorageCloud::Configuration::api_key or $AsposeStorageCloud::Configuration::api_key =~ /^XXX/i){
	done_testing();
    exit;
}
my $data_path = './data/';

if (not -d $data_path){
	done_testing();
    exit;
}

$AsposeStorageCloud::Configuration::debug = 1;
my $storageApi = AsposeStorageCloud::StorageApi->new();

subtest 'testGetDiscUsage' => sub {
 	my $response = $storageApi->GetDiscUsage();
 	isa_ok($response, 'AsposeStorageCloud::Object::DiscUsageResponse');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetIsExist' => sub {
 	my $response = $storageApi->GetIsExist(Path => 'testfile.txt');
 	isa_ok($response, 'AsposeStorageCloud::Object::FileExistResponse');
 	is($response->{'Status'}, "OK"); 
};	

subtest 'testPutCopy' => sub {
	my $response = $storageApi->PutCreate(Path => 'testfile.txt', file => $data_path.'testfile.txt');
 	$response = $storageApi->PutCopy(Path => 'testfile.txt', newdest => 'new_testfile.txt', file => $data_path.'testfile.txt');
 	isa_ok($response, 'AsposeStorageCloud::Object::ResponseMessage');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPutCreate' => sub {
 	my $response = $storageApi->PutCreate(Path => 'SampleWordDocument.docx', file => $data_path.'SampleWordDocument.docx');
 	isa_ok($response, 'AsposeStorageCloud::Object::ResponseMessage');
 	is($response->{'Status'}, "OK"); 
};
	
subtest 'testGetDownload' => sub {
	my $response = $storageApi->PutCreate(Path => 'SampleWordDocument.docx', file => $data_path.'SampleWordDocument.docx');
	$response = $storageApi->GetDownload(Path => 'SampleWordDocument.docx');
 	isa_ok($response, 'AsposeStorageCloud::Object::ResponseMessage');
 	is($response->{'Status'}, "OK");
};
	
subtest 'testDeleteFile' => sub {
	my $response = $storageApi->PutCreate(Path => 'SampleWordDocument.docx', file => $data_path.'SampleWordDocument.docx');
 	$response = $storageApi->DeleteFile(Path => 'testfile.txt');
 	isa_ok($response, 'AsposeStorageCloud::Object::RemoveFileResponse');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostMoveFile' => sub {
	my $name = 'testfile.txt';	
	my $dest = 'new-testfile.txt';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	$response = $storageApi->PostMoveFile(src => $name, dest=> $dest);
 	isa_ok($response, 'AsposeStorageCloud::Object::MoveFileResponse');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPutCreateFolder' => sub {
	my $name = 'test0';
 	my $response = $storageApi->PutCreateFolder(Path => $name);
 	isa_ok($response, 'AsposeStorageCloud::Object::ResponseMessage');
 	is($response->{'Status'}, "OK"); 
};


subtest 'testPutCopyFolder' => sub {
	my $name = 'test0';	
	my $newdest = 'test1';
	my $response = $storageApi->PutCreateFolder(Path => $name);
 	$response = $storageApi->PutCopyFolder(Path => $name, newdest => $newdest);
 	isa_ok($response, 'AsposeStorageCloud::Object::ResponseMessage');
 	is($response->{'Status'}, "OK"); 
};

	
subtest 'testGetListFiles' => sub {
 	my $response = $storageApi->GetListFiles(Path => 'farooq');
 	isa_ok($response, 'AsposeStorageCloud::Object::ResponseMessage');
 	is($response->{'Status'}, "OK"); 
};
	
subtest 'testDeleteFolder' => sub {
	my $name = 'test0';
 	my $response = $storageApi->PutCreateFolder(Path => $name);
 	$response = $storageApi->DeleteFolder(Path => $name);
 	isa_ok($response, 'AsposeStorageCloud::Object::RemoveFolderResponse');
 	is($response->{'Status'}, "OK"); 
};
	
subtest 'testPostMoveFolder' => sub {
 	my $name = 'test0';	
	my $dest = 'test1';
	my $response = $storageApi->PutCreateFolder(Path => $name);
 	$response = $storageApi->PostMoveFolder(src => $name, dest => $dest);
 	isa_ok($response, 'AsposeStorageCloud::Object::MoveFolderResponse');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetListFileVersions' => sub {
	my $name = 'testfile.txt';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	$response = $storageApi->GetListFileVersions(Path => $name);
 	isa_ok($response, 'AsposeStorageCloud::Object::FileVersionsResponse');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetIsStorageExist' => sub {
	my $name='AsposeDropBox';	
 	my $response = $storageApi->GetIsStorageExist(name => $name);
 	isa_ok($response, 'AsposeStorageCloud::Object::StorageExistResponse');
 	is($response->{'Status'}, "OK"); 
};
	
done_testing();