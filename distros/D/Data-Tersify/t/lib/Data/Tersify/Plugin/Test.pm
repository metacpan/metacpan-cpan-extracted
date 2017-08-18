package Data::Tersify::Plugin::Test;

use strict;
use warnings;

sub handles { 'TestObject' }
sub tersify {
    my ($class, $object) = @_;

    return 'ID ' . $object->id;
}

1;
