use Test::More tests => 2;

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use TestAppOptions;
my $t1_obj = TestAppOptions->new();
my $t1_output = $t1_obj->run();

my $logoutput = ${$t1_obj->{__LOG_MESSAGES}->{HANDLE}};

like($logoutput, qr/log debugEXTRA/, 'logged debug message');
like($logoutput, qr/log infoEXTRA/, 'logged info message');

