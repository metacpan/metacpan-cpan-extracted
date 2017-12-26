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

{
    my $i = 0;
    for (1..8){
        my $id = "aux$_";
        my $res = $test->request(GET "/get_aux/$id");
        ok $res->is_success, "/get_aux/$id request ok";
        my $j = $res->content;
        my $p = decode_json $j;

        is ref $p, 'HASH', "/get_aux/$id return an href in JSON";
        is keys %$p, 7, "$id has ok key count";

        $i++;
    }
}

unset_testing();
unconfig();
db_remove();
done_testing();

