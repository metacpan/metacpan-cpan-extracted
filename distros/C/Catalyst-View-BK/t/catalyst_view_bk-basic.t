use Test::More;
use Test::MockObject;
use Cwd;

my $TEMPLATE = '<BKcommon::row attrib="1"><BKutil::bench></BKutil::bench></BKcommon::row><BKutil::tester></BKutil::tester>';

BEGIN: {
    #create our template directory and files
    warn 'creating test templtes';
    mkdir 'templates';
    open FH, '>templates/test.txml';
    print FH $TEMPLATE;
    close FH;

    plan tests => +1 # Test that we can use the module
                  +1 # Initialize test
                  +2 # Test the object methods
                  ;

    use_ok('Catalyst::View::BK');
    
}
my $body;
my $debug = Test::MockObject->new({});
$debug->set_true('debug');

my $response = Test::MockObject->new({});
$response->mock('body', sub { $body .= $_[1]});
$response->set_true('content_type');

my $cat = Test::MockObject->new({});
$cat->mock('config', sub {return {root => cwd()} } );
$cat->mock('stash', sub {return {'template' => 'test'} } );
$cat->mock('log', sub {return $debug});
$cat->mock('response', sub {return $response});
$cat->set_true('debug');

my $bk;

{
    ok($bk = Catalyst::View::BK->new($cat), 'initialize a view object'); 
}

{ # Render tests
    my $ep = 'tester was here :-)';
    $bk->render($cat, 'test');
    is($body, $ep, 'page text matches expected');
}
$bk->engine->clear();
$body = "";

TODO: { # process tests 
    local $TODO = "test the process method of this view";
    my $ep = 'tester was here :-)';
    $bk->process($cat);
    is($body, $ep, 'page text matches expected after render');
}
$bk->engine->clear();
$body = "";


END: {
    warn 'removing test directory';
    unlink 'templates/tmpl/test.txml';
    rmdir 'templates/tmpl';
    unlink 'templates/test.txml';
    rmdir 'templates';
}
