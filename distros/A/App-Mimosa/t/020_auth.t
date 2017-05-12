use strict;
use warnings;
use Test::Most tests => 2;

BEGIN {
    $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'testing_auth';
}

use lib 't/lib';
use App::Mimosa::Test;
use Test::DBIx::Class;

use File::Slurp qw/slurp/;
use HTTP::Request::Common;
use File::Spec::Functions;
#use Carp::Always;

fixtures_ok 'basic_ss';

{
    my $response = request GET '/';
    like($response->content,qr/Login/, 'index page is a login if allow_anonymous=0');
}
