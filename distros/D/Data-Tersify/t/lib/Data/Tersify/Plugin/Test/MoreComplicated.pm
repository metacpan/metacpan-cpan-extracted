package Data::Tersify::Plugin::Test::MoreComplicated;

use strict;
use warnings;

sub handles { 'TestObject::WithName', 'TestObject::WithUUID' }
sub tersify {
    my ($class, $object) = @_;

    return
          ref($object) eq 'TestObject::WithName' ? ('Name ' . $object->name)
        : ref($object) eq 'TestObject::WithUUID' ? ('UUID ' . $object->uuid)
        :                                          'What?!';
}

1;
