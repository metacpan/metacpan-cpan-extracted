use Test::More;
use Plack::Test;
use HTTP::Request::Common; # install separately
use File::Basename 'dirname';
use File::Spec;
 
{
    package SampleApp;
    BEGIN {
        use Dancer2;
        #set logger => 'Console::Colored';
        set logger => 'Null';
    }

    use Dancer2::Plugin::LiteBlog;
    set views => File::Spec->catfile( dirname(__FILE__), 'views');
    set appdir => File::Spec->catfile(dirname(__FILE__)),

    set log => 'info';
    
    set liteblog => {
        
        title => "Root Blog",
        base_url => 'http://localhost:4000',
        description => 'A great testing blog for testing purposes',
        logo  => '/images/liteblog.jpg',

        navigation => [
            { label => 'Home', link => '/'},
        ],

        widgets => [
            { name => 'blog',
              params => {
                    title => 'Read my Stories',
                    mount => '/', # should be understood as 'root'
                    root  => File::Spec->catfile(dirname(__FILE__), 'articles' ),
                },
            },
        ],
    };

    liteblog_init;
    1;
} 

my $app  = SampleApp->to_app;
my $test = Plack::Test->create($app);
 
subtest "A page mounted at the root of the site" => sub {
    my $res = $test->request( GET '/contact/' );
    is $res->code, 200, "/contact/ is OK";
    like $res->content, qr{You can contact me by email},
        "The /contact/ page is rendered correctly.";
    done_testing;
};

subtest "An article mounted at the root of the site" => sub {
    my $res = $test->request( GET '/tech/first-article/' );
    is $res->code, 200, "/tech/first-article/ is OK";
    like $res->content, qr{It's your time to start editing!},
        "The article /tech/first-article/ is rendered correctly.";
    done_testing;
};

subtest "RSS feed" => sub {
    my $res = $test->request( GET '/rss/' );
    is $res->code, 200, 'GET /rss/ returns a 200';
    is $res->content_type, 'application/rss+xml', 'content type is valid xml/rss';
    like $res->content, qr{<channel>.*<title>Root Blog</title>}s, "RSS feed contains <title> element";
    like $res->content, qr{<guid isPermaLink="true">http://localhost:4000/perl/article-perl-dup3/</guid>}, 
        "RSS content contains an article with a valid permalink";
    like $res->content, qr{<pubDate>(Mon|Tue|Wed|Thu|Fri|Sat|Sun), \d\d \w{3} \d{4} \d\d:\d\d:\d\d .\d{4}</pubDate>},
        "RSS feed contians a valid RFC 822 Date";

    $res = $test->request( GET '/rss/' );
    is $res->code, 200, 'Second call to GET /rss/ returns a 200 (cached)';
    is $res->content_type, 'application/rss+xml', 'Second call returns a valid content type (cache)';
    done_testing;
};


done_testing;
