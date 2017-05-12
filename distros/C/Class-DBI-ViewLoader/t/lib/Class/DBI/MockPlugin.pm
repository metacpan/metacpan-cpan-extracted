package Class::DBI::MockPlugin;

use strict;
use warnings;

# simple Class::DBI plugin class with hand-made import function

sub import {
    my $caller = caller();

    no strict 'refs';
    ${$caller.'::MockPluginLoaded'} = 1;
}

1;

__END__
