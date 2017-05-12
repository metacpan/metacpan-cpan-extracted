use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use Test::More;
use Test::Output;

use Amon2::CLI 'MyApp';

{
    Test::Output::stdout_like {
        eval {
            MyApp->bootstrap->run(sub{
                my ($c) = @_;
                die 'die!';
            });
        };
        print "$@";
    } qr/die!/, 'dying';
}

done_testing;
