use strict;
use warnings;
use Test::More;
use Test::Builder;
use BusyBird::Main;
use BusyBird::Log;
use BusyBird::StatusStorage::SQLite;
use JSON qw(decode_json);
use utf8;
use Encode qw(encode_utf8);
use lib "t";
use testlib::HTTP;
use testlib::Main_Util;
use testlib::CrazyStatus qw(crazy_statuses);

BEGIN {
    use_ok("BusyBird::Main::PSGI::View");
}

$BusyBird::Log::Logger = undef;

sub test_psgi_response {
    my ($psgi_res, $exp_code, $label) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is(ref($psgi_res), "ARRAY", "$label: top array-ref OK");
    is($psgi_res->[0], $exp_code, "$label: status code OK");
    is(ref($psgi_res->[1]), "ARRAY", "$label: header array-ref OK");
    is(ref($psgi_res->[2]), "ARRAY", "$label: content array-ref OK");
}

sub test_json_response {
    my ($psgi_res, $exp_code, $exp_obj, $label) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    test_psgi_response($psgi_res, $exp_code, $label);
    my $got_obj = decode_json(join("", @{$psgi_res->[2]}));
    is_deeply($got_obj, $exp_obj, "$label: json object OK");
}

sub create_main {
    my $main = testlib::Main_Util::create_main();
    $main->timeline('test');
    return $main;
}

{
    note("--- response methods");
    my $main = create_main();
    my $view = new_ok("BusyBird::Main::PSGI::View", [main_obj => $main, script_name => ""]);

    test_psgi_response($view->response_notfound(), 404, "notfound");
    
    test_json_response($view->response_json(200, {}),
                       200, {error => undef}, "json, 200, empty hash");
    test_json_response($view->response_json(200, [0,1,2]),
                       200, [0,1,2], "json, 200, array");
    test_json_response($view->response_json(400, {}),
                       400, {}, "json, 400, empty hash");
    test_json_response($view->response_json(500, {error => "something bad happened"}),
                       500, {error => "something bad happened"}, "json, 500, error set");
    test_json_response($view->response_json(200, {main => $main}),
                       500, {error => "error while encoding to JSON."}, "json, 500, unable to encode");

    test_psgi_response($view->response_statuses(statuses => [], http_code => 200, format => "html", timeline_name => "test"),
                       200, "statuses success");
    test_psgi_response($view->response_statuses(error => "hoge", http_code => 400, format => "html", timeline_name => "test"),
                       400, "statuses failure");
    test_psgi_response($view->response_statuses(statuses => [], http_code => 200, format => "foobar", timeline_name => "test"),
                       400, "statuses unknown format");

    test_psgi_response($view->response_timeline("test", ""), 200, "existent timeline");
    test_psgi_response($view->response_timeline("hoge", ""), 404, "missing timeline");
}

{
    note("--- response_error_html");
    my $main = create_main();
    my $view = new_ok("BusyBird::Main::PSGI::View", [main_obj => $main, script_name => ""]);
    foreach my $case (
        {in_code => 400, in_message => "bad request, man", exp_message => qr/bad request, man/},
        {in_code => 404, in_message => "no such page", exp_message => qr/no such page/},
        {in_code => 500, in_message => "fatal error", exp_message => qr/fatal error/},
    ) {
        my $res = $view->response_error_html($case->{in_code}, $case->{in_message});
        test_psgi_response($res, $case->{in_code}, "case: $case->{in_message} HTTP code OK");
        like(join("", @{$res->[2]}), $case->{exp_message}, "case: $case->{in_message} message OK");
    }
}

{
    note("--- response_statuses should not croak even if crazy statuses are given");
    my $main = create_main();
    my $view = BusyBird::Main::PSGI::View->new(main_obj => $main, script_name => "");
    my @logs = ();
    local $BusyBird::Log::Logger = sub {
        push @logs, \@_;
    };
    foreach my $s (crazy_statuses()) {
        @logs = ();
        my $ret = $view->response_statuses(statuses => [$s], http_code => 200, format => 'html', timeline_name => 'test');
        test_psgi_response($ret, 200, "$s->{id}");
        is(scalar(grep { $_->[0] =~ /^(err|warn|crit|alert|fatal)/i } @logs), 0, "$s->{id}: no warning or error") or do {
            diag(join "", map { "$_->[0]: $_->[1]\n" } @logs);
        };
        ## my $content = join "", @{$ret->[2]};
        ## note("============\n$content");
    }
}

