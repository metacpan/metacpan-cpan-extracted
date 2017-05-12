use Test::More tests => 2;

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestAppLoadtmpl;
my $t1_obj = TestAppLoadtmpl->new();
my $t1_output = $t1_obj->run();

like($t1_output, qr/template param\./, 'template parameter');
like($t1_output, qr/load_tmpl param\./, 'load_tmpl parameter');

