package AsposeWordsCloud::Configuration;

use strict;
use warnings;
use utf8;

use Log::Any qw($log);
use Carp;

use constant VERSION => '1.0.1';

# class/static variables
our $api_client;
our $http_timeout = 180;
our $http_user_agent = 'Aspose-Cloud-SDK-Perl-Agent';
our $debug = 0;

# authenticaiton setting
our $app_sid;
our $api_key;
our $api_server = 'http://api.aspose.cloud/v1.1';

1;
