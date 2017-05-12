use strict;
use warnings;
use Test::More;
use JSON;
use utf8;
use lib "t";
use testlib::CrazyStatus qw(crazy_statuses);

BEGIN {
    use_ok('BusyBird::Filter::Twitter', qw(:transform :filter));
}

{
    note('--- basic transforms and filters');
    my $default_apiurl = "https://api.twitter.com/1.1/";
    foreach my $case (
        {
            name => "status_id",
            input_json => q{{"id": 10, "in_reply_to_status_id": 55}},
            exp =>{
                id => "${default_apiurl}statuses/show/10.json",
                in_reply_to_status_id => "${default_apiurl}statuses/show/55.json",
                busybird => { original => {
                    id => 10, in_reply_to_status_id => 55
                } }
            }
        },
        {
            name => "search_status",
            input_json => <<'INPUT',
{"id": 10, "from_user_id": 88, "from_user": "hoge", "created_at": "Thu, 06 Oct 2011 19:36:17 +0000"}
INPUT
            exp => {
                id => 10, user => {
                    id => 88,
                    screen_name => "hoge"
                },
                created_at => 'Thu Oct 06 19:36:17 +0000 2011'
            },
        },
        {
            name => "all",
            input_json => <<'INPUT',
{
    "id": 5, "id_str": "5", "created_at": "Wed, 05 Dec 2012 14:09:11 +0000",
    "in_reply_to_status_id": 12, "in_reply_to_status_id_str": "12",
    "from_user": "foobar",
    "from_user_id": 100,
    "from_user_id_str": "100",
    "true_flag": true,
    "false_flag": false,
    "null_value": null
}
INPUT
            exp => {
                id => "${default_apiurl}statuses/show/5.json", id_str => "${default_apiurl}statuses/show/5.json",
                in_reply_to_status_id => "${default_apiurl}statuses/show/12.json",
                in_reply_to_status_id_str => "${default_apiurl}statuses/show/12.json",
                created_at => "Wed Dec 05 14:09:11 +0000 2012",
                true_flag => JSON::true,
                false_flag => JSON::false,
                null_value => undef,
                user => {
                    screen_name => "foobar",
                    id => 100,
                    id_str => "100"
                },
                busybird => {
                    original => {
                        id => 5,
                        id_str => "5",
                        in_reply_to_status_id => 12,
                        in_reply_to_status_id_str => "12",
                    }
                }
            },
        }
    ) {
        no strict "refs";
        my $trans_func = "trans_twitter_$case->{name}";
        is_deeply($trans_func->(decode_json($case->{input_json})), $case->{exp}, "$trans_func OK");
        my $filter_func = "filter_twitter_$case->{name}";
        is_deeply($filter_func->()->([decode_json($case->{input_json})]), [$case->{exp}], "$filter_func OK");
    }
}

{
    note('--- apiurl option');
    my $apiurl = 'https://foobar.co.jp';
    my $input_gen = sub { {id => 109, user => { screen_name => "hoge" }} };
    my $exp = {
        id => "https://foobar.co.jp/statuses/show/109.json",
        busybird => { original => {
            id => 109
        }},
        user => { screen_name => "hoge" },
    };
    foreach my $label (qw(status_id all)) {
        no strict "refs";
        my $trans_func_name = "trans_twitter_$label";
        is_deeply($trans_func_name->($input_gen->(), $apiurl),
                  $exp,
                  "$trans_func_name: apiurl option ok"
        );
        my $filter_func_name = "filter_twitter_$label";
        is_deeply($filter_func_name->($apiurl)->([$input_gen->()]),
                  [$exp],
                  "$filter_func_name: apiurl option ok");
    }
}

