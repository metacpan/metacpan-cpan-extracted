use strict;
use Test::More tests => 5;

$ENV{CAP_DEVPOPUP_EXEC} = 1;

use lib './t';
use_ok "OptionsApp";

$ENV{CGI_APP_RETURN_ONLY} = 1;
$ENV{REQUEST_METHOD} = 'GET';
my $app = OptionsApp->new;

my $out = $app->run;
like $out, qr/valid/, 'valid html';
like $out, qr/name="generator" content="(?:HTML Tidy|tidyp)/, 'tidy-mark option on';
like $out, qr/alt="xxx"/, 'alt-text set';

my $app2 = OptionsApp->new();
$app2->start_mode('invalid_html');

unlike $app2->run, qr/headhunter/, 'properly cleaned';

