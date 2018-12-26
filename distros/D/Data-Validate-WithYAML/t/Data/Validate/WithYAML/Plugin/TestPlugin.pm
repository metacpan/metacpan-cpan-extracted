package
    Data::Validate::WithYAML::Plugin::TestPlugin;

use strict;
use warnings;

sub check {
    my ($class,$value,$config) = @_;
    
    if ( $value eq $config->{checkvalue} ) {
        return 1;
    }
    
    return;
}

1;
