use strict;
use warnings;

use Test::More tests => 8;
use Test::WWW::Mechanize::PSGI;

{

    package MyApp;

    use lib 't/lib';

    use Dancer2;

    set views => 't/views';

    set show_errors => 1;
    set traces      => 1;

    set engines => {
        handlebars => { helpers => ['MyHelpers'] },
    };

    set template => 'handlebars';

    get '/string' => sub {
        template \'hello {{ you }}', { you => 'world', };
    };

    get '/file' => sub {
        template 'hello', { you => 'File', };
    };

    get '/helper' => sub {
        template 'helper', { name => 'Bob', };
    };

    get '/helper2' => sub {
        template 'helper2', { name => 'Bob', };
    };
}

my $mech = Test::WWW::Mechanize::PSGI->new( app => MyApp->to_app );

$mech->get_ok('/string');
$mech->content_contains('hello world');

$mech->get_ok('/file');
$mech->content_contains('Hello there, File');

$mech->get_ok('/helper');
$mech->content_contains('hello BOB');

$mech->get_ok('/helper2');
$mech->content_contains('hello bob');
