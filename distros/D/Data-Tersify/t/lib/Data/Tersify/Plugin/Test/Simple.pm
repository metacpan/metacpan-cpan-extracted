package Data::Tersify::Plugin::Test::Simple;

use strict;
use warnings;

sub handles { 'TestObject' }
sub tersify {
    my ($class, $object) = @_;

    return 'ID ' . $object->id;
}

1;
