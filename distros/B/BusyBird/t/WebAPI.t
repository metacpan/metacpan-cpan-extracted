use strict;
use warnings;
use lib "t";
use utf8;
use Test::More;
use Test::MockObject;
use DateTime;
use DateTime::Duration;
use BusyBird::Main;
use BusyBird::Main::PSGI qw(create_psgi_app);
use BusyBird::StatusStorage::SQLite;
use BusyBird::DateTime::Format;
use testlib::HTTP;
use BusyBird::Test::StatusStorage qw(:status test_cases_for_ack);
use testlib::Timeline_Util qw(status);
use testlib::Main_Util qw(create_main);
use BusyBird::Log ();
use Plack::Test;
use Encode ();
use JSON qw(encode_json decode_json);
use Try::Tiny;

$BusyBird::Log::Logger = undef;

sub create_dying_status_storage {
    my $mock = Test::MockObject->new();
    foreach my $method (map { "${_}_statuses" } qw(ack get put delete)) {
        $mock->mock($method, sub {
            die "$method dies.";
        });
    }
    ## ** We cannot create a Timeline if get_unacked_counts throws an exception.
    $mock->mock('get_unacked_counts', sub {
        my ($self, %args) = @_;
        $args{callback}->(undef, "get_unacked_counts reports error.");
    });
    return $mock;
}

sub create_erroneous_status_storage {
    my $mock = Test::MockObject->new();
    foreach my $method ('get_unacked_counts', map { "${_}_statuses" } qw(ack get put delete)) {
        $mock->mock($method, sub {
            my ($self, %args) = @_;
            my $cb = $args{callback};
            if($cb) {
                $cb->("$method reports error.");
            }
        });
    }
    return $mock;
}

sub create_json_status {
    my ($id, $level) = @_;
    my $created_at_str = BusyBird::DateTime::Format->format_datetime(
        DateTime->from_epoch(epoch => $id, time_zone => 'UTC')
    );
    my $bb_string = defined($level) ? qq{,"busybird":{"level":$level}} : "";
    my $json_status = <<EOD;
{"id":"$id","created_at":"$created_at_str","text":"テキスト $id"$bb_string}
EOD
    return Encode::encode('utf8', $json_status);
}

sub json_array {
    my (@json_objects) = @_;
    return "[".join(",", @json_objects)."]";
}

sub test_get_statuses {
    my ($tester, $timeline_name, $query_str, $exp_id_list, $label) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $request_url = "/timelines/$timeline_name/statuses.json";
    if($query_str) {
        $request_url .= "?$query_str";
    }
    my $res_obj = $tester->get_json_ok($request_url, qr/^200$/, "$label: GET statuses OK");
    is($res_obj->{error}, undef, "$label: GET statuses error = null OK");
    test_status_id_list($res_obj->{statuses}, $exp_id_list, "$label: GET statuses ID list OK");
}

sub test_error_request {
    my ($tester, $endpoint, $content, $label) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($method, $request_url) = split(/ +/, $endpoint);
    $label ||= "";
    my $msg = "$label: $endpoint returns error";
    $tester->request_ok($method, $request_url, $content, qr/^[45]/, $msg);
}

