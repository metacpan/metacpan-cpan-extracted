use strict;
use Test::More;

use App::YG::Apache::Combined;

{
    # labels
    my $labels = App::YG::Apache::Combined::labels();
    is ref($labels), 'ARRAY', 'type of value';
}

done_testing;
