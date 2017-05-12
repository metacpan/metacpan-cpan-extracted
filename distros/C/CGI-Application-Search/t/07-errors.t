use Test::More;
use CGI;
use CGI::Application::Search;
use File::Spec::Functions qw(catfile);
use Test::LongString;
use lib './t/lib';

# setup our tests
plan(tests => 4);
$ENV{CGI_APP_RETURN_ONLY} = 1;

# 1..4
# use without a correct index
{
    # first an index that does not exist
    my $cgi = CGI->new({
        keywords    => 'please',    
        rm          => 'perform_search',
    });
    my $app = CGI::Application::Search->new(
        QUERY   => $cgi,
        PARAMS  => {
            SWISHE_INDEX => catfile('foo.txt'),
        },
    );
    eval { $app->run };
    ok($@);
    contains_string($@, 'Index file foo.txt does not exist!');
    
    # now a file that isn't an index
    $cgi = CGI->new({
        'index'     => 't/conf/not-a-swish-e.index',
        keywords    => 'please',    
        rm          => 'perform_search',
    });
    $app = CGI::Application::Search->new(
        QUERY   => $cgi,
        PARAMS  => {
            SWISHE_INDEX => catfile('t', 'conf', 'not-a-swish-e.index'),
        },
    );
    eval { $app->run };
    ok($@);
    contains_string($@, 'Problem reading');
}

