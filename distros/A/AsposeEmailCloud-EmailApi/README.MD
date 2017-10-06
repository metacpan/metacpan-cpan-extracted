##Aspose.Email Cloud SDK for Perl

This repository contains Aspose.Email Cloud SDK for Perl source code. This SDK allows you to work with Aspose.Email Cloud REST APIs in your perl applications quickly and easily. 

<p align="center">
  <a title="Download complete Aspose.Email for Cloud source code" href="https://github.com/asposeEmail/Aspose_Email_Cloud/archive/master.zip">
	<img src="https://raw.github.com/AsposeExamples/java-examples-dashboard/master/images/downloadZip-Button-Large.png" />
  </a>
</p>

##How to Use the SDK?
The complete source code is available in this repository folder. For more details, please visit our [documentation website](http://www.aspose.com/docs/display/Emailcloud/Available+SDKs).

##Quick SDK Tutorial
```javascript
use lib 'lib';
use strict;
use warnings;
use File::Slurp; # From CPAN

use AsposeStorageCloud::StorageApi;
use AsposeStorageCloud::ApiClient;
use AsposeStorageCloud::Configuration;

use AsposeEmailCloud::EmailApi;
use AsposeEmailCloud::ApiClient;
use AsposeEmailCloud::Configuration;

$AsposeEmailCloud::Configuration::app_sid = 'XXX';
$AsposeEmailCloud::Configuration::api_key = 'XXX';

$AsposeEmailCloud::Configuration::debug = 1;
$AsposeStorageCloud::Configuration::app_sid = $AsposeEmailCloud::Configuration::app_sid;
$AsposeStorageCloud::Configuration::api_key = $AsposeEmailCloud::Configuration::api_key;

#Instantiate Aspose.Storage API SDK 
my $storageApi = AsposeStorageCloud::StorageApi->new();

#Instantiate Aspose.Email API SDK
my $EmailApi = AsposeEmailCloud::EmailApi->new();


```javascript
##Contact Us
Your feedback is very important to us. Please feel free to contact us using our [Support Forums](https://www.aspose.com/community/forums/)
