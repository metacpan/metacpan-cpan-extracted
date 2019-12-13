use 5.008001;
use strict;
use warnings;

use Test::More import => ['!pass'];
use Test::NoWarnings;
use Plack::Test;
use HTTP::Request::Common;

plan tests => 6;

my $app;
{
    package TestApp;
    use Dancer2;
    # Set the configuration before loading MobileDevice.  This is because
    # configuration is immutable as soon as it is read, and MobileDevice
    # reads its configuration on startup.
    set plugins => { MobileDevice => { mobile_layout => 'mobile' } } ;

    use File::Spec;
    use Dancer2::Plugin::MobileDevice;

    $app = app;     # For the use of the tests

    setting show_errors => 1;

    set template => 'simple';   # default is 'tiny'
    set views => File::Spec->catfile('t', 'views');

    get '/' => sub {
        template 'index';
    };
}

my $dut = Plack::Test->create(TestApp->to_app);
isa_ok $app, 'Dancer2::Core::App';

sub resp_for_agent($$$) {
    my( $agent, $result, $comment ) = @_;
    diag '-' x 40;
    my $resp = $dut->request(GET '/', 'User-Agent' => $agent);
    is $resp->content, $result, $comment;
}

# no default layout
$app->setting(layout => undef);

resp_for_agent 'Android' =>
    "mobile\nis_mobile_device: 1\n\n",
    "mobile layout is set for mobile agents when desired";

resp_for_agent 'Mozilla',
    "is_mobile_device: 0\n",
    "no layout for non-mobile agents";

$app->setting(layout => 'main');

resp_for_agent 'Android' =>
    "mobile\nis_mobile_device: 1\n\n",
    "mobile layout is set for mobile agents still";

resp_for_agent 'Mozilla' =>
    "main\nis_mobile_device: 0\n\n",
    "main layout for non-mobile agents";

