use strict;
use warnings;
use Test::More import => ['!pass'];
use Test::Exception;
use Class::Load qw(load_class try_load_class);
use Dancer::Plugin::PageHistory::PageSet;
use File::Spec;
use File::Temp;
use HTTP::Cookies;
use HTTP::Request::Common;
use JSON qw//;
use Plack::Builder;
use Plack::Test;
use lib File::Spec->catdir( 't', 'TestApp', 'lib' );

# not yet supported: KiokuDB Redis
my @session_engines = (
    qw/
      CHI Cookie DBIC JSON Memcached Memcached::Fast MongoDB
      PSGI Simple Storable YAML
      /
);

my $release = $ENV{RELEASE_TESTING};
my $jar     = HTTP::Cookies->new;
my $test;

sub fail_or_diag {
    my $msg = shift;
    if ($release) {
        fail $msg;
    }
    else {
        diag $msg;
    }
}

sub get_history {
    my $uri = shift;
    my $req = GET "http://localhost$uri";
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    ok( $res->is_success, "get $uri OK" );
    $jar->extract_cookies($res);
    return Dancer::Plugin::PageHistory::PageSet->new(
        pages => JSON::from_json( $res->content ) );
}

sub run_tests {
    my $engine = shift;
    diag "Testing with $engine";

    my ( %settings, $history, $req, $res );

    # lots of session engines need a directory to store stuff in

    $settings{session_dir} = File::Temp::newdir(
        '_dpph_test.XXXX',
        CLEANUP => 1,
        EXLOCK  => 0,
        TMPDIR  => 1,
    );

    # engine-specific checks and setup

    if ( $engine eq 'DBIC' ) {
        unless ( try_load_class('DBIx::Class') ) {
            &fail_or_diag("DBIx::Class needed for this test");
            return;
        }
        unless ( try_load_class('DBD::SQLite') ) {
            &fail_or_diag("DBD::SQLite needed for this test");
            return;
        }
        load_class('TestApp::Schema');
        my $schema = TestApp::Schema->connect("dbi:SQLite:dbname=:memory:");
        $schema->deploy;
        $settings{session_options} = { schema => $schema };
    }
    elsif ( $engine =~ /^Memcached/ ) {
        my $cache_class = "Cache::$engine";
        unless ( try_load_class($cache_class) ) {
            &fail_or_diag("$cache_class needed for this test");
            return;
        }
        my $memd = $cache_class->new( { servers => ["127.0.0.1:11211"] } );
        my $ret = $memd->set( "_pagehistory_test.$$" => 1 );
        if ($ret) {
            $memd->delete("_pagehistory_test.$$");
        }
        else {
            &fail_or_diag("Cannot test $engine - cannot reach server");
            return;
        }
    }
    elsif ( $engine eq 'MongoDB' ) {
        my $conn;
        eval { $conn = MongoDB::Connection->new; };
        if ($@) {
            &fail_or_diag("MongoDB needs to be running for this test.");
            return;
        }
        my $engine;
        lives_ok( sub { $engine = Dancer::Session::MongoDB->create },
            "create mongodb" );
    }
    elsif ( $engine eq 'PSGI' ) {
        unless ( try_load_class('Plack::Middleware::Session') ) {
            &fail_or_diag("Plack::Middleware::Session needed for this test");
            return;
        }
    }
    elsif ( $engine eq 'YAML' ) {
        unless ( try_load_class('YAML') ) {
            &fail_or_diag("YAML needed for this test");
            return;
        }
    }

    # build the app

    my $app = sub {
        use Dancer;
        use Dancer::Plugin::PageHistory;

        set plugins => {
            PageHistory => {
                add_all_pages => 1,
                ignore_ajax   => 1,
                PageSet       => {
                    max_items => 3,
                    methods   => [qw/default product/],
                }
            }
        };

        set memcached_servers      => "127.0.0.1:11211";
        set mongodb_session_db     => 'test_dancer_plugin_pagehistory';
        set mongodb_auto_reconnect => 0;
        set redis_session          => { server => "127.0.0.1:6379", };
        set session_CHI            => { driver => 'Memory', global => 1 };
        set session_cookie_key     => 'notagood secret';
        set session_name           => 'dancer.session';
        set session_memcached_fast_servers   => "127.0.0.1:11211";
        set session_memcached_fast_namespace => "page_history_testing";

        while ( my ( $key, $value ) = each %settings ) {
            set $key => $value;
        }

        set session => $engine;

        #isa_ok( session, "Dancer::Session::$engine" );

        get '/session/class' => sub {
            my $session = session;
            return ref($session);
        };

        get '/session/destroy' => sub {
            session->destroy;
            return "destroyed";
        };

        get '/product/**' => sub {
            add_to_history( type => 'product' );
            pass;
        };

        get '/**' => sub {
            content_type('application/json');
            return to_json( session('page_history') );
        };

        my $env = shift;
        my $request = Dancer::Request->new( env => $env );
        Dancer->dance($request);
    };

    if ( $engine eq 'PSGI' ) {
        my $builder = Plack::Builder->new;
        $builder->add_middleware('Session');
        $app = $builder->wrap($app);
    }

    # let's test!

    $test = Plack::Test->create($app);
    $jar->clear;

    my $uri = "http://localhost";

    $req = GET "$uri/session/class", "X-Requested-With" => "XMLHttpRequest";
    $res = $test->request($req);
    ok( $res->is_success, "get /session/class OK" );
    $jar->extract_cookies($res);
    cmp_ok( $res->content, "eq", "Dancer::Session::$engine", "class is good" );

    $history = get_history('/one');
    cmp_ok( keys %{ $history->pages },  '==', 1,      "1 key in pages" );
    cmp_ok( @{ $history->default },     '==', 1,      "1 page type default" );
    cmp_ok( $history->latest_page->uri, "eq", "/one", "latest_page OK" );
    ok( !defined $history->previous_page, "previous_page undef" );

    $history = get_history('/two');
    cmp_ok( keys %{ $history->pages },  '==', 1,      "1 key in pages" );
    cmp_ok( @{ $history->default },     '==', 2,      "2 pages type default" );
    cmp_ok( $history->latest_page->uri, "eq", "/two", "latest_page OK" );
    cmp_ok( $history->previous_page->uri, "eq", "/one", "previous_page OK" );

    $history = get_history('/product/three');
    cmp_ok( keys %{ $history->pages }, '==', 2, "2 key in pages" );
    cmp_ok( @{ $history->default },    '==', 3, "3 pages type default" );
    cmp_ok( @{ $history->product },    '==', 1, "1 page type product" );
    cmp_ok( $history->latest_page->uri,
        "eq", "/product/three", "latest_page OK" );
    cmp_ok( $history->previous_page->uri, "eq", "/two", "previous_page OK" );

    $history = get_history('/four');
    cmp_ok( keys %{ $history->pages },  '==', 2,       "2 keys in pages" );
    cmp_ok( @{ $history->default },     '==', 3,       "3 pages type default" );
    cmp_ok( @{ $history->product },     '==', 1,       "1 page type product" );
    cmp_ok( $history->latest_page->uri, "eq", "/four", "latest_page OK" );
    cmp_ok( $history->previous_page->uri,
        "eq", "/product/three", "previous_page OK" );

    $req = GET "$uri/session/destroy", "X-Requested-With" => "XMLHttpRequest";
    $jar->add_cookie_header($req);
    $res = $test->request($req);
    ok( $res->is_success, "get /session/destroy OK" );

    $history = get_history('/one');
    cmp_ok( $history->latest_page->uri, "eq", "/one", "latest_page OK" );
    if ( $engine =~ /^(Cookie|PSGI)$/ ) {
      TODO: {
            local $TODO = "Cookie and PSGI don't handle destroy correctly";
            cmp_ok( keys %{ $history->pages }, '==', 1, "1 key in pages" );
            cmp_ok( @{ $history->default },    '==', 1, "1 page type default" );
            ok( !defined $history->previous_page, "previous_page undef" );
        }
    }
    else {
        cmp_ok( keys %{ $history->pages }, '==', 1, "1 key in pages" );
        cmp_ok( @{ $history->default },    '==', 1, "1 page type default" );
        ok( !defined $history->previous_page, "previous_page undef" );
    }

}

foreach my $engine (@session_engines) {

    my $session_class = "Dancer::Session::$engine";
    if ( try_load_class($session_class) ) {
        run_tests($engine);
    }
    else {
        if ($release) {
            fail "$session_class missing";
        }
        else {
            diag "$session_class missing so not testing this session engine";
        }
    }
}

done_testing;
