use strict;
use Test::More;

use App::YG::Vmstat;

{
    # labels
    my $labels = App::YG::Vmstat::labels();
    is ref($labels), 'ARRAY', 'type of value';
}

done_testing;
