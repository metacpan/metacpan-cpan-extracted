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

use AsposeEmailCloud::EmailApi;
use AsposeEmailCloud::ApiClient;
use AsposeEmailCloud::Configuration;

use AsposeEmailCloud::Object::EmailPropertiesResponse;
use AsposeEmailCloud::Object::EmailDocumentResponse;
use AsposeEmailCloud::Object::EmailPropertyResponse;

use AsposeEmailCloud::Object::EmailProperty;
use AsposeEmailCloud::Object::EmailProperties;
use AsposeEmailCloud::Object::EmailDocument;

use_ok('AsposeEmailCloud::Configuration');
use_ok('AsposeEmailCloud::ApiClient');
use_ok('AsposeEmailCloud::EmailApi');

$AsposeEmailCloud::Configuration::app_sid = 'XXX';
$AsposeEmailCloud::Configuration::api_key = 'XXX';

$AsposeEmailCloud::Configuration::debug = 1;

if(not defined $AsposeEmailCloud::Configuration::app_sid or $AsposeEmailCloud::Configuration::app_sid =~ /^XXX/i){
		done_testing();
    	exit;
  }else{
  	$AsposeStorageCloud::Configuration::app_sid = $AsposeEmailCloud::Configuration::app_sid
  }
    
if (not defined $AsposeEmailCloud::Configuration::api_key or $AsposeEmailCloud::Configuration::api_key =~ /^XXX/i){
	done_testing();
    exit;
}else{
	$AsposeStorageCloud::Configuration::api_key = $AsposeEmailCloud::Configuration::api_key;
}

my $data_path = './data/';

if (not -d $data_path){
	done_testing();
    exit;
}

if($AsposeEmailCloud::Configuration::debug){
	$AsposeStorageCloud::Configuration::debug = $AsposeEmailCloud::Configuration::debug;
}

my $storageApi = AsposeStorageCloud::StorageApi->new();
my $emailApi = AsposeEmailCloud::EmailApi->new();

subtest 'testGetDocument' => sub {
	my $name = 'email_test.eml';
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 
 	$response = $emailApi->GetDocument(name=> $name);
 	isa_ok($response, 'AsposeEmailCloud::Object::EmailPropertiesResponse');
};


subtest 'testGetDocumentWithFormat' => sub {
	my $name = 'email_test.eml';
	my $format = "msg";
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 
 	$response = $emailApi->GetDocumentWithFormat(name=> $name, format=>$format); 	
 	is($response->{'Status'}, "OK"); 
};

	
subtest 'testGetEmailAttachment' => sub {
	my $name = 'email_test2.eml';
	my $attachName = "README.TXT";
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 
 	$response = $emailApi->GetEmailAttachment(name=> $name, attachName=>$attachName);
 	is($response->{'Status'}, "OK");
};	


subtest 'testGetEmailAttachment' => sub {
	my $name = 'email_test2.eml';
	my $attachName = "README.TXT";
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $storageApi->PutCreate(Path => $attachName, file => $data_path.$attachName);
 	is($response->{'Status'}, "OK"); 
 	
 	$response = $emailApi->PostAddEmailAttachment(name=> $name, attachName=>$attachName);
 	isa_ok($response, 'AsposeEmailCloud::Object::EmailDocumentResponse');
 	is($response->{'Status'}, "OK");
};	

subtest 'testGetEmailProperty' => sub {
	my $name = 'email_test2.eml';
	my $propertyName = "Subject";
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $emailApi->GetEmailProperty(name=> $name, propertyName=>$propertyName);
 	isa_ok($response, 'AsposeEmailCloud::Object::EmailPropertyResponse');
 	is($response->{'Status'}, "OK");
};


subtest 'testPutCreateNewEmail' => sub {
	my $name = 'email_test2.eml';
	
	my @emailProperty1 = AsposeEmailCloud::Object::EmailProperty->new('Name' => 'Body', 'Value' => 'This is a body');
	my @emailProperty2 = AsposeEmailCloud::Object::EmailProperty->new('Name' => 'To', 'Value' => 'developer@aspose.com');
	my @emailProperty3 = AsposeEmailCloud::Object::EmailProperty->new('Name' => 'From', 'Value' => 'sales@aspose.com');
	
	my $emailProperties = AsposeEmailCloud::Object::EmailProperties->new('List' => [@emailProperty1, @emailProperty2, @emailProperty3]);
	
	my $emailDocument = AsposeEmailCloud::Object::EmailDocument->new('DocumentProperties' => $emailProperties, 'Format' => 'eml');
	
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $emailApi->PutCreateNewEmail(name=> $name, body=>$emailDocument);
 	isa_ok($response, 'AsposeEmailCloud::Object::EmailDocumentResponse');
 	is($response->{'Status'}, "OK");
};

subtest 'testPutSetEmailProperty' => sub {
	my $name = 'email_test.eml';
	my $propertyName = 'Subject';
	
	my @emailProperty = AsposeEmailCloud::Object::EmailProperty->new('Name' => 'Body', 'Value' => 'This is a body');
	
	
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $emailApi->PutSetEmailProperty(name=> $name, propertyName=>$propertyName, body=>@emailProperty);
 	isa_ok($response, 'AsposeEmailCloud::Object::EmailPropertyResponse');
 	is($response->{'Status'}, "OK");
};
done_testing();