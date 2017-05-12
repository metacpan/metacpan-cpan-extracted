use strict;
use warnings;
use Test::Builder;
use Test::More;
use BusyBird::Input::Feed::Run;
use FindBin;
use JSON qw(decode_json);
use Test::LWP::UserAgent;
use HTTP::Response;

if(!$ENV{BB_INPUT_FEED_NETWORK_TEST}) {
    plan('skip_all', "Set BB_INPUT_FEED_NETWORK_TEST environment to enable the test");
    exit;
}

sub check_output {
    my ($output_json) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $got = decode_json($output_json);
    is ref($got), "ARRAY", "got ARRAY-ref";
    my $num = scalar(@$got);
    cmp_ok $num, '>', 0, "got more than one (actually $num) statuses";
    foreach my $i (0 .. $#$got) {
        my $s = $got->[$i];
        ok defined($s->{id}), "status $i: id is defined";
        ok defined($s->{text}), "status $i: text is defined";
        ok defined($s->{busybird}{status_permalink}), "status $i: busybird.status_permalink is defined";
    }
}

my $run_cmd = "perl -Ilib $FindBin::RealBin/../bin/busybird_input_feed";

{
    note("--- STDIN -> STDOUT");
    my $output = `$run_cmd < '$FindBin::RealBin/../t/samples/stackoverflow.atom'`;
    check_output $output;
}

{
    note("--- STDIN -> STDOUT (level)");
    my $output = `$run_cmd -l 5 < '$FindBin::RealBin/../t/samples/stackoverflow.atom'`;
    my $got = decode_json($output);
    cmp_ok scalar(@$got), ">", 0, "get at least 1 status";
    foreach my $s (@$got) {
        is $s->{busybird}{level}, 5, "level set to 5";
    }
}

{
    note("--- URL -> STDOUT");
    my $output = `$run_cmd 'http://rss.slashdot.org/Slashdot/slashdot'`;
    check_output $output;
}

{
    note("--- URL -> URL");
    my $ua = Test::LWP::UserAgent->new(network_fallback => 1);
    my $output;
    $ua->env_proxy;
    $ua->map_response(qr{/timelines/home/statuses\.json}, sub {
        my ($request) = @_;
        $output = $request->decoded_content;
        my $mocked_res = HTTP::Response->new(200);
        $mocked_res->header('Content-Type' => 'application/json; charset=utf-8');
        $mocked_res->content(q{{"error":null,"count":10}});  ## count may be wrong...
        return $mocked_res;
    });
    BusyBird::Input::Feed::Run->run(
        download_url => 'http://rss.slashdot.org/Slashdot/slashdot',
        post_url => 'http://hogehoge.com/timelines/home/statuses.json',
        user_agent => $ua
    );
    ok defined($output), "output is captured";
    check_output $output;
}

done_testing;