{
    note("--- template_functions");
    my $main = create_main();
    my $view = BusyBird::Main::PSGI::View->new(main_obj => $main, script_name => "/apptop");
    my $funcs = $view->template_functions();

    note("--- -- js"); ## from SYNOPSIS of JavaScript::Value::Escape with a small modification
    is($funcs->{js}->(q{&foo"bar'</script>}), "\\u0026foo\\u0022bar\\u0027\\u003c/script\\u003e", "js filter OK");

    note("--- -- link");
    foreach my $case (
        {label => "escape text", args => ['<hoge>', href => 'http://example.com/'],
         exp => '<a href="http://example.com/">&lt;hoge&gt;</a>'},
        {label => "external href", args => ['foo & bar', href => 'https://www.google.co.jp/search?channel=fs&q=%E3%81%BB%E3%81%92&ie=utf-8&hl=ja#112'],
         exp => '<a href="https://www.google.co.jp/search?channel=fs&q=%E3%81%BB%E3%81%92&ie=utf-8&hl=ja#112">foo &amp; bar</a>'},
        {label => "internal absolute href",
         args => ['hoge', href => '/timelines/hoge/statuses.html?count=10&max_id=http%3A%2F%2Fhoge.com%2F%3Fid%3D31245%26cat%3Dfoo'],
         exp => '<a href="/timelines/hoge/statuses.html?count=10&max_id=http%3A%2F%2Fhoge.com%2F%3Fid%3D31245%26cat%3Dfoo">hoge</a>'},
        {label => "with target and class", args => ['ほげ', href => '/', target => '_blank', class => 'link important'],
         exp => '<a href="/" target="_blank" class="link important">ほげ</a>'},
        {label => "no href", args => ['no link', class => "hogeclass"],
         exp => 'no link'},
        {label => "javascript: href", args => ['alert!', href => 'javascript: alert("hogehoge"); return false;'],
         exp => 'alert!'},
        {label => "empty text", args => ['', href => 'http://empty.net/'],
         exp => '<a href="http://empty.net/"></a>'},
        {label => "undef text", args => [undef], exp => ""},
    ) {
        is($funcs->{link}->(@{$case->{args}}), $case->{exp}, "$case->{label} OK");
    }

    note("--- -- image");
    foreach my $case (
        {label => "external http", args => [src => "http://www.hoge.com/images.php?id=101&size=large"],
         exp => '<img src="http://www.hoge.com/images.php?id=101&size=large" />'},
        {label => "external https", args => [src => "https://example.co.jp/favicon.ico"],
         exp => '<img src="https://example.co.jp/favicon.ico" />'},
        {label => "internal absolute", args => [src => "/static/hoge.png"],
         exp => '<img src="/static/hoge.png" />'},
        {label => "with width, height and class",
         args => [src => '/foobar.jpg', width => "400", height => "300", class => "foo bar"],
         exp => '<img src="/foobar.jpg" width="400" height="300" class="foo bar" />'},
        {label => "no src", args => [], exp => ''},
        {label => "script", args => [src => '<script>alert("hoge");</script>'],
         exp => ''},
        {label => "data:",
         args => [src => 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAAAXNSR0IArs4c6QAAAAxJREFUCNdjuKCgAAAC1AERHXzACQAAAABJRU5ErkJggg=='],
         exp => ''},
        {label => "javascript:", args => [src => 'javascript: alert("hoge");'],
         exp => ''},
    ) {
        is($funcs->{image}->(@{$case->{args}}), $case->{exp}, "$case->{label} OK");
    }

    note("--- -- path");
    foreach my $case (
        {arg => "relative/foo.png", exp => "relative/foo.png"},
        {arg => "/absolute/foo.png", exp => "/apptop/absolute/foo.png"},
        {arg => "", exp => ""},
        {arg => "/", exp => "/apptop/"},
    ) {
        is($funcs->{path}->($case->{arg}), $case->{exp}, "$case->{arg}: OK");
    }

    is($funcs->{script_name}->(), "/apptop", "script_name() function OK");

    note("--- -- link to image");
    foreach my $case (
        {label => "valid url", url => 'http://hoge.com/img.png',
         exp => '<a href="http://hoge.com/img.png"><img src="http://hoge.com/img.png" /></a>'},
        {label => "invalid url", url => 'javascript: return false;',
         exp => ''}
    ) {
        is($funcs->{link}($funcs->{image}(src => $case->{url}), href => $case->{url}), $case->{exp}, "$case->{label}: OK");
    }

    note("--- -- bb_level");
    foreach my $case (
        {label => "positive level", args => [10], exp => "10"},
        {label => "zero", args => [0], exp => "0"},
        {label => "negative level", args => [-5], exp => "-5"},
        {label => "undef", args => [undef], exp => "0"},
    ) {
        is($funcs->{bb_level}->(@{$case->{args}}), $case->{exp}, "$case->{label} OK");
    }
}

{
    note("--- template_functions_for_timeline");
    my $main = create_main();
    my $view = BusyBird::Main::PSGI::View->new(main_obj => $main, script_name => "");
    my $funcs = $view->template_functions_for_timeline('test');
    $main->set_config(
        time_zone => "UTC",
        time_format => '%Y-%m-%d %H:%M:%S',
        time_locale => 'en_US',
    );

    note("--- -- bb_timestamp");
    foreach my $case (
        {label => 'normal', args => ['Tue May 28 20:10:13 +0900 2013'], exp => '2013-05-28 11:10:13'},
        {label => 'undef', args => [undef], exp => ''},
        {label => 'empty string', args => [''], exp => ''},
    ) {
        is($funcs->{bb_timestamp}->(@{$case->{args}}), $case->{exp}, "$case->{label}: OK");
    }

    note("--- -- bb_status_permalink");
    foreach my $case (
        {label => "complete status",
         args => [{id => "191", user => {screen_name => "hoge"}, busybird => {status_permalink => "http://hoge.com/"}}],
         exp => "http://hoge.com/"},
        {label => "missing status_permalink field",
         args => [{id => "191", user => {screen_name => "hoge"}}],
         exp => "https://twitter.com/hoge/status/191"},
        {label => "unable to build", args => [{id => "191"}], exp => ""},
        {label => "invalid status_permalink",
         args => [{id => "191", busybird => {status_permalink => "javascript: alert('hoge')"}}],
         exp => ""},
        {label => "non-integral status ID",
         args => [{id => 'busybird://110131', user => {screen_name => "foobar"}, text => "HOGE HOGE"}],
         exp => ""},
        {label => "original ID",
         args => [{id => "converted ID", user => {screen_name => '_hoge_'}, busybird => {original => {id => '119302'}}}],
         exp => 'https://twitter.com/_hoge_/status/119302'}
    ) {
        is($funcs->{bb_status_permalink}->(@{$case->{args}}), $case->{exp}, "$case->{label}: OK");
    }

    note("--- -- bb_text");
    foreach my $case (
        {label => "HTML special char, no URL, no entity",
         args => [{text => q{foo bar "A & B"} }],
         exp => q{foo bar &quot;A &amp; B&quot;}},
        
        {label => "URL and HTML special char, no entity",
         args => [{id => "hoge", text => 'this contains URL http://hogehoge.com/?a=foo+bar&b=%2Fhoge here :->'}],
         exp => q{this contains URL <a href="http://hogehoge.com/?a=foo+bar&b=%2Fhoge" target="_blank">http://hogehoge.com/?a=foo+bar&amp;b=%2Fhoge</a> here :-&gt;}},
        
        {label => "URL at the top and bottom",
         args => [{text => q{http://hoge.com/toc.html#item5 hogehoge http://foobar.co.jp/q=hoge&page=5}}],
         exp => q{<a href="http://hoge.com/toc.html#item5" target="_blank">http://hoge.com/toc.html#item5</a> hogehoge <a href="http://foobar.co.jp/q=hoge&page=5" target="_blank">http://foobar.co.jp/q=hoge&amp;page=5</a>}},
        
        {label => "Twitter Entities",
         args => [{
             text => q{てすと &lt;"&amp;hearts;&amp;&amp;hearts;"&gt; http://t.co/dNlPhACDcS &gt;"&lt; @debug_ito &amp; &amp; &amp; #test},
             entities => {
                 hashtags => [ { text => "test", indices => [106,111] } ],
                 user_mentions => [ {
                     "name" => "Toshio Ito",
                     "id" => 797588971,
                     "id_str" => "797588971",
                     "indices" => [ 77, 87 ],
                     "screen_name" => "debug_ito"
                 } ],
                 symbols => [],
                 urls => [ {
                     "display_url" => "google.co.jp",
                     "expanded_url" => "http://www.google.co.jp/",
                     "url" => "http://t.co/dNlPhACDcS",
                     "indices" => [ 44, 66 ]
                 } ]
             }
         }],
         exp => q{てすと &amp;lt;&quot;&amp;amp;hearts;&amp;amp;&amp;amp;hearts;&quot;&amp;gt; <a href="http://t.co/dNlPhACDcS" target="_blank">google.co.jp</a> &amp;gt;&quot;&amp;lt; <a href="https://twitter.com/debug_ito" target="_blank">@debug_ito</a> &amp;amp; &amp;amp; &amp;amp; <a href="https://twitter.com/search?q=%23test&src=hash" target="_blank">#test</a>}},

        {label => "2 urls entities",
         args => [{
             text => q{http://t.co/0u6Ki0bOYQ - plain,  http://t.co/0u6Ki0bOYQ - with scheme},
             entities => {
                 "hashtags" => [],
                 "user_mentions" => [],
                 "symbols" => [],
                 "urls" => [
                     {
                         "display_url" => "office.com",
                         "expanded_url" => "http://office.com",
                         "url" => "http://t.co/0u6Ki0bOYQ",
                         "indices" => [ 0, 22 ]
                     },
                     {
                         "display_url" => "office.com",
                         "expanded_url" => "http://office.com",
                         "url" => "http://t.co/0u6Ki0bOYQ",
                         "indices" => [ 33, 55 ]
                     }
                 ]
             }
         }],
         exp => q{<a href="http://t.co/0u6Ki0bOYQ" target="_blank">office.com</a> - plain,  <a href="http://t.co/0u6Ki0bOYQ" target="_blank">office.com</a> - with scheme}},

        {label => "Unicode hashtags and media entities",
         args => [{
             text => q{ドコモ「docomo Wi-Fi」、南海/阪急/JR 九州でサービス エリア拡大 http://t.co/mvgqG5v3mQ #南海 #阪急 #JR九州 http://t.co/U3h7lEDZKT},
             entities => {
                 "hashtags" => [
                     { "text" => "南海", "indices" => [64, 67] },
                     { "text" => "阪急", "indices" => [68, 71] },
                     { "text" => "JR九州", "indices" => [72, 77] }
                 ],
                 "user_mentions" => [],
                 "media" => [
                     {
                         "display_url" => "pic.twitter.com/U3h7lEDZKT",
                         "id_str" => "340966457888370689",
                         "sizes" => {
                             "small" => { "w" => 340, "resize" => "fit", "h" => 83 },
                             "large" => { "w" => 389, "resize" => "fit", "h" => 95 },
                             "medium" => { "w" => 389, "resize" => "fit", "h" => 95 },
                             "thumb" => { "w" => 150, "resize" => "crop", "h" => 95 }
                         },
                         "expanded_url" => "http://twitter.com/jic_news/status/340966457884176384/photo/1",
                         "media_url_https" => "https://pbs.twimg.com/media/BLtbL9rCcAEfjCr.jpg",
                         "url" => "http://t.co/U3h7lEDZKT",
                         "indices" => [78,100],
                         "type" => "photo",
                         "id" => 340966457888370689,
                         "media_url" => "http://pbs.twimg.com/media/BLtbL9rCcAEfjCr.jpg"
                     }
                 ],
                 "symbols" => [],
                 "urls" => [
                     {
                         "display_url" => "bit.ly/14jappE",
                         "expanded_url" => "http://bit.ly/14jappE",
                         "url" => "http://t.co/mvgqG5v3mQ",
                         "indices" => [41,63]
                     }
                 ]
             }
         }],
         exp => q{ドコモ「docomo Wi-Fi」、南海/阪急/JR 九州でサービス エリア拡大 <a href="http://t.co/mvgqG5v3mQ" target="_blank">bit.ly/14jappE</a> <a href="https://twitter.com/search?q=%23%E5%8D%97%E6%B5%B7&src=hash" target="_blank">#南海</a> <a href="https://twitter.com/search?q=%23%E9%98%AA%E6%80%A5&src=hash" target="_blank">#阪急</a> <a href="https://twitter.com/search?q=%23JR%E4%B9%9D%E5%B7%9E&src=hash" target="_blank">#JR九州</a> <a href="http://t.co/U3h7lEDZKT" target="_blank">pic.twitter.com/U3h7lEDZKT</a>}}
    ) {
        is($funcs->{bb_text}->(@{$case->{args}}), $case->{exp}, "$case->{label}: OK");
    }

    note("-- bb_attached_image_urls");
    foreach my $case (
        {label => "no entities at all", args => [{text => "hogehoge"}], exp => []},
        {label => "media entities",
         args => [{
             text => "foobar",
             entities => { media => [
                 { media_url => "http://example.com/media1.png" },
                 { media_url => "http://example.com/media2.png" }
             ] }
         }],
         exp => ["http://example.com/media1.png", "http://example.com/media2.png"]},
        {label => "mixed entities and extended_entities. URLs in entities are rendered first.",
         args => [{
             text => "FOO",
             entities => { media => [
                 {media_url => "http://example.com/media1.png"},
                 {media_url => "http://example.com/media2.png"},
             ] },
             extended_entities => { media => [
                 {media_url => "http://example.com/media3.png"},
                 {media_url => "http://example.com/media2.png"},
                 {media_url => "http://example.com/media1.png"},
             ] }
         }],
         exp => [map { "http://example.com/media$_.png" } (1, 2, 3)]},
        {label => "invalid input for media URLs",
         args => [{
             text => "hoge",
             entities => { media => [
                 {media_url => "javascript: alert('boom!')"},
                 {media_url => 100},
                 {},
                 {media_url => 'http://this.is.ok.com/hoge.png'}
             ] }
         }],
         exp => ["http://this.is.ok.com/hoge.png"]},
        {label => "media entity with type = video",
         args => [{
             text => "hoge",
             entities => { media => [
                 { type => "video", media_url => "http://hoge.com/video.ogg" },
                 { type => "photo", media_url => "http://hoge.com/photo.jpg" },
                 {                  media_url => "http://hoge.com/no_type.png" },
             ] }
         }],
         exp => ["http://hoge.com/photo.jpg", "http://hoge.com/no_type.png"]},
    ) {
        is_deeply $funcs->{bb_attached_image_urls}(@{$case->{args}}), $case->{exp}, "$case->{label}: OK";
    }
}

{
    note("--- tests for response_timeline_list");
    my $main = create_main();
    my $EXP_PAGER_ENTRY_MAX = 7;
    $main->set_config(timeline_list_pager_entry_max => $EXP_PAGER_ENTRY_MAX);
    my $view = BusyBird::Main::PSGI::View->new(main_obj => $main, script_name => "/apptop");
    foreach my $case (
        {
            label => "single page",
            input => {total_page_num => 1, cur_page => 0, timeline_unacked_counts => [
                {name => 'home', counts => {total => 5, 0 => 5}}
            ]},
            exp_timelines => [
                {link => "/apptop/timelines/home/", name => "home"}
            ]
        },
        {
            label => "multiple pages (moderate number)",
            input => {total_page_num => 5, cur_page => 3, timeline_unacked_counts => [
                {name => 'test', counts => {total => 0}}
            ]},
            exp_timelines => [
                {link => "/apptop/timelines/test/", name => "test"}
            ],
            exp_shown_pages => [0,1,2,3,4],
            exp_prev_page => 2, exp_next_page => 4,
        },
        {
            label => "multiple pages (large number, front)",
            input => {total_page_num => 50, cur_page => 2, timeline_unacked_counts => [
                {name => 'test', counts => {total => 0}}
            ]},
            exp_timelines => [ {link => "/apptop/timelines/test/", name => "test"} ],
            exp_shown_pages => [0 .. ($EXP_PAGER_ENTRY_MAX-1)],
            exp_prev_page => 1, exp_next_page => 3,
        },
        {
            label => "multiple pages (large number, middle)",
            input => {total_page_num => 50, cur_page => 20, timeline_unacked_counts => [
                {name => 'test', counts => {total => 0}}
            ]},
            exp_timelines => [ {link => "/apptop/timelines/test/", name => "test"} ],
            exp_shown_pages => [(20 - ($EXP_PAGER_ENTRY_MAX-1)/2) .. (20 + ($EXP_PAGER_ENTRY_MAX-1)/2)],
            exp_prev_page => 19, exp_next_page => 21
        },
        {
            label => "multiple pages (large number, back)",
            input => {total_page_num => 50, cur_page => 48, timeline_unacked_counts => [
                {name => 'test', counts => {total => 0}}
            ]},
            exp_timelines => [ {link => "/apptop/timelines/test/", name => "test"} ],
            exp_shown_pages => [(50 - $EXP_PAGER_ENTRY_MAX) .. 49],
            exp_prev_page => 47, exp_next_page => 49
        },
        {
            label => 'top page',
            input => {total_page_num => 2, cur_page => 0, timeline_unacked_counts => [
                {name => 'hoge', counts => {total => 0}}
            ]},
            exp_timelines => [ {link => '/apptop/timelines/hoge/', name => "hoge"} ],
            exp_shown_pages => [0, 1],
            exp_prev_page => undef, exp_next_page => 1
        },
        {
            label => 'bottom page',
            input => {total_page_num => 2, cur_page => 1, timeline_unacked_counts => [
                {name => 'hoge', counts => {total => 0}}
            ]},
            exp_timelines => [ {link => '/apptop/timelines/hoge/', name => "hoge"} ],
            exp_shown_pages => [0, 1],
            exp_prev_page => 0, exp_next_page => undef
        }
    ) {
        note("--- -- case: $case->{label}");
        my $exp_pager_num = ($case->{input}{total_page_num} > 1 ? 2 : 0);
        my $psgi_response = $view->response_timeline_list(%{$case->{input}});
        test_psgi_response($psgi_response, 200, "PSGI response OK");
        my $tree = testlib::HTTP->parse_html(join "", @{$psgi_response->[2]});
        
        my @pager_nodes = $tree->findnodes('//ul[@class="bb-timeline-page-list pagination"]');
        is(scalar(@pager_nodes), $exp_pager_num, "$exp_pager_num pager objects should exist");
        foreach my $pager_index (0 .. ($exp_pager_num - 1)) {
            my $pager_node = $pager_nodes[$pager_index];
            my $exp_prev_link = defined($case->{exp_prev_page}) ? "/apptop/?page=$case->{exp_prev_page}" : "#";
            my $exp_next_link = defined($case->{exp_next_page}) ? "/apptop/?page=$case->{exp_next_page}" : "#";
            my (@a_nodes) = $pager_node->findnodes('.//a');
            is(scalar(@a_nodes), @{$case->{exp_shown_pages}} + 4, "pager $pager_index: num of links OK");
            is($a_nodes[0]->attr('href'), '/apptop/?page=0', "pager $pager_index: link to top OK");
            is($a_nodes[1]->attr('href'), $exp_prev_link, "pager $pager_index: link to prev OK");
            is($a_nodes[-1]->attr('href'), '/apptop/?page=' . ($case->{input}{total_page_num}-1), "pager $pager_index: link to bottom OK");
            is($a_nodes[-2]->attr('href'), $exp_next_link, "pager $pager_index: link to next OK");
            is_deeply(
                [map { $_->attr('href') } @a_nodes[2 .. (@a_nodes - 3)]], [map { "/apptop/?page=$_" } @{$case->{exp_shown_pages}}],
                "pager $pager_index: links to pages OK"
            );
        }
        
        my ($timeline_list_table) = $tree->findnodes('//table[@id="bb-timeline-list"]');
        isnt($timeline_list_table, undef, "timeline list table exists");
        my @timeline_rows = $timeline_list_table->findnodes('.//tbody/tr');
        my $exp_timeline_num = @{$case->{exp_timelines}};
        is(scalar(@timeline_rows), $exp_timeline_num, "$exp_timeline_num timeline rows.");
        foreach my $i (0 .. ($exp_timeline_num - 1)) {
            my $row = $timeline_rows[$i];
            my $exp_timeline = $case->{exp_timelines}[$i];
            my $href = $row->findvalue('.//a/@href');
            is($href, $exp_timeline->{link}, "link should be $exp_timeline->{link}");
            my ($name_node) = $row->findnodes('.//span[@class="bb-timeline-name"]');
            my $got_name = join "", $name_node->content_list;
            is($got_name, $exp_timeline->{name}, "name should be $exp_timeline->{name}");
        }
    }
}

{
    note("--- response_timeline_list: timelines with names containing HTML special chars, URL special chars and Unicode chars.");
    my $main = create_main();
    my $view = BusyBird::Main::PSGI::View->new(main_obj => $main, script_name => "/myapp");
    my @counts = (
        {name => '   ', counts => {total => 0},
         exp_display_name => "   ", exp_link => '/myapp/timelines/%20%20%20/'},
        {name => q{"<'&'>"}, counts => {total => 0},
         exp_display_name => q{&quot;&lt;&#39;&amp;&#39;&gt;&quot;},
         exp_link => '/myapp/timelines/%22%3C%27%26%27%3E%22/'},
        {name => 'タイムライン', counts => {total => 0},
         exp_display_name => encode_utf8('タイムライン'),
         exp_link => '/myapp/timelines/%E3%82%BF%E3%82%A4%E3%83%A0%E3%83%A9%E3%82%A4%E3%83%B3/'},
        {name => '#?=&=?#', counts => {total => 0},
         exp_display_name => '#?=&amp;=?#',
         exp_link => '/myapp/timelines/%23%3F%3D%26%3D%3F%23/'},
    );
    my $psgi_response = $view->response_timeline_list(
        timeline_unacked_counts => [map { +{name => $_->{name}, counts => $_->{counts}} } @counts],
        total_page_num => 1,
        cur_page => 0
    );
    test_psgi_response($psgi_response, 200, "response OK");
    my $tree = testlib::HTTP->parse_html(join "", @{$psgi_response->[2]});
    my @timeline_rows = $tree->findnodes('//table[@id="bb-timeline-list"]/tbody/tr');
    is(scalar(@timeline_rows), scalar(@counts), "timeline row num OK");
    foreach my $i (0 .. $#timeline_rows) {
        my $timeline_row = $timeline_rows[$i];
        my $exp_count = $counts[$i];
        my ($a_tag) = $timeline_row->findnodes('.//a');
        is($a_tag->attr('href'), $exp_count->{exp_link}, "row $i: link OK");
        my ($name_tag) = $timeline_row->findnodes('.//span[@class="bb-timeline-name"]');
        my ($got_name) = $name_tag->content_list;
        is($got_name, $exp_count->{exp_display_name}, "row $i: displayed timeline name OK");
    }
}



done_testing();

