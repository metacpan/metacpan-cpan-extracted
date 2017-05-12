use strict;
use Test::More;

use App::YG::Apache::Common;

{
    # labels
    my $labels = App::YG::Apache::Common::labels();
    is ref($labels), 'ARRAY', 'type of value';
}

done_testing;
