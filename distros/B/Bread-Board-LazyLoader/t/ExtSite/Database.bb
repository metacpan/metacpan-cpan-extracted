use strict;
use warnings;

use Bread::Board;

sub {
    my $cont = shift;

    # we replace the container
    my $name = $cont->name;
    container $name => as {     
        service modified_by => __FILE__;
    };
};
