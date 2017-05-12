
package Test::LoadingTraitsWithColonsInThem;

use strict;
use warnings;

use Class::Trait 'base';

sub isLoaded {
    return __PACKAGE__;
}

1;

