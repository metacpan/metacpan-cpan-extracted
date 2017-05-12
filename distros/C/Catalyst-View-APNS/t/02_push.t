use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Catalyst::Test qw(TestApp);
use Test::More;

plan tests => 1;

my $entrypoint = "http://localhost/push";
{
    my $response = request($entrypoint);
    is( $response->code, 500 );
};

1;

