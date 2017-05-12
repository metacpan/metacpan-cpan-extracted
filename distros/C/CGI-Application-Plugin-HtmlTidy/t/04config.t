
use strict;

use Test::More tests => 3;

use lib './t';

use CleanApp;

$ENV{CGI_APP_RETURN_ONLY} = 1;
$ENV{REQUEST_METHOD} = 'GET';
my $app = CleanApp->new(PARAMS=> {
        htmltidy_config => {
            config_file => './t/tidy.conf',
        }
    });

like($app->run, qr/<meta name="generator" content="(?:HTML Tidy|tidyp)/, 'valid html');
is($app->{'CGI::Application::Plugin::HtmlTidyOPTIONS'}{config_file}, './t/tidy.conf');

my $app2 = CleanApp->new();
$app2->start_mode('invalid_html');

like ($app2->run, qr!<h1>h1 not allowed here, and not closed Missing body</h1>! , 'First error message');

