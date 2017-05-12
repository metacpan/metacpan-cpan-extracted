use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use Test::More;
use Test::Output;

use MyHookApp;

{
    Test::Output::stdout_is {
        MyHookApp->bootstrap->run(sub{
            my ($c) = @_;
            print "hook!\n";
        });
    } "before_run!\nhook!\nafter_run!", 'hook!';
}

done_testing;
