use Test::More tests => 5;

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestAppCallback;
my $t1_obj = TestAppCallback->new();
my $t1_output = $t1_obj->run();

like($t1_output, qr/template param\./, 'template parameter');
like($t1_output, qr/template param hash\./, 'template parameter hash');
like($t1_output, qr/template param hashref\./, 'template parameter hashref');
like($t1_output, qr/pre_process param\./, 'pre process parameter');
like($t1_output, qr/post_process param\./, 'post process parameter');

