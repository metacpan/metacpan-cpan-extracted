use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use Test::More;
use Test::Output;

use Amon2::CLI 'MyApp';

{
    Test::Output::stdout_is {
        MyApp->bootstrap->run(sub{
            my ($c) = @_;
            print 'd!';
        });
    } 'd!', 'direct run!';
}

{
    Test::Output::stdout_is {
        MyApp->bootstrap->run('Foo');
    } 'done!', 'MyApp::CLI::Foo';
}

done_testing;
