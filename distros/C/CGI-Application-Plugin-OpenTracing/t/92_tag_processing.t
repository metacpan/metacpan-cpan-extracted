use syntax 'maybe';
use Test::Most;
use Test::MockObject;
use Test::OpenTracing::Integration;
use Test::WWW::Mechanize::CGIApp;

{

    package MyTest::App;
    use base 'CGI::Application';

    use CGI::Application::Plugin::OpenTracing qw/Test/;
    use OpenTracing::GlobalTracer qw/$TRACER/;

    sub run_modes {
        start => 'rm_start',
        foo   => 'rm_foo',
        bar   => 'rm_bar',
    }
    sub rm_start { return }
    sub rm_foo   { return }
    sub rm_bar   { return }
}

my @tests = (
    {
        name  => 'query only',
        specs => {
            query => sub {
                token    => '###',
                location => undef,
            },
        },
        cases => [
            {
                name   => 'basic query',
                method => 'GET',
                query  => 'token=1234&location=UK&bar=XbarX',
                tags   => {
                    'run_method'       => 'rm_start',
                    'run_mode'         => 'start',
                    'http.query.token' => '###',
                    'http.query.bar'   => 'XbarX',
                },
            },
            {
                name   => 'form with names defined for query',
                method => 'POST',
                form   => { token => 1234, location => 'UK', bar => 'XbarX' },
                tags   => {
                    'run_method'         => 'rm_start',
                    'run_mode'           => 'start',
                    'http.form.token'    => '1234',
                    'http.form.bar'      => 'XbarX',
                    'http.form.location' => 'UK',
                },
            },
        ],
    },
    {
        name  => 'query with fallback',
        specs => {
            query => sub {
                token    => '###',
                location => undef,
                sub { "[@_]" },
            },
        },
        cases => [
            {
                name   => 'basic query',
                method => 'GET',
                query  => 'token=1234&location=UK&bar=XbarX',
                tags   => {
                    'run_method'       => 'rm_start',
                    'run_mode'         => 'start',
                    'http.query.token' => '###',
                    'http.query.bar'   => '[XbarX]',
                },
            },
            {
                name   => 'fallback does not work on form data',
                method => 'POST',
                form   => { token => 1234, location => 'UK', bar => 'XbarX' },
                tags   => {
                    'run_method'         => 'rm_start',
                    'run_mode'           => 'start',
                    'http.form.token'    => '1234',
                    'http.form.bar'      => 'XbarX',
                    'http.form.location' => 'UK',
                },
            },
        ],
    },
    {
        name  => 'undef fallback',
        specs => {
            query => sub {
                token => '###',
                sub { undef },
            },
        },
        cases => [
            {
                name   => 'all non-specified query params removed',
                method => 'GET',
                query  => 'token=1234&location=UK&bar=XbarX',
                tags   => {
                    'run_method'       => 'rm_start',
                    'run_mode'         => 'start',
                    'http.query.token' => '###',
                },
            },
        ],
    },
    {
        name  => 'form only',
        specs => {
            form => sub {
                password => '******',
                location => undef,
            },
        },
        cases => [
            {
                name   => 'basic form',
                method => 'POST',
                form   => {
                    password => 'hunter2',
                    location => 'UK',
                    bar      => 'XbarX'
                },
                tags => {
                    'run_method'         => 'rm_start',
                    'run_mode'           => 'start',
                    'http.form.password' => '******',
                    'http.form.bar'      => 'XbarX',
                },
            },
            {
                name   => 'query with names defined for form',
                method => 'GET',
                query  => 'password=hunter2&location=UK&bar=XbarX',
                tags   => {
                    'run_method'          => 'rm_start',
                    'run_mode'            => 'start',
                    'http.query.location' => 'UK',
                    'http.query.bar'      => 'XbarX',
                    'http.query.password' => 'hunter2',
                },
            },
        ],
    },
    {
        name  => 'form with fallback',
        specs => {
            form => sub {
                password => '******',
                location => undef,
                sub { "[@_]" },
            },
        },
        cases => [
            {
                name   => 'basic form',
                method => 'POST',
                form   => {
                    password => 'hunter2',
                    location => 'UK',
                    bar      => 'XbarX',
                    foo      => 'XfooX'
                },
                tags => {
                    'run_method'         => 'rm_start',
                    'run_mode'           => 'start',
                    'http.form.password' => '******',
                    'http.form.bar'      => '[XbarX]',
                    'http.form.foo'      => '[XfooX]',
                },
            },
            {
                name   => 'fallback does not work on query params',
                method => 'GET',
                query  => 'password=hunter2&location=UK&bar=XbarX&foo=XfooX',
                tags   => {
                    'run_method'          => 'rm_start',
                    'run_mode'            => 'start',
                    'http.query.location' => 'UK',
                    'http.query.bar'      => 'XbarX',
                    'http.query.foo'      => 'XfooX',
                    'http.query.password' => 'hunter2',
                },
            },
        ],
    },
    {
        name  => 'query and form',
        specs => {
            query => sub {
                id => sub { join ';', @_ },;
            },
            form => sub {
                password => undef,
                location => 'redacted',
            },
        },
        cases => [
            {
                name   => 'get with query and form defined',
                method => 'GET',
                query  => 'password=leaked&id=1&id=2',
                tags   => {
                    'run_method'          => 'rm_start',
                    'run_mode'            => 'start',
                    'http.query.id'       => '1;2',
                    'http.query.password' => 'leaked',
                },
            },
            {
                name   => 'post with query and form defined',
                method => 'POST',
                query  => 'password=leaked&id=1&id=2',
                form   => { location => 'whatever', password => '123' },
                tags   => {
                    'run_method'          => 'rm_start',
                    'run_mode'            => 'start',
                    'http.query.id'       => '1;2',
                    'http.query.password' => 'leaked',
                    'http.form.location'  => 'redacted',
                },
            },
        ],
    },
    {
        name  => 'query, form and generic',
        specs => {
            query => sub {
                id => sub { join ';', @_ },
                sub { "[@_]" },
            },
            form => sub {
                location => 'redacted',
                sub { "[@_]" },
            },
            generic => sub {
                password => undef,
            },
        },
        cases => [
            {
                name   => 'get with query and form defined',
                method => 'GET',
                query  => 'password=leaked&id=1&id=2',
                tags   => {
                    'run_method'    => 'rm_start',
                    'run_mode'      => 'start',
                    'http.query.id' => '1;2',
                },
            },
            {
                name   => 'post with query and form defined',
                method => 'POST',
                query  => 'password=leaked&id=1&id=2',
                form   => { location => 'whatever', password => '123' },
                tags   => {
                    'run_method'         => 'rm_start',
                    'run_mode'           => 'start',
                    'http.query.id'      => '1;2',
                    'http.form.location' => 'redacted',
                },
            },
        ],
    },
    {
        name  => 'query-generic fallback, no form fallback',
        specs => {
            query => sub {
                id => sub { join ';', @_ },
                sub { "[@_]" },
            },
            form => sub {
                location => 'redacted',
            },
            generic => sub {
                sub { "{-@_-}" },
            },
        },
        cases => [
            {
                name   => 'fall-through to generic fallback',
                method => 'POST',
                query  => 'id=1&id=2&token=11',
                form   => { location => 'whatever', token => '22' },
                tags   => {
                    'run_method'         => 'rm_start',
                    'run_mode'           => 'start',
                    'http.query.id'      => '1;2',
                    'http.query.token'   => '[11]',
                    'http.form.location' => 'redacted',
                    'http.form.token'    => '{-22-}',
                },
            },
        ],
    },
    {
        name  => 'form-generic fallback, no query fallback',
        specs => {
            query => sub {
                id => sub { join ';', @_ },
            },
            form => sub {
                location => 'redacted',
                sub { "[@_]" },
            },
            generic => sub {
                sub { "{-@_-}" },
            },
        },
        cases => [
            {
                name   => 'fall-through to generic fallback',
                method => 'POST',
                query  => 'id=1&id=2&token=11',
                form   => { location => 'whatever', token => '22' },
                tags   => {
                    'run_method'         => 'rm_start',
                    'run_mode'           => 'start',
                    'http.query.id'      => '1;2',
                    'http.query.token'   => '{-11-}',
                    'http.form.location' => 'redacted',
                    'http.form.token'    => '[22]',
                },
            },
        ],
    },
    {
        name  => 'join string via package var',
        specs => {
            query => sub {
                stuff => sub { [ map { "_$_" } @_ ] },
            },
            join_char => '+'
        },
        cases => [
            {
                name   => 'tags joined with the package var',
                method => 'GET',
                query  => 'id=1&id=2&id=3&stuff=x&stuff=y',
                tags   => {
                    'run_method'       => 'rm_start',
                    'run_mode'         => 'start',
                    'http.query.id'    => '1+2+3',
                    'http.query.stuff' => '_x+_y',
                },
            },
        ],
    },
    {
        name  => 'regex matching',
        specs => {
            query => sub {
                qr/id|num/ => sub { join ':', @_ },
            },
        },
        cases => [
            {
                name   => 'basic query',
                method => 'GET',
                query  => 'id=1&id=2&number=3&number=4&num=2&num=1',
                tags   => {
                    'run_method'        => 'rm_start',
                    'run_mode'          => 'start',
                    'http.query.id'     => '1:2',
                    'http.query.num'    => '2:1',
                    'http.query.number' => '3:4',
                },
            },
        ],
    },
    {
        name  => 'same formatter for multiple params',
        specs => {
            query => sub {
                [ 'id', 'num' ] => sub { join ':', @_ },
            },
        },
        cases => [
            {
                name   => 'basic query',
                method => 'GET',
                query  => 'id=1&id=2&number=3&number=4&num=2&num=1',
                tags   => {
                    'run_method'        => 'rm_start',
                    'run_mode'          => 'start',
                    'http.query.id'     => '1:2',
                    'http.query.num'    => '2:1',
                    'http.query.number' => '3,4',
                },
            },
        ],
    },
);

