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
        temp_limit humidity_limit temp_aux_on_time humidity_aux_on_time
        temp_aux humidity_aux light_aux
        );

    my @values = qw(
        80 20 1800 1800 aux1 aux2 aux3
        );

    is @directives, @values, "test configuration ok";

    my $i = 0;
    for (@directives){
        my $res = $test->request(GET "/get_control/$_");
        ok $res->is_success, "/get_control/$_ request ok";
        my $ret = $res->content;
        is $ret, $values[$i], "${_}'s value is returned correctly";
        $i++;
    }
}

unset_testing();
unconfig();
db_remove();
done_testing();

