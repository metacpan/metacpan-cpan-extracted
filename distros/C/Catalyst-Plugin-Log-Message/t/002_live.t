#!perl
BEGIN {
    chdir 't' if -d 't';
    use lib qw[../lib/ lib/];
}

use Test::More 'no_plan';
use Catalyst::Test 'TestApp';
use Data::Dumper;

{
    my %tests = (
            last_error  => {
                    response    => 'Error',
                },
            whole_stack => {
                    response    => qr/debug.*?Error/s,
                    like        => 1,
                },
            only_debug  => {
                    response    => 'debug'
                },
            other_debug => {
                    response    => 'another_debug'
                },
        );
    my $reqtest = 0;

    foreach my $test (keys %tests) {
        my $response;
        my $url = '/functions/' . $test;
        $url .= '/?' . $tests{$test}->{get} if $tests{$test}->{get};
        if ($reqtest) {
            $response = request($url, 'Request OK');
        } else {
            ok($response = request($url, 'Request OK'));
            $reqtest = 1;
        }
        if ($tests{$test}->{like}) {
            like($response->content, $tests{$test}->{response}, $test .
                    ' profile check');

        } else {
            is( $response->content, $tests{$test}->{response},  $test .
                    ' profile check');
        }
    }
}
