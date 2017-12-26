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

{ # /light route

    my $res = $test->request(GET '/light');
    ok $res->is_success, '/light request ok';

    my $j = $res->content;
    my $p = decode_json $j;

    is ref $p, 'HASH', "/light returns json, which is an href";
    is keys %$p, 5, "return has proper num keys";

    is $p->{on_at}, '18:00', "fetch on_at ok";
    is $p->{on_hours}, 12, "fetch on_hours ok";
    is $p->{enable}, 0, "fetch enable ok";
}

unset_testing();
db_remove();
unconfig();
done_testing();

