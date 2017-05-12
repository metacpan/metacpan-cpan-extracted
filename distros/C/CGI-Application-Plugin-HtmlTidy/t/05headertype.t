
use strict;

use Test::More tests => 5;

use lib './t';

use CleanApp;

$ENV{CGI_APP_RETURN_ONLY} = 1;
$ENV{REQUEST_METHOD} = 'GET';

my $app = CleanApp->new(PARAMS=> {
                htmltidy_config => {
					config_file => './t/tidy.conf',
				}
		});
$app->start_mode('non_html');
my $out = $app->run;

unlike($out, qr/<meta name="generator" content="HTML Tidy/,  'text/js not marked');
like($out, qr!var a = new Array!, 'content ok');

$app = CleanApp->new(PARAMS=> {
                htmltidy_config => {
					config_file => './t/tidy.conf',
				}
		});
$app->start_mode('header_redirect');
$out = $app->run;

unlike($out, qr/<meta name="generator" content="HTML Tidy/,  'text/js not marked');
like  ($out, qr/302 (?:Moved|Found)/, 'header ok');

$app = CleanApp->new(PARAMS=> {
                htmltidy_config => {
					config_file => './t/tidy.conf',
				}
		});
$app->start_mode('header_none');
$out = $app->run;

is($out, 'none');

