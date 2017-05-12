use Test::More tests => 3;
BEGIN { use_ok('CGI::Application::Plugin::ValidateRM') };

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestApp1;
my $app = TestApp1->new(QUERY=>CGI->new("email=broken;rm=form_process"));
my $output = $app->run();
unlike($output, qr/Filler Up/);

$app->param(dfv_fif_class => 'TestFormFiller');
$output = $app->run();
like($output, qr/Filler Up/);
exit(0);

package TestFormFiller;
use strict;
use warnings;

sub new { bless {}, $_[0] }
sub fill { "Filler Up!" }

1;