## success if $got matches one of the choices.
sub test_list_choice {
    my ($got_list, $exp_choices, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    CHOICE_LOOP: foreach my $exp_list (@$exp_choices) {
        next CHOICE_LOOP if @$got_list != @$exp_list;
        foreach my $i (0 .. $#$got_list) {
            next CHOICE_LOOP if $got_list->[$i] ne $exp_list->[$i];
        }
        pass $msg;
        return 1;
    }
    fail $msg;
    diag("got:");
    diag(explain $got_list);
    diag("expected either:");
    diag(join "\n  or\n", map { explain($_) } @$exp_choices);
    return 0;
}

{
    note('--- normal functionalities');
    my $main = create_main();
    $main->timeline('test');
    $main->timeline('foobar');

    test_psgi create_psgi_app($main), sub {
        my $tester = testlib::HTTP->new(requester => shift);
        test_get_statuses($tester, 'test', undef, [], 'No status');
        my $res_obj = $tester->post_json_ok('/timelines/test/statuses.json',
                                           create_json_status(1), qr/^200$/, 'POST statuses (single) OK');
        is_deeply($res_obj, {error => undef, count => 1}, "POST statuses (single) results OK");
        $res_obj = $tester->post_json_ok('/timelines/test/statuses.json',
                                       json_array(map {create_json_status($_, $_)} 1..5),
                                       qr/^200$/, 'POST statuses (multi) OK');
        is_deeply($res_obj, {error => undef, count => 4}, "POST statuses (multi) results OK");

        test_get_statuses($tester, 'test', 'count=100', [reverse 1..5], "Get all");
        test_get_statuses($tester, 'test', 'ack_state=acked', [], 'only acked');
        test_get_statuses($tester, 'test', 'ack_state=unacked', [reverse 1..5], 'only unacked');

        $res_obj = $tester->post_json_ok('/timelines/test/ack.json', undef, qr/^200$/, 'POST ack (no param) OK');
        is_deeply($res_obj, {error => undef, count => 5}, 'POST ack (no param) results OK');

        $res_obj = $tester->post_json_ok('/timelines/test/statuses.json',
                                         json_array(map {
                                             my $id = $_;
                                             my $level = $id <= 10 ? undef
                                                 : $id <= 20 ? 1 : 2;
                                             create_json_status($id, $level)
                                         } 6..30), qr/^200$/, 'POST statuses (25) OK');
        is_deeply($res_obj, {error => undef, count => 25}, 'POST statuses (25) OK');

        test_get_statuses($tester, 'test', undef, [reverse 11..30], 'Get no count');
        test_get_statuses($tester, 'test', 'ack_state=acked', [reverse 1..5], 'Get only acked');
        test_get_statuses($tester, 'test', 'max_id=20&count=30', [reverse 1..20], 'max_id and count');
        test_get_statuses($tester, 'test', 'max_id=20&count=30&ack_state=unacked', [reverse 6..20], 'max_id, count and ack_state');
        test_get_statuses($tester, 'test', 'max_id=20&count=30&ack_state=acked', [], 'max_id in unacked, ack_state = acked');
        test_get_statuses($tester, 'test', 'max_id=60', [], 'unknown max_id');
        test_get_statuses($tester, 'test', 'max_id=23', [reverse 4..23], 'only max_id');

        {
            my $got = $tester->get_json_ok('/timelines/test/statuses.json?max_id=20&count=30&only_statuses=1', qr/^200$/, 'GET only_statuses=1 OK');
            is ref($got), "ARRAY", 'GET only_statuses=1 returns ARRAY-ref';
            test_status_id_list($got, [reverse 1..20], 'GET only_statuses=1 ids OK');
        }

        {
            my $exp_res = {error => undef, unacked_counts => {total => 25, 0 => 5, 1 => 10, 2 => 10}};
            foreach my $case (
                {label => "no param", param => ""},
                {label => "total", param => "?total=20"},
                {label => "level 0", param => "?0=3"},
                {label => "only level 1 differs", param => "?1=9&2=10&0=5&total=25"},
            ) {
                $res_obj = $tester->get_json_ok("/timelines/test/updates/unacked_counts.json$case->{param}",
                                                qr/^200$/, "GET tl unacked_counts ($case->{label}) OK");
                is_deeply($res_obj, $exp_res, "GET tl unacked_counts ($case->{label}) result OK");
            }
        }
        
        $res_obj = $tester->post_json_ok('/timelines/test/ack.json', qq{{"max_id":"100"}}, qr/^200$/, 'POST ack (unknown max_id) OK');
        is_deeply($res_obj, {error => undef, count => 0}, 'POST ack (unknown max_id) acks nothing');
        $res_obj = $tester->post_json_ok('/timelines/test/ack.json', qq{{"max_id":"4"}}, qr/^200$/, 'POST ack (acked max_id) OK');
        is_deeply($res_obj, {error => undef, count => 0}, 'POST ack (acked max_id) acks nothing');
        $res_obj = $tester->post_json_ok('/timelines/test/ack.json', qq{{"max_id":"20"}}, qr/^200$/, 'POST ack (unacked max_id) OK');
        is_deeply($res_obj, {error => undef, count => 15}, 'POST ack (unacked max_id) acks OK');

        test_get_statuses($tester, 'test', 'ack_state=unacked&count=100', [reverse 21..30], 'unacked');
        test_get_statuses($tester, 'test', 'ack_state=acked&count=100', [reverse 1..20], 'acked');

        $res_obj = $tester->post_json_ok('/timelines/foobar/statuses.json',
                                         json_array(map {create_json_status($_, $_ % 2 ? 2 : -2)} 1..10),
                                         qr/^200$/, 'POST statuses to foobar OK');
        is_deeply($res_obj, {error => undef, count => 10}, 'POST statuses result OK');
        
        {
            my $exp_tl_test = {error => undef, unacked_counts => {
                test => { total => 10, 2 => 10 }
            }};
            my $exp_tl_foobar = {error => undef, unacked_counts => {
                foobar => { total => 10,  -2 => 5, 2 => 5 }
            }};
            foreach my $case (
                {label => "total, 1 TL", param => '?level=total&tl_test=0', exp => $exp_tl_test},
                {label => "no level, TL test right", param => '?tl_test=10&tl_foobar=5', exp => $exp_tl_foobar},
                {label => "level -2, TL foobar right", param => '?level=-2&tl_foobar=5&tl_test=5', exp => $exp_tl_test},
                {label => "level -2, TL test right", param => '?level=-2&tl_foobar=3&tl_test=0', exp => $exp_tl_foobar},
                {label => "level 2, TL foobar right", param => '?level=2&tl_test=0&tl_foobar=5', exp => $exp_tl_test},
                {label => "level 2, TL test right", param => '?level=2&tl_test=10&tl_foobar=12', exp => $exp_tl_foobar},
                {label => "level 3, TL test right", param => '?level=3&tl_test=0&tl_foobar=1', exp => $exp_tl_foobar},
                {label => "total, 1 TL 2 junk TLs", param => '?level=total&tl_junk=6&tl_hoge=0&tl_test=0', exp => $exp_tl_test},
            ) {
                $res_obj = $tester->get_json_ok("/updates/unacked_counts.json$case->{param}",
                                                qr/^200$/, "GET /updates/unacked_counts.json ($case->{label}) OK");
                is_deeply($res_obj, $case->{exp}, "GET /updates/unacked_counts.json ($case->{label}) results OK");
            }
        }
    };
}

{
    note('--- status filters, auto-generation of id and created_at');
    my $main = create_main();
    my $filter_executed = 0;
    $main->timeline("test")->add_filter(sub {
        my ($statuses) = @_;
        $_->{filtered} = "yes" foreach @$statuses;
        $filter_executed++;
        return $statuses;
    });
    test_psgi create_psgi_app($main), sub {
        my $tester = testlib::HTTP->new(requester => shift);
        my $res_obj = $tester->post_json_ok('/timelines/test/statuses.json',
                                            '[{"text":"one"},{"text":"two"},{"text":"three"}]',
                                            qr/^200$/, 'POST statuses OK');
        is_deeply $res_obj, {error => undef, count => 3}, "POST count OK";
        cmp_ok $filter_executed, ">", 0, "filter is executed";
        $res_obj = $tester->get_json_ok('/timelines/test/statuses.json', qr/^200$/, 'GET statuses OK');
        is $res_obj->{error}, undef, "GET succeed";
        my $statuses = $res_obj->{statuses};
        my %got_texts = ();
        foreach my $s (@$statuses) {
            $got_texts{$s->{text}}++;
            ok defined($s->{id}), "id is generated";
            ok defined($s->{created_at}), "created_at is generated";
            is $s->{filtered}, "yes", "filtered is marked";
        }
        is_deeply \%got_texts, {one => 1, two => 1, three => 1}, "status texts are OK. we don't care the order here";
    };
}

{
    note('--- -- various POST ack argument patterns');
    my $f = 'BusyBird::DateTime::Format';
    foreach my $case (test_cases_for_ack(is_ordered => 0), test_cases_for_ack(is_ordered => 1)) {
        note("--- POST ack case: $case->{label}");
        my $main = create_main();
        $main->timeline('test');
        test_psgi create_psgi_app($main), sub {
            my $tester = testlib::HTTP->new(requester => shift);
            my $already_acked_at = $f->format_datetime(
                DateTime->now(time_zone => 'UTC') - DateTime::Duration->new(days => 1)
            );
            my $input_statuses = [
                (map {status($_,0,$already_acked_at)} 1..10),
                (map {status($_)} 11..20)
            ];
            my $res_obj = $tester->post_json_ok('/timelines/test/statuses.json',
                                                encode_json($input_statuses), qr/^200$/, 'POST statuses OK');
            is_deeply($res_obj, {error => undef, count => 20}, "POST count OK");
            my $request_message = defined($case->{req}) ? encode_json($case->{req}) : undef;
            $res_obj = $tester->post_json_ok('/timelines/test/ack.json', $request_message, qr/^200$/, 'POST ack OK');
            is_deeply($res_obj, {error => undef, count => $case->{exp_count}}, "ack count is $case->{exp_count}");
            test_get_statuses($tester, 'test', 'ack_state=unacked&count=100', $case->{exp_unacked}, 'unacked statuses OK');
            test_get_statuses($tester, 'test', 'ack_state=acked&count=100', $case->{exp_acked}, 'acked statuses OK');
        };
    }
}

{
    my $main = create_main();
    $main->timeline('test');
    note('--- GET /updates/unacked_counts.json with no valid TL');
    test_psgi create_psgi_app($main), sub {
        my $tester = testlib::HTTP->new(requester => shift);
        foreach my $case (
            {label => "no params", param => ""},
            {label => "junk TLs and params", param => "?tl_hoge=10&tl_foo=1&bar=3&_=1020"}
        ) {
            my $res_obj = $tester->get_json_ok("/updates/unacked_counts.json$case->{param}",
                                               qr/^[45]/,
                                               "GET /updates/unacked_counts.json ($case->{label}) returns error");
            ok(defined($res_obj->{error}), ".. $case->{label}: error is set");
        }
    };
}

{
    my $main = create_main();
    $main->timeline('test');
    note('--- Not Found cases');
    test_psgi create_psgi_app($main), sub {
        my $tester = testlib::HTTP->new(requester => shift);
        foreach my $case (
            {endpoint => "GET /timelines/foobar/statuses.json"},
            {endpoint => "GET /timelines/foobar/updates/unacked_counts.json"},
            {endpoint => "POST /timelines/foobar/ack.json"},
            {endpoint => "POST /timelines/foobar/statuses.json", content => create_json_status(1)},
            {endpoint => "POST /timelines/test/statuses.json"},
            {endpoint => "POST /timelines/test/updates/unacked_counts.json"},
            {endpoint => "GET /timelines/test/ack.json"},
            {endpoint => "POST /updates/unacked_counts.json?tl_test=10"},
        ) {
            test_error_request($tester, $case->{endpoint}, $case->{content});
        }
    };
}

{
    foreach my $storage_case (
        {label => "dying", storage => create_dying_status_storage()},
        {label => "erroneous", storage => create_erroneous_status_storage()},
    ) {
        note("--- $storage_case->{label} status storage");
        my $main = create_main();
        $main->set_config(default_status_storage => $storage_case->{storage});
        $main->timeline('test');
        test_psgi create_psgi_app($main), sub {
            my $tester = testlib::HTTP->new(requester => shift);
            foreach my $case (
                {endpoint => "GET /timelines/test/statuses.json"},
                ## {endpoint => "GET /timelines/test/updates/unacked_counts.json"},
                {endpoint => "POST /timelines/test/ack.json"},
                {endpoint => "POST /timelines/test/statuses.json", content => create_json_status(1)},
                ## {endpoint => "GET /updates/unacked_counts.json?tl_test=3"}
            ) {
                my $label = "$storage_case->{label} $case->{endpoint}";
                my ($method, $path) = split(/ +/, $case->{endpoint});
                my $got = $tester->request_json_ok($method, $path, $case->{content}, qr/^[45]/, "$label: request OK");
                ok(defined($got->{error}), "$label: error message defined OK");
            }

            my $got = $tester->get_json_ok('/timelines/test/statuses.json?only_statuses=1', qr/^[45]/,
                                           "$storage_case->{label}: GET only_statuses HTTP error OK");
            is_deeply $got, [], "$storage_case->{label}: GET only_statuses returns an empty array OK";
        }
    }
}

{
    my $main = create_main();
    $main->timeline('test');
    note('--- status with weird ID');
    test_psgi create_psgi_app($main), sub {
        my $tester = testlib::HTTP->new(requester => shift);
        my $weird_id_status = {
            id => q{!"#$%&'(){}=*+>< []\\|/-_;^~@`?: 3},
            created_at => "Thu Jan 01 00:00:03 +0000 1970",
            text => q{変なIDのステータス。},
        };
        my $encoded_id = '%21%22%23%24%25%26%27%28%29%7B%7D%3D%2A%2B%3E%3C%20%5B%5D%5C%7C%2F-_%3B%5E~%40%60%3F%3A%203';
        my $res_obj = $tester->post_json_ok('/timelines/test/statuses.json',
                                            json_array(map { create_json_status($_) } 1,2,4,5),
                                            qr/^200$/, 'POST normal statuses OK');
        is_deeply($res_obj, {error => undef, count => 4}, "POST normal statuses results OK");
        $res_obj = $tester->post_json_ok('/timelines/test/statuses.json',
                                         encode_json($weird_id_status), qr/^200$/, 'POST weird status OK');
        is_deeply($res_obj, {error => undef, count => 1}, 'POST weird status OK');

        test_get_statuses($tester, 'test', "max_id=$encoded_id&count=10",
                          [$weird_id_status->{id}, 2, 1], 'max_id = weird ID');
        
        $res_obj = $tester->post_json_ok('/timelines/test/ack.json',
                                         encode_json({max_id => $weird_id_status->{id}}),
                                         qr/^200$/, 'POST ack max_id = weird ID OK');
        is_deeply($res_obj, {error => undef, count => 3}, "POST ack max_id = weird ID results OK");

        test_get_statuses($tester, 'test', 'ack_state=unacked', [5,4], "GET unacked");
        test_get_statuses($tester, 'test', 'ack_state=acked', [$weird_id_status->{id}, 2, 1], 'GET acked');
    };
}

{
    note('--- Unicode timeline name and status IDs');
    my $main = create_main();
    my $tl_name = "タイムライン 壱";
    my $tl_encoded = '%E3%82%BF%E3%82%A4%E3%83%A0%E3%83%A9%E3%82%A4%E3%83%B3%20%E5%A3%B1';
    my @post_statuses = map { status($_) } 0..4;
    my @ids = qw(零 壱 弐 参 四);
    my @ids_encoded = qw(%E9%9B%B6 %E5%A3%B1 %E5%BC%90 %E5%8F%82 %E5%9B%9B);
    foreach my $i (0 .. $#ids) {
        $post_statuses[$i]{id} = $ids[$i];
    }
    $main->timeline($tl_name);
    test_psgi create_psgi_app($main), sub {
        my $tester = testlib::HTTP->new(requester => shift);
        my $res_obj = $tester->post_json_ok(
            "/timelines/$tl_encoded/statuses.json",
            encode_json(\@post_statuses), qr/^200$/, "POST Unicode IDs to Unicode timeline OK"
        );
        is_deeply($res_obj, {error => undef, count => 5}, "POST statuses result OK") or diag(explain $res_obj);
        
        $res_obj = $tester->get_json_ok(
            "/timelines/$tl_encoded/statuses.json?count=10&max_id=$ids_encoded[2]",
            qr/^200$/, "GET max_id = Unicode ID OK"
        );
        is($res_obj->{error}, undef, "GET statuses succeed");
        test_status_id_list($res_obj->{statuses}, [reverse @ids[0,1,2]], "Unicode IDs OK");
        
        $res_obj = $tester->post_json_ok(
            "/timelines/$tl_encoded/ack.json",
            encode_json({ids => [qw(壱 参)]}), qr/^200$/, "POST ack.json Unicode ids OK"
        );
        is_deeply($res_obj, {error => undef, count => 2}, "POST ack.json ids results OK");
        $res_obj = $tester->get_json_ok(
            "/timelines/$tl_encoded/statuses.json?count=10&ack_state=unacked",
            qr/^200$/, "GET unacked statuses OK"
        );
        is($res_obj->{error}, undef, "GET unacked statuses succeed");
        test_status_id_list($res_obj->{statuses}, [reverse @ids[0,2,4]], "unacked statuse ID OK");

        $res_obj = $tester->get_json_ok(
            "/updates/unacked_counts.json?level=total&tl_${tl_encoded}=0",
            qr/^200$/, "GET updates unacked_counts OK"
        );
        is_deeply($res_obj,
                  {error => undef, unacked_counts => { $tl_name => { total => 3, 0 => 3 } }},
                  "GET updates unacked_counts results OK");

        $res_obj = $tester->post_json_ok(
            "/timelines/$tl_encoded/ack.json",
            encode_json({max_id => qw(四)}), qr/^200$/, "POST ack.json Unicode max_id OK"
        );
        is_deeply($res_obj, {error => undef, count => 3}, "3 statuses acked OK");
        $res_obj = $tester->get_json_ok(
            "/timelines/$tl_encoded/statuses.json?count=10&ack_state=acked",
            qr/^200$/, "GET acked statuses OK"
        );
        is($res_obj->{error}, undef, "GET acked statuses succeed");
        test_list_choice(
            [map { $_->{id} } @{$res_obj->{statuses}}],
            [ [reverse @ids], [map { $ids[$_] } (4,2,0,3,1)] ],
            "acked statuse IDs OK. The order depends on the times when the test actually acked the statuses"
        );
    };
}

{
    note('--- /updates/unacked_counts.json: strange timeline names');
    my $main = create_main();
    my %assumed_counts = (
        'contains space ' => {request_name => 'tl_contains+space+', counts => 5},
        ' contains space 2' => {request_name => 'tl_%20contains%20space%202', counts => 8},
        'tl_tl_tl_' => {request_name => 'tl_tl_tl_tl_', counts => 3},
        '&?&' => {request_name => 'tl_%26%3F%26', counts => 2},
        'たいむらいん' => {request_name => 'tl_%E3%81%9F%E3%81%84%E3%82%80%E3%82%89%E3%81%84%E3%82%93', counts => 10},
    );
    my $all_done = sub {
        my ($counts_ref) = @_;
        foreach my $counts (values %$counts_ref) {
            return 0 if $counts->{counts} != 0;
        }
        return 1;
    };
    $main->timeline($_) foreach keys %assumed_counts;
    test_psgi create_psgi_app($main), sub {
        my $tester = testlib::HTTP->new(requester => shift);
        my $loop_count = 0;
        while(!$all_done->(\%assumed_counts)) {
            if($loop_count > scalar(keys %assumed_counts)) {
                fail("/updates/unacked_counts.json is called $loop_count times and still all timeline assumptions are not done. something is wrong.");
                last;
            }
            my $query = join('&', 'level=total', map { "$_->{request_name}=$_->{counts}" } values %assumed_counts);
            my $res = $tester->get_json_ok(
                "/updates/unacked_counts.json?$query",
                qr/^200$/, "GET updates unacked_counts OK"
            );
            is($res->{error}, undef, "error should be undef");
            is(ref($res->{unacked_counts}), "HASH", "unacked_counts should be a hash-ref");
            foreach my $timeline (keys %{$res->{unacked_counts}}) {
                $assumed_counts{$timeline}{counts} = $res->{unacked_counts}{$timeline}{total};
            }
            $loop_count++;
        }
    };
}

{
    note('--- hidden timelines are accessible');
    my $main = create_main();
    $main->timeline("hidden")->set_config(hidden => 1);
    test_psgi create_psgi_app($main), sub {
        my $tester = testlib::HTTP->new(requester => shift);
        my $res_obj = $tester->post_json_ok('/timelines/hidden/statuses.json',
                                            create_json_status(1), qr/^200$/, 'POST statuses to hidden OK');
        is_deeply($res_obj, {error => undef, count => 1}, "POST statuses response OK");
        $res_obj = $tester->get_json_ok('/timelines/hidden/statuses.json',
                                        qr/^200$/, 'GET statuses from hidden OK');
        is $res_obj->{error}, undef, "GET statuses no error OK";
    };
}

{
    note('--- For examples');
    my $main = create_main();
    $main->timeline("home");
    my @cases = (
        {endpoint => 'POST /timelines/home/statuses.json',
         content => <<EOD,
[
  {
    "id": "http://example.com/page/2013/0204",
    "created_at": "Mon Feb 04 11:02:45 +0900 2013",
    "text": "content of the status",
    "busybird": { "level": 3 }
  },
  {
    "id": "http://example.com/page/2013/0202",
    "created_at": "Sat Feb 02 17:38:12 +0900 2013",
    "text": "another content"
  }
]
EOD
         exp_response => q{{"error": null, "count": 2}}},
        {endpoint => 'GET /timelines/home/statuses.json?count=1&ack_state=any&max_id=http://example.com/page/2013/0202',
         exp_response => <<EOD},
{
  "error": null,
  "statuses": [
    {
      "id": "http://example.com/page/2013/0202",
      "created_at": "Sat Feb 02 17:38:12 +0900 2013",
      "text": "another content"
    }
  ]
}
EOD
        {endpoint => 'GET /timelines/home/statuses.json?count=1&ack_state=any&max_id=http://example.com/page/2013/0202&only_statuses=1',
         exp_response => <<EOD},
[
    {
      "id": "http://example.com/page/2013/0202",
      "created_at": "Sat Feb 02 17:38:12 +0900 2013",
      "text": "another content"
    }
]
EOD
        {endpoint => 'GET /timelines/home/updates/unacked_counts.json?total=2&0=2',
         exp_response => <<EOD},
{
  "error": null,
  "unacked_counts": {
    "total": 2,
    "0": 1,
    "3": 1
  }
}
EOD
        {endpoint => 'GET /updates/unacked_counts.json?level=total&tl_home=0&tl_foobar=0',
         exp_response => <<EOD},
{
  "error": null,
  "unacked_counts": {
    "home": {
      "total": 2,
      "0": 1,
      "3": 1
    }
  }
}
EOD
        {endpoint => 'POST /timelines/home/ack.json',
         content => <<EOD,
{
  "max_id": "http://example.com/page/2013/0202",
  "ids": [
    "http://example.com/page/2013/0204"
   ]
}
EOD
         exp_response => q{{"error": null, "count": 2}}}
    );
    test_psgi create_psgi_app($main), sub {
        my $tester = testlib::HTTP->new(requester => shift);
        foreach my $case (@cases) {
            my ($method, $request_url) = split(/ +/, $case->{endpoint});
            my $res_obj = $tester->request_json_ok($method, $request_url, $case->{content},
                                                   qr/^200$/, "$case->{endpoint} OK");
            my $exp_obj = decode_json($case->{exp_response});
            is_deeply($res_obj, $exp_obj, "$case->{endpoint} response OK") or diag(explain $res_obj);
        }
    };
}

done_testing();

