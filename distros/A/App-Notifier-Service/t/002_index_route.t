use Test::More tests => 1;
use strict;
use warnings;

# the order is important
use Plack::Test;
use HTTP::Request::Common;    # install separate

# use App::Notifier::Service 0.0800;

my $app  = do { require App::Notifier::Service; };
my $test = Plack::Test->create($app);

my $res = $test->request( GET '/' );

{
    local $TODO = 1;

    # TEST

    is( $res->code, 200, 'response status is 200 for /' );
}
