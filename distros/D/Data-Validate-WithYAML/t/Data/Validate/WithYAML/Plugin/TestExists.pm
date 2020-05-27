package
    Data::Validate::WithYAML::Plugin::TestExists;

use strict;
use warnings;

sub check {
    my ($class,$value,$config) = @_;
    
    if ( $value ) {
        return 1;
    }
    
    return;
}

1;
