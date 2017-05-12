use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use Test::More;
use Test::Output;

use Amon2::CLI 'MyApp', 'MyApp::Cmd';

{
    Test::Output::stdout_is {
        MyApp->bootstrap->run('Foo'); # run MyApp::Cmd::Foo::main
    } 'cmd!', 'MyApp::Cmd::Foo';
}

done_testing;
