use strict;
use warnings;

use Bread::Board;

sub {
    # we add into container
    container shift() => as {
        service modified_by => __FILE__;
    };
}
