use strict;
use warnings;

use Test::More import => ['!pass'];

plan tests => 7;

{
    use Dancer;
    use File::Spec;
    use Dancer::Plugin::MobileDevice;
    setting show_errors => 1;

    set views => File::Spec->catfile('t', 'views');
    
    get '/' => sub {
        template 'index';
    };
}

use Dancer::Test;

sub resp_for_agent($$$) {
    my( $agent, $result, $comment ) = @_;

    # for Dancer 1.x
    $ENV{HTTP_USER_AGENT} = $agent;

    # for Dancer 2.x
    is dancer_response( GET => '/', undef,
        { HTTP_USER_AGENT => $agent } )->{content} => $result, $comment;
} 

# expose a bug
set layout => 'main';

resp_for_agent $_, "main\nis_mobile_device: 0\n\n",
        "main layout for non-mobile agent $_" for qw/ Mozilla Opera /;

# no default layout
set layout => undef;

resp_for_agent 'Android' 
    => "is_mobile_device: 1\n", 
    "No layout used unless asked to";

# this is a bit dirty
if ( $Dancer::VERSION < 2 ) {
    my $settings = Dancer::Config::settings();
    $settings->{plugins}{MobileDevice}{mobile_layout} = 'mobile';
}
else {
    config->{plugins}{MobileDevice}{mobile_layout} = 'mobile';
}

resp_for_agent 'Android' =>
    "mobile\nis_mobile_device: 1\n\n",
    "mobile layout is set for mobile agents when desired";


resp_for_agent 'Mozilla',
    "is_mobile_device: 0\n", 
    "no layout for non-mobile agents";

set layout => 'main';

resp_for_agent 'Android' =>
    "mobile\nis_mobile_device: 1\n\n", 
    "mobile layout is set for mobile agents still";

resp_for_agent 'Mozilla' =>
    "main\nis_mobile_device: 0\n\n", 
    "main layout for non-mobile agents";


