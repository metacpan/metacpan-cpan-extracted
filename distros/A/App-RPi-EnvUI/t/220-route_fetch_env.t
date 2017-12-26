use strict;
use warnings;

use Data::Dumper;
use JSON::XS;
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

{ # /fetch_env route

    my $res = $test->request(GET "/fetch_env");
    ok $res->is_success, "/fetch_env request ok";
    my $j = $res->content;
    my $p = decode_json $j;

    is ref $p, 'HASH', "/fetch_env return an href in JSON";
    is keys %$p, 3, "and has proper key count";

    for (qw(temp humidity)){
        is exists $p->{$_}, 1, "$_ has a key in /fetch_env";

    }

    is $p->{temp}, -1, "/fetch_env returns default value for temp ok";
    is $p->{humidity}, -1, "/fetch_env returns default value for humidity ok";

}

unset_testing();
unconfig();
db_remove();
done_testing();

