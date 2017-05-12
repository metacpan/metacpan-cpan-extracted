
use strict;

use Test::More tests => 4;

use lib './t';

use CleanSubApp;

$ENV{CAP_DEVPOPUP_EXEC}   = 1;
$ENV{CGI_APP_RETURN_ONLY} = 1;
$ENV{REQUEST_METHOD}      = 'GET';

my $app = CleanSubApp->new(PARAMS=> {
        htmltidy_config => {
        config_file => './t/tidy.conf',
        }
        });
my $out = $app->run;

like($out, qr/<meta name="generator" content="(?:HTML Tidy|tidyp)/,  'output cleaned');
like($out, qr!valid!, 'content ok');

eval "require ValidateSubApp";

SKIP: {
    skip "CAP::DevPopup not installed, won't generate validation reports without it", 2 if $@;

my $app2 = ValidateSubApp->new;
$app2->start_mode('valid_html');

unlike($app2->run, qr/validation results/, 'valid html');

$app2 = ValidateSubApp->new();
$app2->start_mode('invalid_html');

like ($app2->run, qr/validation results/ , 'First error message');

}

