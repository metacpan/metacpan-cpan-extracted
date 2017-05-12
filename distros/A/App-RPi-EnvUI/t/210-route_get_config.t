use strict;
use warnings;

use Data::Dumper;
use Test::More;

BEGIN {
    use lib 't/';
    use TestBase;
    config();
    set_testing();
    db_create();
}

use FindBin;
use lib "$FindBin::Bin/../lib";

use HTTP::Request::Common;
use Plack::Test;
use App::RPi::EnvUI;

my $test = Plack::Test->create(App::RPi::EnvUI->to_app);

{
    my @directives = qw(
        event_fetch_timer event_action_timer event_display_timer
        sensor_pin testing time_zone
    );

    my @values = qw(
        15 3 4 -1 0 America/Edmonton
    );

    is @directives, @values, "test configuration ok";

    my $i = 0;
    for (@directives){
        my $res = $test->request(GET "/get_config/$_");
        ok $res->is_success, "/get_config/$_ request ok";
        my $ret = $res->content;
        is $ret, $values[$i], "${_}'s value is returned correctly";
        $i++;
    }
}

#db_remove();
unset_testing();
db_remove();
done_testing();

