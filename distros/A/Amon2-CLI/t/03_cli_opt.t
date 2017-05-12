use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use Test::More;
use Test::Output;

use Amon2::CLI 'MyApp';

{
    local @ARGV = ('--option' => 'bar!');
    Test::Output::stdout_is {
        MyApp->bootstrap->run('Bar');
    } 'bar!', 'cli options';
}

done_testing;
