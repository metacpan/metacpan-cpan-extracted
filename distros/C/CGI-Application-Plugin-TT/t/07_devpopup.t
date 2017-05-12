use Test::More;

use lib './t';
use strict;

BEGIN {
    $ENV{CAP_DEVPOPUP_EXEC} = 1;
    eval {
        require CGI::Application::Plugin::DevPopup;
    };

    if ($@) {
        plan skip_all => "CGI::Application::Plugin::DevPopup required for these tests";
        exit;
    }
}

plan tests => 3;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestAppDevPopup;
my $t1_obj = TestAppDevPopup->new();
my $t1_output = $t1_obj->run();

like($t1_output, qr/template param\./, 'template parameter');
like($t1_output, qr/&#x3C;div class=&#x22;test&#x22;&#x3E;&#x3C;\/div&#x3E;/, 'HTML tags were encoded as entities');
like($t1_output, qr/TT params for/, 'popup title found');