plan tests => scalar @tests;
foreach (@tests) {
    my ($test_name, $specs, $cases) = @$_{qw[ name specs cases ]};

    subtest $test_name => sub {
        plan tests => scalar @$cases;

        no warnings 'once';

        my $spec_query = $specs->{query};
        local *MyTest::App::opentracing_process_tags_query_params
            = $spec_query
            if defined $spec_query;

        my $spec_form = $specs->{form};
        local *MyTest::App::opentracing_process_tags_form_fields = $spec_form
            if defined $spec_form;

        my $spec_all = $specs->{generic};
        local *MyTest::App::opentracing_process_tags = $spec_all
            if defined $spec_all;

        my $spec_var = $specs->{join_char};
        local $CGI::Application::Plugin::OpenTracing::TAG_JOIN_CHAR
            = $spec_var
            if defined $spec_var;

        my $mech = Test::WWW::Mechanize::CGIApp->new(app => 'MyTest::App');
        foreach (@$cases) {
            my ($case_name, $method, $query, $form, $exp_tags)
                = @$_{qw[ name method query form tags ]};

            my $url      = 'https://test.tst/test.cgi';
            my $full_url = $url;
            $full_url .= "?$query" if defined $query;
            $method = lc $method;
            $mech->$method($full_url, maybe content => $form);

            my $exp_spans = [
                {
                    operation_name =>
                        'cgi_application_request',
                    tags => {
                        'component'             => "CGI::Application",
                        'http.method'           => uc $method,
                        'http.status_code'      => "200",
                        'http.status_message'   => "OK",
                        'http.url'              => $url,
                        %$exp_tags,
                    },
                }
            ];
            global_tracer_cmp_easy($exp_spans, $case_name);
        }
    };
}