{
    note("--- trans_twitter_unescape");
    foreach my $case (
        {label => "without entities", in_status_gen => sub {{
            text => '&amp; &lt; &gt; &amp; &quot;',
        }}, out_status => {
            text => q{& < > & "},
        }},

        {label => '&amp; should be unescaped at the last', in_status_gen => sub {{
            text => '&amp;gt; &amp;lt; &amp;amp; &amp;quot;'
        }}, out_status => {
            text => q{&gt; &lt; &amp; &quot;}
        }},
            
        {label => "with entities", in_status_gen => sub{{
            'text' => q{&lt;http://t.co/3Rh1Zcymvo&gt; " #test " $GOOG てすと&amp;hearts; ' @debug_ito '},
            'entities' => {
                'hashtags' => [ { 'text' => 'test', 'indices' => [33, 38] }],
                'user_mentions' => [ { 'indices' => [65,75], 'screen_name' => 'debug_ito' } ],
                'symbols' => [ { 'text' => 'GOOG', 'indices' => [41, 46] } ],
                'urls' => [ { 'url' => 'http://t.co/3Rh1Zcymvo', 'indices' => [4, 26] } ]
            },
        }}, out_status => {
            text => q{<http://t.co/3Rh1Zcymvo> " #test " $GOOG てすと&hearts; ' @debug_ito '},
            'entities' => {
                'hashtags' => [ { 'text' => 'test', 'indices' => [27, 32] }],
                'user_mentions' => [ { 'indices' => [55,65], 'screen_name' => 'debug_ito' } ],
                'symbols' => [ { 'text' => 'GOOG', 'indices' => [35, 40] } ],
                'urls' => [ { 'url' => 'http://t.co/3Rh1Zcymvo', 'indices' => [1, 23] } ],
            },
        }},
        
        {label => "with retweets", in_status_gen => sub{{
            'text' => 'RT @slashdot: Quadcopter Guided By Thought &amp;mdash; Accurately http://t.co/reAljIdd89',
            'entities' => {
                'hashtags' => [],
                'user_mentions' => [ {'screen_name' => 'slashdot',  'indices' => [3,12] } ],
                'symbols' => [],
                'urls' => [ { 'url' => 'http://t.co/reAljIdd89', 'indices' => [66,88] } ],
            },
            retweeted_status => {
                'text' => 'Quadcopter Guided By Thought &amp;mdash; Accurately http://t.co/reAljIdd89',
                'entities' => {
                    'hashtags' => [],
                    'user_mentions' => [],
                    'symbols' => [],
                    'urls' => [ { 'url' => 'http://t.co/reAljIdd89', 'indices' => [52,74]} ],
                },
            },
        }}, out_status => {
            text => 'RT @slashdot: Quadcopter Guided By Thought &mdash; Accurately http://t.co/reAljIdd89',
            'entities' => {
                'hashtags' => [],
                'user_mentions' => [ {'screen_name' => 'slashdot',  'indices' => [3,12] } ],
                'symbols' => [],
                'urls' => [ { 'url' => 'http://t.co/reAljIdd89', 'indices' => [62,84] } ],
            },
            retweeted_status => {
                'text' => 'Quadcopter Guided By Thought &mdash; Accurately http://t.co/reAljIdd89',
                'entities' => {
                    'hashtags' => [],
                    'user_mentions' => [],
                    'symbols' => [],
                    'urls' => [ { 'url' => 'http://t.co/reAljIdd89', 'indices' => [48,70]} ],
                },
            },
        }}
    ) {
        is_deeply(trans_twitter_unescape($case->{in_status_gen}->()),
                  $case->{out_status},
                  "trans $case->{label}: HTML unescape OK");
        is_deeply(filter_twitter_unescape()->([$case->{in_status_gen}->()]),
                  [$case->{out_status}],
                  "filter $case->{label}: HTML unescape OK");
    }
}

{
    note("--- filter_twitter should not croak at crazy statuses");
    my $filter = filter_twitter_all();
    foreach my $s (crazy_statuses()) {
        my $got = $filter->([$s]);
        is scalar(@$got), 1, "$s->{id}: filtered without exception";
    }
}

done_testing();
