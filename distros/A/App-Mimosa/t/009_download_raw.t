use Test::Most tests => 5;
use strict;
use warnings;

use lib 't/lib';
use App::Mimosa::Test;

use File::Slurp qw/slurp/;
use HTTP::Request::Common;
use File::Spec::Functions;
use Test::DBIx::Class;

fixtures_ok 'basic_job';

{
    my $response = request GET '/api/report/raw/42', [
    ];
    is($response->code, 400, 'Downloading the raw report of an invalid Job id should fail');
    like($response->content,qr/does not exist/);
}
{
    my $response = request GET '/api/report/raw/1', [
    ];
    is($response->code, 200, 'get a raw report');
    like($response->content,qr/Altschul, Stephen F/);
}
