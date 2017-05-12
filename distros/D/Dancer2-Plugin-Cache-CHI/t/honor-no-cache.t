use 5.10.0;

use strict;
use warnings;

use Test::More tests => 5;
use Plack::Test;
use HTTP::Request::Common;

{
    package TestApp;

    use Dancer2;
    use Dancer2::Plugin::Cache::CHI;

    set plugins => {
        'Cache::CHI' => {
            driver => 'Memory',
            global => 1,
            expires_in => '1 min',
            'honor_no_cache' => 1,
        },
    };

    check_page_cache;

    get '/cached' => sub {
        state $i;
        return cache_page ++$i;
    };
}

my $app = Dancer2->runner->psgi_app;
is ref $app, 'CODE', 'got app';

test_psgi $app, sub {
    my $cb  = shift;

    my $counter = 0;
    is $cb->(GET '/cached')->content, ++$counter, "initial hit ($counter)";
    is $cb->(GET '/cached')->content, $counter, "cached ($counter)";

    subtest $_ => sub {
        plan tests => 2;
        is $cb->(GET '/cached', $_ => 'no-cache')->content, ++$counter, "$_: no-cache ($counter)";
        is $cb->(GET '/cached')->content, $counter, "cached again ($counter)";
    } for qw/ Cache-Control Pragma /;
};
